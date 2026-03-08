-- =============================================================
-- GuideMapPanel.lua  -  World Map Legend Tab for MCL
--
-- Hooks into the Blizzard QuestMapFrame display-mode / tab
-- system (introduced in 11.1) to add an "MCL Mounts" tab that
-- sits alongside the Quests and Map Legend tabs.  When selected
-- it shows a scrollable list of mounts obtainable in the zone.
--
-- Pattern modelled after the Teleport Compendium tab from
-- EnhanceQoL (WorldMapDungeonPortals.lua).
-- =============================================================

local _, MCLcore = ...
local Guide = MCL_GUIDE

Guide.MapPanel = Guide.MapPanel or {}
local MapPanel = Guide.MapPanel

-- Constants
local DISPLAY_MODE = "MCL_MountGuide"
local MCL_ICON     = "Interface\\AddOns\\MCL\\mcl-logo-32"

-- State
local f         = CreateFrame("Frame")   -- event driver
local panel     = nil                     -- content frame
local scrollBox = nil                     -- scroll child
local tabButton = nil                     -- QuestLogTabButton
local refreshQueued = false

-- Card view state
local cardData          = nil   -- mount data when card is open (nil = list mode)
local cardView          = nil   -- card view container frame
local cardScrollBox     = nil   -- card view scroll child
local cardNotesExpanded = false

-- ================================================================
-- Gold formatting
-- ================================================================
local function FormatGold(copperAmount)
    if not copperAmount or copperAmount <= 0 then return nil end
    local gold = math.floor(copperAmount / 10000)
    if gold >= 1000 then
        return string.format("%s,%03dg", math.floor(gold / 1000), gold % 1000)
    elseif gold >= 1 then
        return tostring(gold) .. "g"
    else
        return tostring(copperAmount) .. "c"
    end
end

