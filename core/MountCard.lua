local MCL, MCLcore = ...;

-- Ensure the Frames module exists
MCLcore.Frames = MCLcore.Frames or {};
MCLcore.MountCard = {};

local MountCard = MCLcore.MountCard;
local MCL_functions = MCLcore.Functions or {};
local L = MCLcore.L or {};

-- Helper function to get mount card dimensions - fixed width, dynamic height matching main frame
local function GetMountCardDimensions()
    local width = 400  -- Fixed mount card width (original size)
    local height
    
    -- Try to get height from main frame if it exists
    if MCL_mainFrame then
        height = MCL_mainFrame:GetHeight()
    -- Fall back to settings if main frame doesn't exist yet
    elseif MCL_SETTINGS and MCL_SETTINGS.frameHeight then
        height = MCL_SETTINGS.frameHeight
    -- Final fallback to default height
    else
        height = 600  -- default main_frame_height
    end
    
    return width, height
end

-- Global frame reference
local MCL_MountCard = nil

-- Hover delay system to prevent tooltip flickering when moving between mounts
local hoverTimer = nil
local currentHoveredMount = nil
local currentAnchorFrame = nil

-- MountCollector compatibility interface
MCLcore.MountCard.Display = MCLcore.MountCard.Display or {}

-- Notes lookup cache (mount journal ID → note text)
local mountNotesLookup = nil
local function GetMountNote(journalID)
    if not MCLcore.mountNotes then return nil end
    -- Build lookup once (maps mount journal ID → note text)
    if not mountNotesLookup then
        mountNotesLookup = {}
        for ref, note in pairs(MCLcore.mountNotes) do
            local jid = nil
            if type(ref) == "string" and string.sub(ref, 1, 1) == "m" then
                jid = tonumber(string.sub(ref, 2))
            elseif type(ref) == "number" then
                jid = C_MountJournal.GetMountFromItem(ref)
            elseif type(ref) == "string" and tonumber(ref) then
                jid = C_MountJournal.GetMountFromItem(tonumber(ref))
            end
            if jid and note and note ~= "" then
                mountNotesLookup[jid] = note
            end
        end
    end
    return mountNotesLookup[journalID]
end

--[[
  Get mount information from WoW API
]]
local function GetMountInfo(mountID)
    if not mountID then
        return nil
    end
    
    -- Handle both item IDs and mount IDs
    local actualMountID = mountID
    if type(mountID) == "string" and string.sub(mountID, 1, 1) == "m" then
        actualMountID = tonumber(string.sub(mountID, 2))
    elseif type(mountID) == "number" and mountID > 100000 then
        -- This might be an item ID, try to get mount from item
        actualMountID = C_MountJournal.GetMountFromItem(mountID)
    end
    
    if not actualMountID then
        return nil
    end
    
    local mountName, spellID, icon, isActive, isUsable, sourceType, isFavorite, 
          isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID_returned = 
          C_MountJournal.GetMountInfoByID(actualMountID)
    
    if not mountName then
        return nil
    end
    
    local creatureDisplayID, description, source, isSelfMount, mountTypeID, uiModelSceneID = 
          C_MountJournal.GetMountInfoExtraByID(actualMountID)
    
    return {
        mountID = actualMountID,
        name = mountName,
        spellID = spellID,
        icon = icon,
        isActive = isActive,
        isUsable = isUsable,
        sourceType = sourceType,
        isFavorite = isFavorite,
        isFactionSpecific = isFactionSpecific,
        faction = faction,
        shouldHideOnChar = shouldHideOnChar,
        isCollected = isCollected,
        creatureDisplayID = creatureDisplayID,
        description = description,
        source = source,
        isSelfMount = isSelfMount,
        mountTypeID = mountTypeID,
        uiModelSceneID = uiModelSceneID
    }
end

--[[
  Get mount source details (vendor, zone, cost, etc.)
]]
local function GetMountSourceDetails(mountInfo, mountData)
    if not mountInfo then
        return {}
    end
    
    local details = {
        vendor = "Unknown",
        zone = "Unknown", 
        cost = "",
        method = "Unknown"
    }
    
    -- Use MCL categorization data first if available
    if mountData and mountData.section and mountData.category then
        local section = mountData.section
        local category = mountData.category
        
        -- Map MCL categories to display information
        if category == "Vendor" or category == "Guild Vendor" or category == "Kun-Lai Vendor" then
            details.method = category
            details.vendor = "Available from " .. category
        elseif category == "Achievement" then
            details.method = "Achievement"
            details.vendor = "Achievement Reward"
        elseif category == "Reputation" or category == "Paragon Reputation" then
            details.method = category
            details.vendor = category .. " Reward"
        elseif category == "Dungeon Drop" then
            details.method = "Dungeon"
            details.vendor = "Dungeon Drop"
        elseif category == "Raid Drop" then
            details.method = "Raid"
            details.vendor = "Raid Drop"
        elseif category == "Rare Spawn" then
            details.method = "Rare Spawn"
            details.vendor = "Rare Mob Drop"
        elseif category == "Treasures" then
            details.method = "Treasure"
            details.vendor = "Treasure Chest"
        elseif category == "Adventures" then
            details.method = "Mission Table"
            details.vendor = "Mission Table Reward"
        elseif category == "Zone" then
            details.method = "Zone Drop"
            details.vendor = "Zone Activity"
        elseif category == "Daily Activities" then
            details.method = "Daily"
            details.vendor = "Daily Activity"
        elseif category == "Tormentors" then
            details.method = "Event"
            details.vendor = "Tormentors of Torghast"
        elseif category == "Maw Assaults" then
            details.method = "Event"
            details.vendor = "Maw Assault"
        elseif category == "Covenant Feature" then
            details.method = "Covenant"
            details.vendor = "Covenant Feature"
        elseif string.find(category, "Night Fae") or string.find(category, "Kyrian") or 
               string.find(category, "Necrolord") or string.find(category, "Venthyr") then
            details.method = "Covenant"
            details.vendor = category .. " Covenant"
        else
            details.method = category
            details.vendor = category
        end
        
        -- Map sections to zones
        if section == "SL" then
            details.zone = "Shadowlands"
        elseif section == "DF" then
            details.zone = "Dragon Isles"
        elseif section == "TWW" then
            details.zone = "Khaz Algar"
        elseif section == "BFA" then
            details.zone = "Kul Tiras / Zandalar"
        elseif section == "Legion" then
            details.zone = "Broken Isles"
        elseif section == "WoD" then
            details.zone = "Draenor"
        elseif section == "Mists" then
            details.zone = "Pandaria"
        elseif section == "Cata" then
            details.zone = "Cataclysm Zones"
        elseif section == "Wrath" then
            details.zone = "Northrend"
        elseif section == "BC" then
            details.zone = "Outland"
        elseif section == "Classic" then
            details.zone = "Eastern Kingdoms / Kalimdor"
        elseif section == "Holiday" then
            details.zone = "Holiday Event"
        elseif section == "Promotion" then
            details.zone = "Promotional"
        elseif section == "Other" then
            details.zone = "Various"
        else
            details.zone = section
        end
    end
    
    -- Parse source information from WoW API as fallback or enhancement
    if mountInfo.source then
        local source = mountInfo.source
        
        -- If we still have unknown vendor, try to parse from source
        if details.vendor == "Unknown" then
            local vendorPatterns = {
                "Sold by ([^,%.]+)",
                "Available from ([^,%.]+)",
                "Purchased from ([^,%.]+)",
                "Vendor: ([^,%.]+)",
                "from ([^,%.]+)"
            }
            
            for _, pattern in ipairs(vendorPatterns) do
                local vendorMatch = string.match(source, pattern)
                if vendorMatch then
                    details.vendor = vendorMatch:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
                    details.method = "Vendor"
                    break
                end
            end
        end
        
        -- If we still have unknown zone, try to parse from source
        if details.zone == "Unknown" then
            local zonePatterns = {
                "in ([^,%.]+)",
                "from ([^,%.]+)",
                "at ([^,%.]+)",
                "Zone: ([^,%.]+)"
            }
            
            for _, pattern in ipairs(zonePatterns) do
                local zoneMatch = string.match(source, pattern)
                if zoneMatch and not string.find(zoneMatch:lower(), "vendor") and not string.find(zoneMatch:lower(), "sold") then
                    details.zone = zoneMatch:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
                    break
                end
            end
        end
        
        -- Enhanced method detection from source
        if details.method == "Unknown" then
            if string.find(source:lower(), "drop") then
                details.method = "Drop"
            elseif string.find(source:lower(), "achievement") then
                details.method = "Achievement"
            elseif string.find(source:lower(), "reputation") then
                details.method = "Reputation"
            elseif string.find(source:lower(), "quest") then
                details.method = "Quest"
            elseif string.find(source:lower(), "rare") then
                details.method = "Rare Spawn"
            elseif string.find(source:lower(), "treasure") then
                details.method = "Treasure"
            elseif string.find(source:lower(), "dungeon") then
                details.method = "Dungeon"
            elseif string.find(source:lower(), "raid") then
                details.method = "Raid"
            elseif details.vendor ~= "Unknown" then
                details.method = "Vendor"
            end
        end
        
        -- Try to extract cost information
        local costPatterns = {
            "(%d+%s*gold)",
            "(%d+g)",
            "(%d+%s*honor)",
            "(%d+%s*conquest)",
            "(%d+%s*[%w%s]+points?)",
            "Cost: ([^,%.]+)"
        }
        
        for _, pattern in ipairs(costPatterns) do
            local costMatch = string.match(source, pattern)
            if costMatch then
                details.cost = costMatch:gsub("^%s*(.-)%s*$", "%1") -- Trim whitespace
                break
            end
        end
        
        -- Handle texture/icon references in cost (remove them or convert to readable format)
        if details.cost and string.find(details.cost, "Interface\\") then
            -- If cost contains texture path, try to extract meaningful info
            local numericCost = string.match(details.cost, "(%d+)")
            local iconPath = string.match(details.cost, "(Interface\\[^%s]+)")
            
            if numericCost then
                -- Try to determine currency type from icon path
                if iconPath then
                    if string.find(iconPath:lower(), "gold") then
                        details.cost = numericCost .. " Gold"
                    elseif string.find(iconPath:lower(), "honor") then
                        details.cost = numericCost .. " Honor"
                    elseif string.find(iconPath:lower(), "conquest") then
                        details.cost = numericCost .. " Conquest"
                    elseif string.find(iconPath:lower(), "azerite") then
                        details.cost = numericCost .. " Residual Memories"
                    elseif string.find(iconPath:lower(), "currency") then
                        details.cost = numericCost .. " Currency"
                    else
                        -- Generic fallback - just show the number
                        details.cost = numericCost
                    end
                else
                    details.cost = numericCost
                end
            else
                -- If no numeric value found, clear the cost
                details.cost = ""
            end
        end
    end
    
    return details
end

--[[
  Create section header with MCL navigation frame styling (matching PetCard)
]]
local function CreateSectionHeader(parent, text, yOffset, currentOpacity, parentWidth)
    -- Use provided width or fallback to fixed mount card width
    local headerWidth = parentWidth and (parentWidth - 40) or (400 - 40)  -- Fixed width instead of dynamic
    
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetSize(headerWidth, 25)
    header:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Use current opacity if provided, otherwise fallback
    local opacity = currentOpacity or (MCL_SETTINGS and MCL_SETTINGS.opacity) or 0.95
    
    -- MCL house style for section headers
    header:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    header:SetBackdropColor(0.1, 0.1, 0.14, opacity)
    header:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
    
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("LEFT", header, "LEFT", 8, 0)
    headerText:SetTextColor(0.4, 0.78, 0.95, 1)
    headerText:SetText(text)
    
    return header
end

