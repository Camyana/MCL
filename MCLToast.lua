-- ========================================================
-- MCL Toast Notification System
-- Shows themed toasts when mounts are collected:
--   • Blue   – mount collected
--   • Purple – category completed
--   • Orange – section completed
-- ========================================================
local _, MCLcore = ...

MCLcore.Toast = {}
local Toast = MCLcore.Toast
local L = MCLcore.L or {}

-- --------------------------------------------------------
-- Constants
-- --------------------------------------------------------
local TOAST_WIDTH      = 300
local TOAST_HEIGHT     = 80
local TOAST_DURATION   = 6      -- seconds visible
local TOAST_FADE_IN    = 0.4
local TOAST_FADE_OUT   = 0.8

-- Sound files (place .ogg files in addon folder)
local SOUND_COLLECTED       = "Interface\\AddOns\\MCL\\collected.ogg"
local SOUND_CATEGORY_DONE   = "Interface\\AddOns\\MCL\\category_complete.ogg"
local SOUND_SECTION_DONE    = "Interface\\AddOns\\MCL\\section_complete.ogg"

-- Theme colour palettes  { border, glow, accent, headerRight text }
local THEME = {
    collected = {
        border      = { 0.2, 0.6, 0.9, 0.8 },
        glow        = { 0.2, 0.6, 0.9, 0.15 },
        accent      = { 0.2, 0.6, 0.9, 0.6 },
        iconBorder  = { 0.3, 0.6, 0.9, 0.8 },
        titleColor  = { 0.3, 0.85, 0.4, 1 },
        sound       = SOUND_COLLECTED,
        soundSetting = "enableCollectedSound",
    },
    category = {
        border      = { 0.55, 0.3, 0.85, 0.9 },
        glow        = { 0.5, 0.2, 0.8, 0.2 },
        accent      = { 0.55, 0.3, 0.85, 0.7 },
        iconBorder  = { 0.6, 0.35, 0.9, 0.9 },
        titleColor  = { 0.7, 0.5, 1, 1 },
        sound       = SOUND_CATEGORY_DONE,
        soundSetting = "enableCategoryCompleteSound",
    },
    section = {
        border      = { 0.9, 0.55, 0.1, 0.9 },
        glow        = { 0.9, 0.5, 0.1, 0.25 },
        accent      = { 0.9, 0.55, 0.1, 0.8 },
        iconBorder  = { 1.0, 0.6, 0.1, 1.0 },
        titleColor  = { 1.0, 0.7, 0.2, 1 },
        sound       = SOUND_SECTION_DONE,
        soundSetting = "enableSectionCompleteSound",
    },
}

-- --------------------------------------------------------
-- Helpers: find which section & category a mount belongs to
-- --------------------------------------------------------
local function FindMountInfo(mountID)
    -- mountID here is the mount journal ID (number)
    if not MCLcore.sectionNames then return nil end

    for _, section in ipairs(MCLcore.sectionNames) do
        if section.mounts and section.mounts.categories then
            for catKey, catData in pairs(section.mounts.categories) do
                -- Check both mounts[] and mountID[] arrays
                local lists = { catData.mounts, catData.mountID }
                for _, list in ipairs(lists) do
                    if list then
                        for _, entry in ipairs(list) do
                            local resolvedID
                            if type(entry) == "string" and entry:sub(1,1) == "m" then
                                resolvedID = tonumber(entry:sub(2))
                            else
                                -- Resolve item/spell → mount ID
                                if MCLcore.Function and MCLcore.Function.GetMountID then
                                    resolvedID = MCLcore.Function:GetMountID(entry)
                                end
                            end
                            if resolvedID and resolvedID == mountID then
                                return section, catData
                            end
                        end
                    end
                end
            end
        end
    end
    return nil, nil
end