-- ================================================================
-- Detail text (cost / rep / achievement / drop chance)
-- ================================================================
local function GetDetailText(data)
    local parts = {}
    if data.spellId and MCL_GUIDE_CURRENCY_DATA then
        local costData = MCL_GUIDE_CURRENCY_DATA[data.spellId]
        if costData then
            for _, entry in ipairs(costData) do
                if entry.type == "gold" then
                    local gs = FormatGold(entry.amount)
                    if gs then parts[#parts + 1] = gs end
                elseif entry.type == "currency" and entry.id then
                    local info = C_CurrencyInfo.GetCurrencyInfo(entry.id)
                    if info and info.name then
                        local icon = info.iconFileID and ("|T" .. info.iconFileID .. ":12:12|t") or ""
                        local current = info.quantity or 0
                        local needed  = entry.amount
                        local clr     = current >= needed and "4CE04C" or "FF6666"
                        parts[#parts + 1] = icon .. " |cFF" .. clr .. current .. "/" .. needed .. "|r"
                    end
                end
            end
        end
    end
    if data.rep then
        local ri   = data.rep
        local name = ri.factionName or ""
        if ri.levelName then name = name .. " - " .. ri.levelName end
        if name ~= "" then parts[#parts + 1] = name end
    end
    if data.achievementId then
        local _, achName, _, achDone = GetAchievementInfo(data.achievementId)
        if achName then
            local status = achDone and "|cFF4CE04C Done|r" or ""
            parts[#parts + 1] = achName .. status
        end
    end
    if data.chance then
        parts[#parts + 1] = "1/" .. tostring(data.chance)
    end
    return table.concat(parts, "  |  ")
end

-- ================================================================
-- Safe visibility (alpha-based to avoid combat taint)
-- ================================================================
local function SafeSetVisible(frame, visible)
    if not frame then return end
    if frame == panel or frame == tabButton then
        frame._mclPendingVisible = visible and true or false
        frame:SetAlpha(visible and 1 or 0)
        return
    end
    if InCombatLockdown and InCombatLockdown() then
        frame._mclPendingVisible = visible and true or false
        frame:SetAlpha(visible and 1 or 0)
        return
    end
    if visible then frame:Show() else frame:Hide() end
end

-- ================================================================
-- Panel creation
-- ================================================================
local function EnsurePanel(parent)
    local targetParent = QuestMapFrame or parent
    if panel and panel:GetParent() ~= targetParent then panel:SetParent(targetParent) end
    if panel then return panel end

    panel = CreateFrame("Frame", "MCL_MapPanel", targetParent, "BackdropTemplate")
    if not InCombatLockdown() then panel:Hide() end

    local function anchorPanel()
        local ca = QuestMapFrame and QuestMapFrame.ContentsAnchor
        panel:ClearAllPoints()
        if ca and ca.GetWidth and ca:GetWidth() > 0 and ca:GetHeight() > 0 then
            panel:SetPoint("TOPLEFT",     ca, "TOPLEFT",     0, -29)
            panel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", -22, 0)
        else
            panel:SetAllPoints(panel:GetParent())
        end
    end

    anchorPanel()
    C_Timer.After(0,   anchorPanel)
    C_Timer.After(0.1, anchorPanel)

    if QuestMapFrame then
        panel:SetFrameStrata("HIGH")
        panel:SetFrameLevel((QuestMapFrame:GetFrameLevel() or 0) + 200)
    else
        panel:SetFrameStrata("HIGH")
    end
    panel:SetToplevel(true)
    panel:EnableMouse(true)
    panel:EnableMouseWheel(true)
    SafeSetVisible(panel, false)

    -- Scroll area
    local s = CreateFrame("ScrollFrame", "MCL_MapPanelScrollFrame", panel, "ScrollFrameTemplate")
    s:ClearAllPoints()
    s:SetPoint("TOPLEFT")
    s:SetPoint("BOTTOMRIGHT")

    -- Background (same atlas as Map Legend)
    local bg = s:CreateTexture(nil, "BACKGROUND")
    if bg.SetAtlas then bg:SetAtlas("QuestLog-main-background", true) end
    bg:ClearAllPoints()
    bg:SetPoint("TOPLEFT",     s, "TOPLEFT",     3, -1)
    bg:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT", -3, 0)

    -- Scrollbar positioning
    if s.ScrollBar then
        s.ScrollBar:ClearAllPoints()
        s.ScrollBar:SetPoint("TOPLEFT",    s, "TOPRIGHT",    8,  2)
        s.ScrollBar:SetPoint("BOTTOMLEFT", s, "BOTTOMRIGHT", 8, -4)
    end

    local content = CreateFrame("Frame", "MCL_MapPanelScrollChild", s)
    content:SetSize(1, 1)
    s:SetScrollChild(content)

    panel.Content = content
    panel.Scroll  = s

    -- Combat click blocker
    local blocker = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    blocker:SetAllPoints(s)
    blocker:EnableMouse(false)
    blocker:EnableMouseWheel(false)
    blocker:SetAlpha(0)
    panel.Blocker = blocker

    -- Frame levels
    local base = panel:GetFrameLevel() or 1
    s:SetFrameLevel(base + 1)
    content:SetFrameLevel(base + 2)

    -- Border (same as Map Legend)
    local bf = CreateFrame("Frame", nil, panel, "QuestLogBorderFrameTemplate")
    bf:ClearAllPoints()
    bf:SetPoint("TOPLEFT",     s, "TOPLEFT",     -3,  7)
    bf:SetPoint("BOTTOMRIGHT", s, "BOTTOMRIGHT",  3, -6)
    bf:SetFrameStrata(panel:GetFrameStrata())
    bf:SetFrameLevel((panel:GetFrameLevel() or 2) + 3)
    bf:EnableMouse(false)
    panel.BorderFrame = bf

    -- Title above the border
    local title = panel:CreateFontString(nil, "OVERLAY", "Game15Font_Shadow")
    title:SetPoint("BOTTOM", bf, "TOP", -1, 3)
    title:SetText("MCL Zone Mounts")
    panel.Title = title

    scrollBox = content
    panel.displayMode = DISPLAY_MODE

    -- Re-populate on resize
    s:HookScript("OnSizeChanged", function()
        if panel and panel:IsShown() then
            MapPanel:QueueRefresh()
        end
    end)

    return panel
end

-- ================================================================
-- Tab creation
-- ================================================================

-- Reposition ONLY MCL's tab below the last visible non-MCL tab.
-- Runs after every ValidateTabs() call so MCL always lands in the
-- correct slot regardless of addon load order.
local TAB_SPACING = -3
local function RepositionMCLTab()
    if not tabButton then return end
    if not QuestMapFrame or not QuestMapFrame.TabButtons then return end
    local lastOther = nil
    for _, btn in ipairs(QuestMapFrame.TabButtons) do
        if btn ~= tabButton and (btn:IsShown() or (btn.GetAlpha and btn:GetAlpha() > 0)) then
            lastOther = btn
        end
    end
    tabButton:ClearAllPoints()
    if lastOther then
        tabButton:SetPoint("TOP", lastOther, "BOTTOM", 0, TAB_SPACING)
    else
        -- Fallback: no other tabs visible, use default position
        tabButton:SetPoint("TOPRIGHT", QuestMapFrame, "TOPRIGHT", -6, -55)
    end
end

local function EnsureTab(parent)
    if tabButton and tabButton:GetParent() ~= parent then tabButton:SetParent(parent) end
    if tabButton then return tabButton end

    tabButton = CreateFrame("Button", "MCL_MapPanelTab", parent, "QuestLogTabButtonTemplate")
    -- Position is managed by RepositionMCLTab(); set a temporary anchor
    -- so the frame has valid geometry until the first layout pass.
    tabButton:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -6, -100)

    -- Tab metadata used by Blizzard's tab system
    tabButton.activeAtlas   = "questlog-tab-icon-maplegend"
    tabButton.inactiveAtlas = "questlog-tab-icon-maplegend-inactive"
    tabButton.tooltipText   = "MCL Zone Mounts"
    tabButton.displayMode   = DISPLAY_MODE

    -- Replace template icon with the MCL logo
    if tabButton.Icon then tabButton.Icon:SetAlpha(0) end
    local customIcon = tabButton:CreateTexture(nil, "ARTWORK")
    customIcon:SetPoint("CENTER", -2, 0)
    customIcon:SetSize(20, 20)
    customIcon:SetTexture(MCL_ICON)
    customIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tabButton.CustomIcon = customIcon

    -- Guard against Blizzard re-showing the template icon
    if tabButton.Icon then
        hooksecurefunc(tabButton.Icon, "Show",     function(icon) icon:SetAlpha(0) end)
        hooksecurefunc(tabButton.Icon, "SetAtlas",  function(icon) icon:SetAlpha(0) end)
    end

    -- Checked state: flip icon brightness
    if not tabButton._mclStateHooks then
        hooksecurefunc(tabButton, "SetChecked", function(self, checked)
            if self.CustomIcon then self.CustomIcon:SetDesaturated(not checked) end
        end)
        hooksecurefunc(tabButton, "Disable", function(self)
            if self.CustomIcon then self.CustomIcon:SetDesaturated(true) end
        end)
        hooksecurefunc(tabButton, "Enable", function(self)
            if self.CustomIcon then self.CustomIcon:SetDesaturated(false) end
        end)
        tabButton._mclStateHooks = true
    end

    -- Default: not selected
    if tabButton.SetChecked then tabButton:SetChecked(false) end
    SafeSetVisible(tabButton, true)

    -- Tooltip
    tabButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.tooltipText)
        GameTooltip:Show()
    end)
    tabButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Click: switch display mode
    tabButton:SetScript("OnMouseUp", function(self, button, upInside)
        if button ~= "LeftButton" or not upInside then return end
        if not panel then return end
        if QuestMapFrame and QuestMapFrame.SetDisplayMode then
            QuestMapFrame:SetDisplayMode(DISPLAY_MODE)
        end
    end)

    return tabButton
end

-- ================================================================
-- Data helpers
-- ================================================================
local function GetFilteredMounts(mapID)
    if not Guide.ready or not mapID then return {} end

    local includeChildren = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.showChildMapPins
    local hideCollected   = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.hideCollected

    local mapIDs = { mapID }
    if includeChildren and Guide.GetAllChildMapIDs then
        for _, childID in ipairs(Guide:GetAllChildMapIDs(mapID)) do
            mapIDs[#mapIDs + 1] = childID
        end
    end

    local seen    = {}
    local results = {}
    for _, mid in ipairs(mapIDs) do
        local spells = Guide.zoneMounts[mid]
        if spells then
            for _, spellId in ipairs(spells) do
                if not seen[spellId] then
                    seen[spellId] = true
                    local rec = Guide.mountLookup[spellId]
                    if rec and type(rec) == "table" then
                        local checkID = Guide.spellToMount[spellId] or rec.mountID
                        if checkID then
                            local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(checkID)
                            rec.isCollected = collected
                        end
                        if not rec.isCollected then
                            local mName = rec.mountName or rec.name
                            if mName and Guide.collectedNames[mName:lower()] then
                                rec.isCollected = true
                            end
                        end
                        if not (hideCollected and rec.isCollected) then
                            results[#results + 1] = rec
                        end
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if not a or not b then return false end
        local aCol = (a.isCollected == true)
        local bCol = (b.isCollected == true)
        if aCol ~= bCol then return not aCol end
        return (a.mountName or a.name or "") < (b.mountName or b.name or "")
    end)

    return results
end

-- Get ALL mounts in zone (ignoring hideCollected) for counts
local function GetFilteredMountsAll(mapID)
    if not Guide.ready or not mapID then return {} end
    local includeChildren = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.showChildMapPins
    local mapIDs = { mapID }
    if includeChildren and Guide.GetAllChildMapIDs then
        for _, childID in ipairs(Guide:GetAllChildMapIDs(mapID)) do
            mapIDs[#mapIDs + 1] = childID
        end
    end
    local seen, results = {}, {}
    for _, mid in ipairs(mapIDs) do
        local spells = Guide.zoneMounts[mid]
        if spells then
            for _, spellId in ipairs(spells) do
                if not seen[spellId] then
                    seen[spellId] = true
                    local rec = Guide.mountLookup[spellId]
                    if rec and type(rec) == "table" then
                        local checkID = Guide.spellToMount[spellId] or rec.mountID
                        if checkID then
                            local _, _, _, _, _, _, _, _, _, _, coll = C_MountJournal.GetMountInfoByID(checkID)
                            rec.isCollected = coll
                        end
                        if not rec.isCollected then
                            local mName = rec.mountName or rec.name
                            if mName and Guide.collectedNames[mName:lower()] then
                                rec.isCollected = true
                            end
                        end
                        results[#results + 1] = rec
                    end
                end
            end
        end
    end
    return results
end

-- ================================================================
-- Row creation (MapLegend style)
-- ================================================================
local ROW_HEIGHT    = 36
local LEFT_PADDING  = 12
local TOP_PADDING   = 10
local ROW_SPACING   = 2
local ICON_SIZE     = 28

local function CreateMountRow(parent, data, width)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(width, ROW_HEIGHT)
    row.data = data

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("LEFT", 4, 0)
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    row.Icon = icon

    -- Collected overlay
    if data.isCollected then
        icon:SetDesaturated(true)
        icon:SetAlpha(0.6)
        local check = row:CreateTexture(nil, "OVERLAY")
        check:SetSize(14, 14)
        check:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
        check:SetAtlas("Tracker-Check")
    end

    -- Mount name
    local nameLabel = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    nameLabel:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
    nameLabel:SetPoint("RIGHT", -6, 0)
    nameLabel:SetJustifyH("LEFT")
    nameLabel:SetWordWrap(false)
    nameLabel:SetText(data.mountName or data.name or "Unknown")
    if data.isCollected then
        nameLabel:SetTextColor(0.30, 0.88, 0.30)
    else
        nameLabel:SetTextColor(1.0, 0.82, 0.0)
    end
    row.Label = nameLabel

    -- Source method line
    local method = Guide:GetMethodText(data.method)
    local detail = GetDetailText(data)
    local subText = method or ""
    if detail and detail ~= "" then
        subText = subText .. "  |  " .. detail
    end

    local subLabel = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    subLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -1)
    subLabel:SetPoint("RIGHT", -6, 0)
    subLabel:SetJustifyH("LEFT")
    subLabel:SetWordWrap(false)
    subLabel:SetText(subText)
    subLabel:SetTextColor(0.60, 0.65, 0.72)
    row.SubLabel = subLabel

    -- Full-row highlight
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(row)
    if hl.SetAtlas then
        hl:SetAtlas("Options_List_Active", true)
        if hl.SetBlendMode then hl:SetBlendMode("ADD") end
    else
        hl:SetColorTexture(1, 1, 1, 0.08)
    end
    row:SetHighlightTexture(hl)

    -- Row interactions
    row:RegisterForClicks("LeftButtonUp", "RightButtonDown")
    row:SetScript("OnClick", function(self, button)
        if not self.data then return end
        if IsControlKeyDown() then
            if self.data.mountID then
                DressUpMount(self.data.mountID)
            end
        elseif button == "LeftButton" then
            MapPanel:ShowMountCard(self.data)
        else
            -- Right-click: set waypoint
            if Guide.MapPins and Guide.MapPins.PinMount then
                Guide.MapPins:PinMount(self.data)
            end
        end
    end)

    -- Tooltip
    row:SetScript("OnEnter", function(self)
        if self.SetHighlightLocked then
            self:SetHighlightLocked(true)
        else
            self:LockHighlight()
        end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local name = self.data and (self.data.mountName or self.data.name) or "Mount"
        GameTooltip:AddLine(name, 0.40, 0.78, 0.95)
        GameTooltip:AddLine("Left-click: Open mount details", 0.70, 0.70, 0.70)
        GameTooltip:AddLine("Right-click: Set waypoint", 0.70, 0.70, 0.70)
        GameTooltip:AddLine("Ctrl+click: Preview mount", 0.70, 0.70, 0.70)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        if self.SetHighlightLocked then
            self:SetHighlightLocked(false)
        else
            self:UnlockHighlight()
        end
        GameTooltip:Hide()
    end)

    -- Frame level
    if panel then
        row:SetFrameStrata(panel:GetFrameStrata())
        row:SetFrameLevel((panel:GetFrameLevel() or 1) + 10)
    end

    return row
end

-- ================================================================
-- Clear content
-- ================================================================
local function ClearContent()
    if not scrollBox then return end
    for _, child in ipairs({ scrollBox:GetChildren() }) do
        child:Hide()
        child:SetParent(nil)
    end
end

-- ================================================================
-- Populate panel with mount rows
-- ================================================================
local function PopulatePanel()
    if not panel then return end
    ClearContent()

    local mapID = WorldMapFrame and WorldMapFrame:GetMapID()
    if not mapID then
        local msg = scrollBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        msg:SetPoint("TOPLEFT", 10, -10)
        msg:SetText("Open the World Map to a zone.")
        scrollBox:SetHeight(40)
        return
    end

    -- Zone title
    local mapInfo = C_Map.GetMapInfo(mapID)
    local zoneName = mapInfo and mapInfo.name or ("Map " .. mapID)
    if panel.Title then panel.Title:SetText("MCL  -  " .. zoneName) end

    local mounts = GetFilteredMounts(mapID)

    if #mounts == 0 then
        local msg = scrollBox:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        msg:SetPoint("TOPLEFT", 10, -10)
        msg:SetText("No mounts found for this zone.")
        scrollBox:SetHeight(40)
        return
    end

    -- Count
    local allMounts = GetFilteredMountsAll(mapID)
    local total     = allMounts and #allMounts or 0
    local collected = 0
    if allMounts then
        for _, m in ipairs(allMounts) do
            if m.isCollected then collected = collected + 1 end
        end
    end

    -- Layout
    local scrollW      = panel.Scroll:GetWidth() or 330
    local scrollbarW   = (panel.Scroll.ScrollBar and panel.Scroll.ScrollBar:GetWidth()) or 18
    local usableWidth  = math.max(120, scrollW - scrollbarW - 20)

    local yOffset = -TOP_PADDING

    -- Section header with count
    local header = scrollBox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    header:SetPoint("TOPLEFT", LEFT_PADDING, yOffset)
    header:SetFont(header:GetFont(), 13, "OUTLINE")
    header:SetText(string.format("Mounts (%d/%d collected)", collected, total))
    yOffset = yOffset - (header:GetStringHeight() or 14) - 6

    -- Mount rows
    for _, data in ipairs(mounts) do
        local row = CreateMountRow(scrollBox, data, usableWidth)
        row:SetPoint("TOPLEFT", scrollBox, "TOPLEFT", LEFT_PADDING, yOffset)
        yOffset = yOffset - ROW_HEIGHT - ROW_SPACING
    end

    scrollBox:SetHeight(math.abs(yOffset) + TOP_PADDING)
    if panel.Scroll and panel.Scroll.UpdateScrollChildRect then
        panel.Scroll:UpdateScrollChildRect()
    end
end

-- ================================================================
-- Mount Card View (inline in panel)
-- ================================================================

-- Notes lookup (mount journal ID → note string)
local noteCache = nil
local function GetMountNote(mountID)
    if not MCLcore or not MCLcore.mountNotes then return nil end
    if not noteCache then
        noteCache = {}
        for ref, note in pairs(MCLcore.mountNotes) do
            local jid
            if type(ref) == "string" and ref:sub(1, 1) == "m" then
                jid = tonumber(ref:sub(2))
            elseif type(ref) == "number" then
                jid = C_MountJournal.GetMountFromItem(ref)
            elseif type(ref) == "string" and tonumber(ref) then
                jid = C_MountJournal.GetMountFromItem(tonumber(ref))
            end
            if jid and note and note ~= "" then noteCache[jid] = note end
        end
    end
    return noteCache[mountID]
end

local function ClearCardContent()
    if not cardScrollBox then return end
    for _, c in ipairs({ cardScrollBox:GetChildren() }) do c:Hide(); c:SetParent(nil) end
    for _, r in ipairs({ cardScrollBox:GetRegions() })  do r:Hide(); r:SetParent(nil) end
end

local function EnsureCardView()
    if cardView then return cardView end

    cardView = CreateFrame("Frame", "MCL_MapPanelCard", panel)
    cardView:SetAllPoints(panel)
    cardView:Hide()

    -- Background atlas matching the list view
    local bg = cardView:CreateTexture(nil, "BACKGROUND")
    if bg.SetAtlas then bg:SetAtlas("QuestLog-main-background", true) end
    bg:SetAllPoints()

    -- Back button
    local bb = CreateFrame("Button", nil, cardView)
    bb:SetSize(60, 18)
    bb:SetPoint("TOPLEFT", 8, -6)
    bb:SetFrameLevel((cardView:GetFrameLevel() or 1) + 10)
    local bt = bb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bt:SetPoint("LEFT")
    bt:SetJustifyH("LEFT")
    bt:SetText("< Back")
    bt:SetTextColor(0.4, 0.78, 0.95, 1)
    bb:SetScript("OnClick", function() MapPanel:ShowListView() end)
    bb:SetScript("OnEnter", function() bt:SetTextColor(1, 1, 1, 1) end)
    bb:SetScript("OnLeave", function() bt:SetTextColor(0.4, 0.78, 0.95, 1) end)

    -- Scroll frame for card content
    local sf = CreateFrame("ScrollFrame", "MCL_MapPanelCardScroll", cardView, "ScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", 0, -24)
    sf:SetPoint("BOTTOMRIGHT", 0, 0)
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local mx  = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * 40)))
    end)
    if sf.ScrollBar then
        sf.ScrollBar:ClearAllPoints()
        sf.ScrollBar:SetPoint("TOPLEFT",    sf, "TOPRIGHT",    8,  2)
        sf.ScrollBar:SetPoint("BOTTOMLEFT", sf, "BOTTOMRIGHT", 8, -4)
    end

    local ch = CreateFrame("Frame", "MCL_MapPanelCardChild", sf)
    ch:SetSize(1, 1)
    sf:SetScrollChild(ch)
    ch:EnableMouseWheel(true)
    ch:SetScript("OnMouseWheel", function(self, delta)
        local p = self:GetParent()
        if p and p.GetVerticalScroll then
            local cur = p:GetVerticalScroll()
            local mx  = p:GetVerticalScrollRange()
            p:SetVerticalScroll(math.max(0, math.min(mx, cur - delta * 40)))
        end
    end)

    cardView.Scroll  = sf
    cardView.Content = ch
    cardScrollBox    = ch
    return cardView