--[[
  Create the main MountCard frame using MCL styling
]]
function MountCard:CreateMountCard()
    if MCL_MountCard then
        return MCL_MountCard  -- Already exists
    end
    
    -- Get current frame dimensions (matches main frame size)
    local cardWidth, cardHeight = GetMountCardDimensions()
    
    -- Create main frame with MCL styling (matching PetCard)
    local f = CreateFrame("Frame", "MCL_MountCard", UIParent, "BackdropTemplate")
    f:SetSize(cardWidth, cardHeight)  -- Use dynamic dimensions
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(false)  -- Disable moving since it's anchored
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()  -- Start hidden
    
    -- Apply MCL house style (consistent with header bar)
    local currentOpacity = (MCL_SETTINGS and MCL_SETTINGS.opacity) or 0.95
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.09, currentOpacity)
    f:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
    
    -- Header bar at top of mount card (matching main frame header)
    f.headerBar = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.headerBar:SetPoint("TOPLEFT", f, "TOPLEFT", 0, 0)
    f.headerBar:SetPoint("TOPRIGHT", f, "TOPRIGHT", 0, 0)
    f.headerBar:SetHeight(32)
    f.headerBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    f.headerBar:SetBackdropColor(0.08, 0.08, 0.12, 0.98)
    f.headerBar:SetFrameLevel(f:GetFrameLevel() + 2)
    
    -- Accent line at bottom of header
    f.headerAccent = f.headerBar:CreateTexture(nil, "OVERLAY")
    f.headerAccent:SetHeight(1)
    f.headerAccent:SetPoint("BOTTOMLEFT", f.headerBar, "BOTTOMLEFT", 0, 0)
    f.headerAccent:SetPoint("BOTTOMRIGHT", f.headerBar, "BOTTOMRIGHT", 0, 0)
    f.headerAccent:SetColorTexture(0.2, 0.6, 0.9, 0.6)
    
    -- Title bar with mount icon and name (clickable to copy name)
    f.titleFrame = CreateFrame("Button", nil, f.headerBar)
    f.titleFrame:SetPoint("TOPLEFT", f.headerBar, "TOPLEFT", 0, 0)
    f.titleFrame:SetPoint("BOTTOMRIGHT", f.headerBar, "BOTTOMRIGHT", 0, 0)
    f.titleFrame:SetFrameLevel(f.headerBar:GetFrameLevel() + 1)
    
    -- Mount icon in title bar
    f.mountIcon = f.titleFrame:CreateTexture(nil, "ARTWORK")
    f.mountIcon:SetSize(24, 24)
    f.mountIcon:SetPoint("LEFT", f.titleFrame, "LEFT", 10, 0)
    
    -- Mount name in title bar
    f.mountName = f.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.mountName:SetPoint("LEFT", f.mountIcon, "RIGHT", 8, 0)
    f.mountName:SetTextColor(0.4, 0.78, 0.95, 1)

    -- Report button in title bar (parented to headerBar, above titleFrame)
    f.reportBtn = CreateFrame("Button", nil, f.headerBar)
    f.reportBtn:SetSize(55, 20)
    f.reportBtn:SetPoint("RIGHT", f.headerBar, "RIGHT", -8, 0)
    f.reportBtn:SetFrameLevel(f.titleFrame:GetFrameLevel() + 5)
    f.reportBtn:EnableMouse(true)
    f.reportBtn:RegisterForClicks("AnyUp")

    f.reportBtnText = f.reportBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.reportBtnText:SetAllPoints(f.reportBtn)
    f.reportBtnText:SetText("|TInterface\\HELPFRAME\\HelpIcon-Bug:12:12|t Report")
    f.reportBtnText:SetTextColor(0.9, 0.4, 0.4, 1)
    f.reportBtnText:SetJustifyH("RIGHT")

    f.reportBtn:SetScript("OnEnter", function(self)
        f.reportBtnText:SetTextColor(1, 0.5, 0.5, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Report Issue", 1, 0.4, 0.4)
        GameTooltip:AddLine("Click to copy a pre-filled report URL for this mount", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    f.reportBtn:SetScript("OnLeave", function(self)
        f.reportBtnText:SetTextColor(0.9, 0.4, 0.4, 1)
        GameTooltip:Hide()
    end)
    f.reportBtn:SetScript("OnClick", function(self)
        local url = "https://discord.gg/YvrpHSyqtj"
        if f.copyEditBox then
            f.copyEditBox:SetText(url)
            f.copyPopup:Show()
            f.copyEditBox:SetFocus()
            f.copyEditBox:HighlightText()
        end
        f.reportBtnText:SetTextColor(0.3, 0.85, 0.4, 1)
        f.reportBtnText:SetText("|TInterface\\HELPFRAME\\HelpIcon-Bug:12:12|t Copied!")
        C_Timer.After(1.5, function()
            f.reportBtnText:SetTextColor(0.9, 0.4, 0.4, 1)
            f.reportBtnText:SetText("|TInterface\\HELPFRAME\\HelpIcon-Bug:12:12|t Report")
        end)
    end)

    -- Wowhead button in title bar (parented to headerBar, above titleFrame)
    f.wowheadBtn = CreateFrame("Button", nil, f.headerBar)
    f.wowheadBtn:SetSize(70, 20)
    f.wowheadBtn:SetPoint("RIGHT", f.reportBtn, "LEFT", -6, 0)
    f.wowheadBtn:SetFrameLevel(f.titleFrame:GetFrameLevel() + 5)
    f.wowheadBtn:EnableMouse(true)
    f.wowheadBtn:RegisterForClicks("AnyUp")

    f.wowheadBtnText = f.wowheadBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.wowheadBtnText:SetAllPoints(f.wowheadBtn)
    f.wowheadBtnText:SetText("|TInterface\\HELPFRAME\\HelpIcon-KnowledgeBase:12:12|t Wowhead")
    f.wowheadBtnText:SetTextColor(0.9, 0.6, 0.2, 1)
    f.wowheadBtnText:SetJustifyH("RIGHT")

    f.wowheadBtn:SetScript("OnEnter", function(self)
        f.wowheadBtnText:SetTextColor(1, 0.8, 0.3, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Wowhead", 1, 0.82, 0)
        GameTooltip:AddLine("Click to copy Wowhead URL", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    f.wowheadBtn:SetScript("OnLeave", function(self)
        f.wowheadBtnText:SetTextColor(0.9, 0.6, 0.2, 1)
        GameTooltip:Hide()
    end)
    f.wowheadBtn:SetScript("OnClick", function(self)
        local card = f
        local mountID = card.currentMountID
        if mountID then
            local url = "https://www.wowhead.com/mount/" .. mountID
            if card.copyEditBox then
                card.copyEditBox:SetText(url)
                card.copyPopup:Show()
                card.copyEditBox:SetFocus()
                card.copyEditBox:HighlightText()
            end
            f.wowheadBtnText:SetTextColor(0.3, 0.85, 0.4, 1)
            f.wowheadBtnText:SetText("|TInterface\\HELPFRAME\\HelpIcon-KnowledgeBase:12:12|t Copied!")
            C_Timer.After(1.5, function()
                f.wowheadBtnText:SetTextColor(0.9, 0.6, 0.2, 1)
                f.wowheadBtnText:SetText("|TInterface\\HELPFRAME\\HelpIcon-KnowledgeBase:12:12|t Wowhead")
            end)
        end
    end)

    -- Click-to-copy hint
    f.copyHint = f.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.copyHint:SetPoint("RIGHT", f.wowheadBtn, "LEFT", -8, 0)
    f.copyHint:SetText("Click to copy")
    f.copyHint:SetTextColor(0.5, 0.5, 0.5, 0)

    -- Inline copy popup anchored to the title bar
    f.copyPopup = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.copyPopup:SetSize(cardWidth - 20, 36)
    f.copyPopup:SetPoint("TOP", f.titleFrame, "BOTTOM", 0, -2)
    f.copyPopup:SetFrameStrata("DIALOG")
    f.copyPopup:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    f.copyPopup:SetBackdropColor(0.1, 0.1, 0.14, 0.95)
    f.copyPopup:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
    f.copyPopup:EnableMouse(true)
    f.copyPopup:Hide()

    -- Ctrl+C label
    local copyLabel = f.copyPopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    copyLabel:SetPoint("LEFT", f.copyPopup, "LEFT", 6, 0)
    copyLabel:SetText("Ctrl+C:")
    copyLabel:SetTextColor(0.5, 0.5, 0.5, 1)

    -- EditBox inside the popup
    f.copyEditBox = CreateFrame("EditBox", nil, f.copyPopup)
    f.copyEditBox:SetPoint("LEFT", copyLabel, "RIGHT", 4, 0)
    f.copyEditBox:SetPoint("RIGHT", f.copyPopup, "RIGHT", -8, 0)
    f.copyEditBox:SetHeight(20)
    f.copyEditBox:SetFontObject("ChatFontNormal")
    f.copyEditBox:SetAutoFocus(false)
    f.copyEditBox:SetScript("OnEscapePressed", function()
        f.copyPopup:Hide()
    end)
    f.copyEditBox:SetScript("OnEditFocusLost", function()
        C_Timer.After(0.1, function()
            if f.copyPopup:IsShown() and not f.copyEditBox:HasFocus() then
                f.copyPopup:Hide()
            end
        end)
    end)

    f.titleFrame:SetScript("OnEnter", function(self)
        f.copyHint:SetTextColor(0.5, 0.5, 0.5, 0.8)
    end)
    f.titleFrame:SetScript("OnLeave", function(self)
        if not f.copyPopup:IsShown() then
            f.copyHint:SetTextColor(0.5, 0.5, 0.5, 0)
        end
    end)
    f.titleFrame:SetScript("OnClick", function(self)
        local name = f.mountName:GetText()
        if name and name ~= "" then
            if ChatEdit_GetActiveWindow() then
                ChatEdit_InsertLink(name)
                -- Brief flash to confirm
                f.copyHint:SetTextColor(0, 1, 0, 1)
                f.copyHint:SetText("Linked!")
                C_Timer.After(1, function()
                    f.copyHint:SetText("Click to copy")
                    if f.titleFrame:IsMouseOver() then
                        f.copyHint:SetTextColor(0.5, 0.5, 0.5, 0.8)
                    else
                        f.copyHint:SetTextColor(0.5, 0.5, 0.5, 0)
                    end
                end)
            else
                -- Show inline copy popup
                f.copyEditBox:SetText(name)
                f.copyPopup:Show()
                f.copyEditBox:SetFocus()
                f.copyEditBox:HighlightText()
            end
        end
    end)
    
    -- Header frame for additional mount info (below title)
    f.headerFrame = CreateFrame("Frame", nil, f)
    f.headerFrame:SetSize(cardWidth - 20, 1)
    f.headerFrame:SetPoint("TOP", f.titleFrame, "BOTTOM", 0, -5)
    f.headerFrame:EnableMouse(false)
    
    -- Scroll frame for content (positioned below header frame)
    f.scrollFrame = CreateFrame("ScrollFrame", nil, f)
    f.scrollFrame:SetPoint("TOPLEFT", f.headerFrame, "BOTTOMLEFT", 0, -10)
    f.scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    
    -- Scroll child
    f.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
    f.scrollChild:SetSize(cardWidth - 20, cardHeight - 80)
    f.scrollFrame:SetScrollChild(f.scrollChild)

    -- Enable mouse wheel scrolling
    f.scrollFrame:EnableMouseWheel(true)
    f.scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local step = 40
        local newScroll = current - (delta * step)
        newScroll = math.max(0, math.min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

    -- Propagate mouse wheel from scroll child to scroll frame
    f.scrollChild:EnableMouseWheel(true)
    f.scrollChild:SetScript("OnMouseWheel", function(self, delta)
        local sf = self:GetParent()
        if sf and sf.GetVerticalScroll then
            local current = sf:GetVerticalScroll()
            local maxScroll = sf:GetVerticalScrollRange()
            local step = 40
            local newScroll = current - (delta * step)
            newScroll = math.max(0, math.min(newScroll, maxScroll))
            sf:SetVerticalScroll(newScroll)
        end
    end)
    
    -- Initialize properties
    f.isPinned = false
    f.currentMountID = nil
    f.currentAnchorFrame = nil
    
    -- Add hover detection to keep the card open when hovering over it
    f:SetScript("OnEnter", function(self)
        -- Cancel any pending hide timer when hovering over the card
        if hoverTimer then
            hoverTimer:Cancel()
            hoverTimer = nil
        end
    end)
    
    -- Hook into main MCL window hide event to close mount card
    -- Use a safer approach to avoid potential infinite loops
    local function setupMainFrameHook()
        if MCL_mainFrame and not MCL_mainFrame.mountCardHooked then
            local originalHide = MCL_mainFrame:GetScript("OnHide")
            MCL_mainFrame:SetScript("OnHide", function(self)
                -- Hide mount card when main window closes
                if MCL_MountCard and MCL_MountCard:IsVisible() then
                    MCL_MountCard:Hide()
                end
                -- Call original hide handler if it exists
                if originalHide then
                    originalHide(self)
                end
            end)
            MCL_mainFrame.mountCardHooked = true
            return true
        end
        return false
    end
    
    -- Try to set up the hook immediately
    if not setupMainFrameHook() then
        -- If main frame doesn't exist yet, set up a one-time event listener
        local eventFrame = CreateFrame("Frame")
        eventFrame:RegisterEvent("ADDON_LOADED")
        eventFrame:RegisterEvent("PLAYER_LOGIN")
        eventFrame:SetScript("OnEvent", function(self, event, addonName)
            if (event == "ADDON_LOADED" and addonName == "MCL") or 
               event == "PLAYER_LOGIN" or MCL_mainFrame then
                if setupMainFrameHook() then
                    self:UnregisterEvent("ADDON_LOADED")
                    self:UnregisterEvent("PLAYER_LOGIN")
                    self:SetScript("OnEvent", nil)
                end
            end
        end)
    end
    
    -- Also set up the hook whenever we show the mount card, as a backup
    f.ensureHook = setupMainFrameHook
    
    -- Store global reference
    MCL_MountCard = f
    return f
end

--[[
  Create mount card content
]]
function MountCard:CreateMountCardContent(parentFrame, mountData)
    if not parentFrame or not mountData then
        return
    end
    
    -- Clear existing content more thoroughly
    -- First clear all child frames
    local children = {parentFrame:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
        child:ClearAllPoints()
        child:SetParent(nil)
    end
    
    -- Clear all regions (FontStrings, Textures, etc.)
    local regions = {parentFrame:GetRegions()}
    for _, region in ipairs(regions) do
        region:Hide()
        region:ClearAllPoints()
        region:SetParent(nil)
    end
    
    -- Also clear the title frame content to prevent overlapping
    local card = MCL_MountCard
    if card and card.titleFrame then
        -- Clear previous title frame content completely
        local titleChildren = {card.titleFrame:GetChildren()}
        for _, child in ipairs(titleChildren) do
            if child ~= card.mountIcon and child ~= card.mountName then
                child:Hide()
                child:SetParent(nil)
            end
        end
        
        local titleRegions = {card.titleFrame:GetRegions()}
        for _, region in ipairs(titleRegions) do
            if region ~= card.mountIcon and region ~= card.mountName then
                region:Hide()
                region:SetParent(nil)
            end
        end
    end
    
    -- Get mount data from WoW API
    local mountInfo = GetMountInfo(mountData.mountID or mountData.id)
    if not mountInfo then
        -- Show error message
        local errorText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        errorText:SetPoint("CENTER", parentFrame, "CENTER", 0, 0)
        errorText:SetText("Mount information not available")
        errorText:SetTextColor(1, 0.5, 0.5, 1)
        print("MCL Debug: No mountInfo found for ID:", mountData.mountID or mountData.id)
        return
    end
    
    -- Get source details
    local sourceDetails = GetMountSourceDetails(mountInfo, mountData)
    
    -- Set mount icon and name in the title bar
    local card = MCL_MountCard
    if card and card.titleFrame then
        -- Clear previous title frame content
        if card.mountIcon then
            card.mountIcon:SetTexture(nil)
        end
        if card.mountName then
            card.mountName:SetText("")
        end
        
        -- Set new mount icon in title bar
        if card.mountIcon then
            if mountInfo.icon then
                card.mountIcon:SetTexture(mountInfo.icon)
            end
        end
        
        -- Set new mount name in title bar
        if card.mountName then
            card.mountName:SetText(mountInfo.name or "Unknown Mount")
        end
    end
    
    -- Store mountData for re-rendering (expand/collapse)
    if card then
        card.currentMountData = mountData
    end

    local yOffset = 0   -- Start right underneath the title area (was -5)
    local contentHeight = 10  -- Reduced from 20
    local contentWidth = parentFrame:GetWidth() - 20 -- Reduced padding from 60 to 20

    -- Track whether notes are expanded (hides model when true)
    local notesExpanded = card and card.notesExpanded or false
    
    -- Description section (no header, just content)
    if mountInfo.description and mountInfo.description ~= "" then
        local descriptionText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        descriptionText:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)  -- Reduced left margin from 30 to 10
        descriptionText:SetPoint("TOPRIGHT", parentFrame, "TOPRIGHT", -10, yOffset)  -- Reduced right margin from -30 to -10
        descriptionText:SetText(mountInfo.description)
        -- set descriptionText to a soft yellow
        descriptionText:SetTextColor(0.9, 0.9, 0.2, 1)
        descriptionText:SetJustifyH("LEFT")
        descriptionText:SetWordWrap(true)
        
        -- Make description italic
        local fontFile, fontSize, fontFlags = descriptionText:GetFont()
        descriptionText:SetFont(fontFile, fontSize, "ITALIC")
        
        local textHeight = descriptionText:GetStringHeight()
        yOffset = yOffset - (textHeight + 10)  -- Further reduced spacing from 15 to 10
        contentHeight = contentHeight + (textHeight + 10)
    end
    
    -- Notes section (user-defined notes from MCLcore.mountNotes)
    local mountNote = GetMountNote(mountInfo.mountID)
    if mountNote then
        -- Subtle separator
        yOffset = yOffset - 2

        -- Helper: create a clickable waypoint button at a given position
        local function CreateWaypointButton(parent, wpMapId, wpX, wpY, xPos, yPos)
            local zoneInfo = C_Map.GetMapInfo(wpMapId)
            local zoneName = zoneInfo and zoneInfo.name or ("Map " .. wpMapId)

            local wpBtn = CreateFrame("Button", nil, parent, "BackdropTemplate")
            wpBtn:SetSize(160, 18)
            wpBtn:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos, yPos)
            wpBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            wpBtn:SetBackdropColor(0.1, 0.15, 0.22, 0.9)
            wpBtn:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.5)

            local wpText = wpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            wpText:SetPoint("CENTER")
            wpText:SetText(string.format("%s (%.1f, %.1f)", zoneName, wpX, wpY))
            wpText:SetTextColor(0.4, 0.78, 0.95, 1)

            local textWidth = wpText:GetStringWidth()
            wpBtn:SetSize(textWidth + 16, 18)

            wpBtn:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(0.3, 0.7, 1, 1)
                self:SetBackdropColor(0.15, 0.2, 0.28, 1)
            end)
            wpBtn:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.5)
                self:SetBackdropColor(0.1, 0.15, 0.22, 0.9)
            end)
            wpBtn:SetScript("OnClick", function()
                if TomTom and TomTom.AddWaypoint then
                    TomTom:AddWaypoint(wpMapId, wpX / 100, wpY / 100, {
                        title = zoneName,
                        persistent = false,
                        minimap = true,
                        world = true,
                    })
                else
                    local vector = CreateVector2D(wpX / 100, wpY / 100)
                    C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(wpMapId, vector))
                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                end
                OpenWorldMap(wpMapId)
                wpText:SetTextColor(0.3, 0.85, 0.4, 1)
                C_Timer.After(1.5, function()
                    wpText:SetTextColor(0.4, 0.78, 0.95, 1)
                end)
            end)

            return wpBtn
        end

        -- Helper: resolve an item link from itemId (uses GetItemInfo cache)
        local function GetItemLink(itemId)
            local itemName, itemLink = C_Item.GetItemInfo(itemId)
            if itemLink then
                return itemLink
            end
            -- Fallback: build a basic colored item string
            return "|cffffd100[Item " .. itemId .. "]|r"
        end

        -- Helper: estimate item link width using cached name or a conservative default
        local function EstimateItemWidth(itemId)
            local itemName = C_Item.GetItemInfo(itemId)
            if itemName then
                -- Use a hidden FontString to measure the actual link width
                local measureFs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                local link = select(2, C_Item.GetItemInfo(itemId)) or ("[" .. itemName .. "]")
                measureFs:SetText(link)
                local w = measureFs:GetStringWidth()
                measureFs:Hide()
                measureFs:SetText("")
                return math.max(w + 2, 20)
            end
            -- Item not cached — estimate ~18 chars average × ~7px per char
            return 160
        end

        -- Track whether any item links needed async loading for re-render
        local pendingItemLoads = 0

        -- Helper: create an inline item link button with tooltip
        local function CreateItemLinkText(parent, itemId, xPos, yPos)
            local btn = CreateFrame("Button", nil, parent)
            btn:SetPoint("TOPLEFT", parent, "TOPLEFT", xPos, yPos)

            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("LEFT", btn, "LEFT", 0, 0)

            local function UpdateLink()
                local link = GetItemLink(itemId)
                fs:SetText(link)
                local w = fs:GetStringWidth()
                btn:SetSize(math.max(w + 2, 20), 16)
            end

            UpdateLink()

            -- If item wasn't cached, request it and re-render the card once loaded
            local itemName = C_Item.GetItemInfo(itemId)
            if not itemName then
                pendingItemLoads = pendingItemLoads + 1
                local item = Item:CreateFromItemID(itemId)
                item:ContinueOnItemLoad(function()
                    UpdateLink()
                    pendingItemLoads = pendingItemLoads - 1
                    -- Re-render the card once all pending items are loaded
                    if pendingItemLoads <= 0 and card and card.currentMountData then
                        C_Timer.After(0.05, function()
                            if card and card.currentMountData then
                                MountCard:CreateMountCardContent(parentFrame, card.currentMountData)
                            end
                        end)
                    end
                end)
            end

            -- Store estimated width for layout decisions
            btn.estimatedWidth = EstimateItemWidth(itemId)

            -- Tooltip on hover
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetItemByID(itemId)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            return btn
        end

        -- Process note line by line, rendering waypoint buttons and item links inline
        local lines = {}
        for line in (mountNote .. "\n"):gmatch("([^\n]*)\n") do
            table.insert(lines, line)
        end

        -- Count non-empty lines for expand/collapse
        local nonEmptyTotal = 0
        for _, ln in ipairs(lines) do
            local t = ln:match("^%s*(.-)%s*$") or ""
            if t ~= "" then nonEmptyTotal = nonEmptyTotal + 1 end
        end

        if not notesExpanded then
            -- COLLAPSED: show compact "Instructions" bar
            local instrBtn = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
            instrBtn:SetSize(contentWidth, 24)
            instrBtn:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)
            instrBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            instrBtn:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
            instrBtn:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)

            local instrIcon = instrBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            instrIcon:SetPoint("LEFT", instrBtn, "LEFT", 8, 0)
            instrIcon:SetText("|cFF66AADD\226\150\186|r")  -- ► triangle

            local instrLabel = instrBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            instrLabel:SetPoint("LEFT", instrIcon, "RIGHT", 4, 0)
            instrLabel:SetText("Instructions")
            instrLabel:SetTextColor(0.5, 0.75, 0.95, 1)

            local instrCount = instrBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            instrCount:SetPoint("RIGHT", instrBtn, "RIGHT", -8, 0)
            instrCount:SetText("|cFF556677(" .. nonEmptyTotal .. " lines)|r")

            instrBtn:SetScript("OnClick", function()
                if card then
                    card.notesExpanded = true
                    MountCard:CreateMountCardContent(parentFrame, card.currentMountData)
                end
            end)
            instrBtn:SetScript("OnEnter", function(self)
                self:SetBackdropBorderColor(0.35, 0.55, 0.8, 0.9)
                self:SetBackdropColor(0.13, 0.17, 0.24, 1)
                instrLabel:SetTextColor(0.7, 0.9, 1.0, 1)
            end)
            instrBtn:SetScript("OnLeave", function(self)
                self:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)
                self:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
                instrLabel:SetTextColor(0.5, 0.75, 0.95, 1)
            end)

            yOffset = yOffset - 28
            contentHeight = contentHeight + 28
        else
            -- EXPANDED: render all note lines

        for _, line in ipairs(lines) do
            local trimmed = line:match("^%s*(.-)%s*$") or ""
            if trimmed == "" then
                yOffset = yOffset - 4
                contentHeight = contentHeight + 4
            elseif trimmed:find("%{%{m:%d") or trimmed:find("%{%{item:%d") then
                -- Line contains template(s) — render with smart layout
                -- Strategy: render templates and short connectors inline,
                -- then wrap long tail text to an indented new line
                local xOff = 10
                local lineExtraHeight = 0
                local remaining = trimmed
                local templateCount = 0
                while remaining and remaining ~= "" do
                    -- Find whichever template comes first: waypoint or item
                    local wpStart = remaining:find("%{%{m:%d")
                    local itemStart = remaining:find("%{%{item:%d")
                    
                    local nextType = nil
                    if wpStart and (not itemStart or wpStart < itemStart) then
                        nextType = "waypoint"
                    elseif itemStart then
                        nextType = "item"
                    end
                    
                    if nextType == "waypoint" then
                        local pre, mapIdStr, xStr, yStr, post = remaining:match("^(.-)%{%{m:(%d+),%s*([%d%.]+),%s*([%d%.]+)%}%}(.*)$")
                        if pre then
                            local preText = pre:match("^%s*(.-)%s*$") or ""
                            if preText ~= "" then
                                -- Short connector text stays inline; long text wraps
                                local textFs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                textFs:SetText(preText)
                                textFs:SetTextColor(0.7, 0.85, 0.95, 1)
                                local preWidth = textFs:GetStringWidth()
                                if xOff + preWidth > contentWidth - 30 then
                                    xOff = 20
                                    yOffset = yOffset - 16
                                    lineExtraHeight = lineExtraHeight + 16
                                end
                                -- Constrain to container and enable word wrap for long text
                                local availWidth = contentWidth - xOff - 10
                                textFs:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOff, yOffset - 2)
                                if preWidth > availWidth then
                                    textFs:SetPoint("RIGHT", parentFrame, "RIGHT", -10, 0)
                                    textFs:SetWordWrap(true)
                                    textFs:SetJustifyH("LEFT")
                                    local textHeight = textFs:GetStringHeight()
                                    if textHeight > 14 then
                                        local extra = textHeight - 14
                                        yOffset = yOffset - extra
                                        lineExtraHeight = lineExtraHeight + extra
                                    end
                                    -- After wrapped text, next element goes on a new line
                                    xOff = 10
                                    yOffset = yOffset - 16
                                    lineExtraHeight = lineExtraHeight + 16
                                else
                                    xOff = xOff + preWidth + 4
                                end
                            end

                            local wpMapId = tonumber(mapIdStr)
                            local wpX = tonumber(xStr)
                            local wpY = tonumber(yStr)
                            if wpMapId and wpX and wpY then
                                if xOff > contentWidth - 170 then
                                    xOff = 10
                                    yOffset = yOffset - 20
                                    lineExtraHeight = lineExtraHeight + 20
                                end
                                local btn = CreateWaypointButton(parentFrame, wpMapId, wpX, wpY, xOff, yOffset)
                                xOff = xOff + btn:GetWidth() + 4
                            end
                            templateCount = templateCount + 1
                            remaining = post
                        else
                            remaining = nil
                        end
                    elseif nextType == "item" then
                        local pre, itemIdStr, post = remaining:match("^(.-)%{%{item:(%d+)%}%}(.*)$")
                        if pre then
                            local preText = pre:match("^%s*(.-)%s*$") or ""
                            if preText ~= "" then
                                local textFs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                                textFs:SetText(preText)
                                textFs:SetTextColor(0.7, 0.85, 0.95, 1)
                                local preWidth = textFs:GetStringWidth()
                                if xOff + preWidth > contentWidth - 30 then
                                    xOff = 20
                                    yOffset = yOffset - 16
                                    lineExtraHeight = lineExtraHeight + 16
                                end
                                -- Constrain to container and enable word wrap for long text
                                local availWidth = contentWidth - xOff - 10
                                textFs:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOff, yOffset - 2)
                                if preWidth > availWidth then
                                    textFs:SetPoint("RIGHT", parentFrame, "RIGHT", -10, 0)
                                    textFs:SetWordWrap(true)
                                    textFs:SetJustifyH("LEFT")
                                    local textHeight = textFs:GetStringHeight()
                                    if textHeight > 14 then
                                        local extra = textHeight - 14
                                        yOffset = yOffset - extra
                                        lineExtraHeight = lineExtraHeight + extra
                                    end
                                    -- After wrapped text, next element goes on a new line
                                    xOff = 10
                                    yOffset = yOffset - 16
                                    lineExtraHeight = lineExtraHeight + 16
                                else
                                    xOff = xOff + preWidth + 4
                                end
                            end

                            local itemId = tonumber(itemIdStr)
                            if itemId then
                                -- Estimate item link width before creating it
                                local estWidth = EstimateItemWidth(itemId)
                                if xOff + estWidth > contentWidth - 10 then
                                    xOff = 20
                                    yOffset = yOffset - 18
                                    lineExtraHeight = lineExtraHeight + 18
                                end
                                local itemBtn = CreateItemLinkText(parentFrame, itemId, xOff, yOffset)
                                xOff = xOff + math.max(itemBtn:GetWidth(), estWidth) + 4
                            end
                            templateCount = templateCount + 1
                            remaining = post
                        else
                            remaining = nil
                        end
                    else
                        -- No more templates — render remaining tail text
                        local tail = remaining:match("^%s*(.-)%s*$") or ""
                        -- Clean up leading punctuation that looks orphaned (". " or ", ")
                        tail = tail:gsub("^[%.,:;]%s*", "")
                        if tail ~= "" then
                            -- Always wrap tail text to a new indented line for readability
                            xOff = 20
                            yOffset = yOffset - 16
                            lineExtraHeight = lineExtraHeight + 16
                            local textFs = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                            textFs:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOff, yOffset - 2)
                            textFs:SetPoint("RIGHT", parentFrame, "RIGHT", -10, 0)
                            textFs:SetText(tail)
                            textFs:SetTextColor(0.6, 0.75, 0.85, 1)  -- slightly dimmer for description text
                            textFs:SetJustifyH("LEFT")
                            textFs:SetWordWrap(true)
                            local tailHeight = textFs:GetStringHeight()
                            if tailHeight > 14 then
                                lineExtraHeight = lineExtraHeight + (tailHeight - 14)
                            end
                        end
                        remaining = nil
                    end
                end
                local lineHeight = 18 + lineExtraHeight
                yOffset = yOffset - lineHeight - 4  -- extra 4px gap between template blocks
                contentHeight = contentHeight + lineHeight + 4
            else
                -- Plain text line — render with bullet
                local noteLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                noteLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)
                noteLabel:SetText("|cFF8888AA\226\128\162|r")  -- bullet point
                noteLabel:SetTextColor(0.53, 0.53, 0.67, 1)

                local noteText = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                noteText:SetPoint("TOPLEFT", noteLabel, "TOPRIGHT", 4, 0)
                noteText:SetPoint("RIGHT", parentFrame, "RIGHT", -10, 0)
                noteText:SetText(trimmed)
                noteText:SetTextColor(0.7, 0.85, 0.95, 1)
                noteText:SetJustifyH("LEFT")
                noteText:SetWordWrap(true)

                local noteHeight = noteText:GetStringHeight()
                yOffset = yOffset - (noteHeight + 4)
                contentHeight = contentHeight + (noteHeight + 4)
            end
        end
        -- Collapse button at the end of expanded notes
        yOffset = yOffset - 4
        local collapseBtn = CreateFrame("Button", nil, parentFrame, "BackdropTemplate")
        collapseBtn:SetSize(contentWidth, 24)
        collapseBtn:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)
        collapseBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        collapseBtn:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
        collapseBtn:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)

        local collapseIcon = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        collapseIcon:SetPoint("LEFT", collapseBtn, "LEFT", 8, 0)
        collapseIcon:SetText("|cFF66AADD\226\150\188|r")  -- ▼ triangle

        local collapseLabel = collapseBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        collapseLabel:SetPoint("LEFT", collapseIcon, "RIGHT", 4, 0)
        collapseLabel:SetText("Collapse Instructions")
        collapseLabel:SetTextColor(0.5, 0.75, 0.95, 1)

        collapseBtn:SetScript("OnClick", function()
            if card then
                card.notesExpanded = false
                MountCard:CreateMountCardContent(parentFrame, card.currentMountData)
            end
        end)
        collapseBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.35, 0.55, 0.8, 0.9)
            self:SetBackdropColor(0.13, 0.17, 0.24, 1)
            collapseLabel:SetTextColor(0.7, 0.9, 1.0, 1)
        end)
        collapseBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.4, 0.6, 0.6)
            self:SetBackdropColor(0.1, 0.13, 0.18, 0.9)
            collapseLabel:SetTextColor(0.5, 0.75, 0.95, 1)
        end)

        yOffset = yOffset - 28
        contentHeight = contentHeight + 32

        end -- end expanded else block

        -- Extra spacing after notes
        yOffset = yOffset - 4
        contentHeight = contentHeight + 4
    end
    
    -- Source details section (aligned left with description)
    local mainContentFrame = CreateFrame("Frame", nil, parentFrame)
    mainContentFrame:SetSize(contentWidth, 80)
    mainContentFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)  -- Aligned with description at x=10
    
    -- Mount details frame (aligned with description)
    local detailsFrame = CreateFrame("Frame", nil, mainContentFrame)
    detailsFrame:SetPoint("TOPLEFT", mainContentFrame, "TOPLEFT", 0, 0)  -- Removed extra indentation
    detailsFrame:SetPoint("BOTTOMRIGHT", mainContentFrame, "BOTTOMRIGHT", 0, 10)  -- Removed extra indentation
    
    local detailsYOffset = -5
    
    -- Check for Guide drop / source data (from MCL_Guide)
    local guideDropInfo = nil
    if MCL_GUIDE and MCL_GUIDE.mountLookup and mountInfo.spellID then
        guideDropInfo = MCL_GUIDE.mountLookup[mountInfo.spellID]
    end

    -- Only show Blizzard source text if Guide data AND rep/currency/quest data are NOT available
    local hasGuideRep = MCL_GUIDE_GET_REP_INFO and mountInfo.spellID and MCL_GUIDE_GET_REP_INFO(mountInfo.spellID)
    local hasGuideCurrency = MCL_GUIDE_CURRENCY_DATA and mountInfo.spellID and MCL_GUIDE_CURRENCY_DATA[mountInfo.spellID]
    local hasGuideQuest = MCL_GUIDE_QUEST_DATA and mountInfo.mountID and MCL_GUIDE_QUEST_DATA[mountInfo.mountID]
    if not guideDropInfo and not hasGuideRep and not hasGuideCurrency and not hasGuideQuest then
        local blizzardSourceText = "Unknown"
        if mountInfo and mountInfo.mountID then
            local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountInfo.mountID)
            if source and source ~= "" then
                blizzardSourceText = source
            end
        end
        
        if blizzardSourceText ~= "Unknown" then
            local sourceText = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sourceText:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
            sourceText:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", 0, detailsYOffset)
            sourceText:SetText(blizzardSourceText)
            sourceText:SetTextColor(0.65, 0.75, 0.85, 1)
            sourceText:SetJustifyH("LEFT")
            sourceText:SetWordWrap(true)
            
            detailsYOffset = detailsYOffset - 18
        end
    end
    
    -- --------------------------------------------------------
    -- Guide drop / source data (from MCL_Guide)
    -- --------------------------------------------------------

    -- Method label lookup
    local GUIDE_METHOD_LABELS = {
        NPC        = "Rare / NPC Drop",
        BOSS       = "Boss Drop",
        ZONE       = "Zone Drop",
        USE        = "Container / Use",
        FISHING    = "Fishing",
        ARCH       = "Archaeology",
        SPECIAL    = "Special",
        MINING     = "Mining",
        COLLECTION = "Collection",
        VENDOR     = "Vendor",
        QUEST      = "Quest",
    }

    if guideDropInfo then

        -- Check if a rep/renown vendor section will show coords for this mount
        -- If so, skip NPC/Zone/Coords here to avoid duplication
        local repVendorWillShow = false
        if MCL_GUIDE_GET_REP_INFO and mountInfo.spellID then
            local repCheck = MCL_GUIDE_GET_REP_INFO(mountInfo.spellID)
            if repCheck and repCheck.vendorName and repCheck.vendorMapId then
                repVendorWillShow = true
            end
        end

        -- Method / source type
        if guideDropInfo.method then
            local methodLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            methodLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
            methodLabel:SetText(L["Source:"] or "Source:")
            methodLabel:SetTextColor(0.5, 0.55, 0.65, 1)

            local methodValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            methodValue:SetPoint("LEFT", methodLabel, "RIGHT", 4, 0)
            methodValue:SetText(GUIDE_METHOD_LABELS[guideDropInfo.method] or guideDropInfo.method or "Unknown")
            methodValue:SetTextColor(0.4, 0.78, 0.95, 1)
            detailsYOffset = detailsYOffset - 16
        end

        -- Drop rate
        if guideDropInfo.chance and guideDropInfo.chance > 0 then
            local chanceLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            chanceLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
            chanceLabel:SetText(L["Drop Rate:"] or "Drop Rate:")
            chanceLabel:SetTextColor(0.5, 0.55, 0.65, 1)

            local pct = (1 / guideDropInfo.chance) * 100
            local chanceStr
            if pct >= 1 then
                chanceStr = string.format("1/%d (%d%%)", guideDropInfo.chance, pct)
            elseif pct >= 0.1 then
                chanceStr = string.format("1/%d (%.1f%%)", guideDropInfo.chance, pct)
            else
                chanceStr = string.format("1/%d (%.2f%%)", guideDropInfo.chance, pct)
            end

            local chanceValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            chanceValue:SetPoint("LEFT", chanceLabel, "RIGHT", 4, 0)
            chanceValue:SetText(chanceStr)
            -- Colour by rarity: green ≥10%, yellow ≥1%, orange ≥0.1%, red <0.1%
            if pct >= 10 then
                chanceValue:SetTextColor(0.3, 0.85, 0.4, 1)
            elseif pct >= 1 then
                chanceValue:SetTextColor(0.9, 0.9, 0.2, 1)
            elseif pct >= 0.1 then
                chanceValue:SetTextColor(0.9, 0.55, 0.1, 1)
            else
                chanceValue:SetTextColor(0.9, 0.25, 0.25, 1)
            end
            detailsYOffset = detailsYOffset - 16
        end

        -- NPC / Boss name (skip if rep vendor section will show this info)
        if not repVendorWillShow then
            do
                local npcDisplayName = guideDropInfo.lockBossName
                if not npcDisplayName and guideDropInfo.coords and guideDropInfo.coords[1] then
                    npcDisplayName = guideDropInfo.coords[1].n
                end
                if npcDisplayName then
                    local npcLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    npcLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                    npcLabel:SetText(L["NPC:"] or "NPC:")
                    npcLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                    local npcValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    npcValue:SetPoint("LEFT", npcLabel, "RIGHT", 4, 0)
                    npcValue:SetText(npcDisplayName)
                    npcValue:SetTextColor(0.8, 0.8, 0.85, 1)
                    detailsYOffset = detailsYOffset - 16
                end
            end

            -- Zone / Coords / Waypoint (skip for instance/boss drops with no outdoor coords)
            -- If coords have .i flag, they point to an instance map (don't show outdoor zone/waypoint)
            -- If mount has lockBossName but NO coords, coords were suppressed (dungeon boss)
            local hasInstanceCoords = guideDropInfo.coords and guideDropInfo.coords[1] and guideDropInfo.coords[1].i
            local isBossWithoutCoords = guideDropInfo.lockBossName and not (guideDropInfo.coords and guideDropInfo.coords[1])
            local isInstanceMount = hasInstanceCoords or isBossWithoutCoords
            if not isInstanceMount then
            -- Zone (derived from first coordinate's map)
            if guideDropInfo.coords and guideDropInfo.coords[1] and guideDropInfo.coords[1].m then
                local zoneMapInfo = C_Map.GetMapInfo(guideDropInfo.coords[1].m)
                if zoneMapInfo and zoneMapInfo.name then
                    local zoneLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    zoneLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                    zoneLabel:SetText(L["Zone:"] or "Zone:")
                    zoneLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                    local zoneValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    zoneValue:SetPoint("LEFT", zoneLabel, "RIGHT", 4, 0)
                    zoneValue:SetText(zoneMapInfo.name)
                    zoneValue:SetTextColor(0.8, 0.8, 0.85, 1)
                    detailsYOffset = detailsYOffset - 16
                end
            end

            -- Coordinates + Waypoint button
            if guideDropInfo.coords and guideDropInfo.coords[1] then
                local c = guideDropInfo.coords[1]
                if c.x and c.y then
                    local coordLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    coordLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                    coordLabel:SetText(L["Coords:"] or "Coords:")
                    coordLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                    local coordValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    coordValue:SetPoint("LEFT", coordLabel, "RIGHT", 4, 0)
                    coordValue:SetText(string.format("%.1f, %.1f", c.x, c.y))
                    coordValue:SetTextColor(0.8, 0.8, 0.85, 1)

                    -- Waypoint button (pin icon)
                    if c.m and c.m > 0 then
                        local wpBtn = CreateFrame("Button", nil, detailsFrame, "BackdropTemplate")
                        wpBtn:SetSize(80, 16)
                        wpBtn:SetPoint("LEFT", coordValue, "RIGHT", 12, 0)
                        wpBtn:SetBackdrop({
                            bgFile = "Interface\\Buttons\\WHITE8x8",
                            edgeFile = "Interface\\Buttons\\WHITE8x8",
                            edgeSize = 1,
                        })
                        wpBtn:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                        wpBtn:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.6)

                        local wpIcon = wpBtn:CreateTexture(nil, "ARTWORK")
                        wpIcon:SetSize(12, 12)
                        wpIcon:SetPoint("LEFT", wpBtn, "LEFT", 4, 0)
                        wpIcon:SetTexture("Interface\\AddOns\\MCL\\icons\\pin")
                        wpIcon:SetVertexColor(0.2, 0.6, 0.9, 1)

                        local wpText = wpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        wpText:SetPoint("LEFT", wpIcon, "RIGHT", 3, 0)
                        wpText:SetText(L["Waypoint"] or "Waypoint")
                        wpText:SetTextColor(0.4, 0.78, 0.95, 1)

                        wpBtn:SetScript("OnEnter", function(self)
                            self:SetBackdropBorderColor(0.3, 0.7, 1, 1)
                            self:SetBackdropColor(0.18, 0.18, 0.26, 1)
                        end)
                        wpBtn:SetScript("OnLeave", function(self)
                            self:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.6)
                            self:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                        end)
                        wpBtn:SetScript("OnClick", function()
                            -- Try TomTom first
                            if TomTom and TomTom.AddWaypoint then
                                TomTom:AddWaypoint(c.m, c.x / 100, c.y / 100, {
                                    title = guideDropInfo.name or "Mount",
                                    persistent = false,
                                    minimap = true,
                                    world = true,
                                })
                            else
                                -- Use Blizzard's built-in user waypoint
                                local vector = CreateVector2D(c.x / 100, c.y / 100)
                                C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(c.m, vector))
                                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                            end
                            -- Open map to the target zone so the pin is visible
                            OpenWorldMap(c.m)
                            -- Flash the button to confirm
                            wpText:SetTextColor(0.3, 0.85, 0.4, 1)
                            wpText:SetText("Set!")
                            C_Timer.After(1.5, function()
                                wpText:SetTextColor(0.4, 0.78, 0.95, 1)
                                wpText:SetText(L["Waypoint"] or "Waypoint")
                            end)
                        end)
                    end

                    detailsYOffset = detailsYOffset - 16
                end
            end
            end -- if not isInstanceMount
        end -- if not repVendorWillShow
    end -- if guideDropInfo

    -- --------------------------------------------------------
    -- MCL_Guide reputation / renown data (if loaded)
    -- --------------------------------------------------------
    if MCL_GUIDE_GET_REP_INFO and mountInfo.spellID then
        local rep = MCL_GUIDE_GET_REP_INFO(mountInfo.spellID)
        if rep then
            detailsYOffset = detailsYOffset - 6

            -- Row 1: Faction name
            local facLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            facLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
            facLabel:SetText(rep.isFriendship and "Friendship:" or rep.isRenown and "Renown:" or "Reputation:")
            facLabel:SetTextColor(0.5, 0.55, 0.65, 1)

            local facValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            facValue:SetPoint("LEFT", facLabel, "RIGHT", 4, 0)
            facValue:SetText(rep.factionName)
            facValue:SetTextColor(0.4, 0.78, 0.95, 1)
            detailsYOffset = detailsYOffset - 16

            -- Row 2: Required | Current  (two-column)
            local reqLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            reqLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
            reqLabel:SetText("Required:")
            reqLabel:SetTextColor(0.5, 0.55, 0.65, 1)

            local reqValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            reqValue:SetPoint("LEFT", reqLabel, "RIGHT", 4, 0)
            reqValue:SetText(rep.requiredText)
            reqValue:SetTextColor(0.9, 0.9, 0.2, 1)

            -- Current standing on the right side
            local curLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            curLabel:SetPoint("LEFT", reqValue, "RIGHT", 16, 0)
            curLabel:SetText("Current:")
            curLabel:SetTextColor(0.5, 0.55, 0.65, 1)

            local curValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            curValue:SetPoint("LEFT", curLabel, "RIGHT", 4, 0)
            curValue:SetText(rep.currentText)
            if rep.isMet then
                curValue:SetTextColor(0.3, 0.85, 0.4, 1)
            else
                curValue:SetTextColor(0.9, 0.25, 0.25, 1)
            end
            detailsYOffset = detailsYOffset - 16

            -- Row 3: Vendor name + Waypoint button
            if rep.vendorName and rep.vendorMapId and rep.vendorX and rep.vendorY then
                local vLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                vLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                vLabel:SetText("Vendor:")
                vLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                local vValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                vValue:SetPoint("LEFT", vLabel, "RIGHT", 4, 0)
                vValue:SetText(string.format("%s (%.1f, %.1f)", rep.vendorName, rep.vendorX, rep.vendorY))
                vValue:SetTextColor(0.8, 0.8, 0.85, 1)

                -- Waypoint button
                local vpBtn = CreateFrame("Button", nil, detailsFrame, "BackdropTemplate")
                vpBtn:SetSize(80, 16)
                vpBtn:SetPoint("LEFT", vValue, "RIGHT", 12, 0)
                vpBtn:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1,
                })
                vpBtn:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                vpBtn:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.6)

                local vpIcon = vpBtn:CreateTexture(nil, "ARTWORK")
                vpIcon:SetSize(12, 12)
                vpIcon:SetPoint("LEFT", vpBtn, "LEFT", 4, 0)
                vpIcon:SetTexture("Interface\\AddOns\\MCL\\icons\\pin")
                vpIcon:SetVertexColor(0.2, 0.6, 0.9, 1)

                local vpText = vpBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                vpText:SetPoint("LEFT", vpIcon, "RIGHT", 3, 0)
                vpText:SetText(L["Waypoint"] or "Waypoint")
                vpText:SetTextColor(0.4, 0.78, 0.95, 1)

                vpBtn:SetScript("OnEnter", function(self)
                    self:SetBackdropBorderColor(0.3, 0.7, 1, 1)
                    self:SetBackdropColor(0.18, 0.18, 0.26, 1)
                end)
                vpBtn:SetScript("OnLeave", function(self)
                    self:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.6)
                    self:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                end)
                vpBtn:SetScript("OnClick", function()
                    local vm = rep.vendorMapId
                    local vx = rep.vendorX / 100
                    local vy = rep.vendorY / 100
                    if TomTom and TomTom.AddWaypoint then
                        TomTom:AddWaypoint(vm, vx, vy, {
                            title = rep.vendorName or "Vendor",
                            persistent = false,
                            minimap = true,
                            world = true,
                        })
                    else
                        local vector = CreateVector2D(vx, vy)
                        C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(vm, vector))
                        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                    end
                    OpenWorldMap(vm)
                    vpText:SetTextColor(0.3, 0.85, 0.4, 1)
                    vpText:SetText("Set!")
                    C_Timer.After(1.5, function()
                        vpText:SetTextColor(0.4, 0.78, 0.95, 1)
                        vpText:SetText(L["Waypoint"] or "Waypoint")
                    end)
                end)

                detailsYOffset = detailsYOffset - 16
            end
        end
    end

    -- --------------------------------------------------------
    -- General vendor data (from Mount DB2 SourceText)
    -- Only shown when no rep vendor or guide vendor row was already displayed above
    -- --------------------------------------------------------
    local repVendorShown = false
    if MCL_GUIDE_GET_REP_INFO and mountInfo.spellID then
        local repCheck = MCL_GUIDE_GET_REP_INFO(mountInfo.spellID)
        if repCheck and repCheck.vendorName then
            repVendorShown = true
        end
    end
    -- Also skip if guide drop data already showed this mount as a vendor source
    local guideVendorShown = guideDropInfo and guideDropInfo.method == "VENDOR"

    if not repVendorShown and not guideVendorShown and MCL_GUIDE_VENDOR_DATA and mountInfo.mountID then
        local vdRaw = MCL_GUIDE_VENDOR_DATA[mountInfo.mountID]
        -- Normalize: support both old single-table and new array-of-tables format
        local vendorList
        if vdRaw then
            if vdRaw[1] and type(vdRaw[1]) == "table" then
                vendorList = vdRaw  -- already an array
            elseif vdRaw.npc then
                vendorList = { vdRaw }  -- old single-vendor format
            end
        end

        if vendorList then
            -- Filter by player faction if any vendor has a faction tag
            local playerFaction = UnitFactionGroup("player")  -- "Alliance" or "Horde"
            local filtered = {}
            for _, vd in ipairs(vendorList) do
                if vd.npc and vd.npc ~= "" then
                    if not vd.faction or vd.faction == "" or vd.faction == playerFaction then
                        filtered[#filtered + 1] = vd
                    end
                end
            end
            -- If filtering removed everything, show all (safety net)
            if #filtered == 0 then filtered = vendorList end

            for _, vd in ipairs(filtered) do
                if vd.npc and vd.npc ~= "" then
                    detailsYOffset = detailsYOffset - 6

                    -- Vendor NPC name (with optional faction tag)
                    local vLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    vLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                    local labelText = "Vendor:"
                    if vd.faction and vd.faction ~= "" then
                        labelText = vd.faction .. " Vendor:"
                    end
                    vLabel:SetText(labelText)
                    vLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                    local vValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    vValue:SetPoint("LEFT", vLabel, "RIGHT", 4, 0)
                    if vd.x and vd.y then
                        vValue:SetText(string.format("%s (%.1f, %.1f)", vd.npc, vd.x, vd.y))
                    else
                        vValue:SetText(vd.npc)
                    end
                    vValue:SetTextColor(0.8, 0.8, 0.85, 1)

                    -- Waypoint button (only if we have coordinates)
                    if vd.m and vd.x and vd.y then
                        local vwBtn = CreateFrame("Button", nil, detailsFrame, "BackdropTemplate")
                        vwBtn:SetSize(80, 16)
                        vwBtn:SetPoint("LEFT", vValue, "RIGHT", 12, 0)
                        vwBtn:SetBackdrop({
                            bgFile = "Interface\\Buttons\\WHITE8x8",
                            edgeFile = "Interface\\Buttons\\WHITE8x8",
                            edgeSize = 1,
                        })
                        vwBtn:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                        vwBtn:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.6)

                        local vwIcon = vwBtn:CreateTexture(nil, "ARTWORK")
                        vwIcon:SetSize(12, 12)
                        vwIcon:SetPoint("LEFT", vwBtn, "LEFT", 4, 0)
                        vwIcon:SetTexture("Interface\\AddOns\\MCL\\icons\\pin")
                        vwIcon:SetVertexColor(0.2, 0.6, 0.9, 1)

                        local vwText = vwBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        vwText:SetPoint("LEFT", vwIcon, "RIGHT", 3, 0)
                        vwText:SetText(L["Waypoint"] or "Waypoint")
                        vwText:SetTextColor(0.4, 0.78, 0.95, 1)

                        vwBtn:SetScript("OnEnter", function(self)
                            self:SetBackdropBorderColor(0.3, 0.7, 1, 1)
                            self:SetBackdropColor(0.18, 0.18, 0.26, 1)
                        end)
                        vwBtn:SetScript("OnLeave", function(self)
                            self:SetBackdropBorderColor(0.2, 0.6, 0.9, 0.6)
                            self:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                        end)
                        vwBtn:SetScript("OnClick", function()
                            local vm = vd.m
                            local vx = vd.x / 100
                            local vy = vd.y / 100
                            if TomTom and TomTom.AddWaypoint then
                                TomTom:AddWaypoint(vm, vx, vy, {
                                    title = vd.npc or "Vendor",
                                    persistent = false,
                                    minimap = true,
                                    world = true,
                                })
                            else
                                local vector = CreateVector2D(vx, vy)
                                C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(vm, vector))
                                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                            end
                            OpenWorldMap(vm)
                            vwText:SetTextColor(0.3, 0.85, 0.4, 1)
                            vwText:SetText("Set!")
                            C_Timer.After(1.5, function()
                                vwText:SetTextColor(0.4, 0.78, 0.95, 1)
                                vwText:SetText(L["Waypoint"] or "Waypoint")
                            end)
                        end)
                    end

                    detailsYOffset = detailsYOffset - 16

                    -- Zone name (if available)
                    if vd.zone and vd.zone ~= "" then
                        local vzLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        vzLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                        vzLabel:SetText("Location:")
                        vzLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                        local vzValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        vzValue:SetPoint("LEFT", vzLabel, "RIGHT", 4, 0)
                        vzValue:SetText(vd.zone)
                        vzValue:SetTextColor(0.8, 0.8, 0.85, 1)
                        detailsYOffset = detailsYOffset - 16
                    end
                end
            end
        end
    end

    -- --------------------------------------------------------
    -- Quest data (from Mount DB2 SourceText)
    -- Shows quest name, quest giver NPC, zone, and waypoint
    -- --------------------------------------------------------
    if MCL_GUIDE_QUEST_DATA and mountInfo.mountID then
        local qd = MCL_GUIDE_QUEST_DATA[mountInfo.mountID]
        if qd and qd.quest and qd.quest ~= "" then
            detailsYOffset = detailsYOffset - 6

            -- Quest name label
            local qLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            qLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
            qLabel:SetText("Quest:")
            qLabel:SetTextColor(0.5, 0.55, 0.65, 1)

            -- Quest name as a clickable button (opens quest in Wowhead)
            local qBtn = CreateFrame("Button", nil, detailsFrame)
            qBtn:SetPoint("LEFT", qLabel, "RIGHT", 4, 0)
            local qBtnText = qBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            qBtnText:SetPoint("LEFT", qBtn, "LEFT", 0, 0)
            qBtnText:SetText(qd.quest)
            qBtnText:SetTextColor(1, 0.82, 0, 1)
            qBtn:SetSize(qBtnText:GetStringWidth() + 4, 14)

            qBtn:SetScript("OnEnter", function(self)
                qBtnText:SetTextColor(1, 1, 0.5, 1)
                GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
                if qd.questId then
                    GameTooltip:SetHyperlink(string.format("quest:%d", qd.questId))
                else
                    GameTooltip:AddLine(qd.quest, 1, 0.82, 0)
                end
                GameTooltip:Show()
            end)
            qBtn:SetScript("OnLeave", function(self)
                qBtnText:SetTextColor(1, 0.82, 0, 1)
                GameTooltip:Hide()
            end)

            -- Quest completion check
            if qd.questId then
                local completed = C_QuestLog.IsQuestFlaggedCompleted(qd.questId)
                if completed then
                    local qCheck = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    qCheck:SetPoint("LEFT", qBtn, "RIGHT", 4, 0)
                    qCheck:SetText("|cFF00FF00\226\156\147|r")
                end
            end

            detailsYOffset = detailsYOffset - 16

            -- Quest giver NPC + coords + waypoint
            if qd.npc and qd.npc ~= "" then
                local qnLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                qnLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                qnLabel:SetText("Quest Giver:")
                qnLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                local qnValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                qnValue:SetPoint("LEFT", qnLabel, "RIGHT", 4, 0)
                if qd.x and qd.y then
                    qnValue:SetText(string.format("%s (%.1f, %.1f)", qd.npc, qd.x, qd.y))
                else
                    qnValue:SetText(qd.npc)
                end
                qnValue:SetTextColor(0.8, 0.8, 0.85, 1)

                -- Waypoint button (only if we have coordinates)
                if qd.m and qd.x and qd.y then
                    local qwBtn = CreateFrame("Button", nil, detailsFrame, "BackdropTemplate")
                    qwBtn:SetSize(80, 16)
                    qwBtn:SetPoint("LEFT", qnValue, "RIGHT", 12, 0)
                    qwBtn:SetBackdrop({
                        bgFile = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })
                    qwBtn:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                    qwBtn:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.6)

                    local qwIcon = qwBtn:CreateTexture(nil, "ARTWORK")
                    qwIcon:SetSize(12, 12)
                    qwIcon:SetPoint("LEFT", qwBtn, "LEFT", 4, 0)
                    qwIcon:SetTexture("Interface\\AddOns\\MCL\\icons\\pin")
                    qwIcon:SetVertexColor(0.9, 0.7, 0.2, 1)

                    local qwText = qwBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    qwText:SetPoint("LEFT", qwIcon, "RIGHT", 3, 0)
                    qwText:SetText(L["Waypoint"] or "Waypoint")
                    qwText:SetTextColor(0.95, 0.82, 0.4, 1)

                    qwBtn:SetScript("OnEnter", function(self)
                        self:SetBackdropBorderColor(1, 0.8, 0.3, 1)
                        self:SetBackdropColor(0.18, 0.18, 0.26, 1)
                    end)
                    qwBtn:SetScript("OnLeave", function(self)
                        self:SetBackdropBorderColor(0.9, 0.7, 0.2, 0.6)
                        self:SetBackdropColor(0.12, 0.12, 0.18, 0.9)
                    end)
                    qwBtn:SetScript("OnClick", function()
                        local qm = qd.m
                        local qx = qd.x / 100
                        local qy = qd.y / 100
                        if TomTom and TomTom.AddWaypoint then
                            TomTom:AddWaypoint(qm, qx, qy, {
                                title = qd.npc or "Quest Giver",
                                persistent = false,
                                minimap = true,
                                world = true,
                            })
                        else
                            local vector = CreateVector2D(qx, qy)
                            C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(qm, vector))
                            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                        end
                        OpenWorldMap(qm)
                        qwText:SetTextColor(0.3, 0.85, 0.4, 1)
                        qwText:SetText("Set!")
                        C_Timer.After(1.5, function()
                            qwText:SetTextColor(0.95, 0.82, 0.4, 1)
                            qwText:SetText(L["Waypoint"] or "Waypoint")
                        end)
                    end)
                end

                detailsYOffset = detailsYOffset - 16
            end

            -- Zone name
            if qd.zone and qd.zone ~= "" then
                local qzLabel = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                qzLabel:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                qzLabel:SetText("Quest Zone:")
                qzLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                local qzValue = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                qzValue:SetPoint("LEFT", qzLabel, "RIGHT", 4, 0)
                qzValue:SetText(qd.zone)
                qzValue:SetTextColor(0.8, 0.8, 0.85, 1)
                detailsYOffset = detailsYOffset - 16
            end
        end
    end

    -- --------------------------------------------------------
    -- MCL_Guide currency / cost data (if loaded)
    -- --------------------------------------------------------
    if MCL_GUIDE_CURRENCY_DATA and mountInfo.spellID then
        local costList = MCL_GUIDE_CURRENCY_DATA[mountInfo.spellID]
        if costList and #costList > 0 then
            do
                detailsYOffset = detailsYOffset - 6

                -- "Cost:" label on the same line as the first cost entry
                local costHeader = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                costHeader:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                costHeader:SetText("Cost:")
                costHeader:SetTextColor(0.5, 0.55, 0.65, 1)
                local headerWidth = costHeader:GetStringWidth() or 30
                local costInlineOffset = headerWidth + 6

                for i, cost in ipairs(costList) do
                    local costName = "?"
                    local costIcon = nil
                    local playerHas = 0
                    local required = cost.amount or 0

                    if cost.type == "currency" and cost.id > 0 then
                        -- Query currency info from game
                        local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(cost.id)
                        if info then
                            costName = info.name or ("Currency " .. cost.id)
                            costIcon = info.iconFileID
                            playerHas = info.quantity or 0
                        else
                            costName = "Currency " .. cost.id
                        end
                    elseif cost.type == "item" and cost.id > 0 then
                        -- Query item info
                        local itemName, _, _, _, _, _, _, _, _, itemTexture = C_Item.GetItemInfo(cost.id)
                        costName = itemName or ("Item " .. cost.id)
                        costIcon = itemTexture
                        playerHas = C_Item.GetItemCount(cost.id, true) or 0
                    elseif cost.type == "gold" then
                        costName = "Gold"
                        costIcon = "Interface\\MoneyFrame\\UI-GoldIcon"
                        playerHas = (GetMoney() or 0)
                    end

                    -- First cost item sits inline with "Cost:", subsequent ones go on new lines
                    local rowLeftOffset = (i == 1) and costInlineOffset or costInlineOffset

                    -- Icon (if available)
                    local rowAnchorOffset = rowLeftOffset
                    if costIcon then
                        local icon = detailsFrame:CreateTexture(nil, "ARTWORK")
                        icon:SetSize(14, 14)
                        icon:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", rowLeftOffset, detailsYOffset)
                        icon:SetTexture(costIcon)
                        rowAnchorOffset = rowLeftOffset + 16
                    end

                    -- Name + required amount
                    local nameStr = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    nameStr:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", rowAnchorOffset, detailsYOffset)
                    nameStr:SetText(costName)
                    nameStr:SetTextColor(0.8, 0.8, 0.85, 1)

                    -- Display amount: "have / need"
                    local isMet = playerHas >= required
                    local displayHas, displayNeed
                    if cost.type == "gold" then
                        displayHas = math.floor(playerHas / 10000)
                        displayNeed = math.floor(required / 10000)
                    else
                        displayHas = playerHas
                        displayNeed = required
                    end

                    local amtStr = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                    amtStr:SetPoint("LEFT", nameStr, "RIGHT", 6, 0)
                    amtStr:SetText(displayHas .. " / " .. displayNeed)
                    if isMet then
                        amtStr:SetTextColor(0.3, 0.85, 0.4, 1)
                    else
                        amtStr:SetTextColor(0.9, 0.25, 0.25, 1)
                    end

                    detailsYOffset = detailsYOffset - 16
                end
            end
        end
    end

    -- --------------------------------------------------------
    -- MCL_Guide achievement data (if loaded)
    -- --------------------------------------------------------
    if MCL_GUIDE_ACHIEVEMENT_DATA and mountInfo.spellID then
        -- Build a spellID → achievementId cache once
        if not MCL_GUIDE_ACHIEVEMENT_DATA._spellCache and MCL_GUIDE_ACHIEVEMENT_DATA.byAchievement then
            MCL_GUIDE_ACHIEVEMENT_DATA._spellCache = {}
            for achIdKey, achData in pairs(MCL_GUIDE_ACHIEVEMENT_DATA.byAchievement) do
                if achData.itemId and achData.itemId ~= 0 then
                    local mID = C_MountJournal.GetMountFromItem(achData.itemId)
                    if mID then
                        local _, sID = C_MountJournal.GetMountInfoByID(mID)
                        if sID then
                            MCL_GUIDE_ACHIEVEMENT_DATA._spellCache[sID] = achIdKey
                        end
                    end
                elseif achData.mountId then
                    -- For mXXX mounts: mountId is the journal ID, resolve to spellID
                    local _, sID = C_MountJournal.GetMountInfoByID(achData.mountId)
                    if sID then
                        MCL_GUIDE_ACHIEVEMENT_DATA._spellCache[sID] = achIdKey
                    end
                end
            end
        end

        local achId = nil
        -- Try the built cache
        if MCL_GUIDE_ACHIEVEMENT_DATA._spellCache then
            achId = MCL_GUIDE_ACHIEVEMENT_DATA._spellCache[mountInfo.spellID]
        end
        -- Fallback: bySpell index
        if not achId and MCL_GUIDE_ACHIEVEMENT_DATA.bySpell then
            local val = MCL_GUIDE_ACHIEVEMENT_DATA.bySpell[mountInfo.spellID]
            achId = type(val) == "table" and val[1] or val
        end
        if achId then
            local _, achName, _, achCompleted, _, _, _, achDesc, _, achIcon = GetAchievementInfo(achId)
            if achName then
                detailsYOffset = detailsYOffset - 6

                -- Clickable achievement row
                local achBtn = CreateFrame("Button", nil, detailsFrame)
                achBtn:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
                achBtn:SetPoint("RIGHT", detailsFrame, "RIGHT", 0, 0)
                achBtn:SetHeight(16)
                achBtn:EnableMouse(true)
                achBtn:SetFrameLevel(detailsFrame:GetFrameLevel() + 10)

                local achLabel = achBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                achLabel:SetPoint("LEFT", achBtn, "LEFT", 0, 0)
                achLabel:SetText(L["Achievement:"] or "Achievement:")
                achLabel:SetTextColor(0.5, 0.55, 0.65, 1)

                local achValue = achBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                achValue:SetPoint("LEFT", achLabel, "RIGHT", 4, 0)
                achValue:SetText(achName)
                if achCompleted then
                    achValue:SetTextColor(0.3, 0.85, 0.4, 1)
                else
                    achValue:SetTextColor(0.9, 0.9, 0.2, 1)
                end

                achBtn:SetScript("OnClick", function()
                    -- Debug: confirm click fires
                    print("|cFF1FB7EBMCL|r Opening achievement: " .. (achName or "?") .. " (ID: " .. achId .. ")")
                    -- Load the achievement UI addon if needed
                    if not AchievementFrame then
                        if C_AddOns and C_AddOns.LoadAddOn then
                            C_AddOns.LoadAddOn("Blizzard_AchievementUI")
                        elseif LoadAddOn then
                            LoadAddOn("Blizzard_AchievementUI")
                        end
                    end
                    -- Open and navigate to the achievement
                    if AchievementFrame then
                        if not AchievementFrame:IsShown() then
                            ShowUIPanel(AchievementFrame)
                        end
                        if AchievementFrame_SelectAchievement then
                            AchievementFrame_SelectAchievement(achId)
                        end
                    else
                        print("|cFF1FB7EBMCL|r Error: Could not load AchievementFrame")
                    end
                end)
                achBtn:SetScript("OnEnter", function(self)
                    achValue:SetTextColor(1, 1, 1, 1)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

                    -- Custom achievement tooltip with manual criteria tracking
                    GameTooltip:AddLine(achName, 1, 1, 1)
                    if achCompleted then
                        GameTooltip:AddLine("Achievement completed", 0.3, 0.85, 0.4)
                    else
                        GameTooltip:AddLine("Achievement in progress", 0.9, 0.9, 0.2)
                    end
                    if achDesc and achDesc ~= "" then
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine(achDesc, 1, 0.82, 0, true)
                    end

                    -- Query criteria and display with correct completion colors
                    local numCriteria = GetAchievementNumCriteria(achId)
                    if numCriteria and numCriteria > 0 then
                        GameTooltip:AddLine(" ")
                        -- Two-column layout for many criteria
                        if numCriteria > 4 then
                            for i = 1, numCriteria, 2 do
                                local name1, _, completed1 = GetAchievementCriteriaInfo(achId, i)
                                local r1, g1, b1 = 0.6, 0.6, 0.6
                                if completed1 then r1, g1, b1 = 0.3, 0.85, 0.4 end

                                if i + 1 <= numCriteria then
                                    local name2, _, completed2 = GetAchievementCriteriaInfo(achId, i + 1)
                                    local r2, g2, b2 = 0.6, 0.6, 0.6
                                    if completed2 then r2, g2, b2 = 0.3, 0.85, 0.4 end
                                    GameTooltip:AddDoubleLine(name1 or "?", name2 or "?", r1, g1, b1, r2, g2, b2)
                                else
                                    GameTooltip:AddLine(name1 or "?", r1, g1, b1)
                                end
                            end
                        else
                            for i = 1, numCriteria do
                                local name, _, completed = GetAchievementCriteriaInfo(achId, i)
                                if completed then
                                    GameTooltip:AddLine((name or "?"), 0.3, 0.85, 0.4)
                                else
                                    GameTooltip:AddLine((name or "?"), 0.6, 0.6, 0.6)
                                end
                            end
                        end
                    end

                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF00FF00Click to view achievement|r")
                    GameTooltip:Show()
                end)
                achBtn:SetScript("OnLeave", function()
                    if achCompleted then
                        achValue:SetTextColor(0.3, 0.85, 0.4, 1)
                    else
                        achValue:SetTextColor(0.9, 0.9, 0.2, 1)
                    end
                    GameTooltip:Hide()
                end)

                detailsYOffset = detailsYOffset - 16
            end
        end
    end

    -- Calculate actual details height from how far detailsYOffset moved
    local detailsUsedHeight = math.abs(detailsYOffset) + 10
    if detailsUsedHeight < 80 then detailsUsedHeight = 80 end
    mainContentFrame:SetHeight(detailsUsedHeight)
    yOffset = yOffset - detailsUsedHeight
    contentHeight = contentHeight + detailsUsedHeight
    
    -- Mount Model Section (hidden when notes are expanded to give more space)
    if not notesExpanded then
    yOffset = yOffset - 5  -- Reduced gap from 10 to 5
    contentHeight = contentHeight + 5
    
    -- Use fixed height for model frame
    local modelHeight = 450 -- Fixed height instead of dynamic calculation
    
    local modelFrame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    modelFrame:SetSize(parentFrame:GetWidth() - 20, modelHeight) -- Use full width minus small padding
    modelFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)  -- Aligned with description
    modelFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    modelFrame:SetBackdropColor(0.04, 0.04, 0.06, 0.6)
    modelFrame:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.5)
    
    -- Create model display using PlayerModel frame (no backdrop)
    local mountModel = CreateFrame("PlayerModel", nil, modelFrame)
    -- Use the full frame size to prevent clipping
    mountModel:SetSize(modelFrame:GetWidth(), modelFrame:GetHeight())
    mountModel:SetPoint("CENTER", modelFrame, "CENTER", 0, 0)
    
    -- Try to display the mount model
    if mountInfo.creatureDisplayID and mountInfo.creatureDisplayID > 0 then
        -- Clear any existing model first to prevent caching issues
        mountModel:ClearModel()
        mountModel:SetDisplayInfo(0)
        
        -- Small delay to ensure clearing takes effect, then set the new model
        C_Timer.After(0.1, function()
            mountModel:SetDisplayInfo(mountInfo.creatureDisplayID)
            
            -- Force a refresh first to ensure the model is properly initialized
            mountModel:RefreshCamera()
                        
            -- Use camera setting 2 for better mount viewing angle
            mountModel:SetCamera(2)
            
            -- Let the model fill the full frame viewport
            mountModel:SetSize(modelFrame:GetWidth(), modelFrame:GetHeight())
            
            -- Position the model for better viewing distance
            mountModel:SetPosition(0, 0, 0)
            
            -- Set initial facing (front-facing like dressing room)
            mountModel:SetFacing(0)

            -- Force a refresh first to ensure the model is properly initialized
            mountModel:RefreshCamera()
        end)
        
        -- Variables for drag rotation and panning
        local isDragging = false
        local isPanning = false
        local lastCursorX, lastCursorY = 0, 0
        local posX, posY, posZ = 0, 0, 0
        
        -- Add model controls with proper click-and-drag
        mountModel:EnableMouse(true)
        mountModel:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                isDragging = true
                lastCursorX = select(1, GetCursorPosition())
            elseif button == "RightButton" then
                isPanning = true
                lastCursorX, lastCursorY = GetCursorPosition()
            end
            if isDragging or isPanning then
                self:SetScript("OnUpdate", function(self)
                    local currentX, currentY = GetCursorPosition()
                    if isDragging then
                        local deltaX = currentX - lastCursorX
                        local sensitivity = 0.01
                        local currentFacing = self:GetFacing()
                        self:SetFacing(currentFacing + (deltaX * sensitivity))
                        lastCursorX = currentX
                    end
                    if isPanning then
                        local scale = UIParent:GetEffectiveScale()
                        local deltaX = (currentX - lastCursorX) / scale
                        local deltaY = (currentY - lastCursorY) / scale
                        local panSpeed = 0.01
                        posY = posY + deltaX * panSpeed   -- left/right
                        posZ = posZ + deltaY * panSpeed    -- up/down
                        self:SetPosition(posX, posY, posZ)
                        lastCursorX, lastCursorY = currentX, currentY
                    end
                end)
            end
        end)
        
        mountModel:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                isDragging = false
            elseif button == "RightButton" then
                isPanning = false
            elseif button == "MiddleButton" then
                -- Reset zoom, pan, and rotation to defaults
                posX, posY, posZ = 0, 0, 0
                currentZoom = 1.0
                self:SetPosition(0, 0, 0)
                self:SetFacing(0)
                self:SetCamDistanceScale(1.0)
            end
            if not isDragging and not isPanning then
                self:SetScript("OnUpdate", nil)
            end
        end)
        
        -- Also handle mouse leaving the frame
        mountModel:SetScript("OnLeave", function(self)
            isDragging = false
            isPanning = false
            self:SetScript("OnUpdate", nil)
        end)
        
        -- Mouse wheel zoom
        local currentZoom = 1.0
        local zoomMin, zoomMax, zoomStep = 0.3, 3.0, 0.15
        mountModel:EnableMouseWheel(true)
        mountModel:SetScript("OnMouseWheel", function(self, delta)
            currentZoom = currentZoom - (delta * zoomStep)
            currentZoom = math.max(zoomMin, math.min(zoomMax, currentZoom))
            self:SetCamDistanceScale(currentZoom)
        end)
        
        -- Model controls text
        local modelControlsText = modelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        modelControlsText:SetPoint("BOTTOM", mountModel, "BOTTOM", 0, -25)
        modelControlsText:SetText("LMB: rotate | RMB: pan | Scroll: zoom | MMB: reset")
        modelControlsText:SetTextColor(0.5, 0.55, 0.65, 0.8)
    else
        -- Fallback: show large mount icon if no model available
        local largeIconFrame = CreateFrame("Frame", nil, modelFrame)
        largeIconFrame:SetSize(128, 128)
        largeIconFrame:SetPoint("CENTER", modelFrame, "CENTER", 0, 0)
        
        local largeIcon = largeIconFrame:CreateTexture(nil, "ARTWORK")
        largeIcon:SetPoint("CENTER", largeIconFrame, "CENTER", 0, 0)
        largeIcon:SetSize(120, 120)
        largeIcon:SetTexture(mountInfo.icon)
        
        -- No model available text
        local noModelText = modelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        noModelText:SetPoint("BOTTOM", largeIconFrame, "BOTTOM", 0, -15)
        noModelText:SetText("3D Model not available")
        noModelText:SetTextColor(0.5, 0.55, 0.65, 0.8)
    end
    
    yOffset = yOffset - modelHeight
    contentHeight = contentHeight + modelHeight
    end -- end notesExpanded check
    
    -- Set the parent frame height to fit all content
    parentFrame:SetHeight(contentHeight + 40)