local function CountCategoryProgress(catData)
    if not catData then return 0, 0 end
    local total, collected = 0, 0
    local lists = { catData.mounts, catData.mountID }
    for _, list in ipairs(lists) do
        if list then
            for _, entry in ipairs(list) do
                local mId
                if type(entry) == "string" and entry:sub(1,1) == "m" then
                    mId = tonumber(entry:sub(2))
                elseif MCLcore.Function and MCLcore.Function.GetMountID then
                    mId = MCLcore.Function:GetMountID(entry)
                end
                if mId and mId > 0 then
                    -- Faction filter
                    local faction, factionSpecific
                    if MCLcore.Function and MCLcore.Function.IsMountFactionSpecific then
                        faction, factionSpecific = MCLcore.Function.IsMountFactionSpecific(entry)
                    end
                    local allowed = true
                    if factionSpecific then
                        local pf = UnitFactionGroup("player")
                        if faction == 0 then faction = "Horde" elseif faction == 1 then faction = "Alliance" end
                        allowed = (faction == pf)
                    end
                    if allowed then
                        total = total + 1
                        if IsMountCollected and IsMountCollected(mId) then
                            collected = collected + 1
                        end
                    end
                end
            end
        end
    end
    return collected, total
end

-- --------------------------------------------------------
-- Create the toast frame (once)
-- --------------------------------------------------------
local toastFrame

local function EnsureToastFrame()
    if toastFrame then return toastFrame end

    toastFrame = CreateFrame("Frame", "MCLToastFrame", UIParent, "BackdropTemplate")
    toastFrame:SetSize(TOAST_WIDTH, TOAST_HEIGHT)
    toastFrame:SetFrameStrata("DIALOG")
    toastFrame:SetFrameLevel(500)
    toastFrame:SetClampedToScreen(true)

    -- Restore saved position or default to top-center
    local pos = MCL_SETTINGS and MCL_SETTINGS.toastPosition
    if pos then
        toastFrame:ClearAllPoints()
        toastFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    else
        toastFrame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    end

    -- Backdrop – house style
    toastFrame:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    toastFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.95)
    toastFrame:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.8)

    -- Glow border (animated later)
    toastFrame.glow = toastFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
    toastFrame.glow:SetPoint("TOPLEFT", -3, 3)
    toastFrame.glow:SetPoint("BOTTOMRIGHT", 3, -3)
    toastFrame.glow:SetColorTexture(0.2, 0.6, 0.9, 0.15)

    -- Header stripe
    toastFrame.header = CreateFrame("Frame", nil, toastFrame, "BackdropTemplate")
    toastFrame.header:SetPoint("TOPLEFT", 1, -1)
    toastFrame.header:SetPoint("TOPRIGHT", -1, -1)
    toastFrame.header:SetHeight(22)
    toastFrame.header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    toastFrame.header:SetBackdropColor(0.08, 0.08, 0.12, 1)

    -- Accent line under header
    toastFrame.accent = toastFrame:CreateTexture(nil, "OVERLAY")
    toastFrame.accent:SetHeight(1)
    toastFrame.accent:SetPoint("TOPLEFT", toastFrame.header, "BOTTOMLEFT", 0, 0)
    toastFrame.accent:SetPoint("TOPRIGHT", toastFrame.header, "BOTTOMRIGHT", 0, 0)
    toastFrame.accent:SetColorTexture(0.2, 0.6, 0.9, 0.6)

    -- MCL label (top-left of header)
    toastFrame.label = toastFrame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toastFrame.label:SetPoint("LEFT", toastFrame.header, "LEFT", 8, 0)
    toastFrame.label:SetText("MCL")
    toastFrame.label:SetTextColor(0.4, 0.78, 0.95, 1)

    -- "Mount Collected!" text  (top-right of header)
    toastFrame.headerRight = toastFrame.header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toastFrame.headerRight:SetPoint("RIGHT", toastFrame.header, "RIGHT", -8, 0)
    toastFrame.headerRight:SetText(L["Mount Collected!"] or "Mount Collected!")
    toastFrame.headerRight:SetTextColor(0.3, 0.85, 0.4, 1)

    -- Mount icon (centered in content area below header)
    toastFrame.icon = toastFrame:CreateTexture(nil, "ARTWORK")
    toastFrame.icon:SetSize(36, 36)
    toastFrame.icon:SetPoint("LEFT", toastFrame, "LEFT", 10, -12)
    toastFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Icon border
    toastFrame.iconBorder = CreateFrame("Frame", nil, toastFrame, "BackdropTemplate")
    toastFrame.iconBorder:SetPoint("TOPLEFT", toastFrame.icon, "TOPLEFT", -1, 1)
    toastFrame.iconBorder:SetPoint("BOTTOMRIGHT", toastFrame.icon, "BOTTOMRIGHT", 1, -1)
    toastFrame.iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    toastFrame.iconBorder:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)

    -- Mount name
    toastFrame.mountName = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    toastFrame.mountName:SetPoint("TOPLEFT", toastFrame.icon, "TOPRIGHT", 8, 2)
    toastFrame.mountName:SetPoint("RIGHT", toastFrame, "RIGHT", -10, 0)
    toastFrame.mountName:SetJustifyH("LEFT")
    toastFrame.mountName:SetTextColor(1, 1, 1, 1)

    -- Category progress text
    toastFrame.categoryText = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toastFrame.categoryText:SetPoint("TOPLEFT", toastFrame.mountName, "BOTTOMLEFT", 0, -3)
    toastFrame.categoryText:SetPoint("RIGHT", toastFrame, "RIGHT", -10, 0)
    toastFrame.categoryText:SetJustifyH("LEFT")
    toastFrame.categoryText:SetTextColor(0.7, 0.78, 0.88, 1)

    -- Section progress text
    toastFrame.sectionText = toastFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    toastFrame.sectionText:SetPoint("TOPLEFT", toastFrame.categoryText, "BOTTOMLEFT", 0, -2)
    toastFrame.sectionText:SetPoint("RIGHT", toastFrame, "RIGHT", -10, 0)
    toastFrame.sectionText:SetJustifyH("LEFT")
    toastFrame.sectionText:SetTextColor(0.5, 0.55, 0.65, 1)

    -- Start hidden
    toastFrame:SetAlpha(0)
    toastFrame:Hide()

    -- Mouse interaction (left = navigate, right = dismiss)
    toastFrame:EnableMouse(true)
    toastFrame:SetScript("OnMouseUp", function(self, button)
        -- Don't intercept clicks when in unlock/drag mode
        if unlocked then return end

        if button == "RightButton" then
            -- Dismiss: immediately hide and show next queued toast
            Toast:DismissToast()
        elseif button == "LeftButton" then
            -- Navigate to the section in MCL
            Toast:DismissToast()
            Toast:NavigateToSection(self.toastSectionName)
        end
    end)

    -- Animation groups
    -- Fade in
    toastFrame.fadeIn = toastFrame:CreateAnimationGroup()
    local fadeInAlpha = toastFrame.fadeIn:CreateAnimation("Alpha")
    fadeInAlpha:SetFromAlpha(0)
    fadeInAlpha:SetToAlpha(1)
    fadeInAlpha:SetDuration(TOAST_FADE_IN)
    fadeInAlpha:SetSmoothing("OUT")
    toastFrame.fadeIn:SetScript("OnFinished", function()
        toastFrame:SetAlpha(1)
    end)

    -- Fade out
    toastFrame.fadeOut = toastFrame:CreateAnimationGroup()
    local fadeOutAlpha = toastFrame.fadeOut:CreateAnimation("Alpha")
    fadeOutAlpha:SetFromAlpha(1)
    fadeOutAlpha:SetToAlpha(0)
    fadeOutAlpha:SetDuration(TOAST_FADE_OUT)
    fadeOutAlpha:SetSmoothing("IN")
    toastFrame.fadeOut:SetScript("OnFinished", function()
        toastFrame:SetAlpha(0)
        toastFrame:Hide()
    end)

    return toastFrame