end

-- Reusable waypoint button for the card view
local function MakeWaypointBtn(parent, mapId, wx, wy, label, xPos, yPos)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetHeight(18)
    b:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos, yPos)
    b:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b:SetBackdropColor(0.1, 0.15, 0.22, 0.9)
    b:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.5)

    local ico = b:CreateTexture(nil, "ARTWORK")
    ico:SetSize(12, 12)
    ico:SetPoint("LEFT", 4, 0)
    ico:SetTexture("Interface\\AddOns\\MCL\\icons\\pin")
    ico:SetVertexColor(0.2, 0.6, 0.9, 1)

    local tx = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tx:SetPoint("LEFT", ico, "RIGHT", 3, 0)
    tx:SetText(label or "Waypoint")
    tx:SetTextColor(0.4, 0.78, 0.95, 1)
    b:SetSize(tx:GetStringWidth() + 25, 18)

    b:SetScript("OnEnter", function(s)
        s:SetBackdropBorderColor(0.3, 0.7, 1, 1)
        s:SetBackdropColor(0.15, 0.2, 0.28, 1)
    end)
    b:SetScript("OnLeave", function(s)
        s:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.5)
        s:SetBackdropColor(0.1, 0.15, 0.22, 0.9)
    end)
    b:SetScript("OnClick", function()
        if TomTom and TomTom.AddWaypoint then
            TomTom:AddWaypoint(mapId, wx / 100, wy / 100, {
                title = label or "Mount", persistent = false,
                minimap = true, world = true,
            })
        else
            local v = CreateVector2D(wx / 100, wy / 100)
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(mapId, v))
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        OpenWorldMap(mapId)
        tx:SetTextColor(0.3, 0.85, 0.4, 1)
        tx:SetText("Set!")
        C_Timer.After(1.5, function()
            tx:SetTextColor(0.4, 0.78, 0.95, 1)
            tx:SetText(label or "Waypoint")
        end)
    end)
    return b