end

--[[
  Show mount card for a specific mount
]]
function MountCard:ShowMountCard(mountData, anchorFrame)
    if not mountData then
        return
    end
    
    local card = self:CreateMountCard()
    if not card then
        return
    end
    
    -- Store current mount and anchor
    card.currentMountID = mountData.mountID or mountData.id
    card.currentAnchorFrame = anchorFrame
    card.notesExpanded = false  -- Reset expand state for new mount
    
    -- Position the card relative to main MCL window
    card:ClearAllPoints()
    if MCL_mainFrame and MCL_mainFrame:IsVisible() then
        -- Attach to the right of the main MCL window
        card:SetPoint("TOPLEFT", MCL_mainFrame, "TOPRIGHT", 10, 0)
    elseif anchorFrame then
        -- Fallback to anchor frame if main window not available
        card:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 10, 0)
    else
        -- Final fallback to center of screen
        card:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    end
    
    -- Create content
    self:CreateMountCardContent(card.scrollChild, mountData)
    
    -- Ensure the main frame hook is established (backup safety check)
    if card.ensureHook then
        card.ensureHook()
    end
    
    -- Show the card
    card:Show()
    
    return card
end

--[[
  Hide mount card
]]
function MountCard:HideMountCard()
    if MCL_MountCard then
        MCL_MountCard:Hide()
    end