end

-- --------------------------------------------------------
-- Apply a theme to the toast frame
-- --------------------------------------------------------
local function ApplyTheme(frame, theme)
    local t = THEME[theme] or THEME.collected
    frame:SetBackdropBorderColor(unpack(t.border))
    frame.glow:SetColorTexture(unpack(t.glow))
    frame.accent:SetColorTexture(unpack(t.accent))
    frame.iconBorder:SetBackdropBorderColor(unpack(t.iconBorder))
    frame.headerRight:SetTextColor(unpack(t.titleColor))
end

-- --------------------------------------------------------
-- Show / Hide logic with toast queue
-- --------------------------------------------------------
local hideTimer
local toastQueue = {}
local isShowingToast = false

local function ShowNextInQueue()
    if #toastQueue == 0 then
        isShowingToast = false
        return
    end
    isShowingToast = true
    local next = table.remove(toastQueue, 1)
    next()
end

local function DisplayToast(theme, headerText, iconTex, iconCoords, line1, line2, line3, sectionName)
    local frame = EnsureToastFrame()

    -- Store section context for click-to-navigate
    frame.toastSectionName = sectionName or nil

    -- Apply theme
    ApplyTheme(frame, theme)

    -- Set content
    frame.headerRight:SetText(headerText)
    frame.icon:SetTexture(iconTex or "Interface\\Icons\\INV_Misc_QuestionMark")
    if iconCoords then
        frame.icon:SetTexCoord(unpack(iconCoords))
    else
        frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end
    frame.mountName:SetText(line1 or "")
    frame.categoryText:SetText(line2 or "")
    frame.sectionText:SetText(line3 or "")

    -- Stop any running animations / timers
    if frame.fadeOut:IsPlaying() then frame.fadeOut:Stop() end
    if frame.fadeIn:IsPlaying() then frame.fadeIn:Stop() end
    if hideTimer then hideTimer:Cancel(); hideTimer = nil end

    -- Play
    frame:Show()
    frame:SetAlpha(0)
    frame.fadeIn:Play()

    -- Play sound
    local t = THEME[theme] or THEME.collected
    if t.sound and (not MCL_SETTINGS or MCL_SETTINGS[t.soundSetting] ~= false) then
        PlaySoundFile(t.sound, "Master")
    end

    -- Schedule fade out, then show next queued toast
    hideTimer = C_Timer.NewTimer(TOAST_DURATION, function()
        if frame:IsShown() and not unlocked then
            frame.fadeOut:Play()
        end
        hideTimer = nil
        -- After fade completes, show next
        C_Timer.After(TOAST_FADE_OUT + 0.2, ShowNextInQueue)
    end)