end

-- ── Populate the card view with mount data ──
local function PopulateCard(data)
    if not cardScrollBox or not data then return end
    ClearCardContent()

    local mountID = data.mountID
    if not mountID then return end

    local mountName, spellID, icon, _, _, _, _, _, _, _, isCollected =
        C_MountJournal.GetMountInfoByID(mountID)
    if not mountName then return end

    local creatureDisplayID, description, blizzSource =
        C_MountJournal.GetMountInfoExtraByID(mountID)

    local pw = (panel and panel:GetWidth()) or 300
    local cw = pw - 24
    local y  = -6
    local P  = cardScrollBox

    -- helper: add a label + value row
    local function Row(label, value, lClr, vClr)
        local l = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        l:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
        l:SetText(label)
        l:SetTextColor(unpack(lClr or {0.5, 0.55, 0.65, 1}))

        local v = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        v:SetPoint("LEFT", l, "RIGHT", 4, 0)
        v:SetWidth(cw - (l:GetStringWidth() or 40) - 12)
        v:SetText(value)
        v:SetTextColor(unpack(vClr or {0.8, 0.8, 0.85, 1}))
        v:SetJustifyH("LEFT")
        v:SetWordWrap(false)
        y = y - 16
        return l, v
    end

    -- ── Mount Header (icon + name + collected) ──
    local hdr = CreateFrame("Frame", nil, P)
    hdr:SetSize(cw, 30)
    hdr:SetPoint("TOPLEFT", P, "TOPLEFT", 8, y)

    local mi = hdr:CreateTexture(nil, "ARTWORK")
    mi:SetSize(26, 26)
    mi:SetPoint("LEFT")
    mi:SetTexture(icon or data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    mi:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local mn = hdr:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mn:SetPoint("LEFT", mi, "RIGHT", 8, 0)
    mn:SetPoint("RIGHT", hdr, "RIGHT", -4, 0)
    mn:SetJustifyH("LEFT")
    mn:SetWordWrap(false)
    mn:SetText(mountName)

    if isCollected then
        mn:SetTextColor(0.30, 0.88, 0.30)
        mi:SetDesaturated(true)
        mi:SetAlpha(0.6)
        local ck = hdr:CreateTexture(nil, "OVERLAY")
        ck:SetSize(14, 14)
        ck:SetPoint("BOTTOMRIGHT", mi, "BOTTOMRIGHT", 2, -2)
        ck:SetAtlas("Tracker-Check")
    else
        mn:SetTextColor(1, 0.82, 0)
    end
    y = y - 34

    -- ── 3D Model Preview ──
    local mH = 160
    local mf = CreateFrame("Frame", nil, P, "BackdropTemplate")
    mf:SetSize(cw, mH)
    mf:SetPoint("TOPLEFT", P, "TOPLEFT", 8, y)
    mf:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    mf:SetBackdropColor(0.04, 0.04, 0.06, 0.6)
    mf:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.5)

    if creatureDisplayID and creatureDisplayID > 0 then
        local mdl = CreateFrame("PlayerModel", nil, mf)
        mdl:SetAllPoints()
        mdl:ClearModel()
        C_Timer.After(0.1, function()
            mdl:SetDisplayInfo(creatureDisplayID)
            mdl:SetCamera(2)
            mdl:SetPosition(0, 0, 0)
            mdl:SetFacing(0)
            mdl:RefreshCamera()
        end)
        -- Drag to rotate
        local drag, lx = false, 0
        mdl:EnableMouse(true)
        mdl:SetScript("OnMouseDown", function(_, b)
            if b == "LeftButton" then drag = true; lx = GetCursorPosition() end
        end)
        mdl:SetScript("OnMouseUp", function(_, b)
            if b == "LeftButton" then drag = false end
        end)
        mdl:SetScript("OnUpdate", function(s)
            if drag then
                local cx = GetCursorPosition()
                s:SetFacing(s:GetFacing() + (cx - lx) * 0.01)
                lx = cx
            end
        end)
        -- Mouse wheel zoom
        local zm = 1.0
        mdl:EnableMouseWheel(true)
        mdl:SetScript("OnMouseWheel", function(s, d)
            zm = math.max(0.3, math.min(3, zm - d * 0.15))
            s:SetCamDistanceScale(zm)
        end)
    else
        local fi = mf:CreateTexture(nil, "ARTWORK")
        fi:SetSize(64, 64)
        fi:SetPoint("CENTER")
        fi:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    y = y - mH - 4

    -- ── Action button row ──
    local aRow = CreateFrame("Frame", nil, P)
    aRow:SetSize(cw, 20)
    aRow:SetPoint("TOPLEFT", P, "TOPLEFT", 8, y)

    -- Preview button
    local prevBtn = CreateFrame("Button", nil, aRow, "BackdropTemplate")
    prevBtn:SetSize(70, 18)
    prevBtn:SetPoint("LEFT", aRow, "LEFT", 0, 0)
    prevBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    prevBtn:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
    prevBtn:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)
    local prevTxt = prevBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    prevTxt:SetAllPoints()
    prevTxt:SetText("Preview")
    prevTxt:SetTextColor(0.4, 0.78, 0.95, 1)
    prevBtn:SetScript("OnClick", function() DressUpMount(mountID) end)
    prevBtn:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(0.35, 0.55, 0.8, 0.9); prevTxt:SetTextColor(1, 1, 1, 1) end)
    prevBtn:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6); prevTxt:SetTextColor(0.4, 0.78, 0.95, 1) end)

    -- Wowhead button
    local whBtn = CreateFrame("Button", nil, aRow, "BackdropTemplate")
    whBtn:SetSize(70, 18)
    whBtn:SetPoint("LEFT", prevBtn, "RIGHT", 6, 0)
    whBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    whBtn:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
    whBtn:SetBackdropBorderColor(0.6, 0.45, 0.15, 0.6)
    local whTxt = whBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    whTxt:SetAllPoints()
    whTxt:SetText("Wowhead")
    whTxt:SetTextColor(0.9, 0.6, 0.2, 1)
    whBtn:SetScript("OnClick", function()
        -- Lazy-create copy popup
        if not cardView._copyPopup then
            local cp = CreateFrame("Frame", nil, cardView, "BackdropTemplate")
            cp:SetSize(pw - 20, 28)
            cp:SetPoint("TOP", cardView, "TOP", 0, -48)
            cp:SetFrameStrata("DIALOG")
            cp:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            cp:SetBackdropColor(0.1, 0.1, 0.14, 0.95)
            cp:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
            cp:EnableMouse(true)
            cp:Hide()
            local eb = CreateFrame("EditBox", nil, cp)
            eb:SetPoint("LEFT", 8, 0)
            eb:SetPoint("RIGHT", -8, 0)
            eb:SetHeight(18)
            eb:SetFontObject("ChatFontNormal")
            eb:SetAutoFocus(false)
            eb:SetScript("OnEscapePressed", function() cp:Hide() end)
            eb:SetScript("OnEditFocusLost", function()
                C_Timer.After(0.1, function()
                    if cp:IsShown() and not eb:HasFocus() then cp:Hide() end
                end)
            end)
            cardView._copyPopup = cp
            cardView._copyEB    = eb
        end
        local url = "https://www.wowhead.com/mount/" .. mountID
        cardView._copyEB:SetText(url)
        cardView._copyPopup:Show()
        cardView._copyEB:SetFocus()
        cardView._copyEB:HighlightText()
        whTxt:SetTextColor(0.3, 0.85, 0.4, 1)
        whTxt:SetText("Copied!")
        C_Timer.After(1.5, function()
            whTxt:SetTextColor(0.9, 0.6, 0.2, 1)
            whTxt:SetText("Wowhead")
        end)
    end)
    whBtn:SetScript("OnEnter", function(s) s:SetBackdropBorderColor(0.8, 0.6, 0.2, 0.9); whTxt:SetTextColor(1, 0.8, 0.3, 1) end)
    whBtn:SetScript("OnLeave", function(s) s:SetBackdropBorderColor(0.6, 0.45, 0.15, 0.6); whTxt:SetTextColor(0.9, 0.6, 0.2, 1) end)

    y = y - 24

    -- ── Description ──
    if description and description ~= "" then
        local d = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        d:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
        d:SetWidth(cw - 4)
        d:SetText(description)
        d:SetTextColor(0.9, 0.9, 0.2, 1)
        d:SetJustifyH("LEFT")
        d:SetWordWrap(true)
        y = y - d:GetStringHeight() - 6
    end

    -- separator
    local sep = P:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
    sep:SetWidth(cw - 4)
    sep:SetColorTexture(0.25, 0.25, 0.3, 0.6)
    y = y - 6

    -- ── Source Details ──
    local gd = Guide.mountLookup and Guide.mountLookup[spellID]
    local mt = Guide:GetMethodText(data.method or (gd and gd.method))
    if mt then Row("Source:", mt, nil, {0.4, 0.78, 0.95, 1}) end

    if gd then
        -- Drop rate
        if gd.chance and gd.chance > 0 then
            local pct = (1 / gd.chance) * 100
            local s
            if pct >= 1 then
                s = string.format("1/%d (%d%%)", gd.chance, pct)
            elseif pct >= 0.1 then
                s = string.format("1/%d (%.1f%%)", gd.chance, pct)
            else
                s = string.format("1/%d (%.2f%%)", gd.chance, pct)
            end
            local c
            if pct >= 10 then     c = {0.3, 0.85, 0.4, 1}
            elseif pct >= 1 then  c = {0.9, 0.9, 0.2, 1}
            elseif pct >= 0.1 then c = {0.9, 0.55, 0.1, 1}
            else                   c = {0.9, 0.25, 0.25, 1} end
            Row("Drop Rate:", s, nil, c)
        end

        -- NPC
        local npc = gd.lockBossName or (gd.coords and gd.coords[1] and gd.coords[1].n)
        if npc then Row("NPC:", npc) end

        -- Zone / Coords / Waypoint (skip instance mounts)
        local instCoords = gd.coords and gd.coords[1] and gd.coords[1].i
        local bossOnly   = gd.lockBossName and not (gd.coords and gd.coords[1])
        if not instCoords and not bossOnly and gd.coords and gd.coords[1] and gd.coords[1].m then
            local co = gd.coords[1]
            local zi = C_Map.GetMapInfo(co.m)
            if zi and zi.name then Row("Zone:", zi.name) end
            if co.x and co.y then
                Row("Coords:", string.format("%.1f, %.1f", co.x, co.y))
                MakeWaypointBtn(P, co.m, co.x, co.y,
                    string.format("%s (%.1f, %.1f)", zi and zi.name or "Go", co.x, co.y), 10, y)
                y = y - 22
            end
        end
    end

    -- ── Reputation ──
    if MCL_GUIDE_GET_REP_INFO and spellID then
        local rep = MCL_GUIDE_GET_REP_INFO(spellID)
        if rep then
            y = y - 4
            local rl = rep.isFriendship and "Friendship:" or rep.isRenown and "Renown:" or "Reputation:"
            Row(rl, rep.factionName, nil, {0.4, 0.78, 0.95, 1})
            Row("Required:", rep.requiredText, nil, {0.9, 0.9, 0.2, 1})
            local curClr = rep.isMet and {0.3, 0.85, 0.4, 1} or {0.9, 0.25, 0.25, 1}
            Row("Current:", rep.currentText, nil, curClr)
            if rep.vendorName and rep.vendorMapId and rep.vendorX and rep.vendorY then
                Row("Vendor:", string.format("%s (%.1f, %.1f)", rep.vendorName, rep.vendorX, rep.vendorY))
                MakeWaypointBtn(P, rep.vendorMapId, rep.vendorX, rep.vendorY, rep.vendorName, 10, y)
                y = y - 22
            end
        end
    end

    -- ── Currency / Cost ──
    if MCL_GUIDE_CURRENCY_DATA then
        local gItemId = gd and gd.itemId
        if not gItemId and MCL_GUIDE_DATA and MCL_GUIDE_DATA.mounts and spellID then
            local raw = MCL_GUIDE_DATA.mounts[spellID]
            if raw then gItemId = raw.itemId end
        end
        local cl = spellID and MCL_GUIDE_CURRENCY_DATA[spellID]
        if not cl and gItemId then cl = MCL_GUIDE_CURRENCY_DATA[gItemId] end
        if cl and #cl > 0 then
            y = y - 4
            for i, cost in ipairs(cl) do
                local cn, ci, ph = "?", nil, 0
                local rq = cost.amount or 0
                if cost.type == "currency" and cost.id > 0 then
                    local inf = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(cost.id)
                    if inf then cn = inf.name or cn; ci = inf.iconFileID; ph = inf.quantity or 0 end
                elseif cost.type == "item" and cost.id > 0 then
                    local n, _, _, _, _, _, _, _, _, t = C_Item.GetItemInfo(cost.id)
                    cn = n or ("Item " .. cost.id); ci = t; ph = C_Item.GetItemCount(cost.id, true) or 0
                elseif cost.type == "gold" then
                    cn = "Gold"; ci = "Interface\\MoneyFrame\\UI-GoldIcon"; ph = GetMoney() or 0
                end
                local dh = cost.type == "gold" and math.floor(ph / 10000) or ph
                local dn = cost.type == "gold" and math.floor(rq / 10000) or rq
                local ok = ph >= rq
                local icStr = ci and ("|T" .. ci .. ":12:12|t ") or ""
                local ac = ok and "4CE04C" or "FF6666"
                Row(i == 1 and "Cost:" or "",
                    icStr .. cn .. "  |cFF" .. ac .. dh .. "/" .. dn .. "|r")
            end
        end
    end

    -- ── Quest ──
    if MCL_GUIDE_QUEST_DATA and mountID then
        local qd = MCL_GUIDE_QUEST_DATA[mountID]
        if qd and qd.quest and qd.quest ~= "" then
            y = y - 4
            local done = qd.questId and C_QuestLog.IsQuestFlaggedCompleted(qd.questId)
            Row("Quest:", qd.quest .. (done and " |cFF00FF00\226\156\147|r" or ""), nil, {1, 0.82, 0, 1})
            if qd.npc and qd.npc ~= "" then
                local ns = qd.x and qd.y and string.format("%s (%.1f, %.1f)", qd.npc, qd.x, qd.y) or qd.npc
                Row("Quest Giver:", ns)
                if qd.m and qd.x and qd.y then
                    MakeWaypointBtn(P, qd.m, qd.x, qd.y, qd.npc, 10, y)
                    y = y - 22
                end
            end
        end
    end

    -- ── Achievement ──
    if MCL_GUIDE_ACHIEVEMENT_DATA and spellID then
        -- Build spell→achievement cache once
        if not MCL_GUIDE_ACHIEVEMENT_DATA._spellCache and MCL_GUIDE_ACHIEVEMENT_DATA.byAchievement then
            MCL_GUIDE_ACHIEVEMENT_DATA._spellCache = {}
            for ak, ad in pairs(MCL_GUIDE_ACHIEVEMENT_DATA.byAchievement) do
                if ad.itemId and ad.itemId ~= 0 then
                    local m = C_MountJournal.GetMountFromItem(ad.itemId)
                    if m then
                        local _, s2 = C_MountJournal.GetMountInfoByID(m)
                        if s2 then MCL_GUIDE_ACHIEVEMENT_DATA._spellCache[s2] = ak end
                    end
                elseif ad.mountId then
                    local _, s2 = C_MountJournal.GetMountInfoByID(ad.mountId)
                    if s2 then MCL_GUIDE_ACHIEVEMENT_DATA._spellCache[s2] = ak end
                end
            end
        end

        local aid = MCL_GUIDE_ACHIEVEMENT_DATA._spellCache
                and MCL_GUIDE_ACHIEVEMENT_DATA._spellCache[spellID]
        if not aid and MCL_GUIDE_ACHIEVEMENT_DATA.bySpell then
            local v = MCL_GUIDE_ACHIEVEMENT_DATA.bySpell[spellID]
            aid = type(v) == "table" and v[1] or v
        end
        if aid then
            local _, achName, _, achDone = GetAchievementInfo(aid)
            if achName then
                y = y - 4
                local achClr = achDone and {0.3, 0.85, 0.4, 1} or {0.9, 0.9, 0.2, 1}
                local _, achVal = Row("Achievement:", achName, nil, achClr)

                -- Make clickable
                local achBtn = CreateFrame("Button", nil, P)
                achBtn:SetAllPoints(achVal)
                achBtn:SetScript("OnClick", function()
                    if not AchievementFrame then
                        if C_AddOns and C_AddOns.LoadAddOn then
                            C_AddOns.LoadAddOn("Blizzard_AchievementUI")
                        elseif LoadAddOn then
                            LoadAddOn("Blizzard_AchievementUI")
                        end
                    end
                    if AchievementFrame then
                        if not AchievementFrame:IsShown() then ShowUIPanel(AchievementFrame) end
                        if AchievementFrame_SelectAchievement then AchievementFrame_SelectAchievement(aid) end
                    end
                end)
                achBtn:SetScript("OnEnter", function()
                    achVal:SetTextColor(1, 1, 1, 1)
                    GameTooltip:SetOwner(achBtn, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(achName, 1, 1, 1)
                    GameTooltip:AddLine(achDone and "Completed" or "In progress",
                        achDone and 0.3 or 0.9, achDone and 0.85 or 0.9, achDone and 0.4 or 0.2)
                    GameTooltip:AddLine("|cFF00FF00Click to view|r")
                    GameTooltip:Show()
                end)
                achBtn:SetScript("OnLeave", function()
                    achVal:SetTextColor(unpack(achClr))
                    GameTooltip:Hide()
                end)
            end
        end
    end

    -- ── Vendor data (when no rep vendor or guide vendor shown) ──
    local repShown = false
    if MCL_GUIDE_GET_REP_INFO and spellID then
        local rc = MCL_GUIDE_GET_REP_INFO(spellID)
        if rc and rc.vendorName then repShown = true end
    end
    local guideVendor = gd and gd.method == "VENDOR"

    if not repShown and not guideVendor and MCL_GUIDE_VENDOR_DATA and mountID then
        local vr = MCL_GUIDE_VENDOR_DATA[mountID]
        local vl
        if vr then
            if vr[1] and type(vr[1]) == "table" then vl = vr
            elseif vr.npc then vl = { vr } end
        end
        if vl then
            local pf = UnitFactionGroup("player")
            local fil = {}
            for _, vd in ipairs(vl) do
                if vd.npc and vd.npc ~= "" and (not vd.faction or vd.faction == "" or vd.faction == pf) then
                    fil[#fil + 1] = vd
                end
            end
            if #fil == 0 then fil = vl end
            for _, vd in ipairs(fil) do
                if vd.npc and vd.npc ~= "" then
                    y = y - 4
                    local vs = vd.x and vd.y
                        and string.format("%s (%.1f, %.1f)", vd.npc, vd.x, vd.y)
                        or vd.npc
                    Row("Vendor:", vs)
                    if vd.m and vd.x and vd.y then
                        MakeWaypointBtn(P, vd.m, vd.x, vd.y, vd.npc, 10, y)
                        y = y - 22
                    end
                end
            end
        end
    end

    -- ── Blizzard source text (fallback when no guide data) ──
    if not gd and blizzSource and blizzSource ~= "" then
        y = y - 4
        local sf2 = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sf2:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
        sf2:SetWidth(cw - 4)
        sf2:SetText(blizzSource)
        sf2:SetTextColor(0.65, 0.75, 0.85, 1)
        sf2:SetJustifyH("LEFT")
        sf2:SetWordWrap(true)
        y = y - sf2:GetStringHeight() - 4
    end

    -- ── Instructions / Notes ──
    local note = GetMountNote(mountID)
    if note then
        y = y - 4
        local sp2 = P:CreateTexture(nil, "ARTWORK")
        sp2:SetHeight(1)
        sp2:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
        sp2:SetWidth(cw - 4)
        sp2:SetColorTexture(0.25, 0.25, 0.3, 0.6)
        y = y - 6

        local lines = {}
        for ln in (note .. "\n"):gmatch("([^\n]*)\n") do lines[#lines + 1] = ln end

        local ne = 0
        for _, l in ipairs(lines) do
            if (l:match("^%s*(.-)%s*$") or "") ~= "" then ne = ne + 1 end
        end

        if not cardNotesExpanded then
            -- Collapsed bar
            local ib = CreateFrame("Button", nil, P, "BackdropTemplate")
            ib:SetSize(cw, 22)
            ib:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
            ib:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            ib:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
            ib:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)

            local ii = ib:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ii:SetPoint("LEFT", 8, 0)
            ii:SetText("|cFF66AADD\226\150\186|r")

            local il = ib:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            il:SetPoint("LEFT", ii, "RIGHT", 4, 0)
            il:SetText("Instructions")
            il:SetTextColor(0.5, 0.75, 0.95, 1)

            local ic = ib:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            ic:SetPoint("RIGHT", -8, 0)
            ic:SetText("|cFF556677(" .. ne .. " lines)|r")

            ib:SetScript("OnClick", function()
                cardNotesExpanded = true
                PopulateCard(data)
            end)
            ib:SetScript("OnEnter", function(s)
                s:SetBackdropBorderColor(0.35, 0.55, 0.8, 0.9)
                il:SetTextColor(0.7, 0.9, 1, 1)
            end)
            ib:SetScript("OnLeave", function(s)
                s:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)
                il:SetTextColor(0.5, 0.75, 0.95, 1)
            end)
            y = y - 26
        else
            -- Expanded: render each line
            for _, ln in ipairs(lines) do
                local t = ln:match("^%s*(.-)%s*$") or ""
                if t == "" then
                    y = y - 4
                elseif t:find("%{%{m:%d") then
                    -- Line with waypoint template(s)
                    local rem = t
                    while rem and rem ~= "" do
                        local pre, mid, xr, yr, post =
                            rem:match("^(.-)%{%{m:(%d+),%s*([%d%.]+),%s*([%d%.]+)%}%}(.*)$")
                        if pre then
                            local pt = pre:match("^%s*(.-)%s*$") or ""
                            if pt ~= "" then
                                local fs = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                fs:SetPoint("TOPLEFT", P, "TOPLEFT", 14, y)
                                fs:SetWidth(cw - 8)
                                fs:SetText(pt)
                                fs:SetTextColor(0.7, 0.85, 0.95, 1)
                                fs:SetJustifyH("LEFT")
                                fs:SetWordWrap(true)
                                y = y - fs:GetStringHeight() - 2
                            end
                            local wm, wx2, wy2 = tonumber(mid), tonumber(xr), tonumber(yr)
                            if wm and wx2 and wy2 then
                                local zInfo = C_Map.GetMapInfo(wm)
                                local zn = zInfo and zInfo.name or ("Map " .. wm)
                                MakeWaypointBtn(P, wm, wx2, wy2,
                                    string.format("%s (%.1f, %.1f)", zn, wx2, wy2), 14, y)
                                y = y - 22
                            end
                            rem = post
                        else
                            local tail = rem:match("^[%.,:;]?%s*(.-)%s*$") or ""
                            if tail ~= "" then
                                local fs = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                fs:SetPoint("TOPLEFT", P, "TOPLEFT", 14, y)
                                fs:SetWidth(cw - 8)
                                fs:SetText(tail)
                                fs:SetTextColor(0.7, 0.85, 0.95, 1)
                                fs:SetJustifyH("LEFT")
                                fs:SetWordWrap(true)
                                y = y - fs:GetStringHeight() - 2
                            end
                            rem = nil
                        end
                    end
                elseif t:find("%{%{item:%d") then
                    -- Line with item template(s) — resolve names
                    local display = t:gsub("%{%{item:(%d+)%}%}", function(id)
                        local iName = C_Item.GetItemInfo(tonumber(id))
                        return iName and ("[" .. iName .. "]") or ("[Item " .. id .. "]")
                    end)
                    local fs = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    fs:SetPoint("TOPLEFT", P, "TOPLEFT", 14, y)
                    fs:SetWidth(cw - 8)
                    fs:SetText("|cFF8888AA\226\128\162|r " .. display)
                    fs:SetTextColor(0.7, 0.85, 0.95, 1)
                    fs:SetJustifyH("LEFT")
                    fs:SetWordWrap(true)
                    y = y - fs:GetStringHeight() - 2
                else
                    -- Plain text line with bullet
                    local fs = P:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    fs:SetPoint("TOPLEFT", P, "TOPLEFT", 14, y)
                    fs:SetWidth(cw - 8)
                    fs:SetText("|cFF8888AA\226\128\162|r " .. t)
                    fs:SetTextColor(0.7, 0.85, 0.95, 1)
                    fs:SetJustifyH("LEFT")
                    fs:SetWordWrap(true)
                    y = y - fs:GetStringHeight() - 2
                end
            end

            -- Collapse button
            local cb = CreateFrame("Button", nil, P, "BackdropTemplate")
            cb:SetSize(cw, 22)
            cb:SetPoint("TOPLEFT", P, "TOPLEFT", 10, y)
            cb:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            cb:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
            cb:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)

            local cbi = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cbi:SetPoint("LEFT", 8, 0)
            cbi:SetText("|cFF66AADD\226\150\188|r")

            local cbl = cb:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            cbl:SetPoint("LEFT", cbi, "RIGHT", 4, 0)
            cbl:SetText("Collapse")
            cbl:SetTextColor(0.5, 0.75, 0.95, 1)

            cb:SetScript("OnClick", function()
                cardNotesExpanded = false
                PopulateCard(data)
            end)
            cb:SetScript("OnEnter", function(s)
                s:SetBackdropBorderColor(0.35, 0.55, 0.8, 0.9)
                cbl:SetTextColor(0.7, 0.9, 1, 1)
            end)
            cb:SetScript("OnLeave", function(s)
                s:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)
                cbl:SetTextColor(0.5, 0.75, 0.95, 1)
            end)
            y = y - 26
        end
    end

    -- Set scroll child height
    P:SetHeight(math.abs(y) + 20)
    if cardView and cardView.Scroll and cardView.Scroll.UpdateScrollChildRect then
        cardView.Scroll:UpdateScrollChildRect()
    end