end

--[[
  Resize mount card to match main frame dimensions
]]
function MountCard:ResizeMountCard()
    if not MCL_MountCard then
        return
    end
    
    -- Get new dimensions (fixed width, dynamic height)
    local cardWidth, cardHeight = GetMountCardDimensions()
    
    -- Resize the main card frame
    MCL_MountCard:SetSize(cardWidth, cardHeight)
    
    -- Resize child frames with fixed width
    if MCL_MountCard.titleFrame then
        MCL_MountCard.titleFrame:SetSize(cardWidth - 20, 30)
    end
    
    if MCL_MountCard.headerFrame then
        MCL_MountCard.headerFrame:SetSize(cardWidth - 20, 1)
    end
    
    if MCL_MountCard.scrollChild then
        MCL_MountCard.scrollChild:SetSize(cardWidth - 20, cardHeight - 80)
    end
end

--[[
  Check if mount card is visible
]]
function MountCard:IsMountCardVisible()
    return MCL_MountCard and MCL_MountCard:IsVisible()
end

--[[
  Show mount card on hover with delay
]]
function MountCard:ShowMountCardOnHover(mountData, anchorFrame, delay)
    -- Check if mount card hover is enabled in settings
    if not MCL_SETTINGS or not MCL_SETTINGS.enableMountCardHover then
        return
    end
    
    -- Cancel any existing hover timer
    if hoverTimer then
        hoverTimer:Cancel()
        hoverTimer = nil
    end
    
    -- Store the current hovered mount
    currentHoveredMount = mountData
    currentAnchorFrame = anchorFrame
    
    -- Set up a delay before showing to prevent flickering
    local showDelay = delay or 0.2  -- Reduced from 0.5 to 0.2 seconds for faster response
    
    -- If delay is 0 or very small, show immediately
    if showDelay <= 0.05 then
        self:ShowMountCard(mountData, anchorFrame)
        return
    end
    
    hoverTimer = C_Timer.NewTimer(showDelay, function()
        -- Only show if we're still hovering the same mount
        if currentHoveredMount and currentHoveredMount.mountID == mountData.mountID then
            self:ShowMountCard(mountData, anchorFrame)
        end
        hoverTimer = nil
    end)