end

local function QueueToast(fn)
    if isShowingToast then
        table.insert(toastQueue, fn)
    else
        isShowingToast = true
        fn()
    end
end

function Toast:ShowToast(mountID)
    -- Guard: setting must be enabled (default true)
    if MCL_SETTINGS and MCL_SETTINGS.enableCollectedToast == false then return end

    -- Get mount info from WoW API
    local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
    if not mountName then return end

    -- Find section & category in MCL data
    local section, catData = FindMountInfo(mountID)

    -- Build text lines
    local catLine = ""
    local sectionLine = ""
    local catCollected, catTotal = 0, 0

    if catData then
        catCollected, catTotal = CountCategoryProgress(catData)
        local catName = catData.name or "Unknown"
        catLine = catName .. ": " .. catCollected .. "/" .. catTotal
    end

    if section then
        local stats = MCLcore.stats and MCLcore.stats[section.name]
        if stats then
            sectionLine = section.name .. ": " .. stats.collected .. "/" .. stats.total
        else
            sectionLine = section.name
        end
    end

    -- Capture section name for click-to-navigate
    local sectionName = section and section.name or nil

    -- Queue the mount-collected toast
    QueueToast(function()
        DisplayToast("collected",
            L["Mount Collected!"] or "Mount Collected!",
            icon, nil, mountName, catLine, sectionLine, sectionName)
    end)

    -- Check for category completion → purple toast
    if catData and catTotal > 0 and catCollected >= catTotal then
        if not MCL_SETTINGS or MCL_SETTINGS.enableCategoryCompleteToast ~= false then
            local catName = catData.name or "Unknown"
            local secName = section and section.name or ""
            local secIcon = section and section.icon or nil
            QueueToast(function()
                DisplayToast("category",
                    L["Category Complete!"] or "Category Complete!",
                    secIcon, { 0, 1, 0, 1 },
                    catName,
                    catTotal .. "/" .. catTotal .. " " .. (L["mounts collected"] or "mounts collected"),
                    secName, secName)
            end)
        end
    end

    -- Check for section completion → orange/legendary toast
    if section then
        local stats = MCLcore.stats and MCLcore.stats[section.name]
        if stats and stats.total > 0 and stats.collected >= stats.total then
            if not MCL_SETTINGS or MCL_SETTINGS.enableSectionCompleteToast ~= false then
                local secIcon = section.icon or nil
                QueueToast(function()
                    DisplayToast("section",
                        L["Section Complete!"] or "Section Complete!",
                        secIcon, { 0, 1, 0, 1 },
                        section.name,
                        stats.total .. "/" .. stats.total .. " " .. (L["mounts collected"] or "mounts collected"),
                        L["Legendary!"] or "Legendary!", section.name)
                end)
            end
        end
    end
end

-- --------------------------------------------------------
-- Unlock mode (for repositioning)
-- --------------------------------------------------------
local unlocked = false