end

-- ── Public API: show card / return to list ──

function MapPanel:ShowMountCard(mountData)
    if not panel or not mountData then return end

    EnsureCardView()
    cardData = mountData
    cardNotesExpanded = false

    -- Switch to our tab if not already active
    if QuestMapFrame and QuestMapFrame.SetDisplayMode then
        QuestMapFrame:SetDisplayMode(DISPLAY_MODE)
    end

    -- Hide list, show card
    if panel.Scroll then panel.Scroll:Hide() end
    if panel.Title then panel.Title:SetText("MCL  -  Mount Details") end
    cardView:Show()
    cardView:SetFrameLevel((panel:GetFrameLevel() or 1) + 5)

    PopulateCard(mountData)
end

function MapPanel:ShowListView()
    cardData = nil
    cardNotesExpanded = false
    if cardView then ClearCardContent(); cardView:Hide() end
    if panel and panel.Scroll then
        panel.Scroll:Show()
        PopulatePanel()
    end
end

-- ================================================================
-- Refresh helpers
-- ================================================================
function MapPanel:QueueRefresh()
    if refreshQueued then return end
    refreshQueued = true
    C_Timer.After(0.05, function()
        refreshQueued = false
        if panel and panel:IsShown() and not cardData then
            PopulatePanel()
        end
    end)