end

--[[
  Show mount card instantly (no delay)
]]
function MountCard:ShowMountCardInstant(mountData, anchorFrame)
    return self:ShowMountCardOnHover(mountData, anchorFrame, 0)
end

--[[
  Hide mount card on hover end
]]
function MountCard:HideMountCardOnHover()
    -- Cancel any pending hover timer
    if hoverTimer then
        hoverTimer:Cancel()
        hoverTimer = nil
    end
    
    -- Clear current hovered mount
    currentHoveredMount = nil
    currentAnchorFrame = nil
    
    -- Hide the card
    self:HideMountCard()
end

--[[
  Toggle mount card visibility
]]
function MountCard:ToggleMountCard(mountData, anchorFrame)
    if self:IsMountCardVisible() and MCL_MountCard.currentMountID == (mountData.mountID or mountData.id) then
        self:HideMountCard()
    else
        self:ShowMountCard(mountData, anchorFrame)
    end
end

-- Compatibility functions for external access
MCLcore.MountCard.Show = function(mountData, anchorFrame)
    return MountCard:ShowMountCard(mountData, anchorFrame)
end

MCLcore.MountCard.Hide = function()
    return MountCard:HideMountCard()
end

MCLcore.MountCard.Toggle = function(mountData, anchorFrame)
    return MountCard:ToggleMountCard(mountData, anchorFrame)
end

MCLcore.MountCard.ShowOnHover = function(mountData, anchorFrame, delay)
    return MountCard:ShowMountCardOnHover(mountData, anchorFrame, delay)
end

MCLcore.MountCard.ShowInstant = function(mountData, anchorFrame)
    return MountCard:ShowMountCardInstant(mountData, anchorFrame)
end

MCLcore.MountCard.HideOnHover = function()
    return MountCard:HideMountCardOnHover()
end

MCLcore.MountCard.Resize = function()
    return MountCard:ResizeMountCard()
end

MCLcore.MountCard.IsVisible = function()
    return MountCard:IsMountCardVisible()
end