function Toast:ToggleUnlock()
    local frame = EnsureToastFrame()
    unlocked = not unlocked

    if unlocked then
        -- Show the frame in "edit" mode
        if frame.fadeOut:IsPlaying() then frame.fadeOut:Stop() end
        if frame.fadeIn:IsPlaying() then frame.fadeIn:Stop() end
        if hideTimer then hideTimer:Cancel(); hideTimer = nil end

        frame:Show()
        frame:SetAlpha(1)
        frame.mountName:SetText(L["Drag to reposition"] or "Drag to reposition")
        frame.categoryText:SetText(L["Click 'Lock Toast' when done"] or "Click 'Lock Toast' when done")
        frame.sectionText:SetText("")
        frame.icon:SetTexture("Interface\\AddOns\\MCL\\mcl-logo-32")
        frame.icon:SetTexCoord(0, 1, 0, 1)
        frame:SetBackdropBorderColor(0.9, 0.7, 0.2, 1)

        -- Make draggable
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save position
            local point, _, relPoint, x, y = self:GetPoint()
            if not MCL_SETTINGS then MCL_SETTINGS = {} end
            MCL_SETTINGS.toastPosition = { point = point, relPoint = relPoint, x = x, y = y }
        end)
    else
        -- Lock it
        frame:SetMovable(false)
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
        frame:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.8)

        -- Save final position
        local point, _, relPoint, x, y = frame:GetPoint()
        if not MCL_SETTINGS then MCL_SETTINGS = {} end
        MCL_SETTINGS.toastPosition = { point = point, relPoint = relPoint, x = x, y = y }

        -- Hide after a moment
        C_Timer.After(0.5, function()
            frame.fadeOut:Play()
        end)
    end

    return unlocked
end

function Toast:IsUnlocked()
    return unlocked
end

-- --------------------------------------------------------
-- Dismiss current toast and advance queue
-- --------------------------------------------------------
function Toast:DismissToast()
    local frame = EnsureToastFrame()
    if frame.fadeOut:IsPlaying() then frame.fadeOut:Stop() end
    if frame.fadeIn:IsPlaying() then frame.fadeIn:Stop() end
    if hideTimer then hideTimer:Cancel(); hideTimer = nil end
    frame:SetAlpha(0)
    frame:Hide()
    -- Advance to next toast after a brief pause
    C_Timer.After(0.15, ShowNextInQueue)
end

-- --------------------------------------------------------
-- Navigate MCL to a specific section by name
-- --------------------------------------------------------
function Toast:NavigateToSection(sectionName)
    if not sectionName then return end

    -- Make sure the main frame is visible
    if MCL_mainFrame and not MCL_mainFrame:IsShown() then
        MCL_mainFrame:Show()
    end

    -- Find the nav tab matching this section name and click it
    local tabs = MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs
    if tabs then
        for _, tab in ipairs(tabs) do
            if tab.section and tab.section.name == sectionName then
                -- Simulate clicking the tab
                if tab:GetScript("OnClick") then
                    tab:GetScript("OnClick")(tab)
                end
                return
            end
        end
    end
end

-- --------------------------------------------------------
-- Position helpers
-- --------------------------------------------------------
function Toast:SetPosition(x, y)
    local frame = EnsureToastFrame()
    frame:ClearAllPoints()
    frame:SetPoint("TOP", UIParent, "TOP", x, y)
    if not MCL_SETTINGS then MCL_SETTINGS = {} end
    MCL_SETTINGS.toastPosition = { point = "TOP", relPoint = "TOP", x = x, y = y }
end

function Toast:ResetPosition()
    self:SetPosition(0, -120)
end

function Toast:CenterPosition()
    self:SetPosition(0, -120)
end

function Toast:GetPosition()
    local pos = MCL_SETTINGS and MCL_SETTINGS.toastPosition
    if pos then
        return pos.x or 0, pos.y or -120
    end
    return 0, -120
end

-- --------------------------------------------------------
-- Event listener: NEW_MOUNT_ADDED
-- --------------------------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("NEW_MOUNT_ADDED")
eventFrame:SetScript("OnEvent", function(self, event, newMountID)
    if event == "NEW_MOUNT_ADDED" then
        -- Short delay so the mount journal updates first
        C_Timer.After(0.5, function()
            -- Recalculate stats so section progress is up-to-date
            if MCLcore.Function and MCLcore.Function.CalculateSectionStats then
                MCLcore.Function:CalculateSectionStats()
            end
            Toast:ShowToast(newMountID)
        end)
    end
end)