end

function MapPanel:Refresh()
    if not panel then return end
    PopulatePanel()
end

-- ================================================================
-- Hook into World Map (Legend Tab system)
-- ================================================================
function f:TryInit()
    if not QuestMapFrame then return end

    local parent = QuestMapFrame
    EnsurePanel(parent)

    -- Re-anchor panel on resize
    if not parent._mclSizeHook then
        parent:HookScript("OnSizeChanged", function()
            if panel and panel:GetParent() then
                panel:ClearAllPoints()
                local ca = QuestMapFrame and QuestMapFrame.ContentsAnchor
                if ca and ca.GetWidth and ca:GetWidth() > 0 and ca:GetHeight() > 0 then
                    panel:SetPoint("TOPLEFT",     ca, "TOPLEFT",     0, -29)
                    panel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", -22, 0)
                else
                    panel:SetAllPoints(panel:GetParent())
                end
                MapPanel:QueueRefresh()
            end
        end)
        parent._mclSizeHook = true
    end

    if QuestMapFrame.ContentsAnchor and not QuestMapFrame.ContentsAnchor._mclSizeHook then
        QuestMapFrame.ContentsAnchor:HookScript("OnSizeChanged", function()
            if panel and panel:GetParent() then
                panel:ClearAllPoints()
                local ca = QuestMapFrame and QuestMapFrame.ContentsAnchor
                if ca and ca.GetWidth and ca:GetWidth() > 0 and ca:GetHeight() > 0 then
                    panel:SetPoint("TOPLEFT",     ca, "TOPLEFT",     0, -29)
                    panel:SetPoint("BOTTOMRIGHT", ca, "BOTTOMRIGHT", -22, 0)
                else
                    panel:SetAllPoints(panel:GetParent())
                end
                MapPanel:QueueRefresh()
            end
        end)
        QuestMapFrame.ContentsAnchor._mclSizeHook = true
    end

    -- Create the tab
    EnsureTab(parent)

    -- Check if LibWorldMapTabs is handling tab layout.
    -- If it is, it scans QuestMapFrame children and positions any
    -- "unofficial" tab automatically.  We must NOT also add our tab
    -- to TabButtons / ContentFrames or reposition it ourselves,
    -- because both systems would fight over the anchor point.
    local hasLibWorldMapTabs = LibStub and LibStub("LibWorldMapTabs", true)

    if hasLibWorldMapTabs then
        -- LibWorldMapTabs discovers our tab by scanning
        -- QuestMapFrame:GetChildren() for frames with .displayMode
        -- + .OnEnter + :IsShown().  Its initial PlaceTabs() ran on
        -- WorldMapOnShow before MCL created its tab, so we must
        -- trigger a re-scan now that our tab exists.
        if hasLibWorldMapTabs.internal and hasLibWorldMapTabs.internal.PlaceTabs then
            hasLibWorldMapTabs.internal:PlaceTabs()
            -- Also re-scan after a brief delay in case other addons
            -- are still creating their tabs.
            C_Timer.After(0.2, function()
                hasLibWorldMapTabs.internal:PlaceTabs()
            end)
        end
    else
        -- No library -- fall back to manual positioning.

        -- Register panel as a content frame so Blizzard manages its visibility
        if QuestMapFrame.ContentFrames then
            local exists = false
            for _, frame in ipairs(QuestMapFrame.ContentFrames) do
                if frame == panel then exists = true; break end
            end
            if not exists then table.insert(QuestMapFrame.ContentFrames, panel) end
        end

        -- Register tab so Blizzard manages checked state
        if QuestMapFrame.TabButtons then
            local present = false
            for _, b in ipairs(QuestMapFrame.TabButtons) do
                if b == tabButton then present = true; break end
            end
            if not present then table.insert(QuestMapFrame.TabButtons, tabButton) end
        end

        -- Recalculate tab layout
        if QuestMapFrame.ValidateTabs then QuestMapFrame:ValidateTabs() end

        -- Hook ValidateTabs so MCL's tab re-anchors after any addon inserts one
        if QuestMapFrame.ValidateTabs and not QuestMapFrame._mclRelayoutHook then
            hooksecurefunc(QuestMapFrame, "ValidateTabs", RepositionMCLTab)
            QuestMapFrame._mclRelayoutHook = true
        end

        -- Immediate layout pass + a delayed one to catch late-loading addons
        RepositionMCLTab()
        C_Timer.After(0.5, RepositionMCLTab)
        C_Timer.After(2.0, RepositionMCLTab)
    end

    -- Track display mode changes via EventRegistry
    if EventRegistry and not f._mclDisplayEvent then
        EventRegistry:RegisterCallback("QuestLog.SetDisplayMode", function(_, mode)
            if mode == DISPLAY_MODE then
                if tabButton and tabButton.SetChecked then tabButton:SetChecked(true) end
                if panel then SafeSetVisible(panel, true) end
                MapPanel:QueueRefresh()
            else
                if tabButton and tabButton.SetChecked then tabButton:SetChecked(false) end
                if panel then SafeSetVisible(panel, false) end
            end
        end, f)
        f._mclDisplayEvent = true
    end

    -- Also hook the direct SetDisplayMode method
    if QuestMapFrame.SetDisplayMode and not QuestMapFrame._mclSetDisplayHook then
        hooksecurefunc(QuestMapFrame, "SetDisplayMode", function(_, mode)
            if mode == DISPLAY_MODE then
                if panel then SafeSetVisible(panel, true) end
            else
                if panel then SafeSetVisible(panel, false) end
            end
        end)
        QuestMapFrame._mclSetDisplayHook = true
    end
end

-- ================================================================
-- Events
-- ================================================================
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "Blizzard_WorldMap" then
        if WorldMapFrame and not WorldMapFrame._mclPanelHook then
            WorldMapFrame:HookScript("OnShow", function()
                C_Timer.After(0.1, function()
                    if not Guide.ready then return end
                    f:TryInit()
                    if QuestMapFrame and QuestMapFrame.ValidateTabs then
                        QuestMapFrame:ValidateTabs()
                    end
                end)
            end)
            WorldMapFrame._mclPanelHook = true
        end
    end

    -- Hook map changes to refresh when user pans to a new zone
    if WorldMapFrame and not WorldMapFrame._mclMapChangedHook then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            if panel and panel:IsShown() then
                MapPanel:QueueRefresh()
            end
        end)
        WorldMapFrame._mclMapChangedHook = true
    end
end)

-- If WorldMapFrame already exists (Blizzard_WorldMap loaded early)
if WorldMapFrame then
    C_Timer.After(0, function()
        if WorldMapFrame and not WorldMapFrame._mclPanelHook then
            WorldMapFrame:HookScript("OnShow", function()
                C_Timer.After(0.1, function()
                    if not Guide.ready then return end
                    f:TryInit()
                    if QuestMapFrame and QuestMapFrame.ValidateTabs then
                        QuestMapFrame:ValidateTabs()
                    end
                end)
            end)
            WorldMapFrame._mclPanelHook = true
        end
        if WorldMapFrame and not WorldMapFrame._mclMapChangedHook then
            hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
                if panel and panel:IsShown() then
                    MapPanel:QueueRefresh()
                end
            end)
            WorldMapFrame._mclMapChangedHook = true
        end
    end)
end
