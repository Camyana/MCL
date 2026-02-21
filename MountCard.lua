local MCL, MCLcore = ...;

-- Ensure the Frames module exists
MCLcore.Frames = MCLcore.Frames or {};
MCLcore.MountCard = {};

local MountCard = MCLcore.MountCard;
local MCL_functions = MCLcore.Functions or {};

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

    -- Click-to-copy hint
    f.copyHint = f.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.copyHint:SetPoint("RIGHT", f.titleFrame, "RIGHT", -5, 0)
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
    
    local yOffset = 0   -- Start right underneath the title area (was -5)
    local contentHeight = 10  -- Reduced from 20
    local contentWidth = parentFrame:GetWidth() - 20 -- Reduced padding from 60 to 20
    
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
    
    -- Source details section (aligned left with description)
    local mainContentFrame = CreateFrame("Frame", nil, parentFrame)
    mainContentFrame:SetSize(contentWidth, 80)
    mainContentFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, yOffset)  -- Aligned with description at x=10
    
    -- Mount details frame (aligned with description)
    local detailsFrame = CreateFrame("Frame", nil, mainContentFrame)
    detailsFrame:SetPoint("TOPLEFT", mainContentFrame, "TOPLEFT", 0, 0)  -- Removed extra indentation
    detailsFrame:SetPoint("BOTTOMRIGHT", mainContentFrame, "BOTTOMRIGHT", 0, 10)  -- Removed extra indentation
    
    local detailsYOffset = -5
    
    -- Get Blizzard source information and display it as the primary source
    local blizzardSourceText = "Unknown"
    if mountInfo and mountInfo.mountID then
        local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountInfo.mountID)
        if source and source ~= "" then
            blizzardSourceText = source
        end
    end
    
    -- Display Blizzard source information without label
    if blizzardSourceText ~= "Unknown" then
        local sourceText = detailsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sourceText:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, detailsYOffset)
        sourceText:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", 0, detailsYOffset)
        sourceText:SetText(blizzardSourceText)
        sourceText:SetTextColor(0.65, 0.75, 0.85, 1)  -- House style secondary text
        sourceText:SetJustifyH("LEFT")
        sourceText:SetWordWrap(true)
        
        detailsYOffset = detailsYOffset - 18
    end
    
    yOffset = yOffset - 80
    contentHeight = contentHeight + 80
    
    -- Mount Model Section (no header, small spacing, subtle border)
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

-- Test slash command for debugging
SLASH_MCLMOUNTCARD1 = "/mclmount"
SlashCmdList["MCLMOUNTCARD"] = function(msg)
    local mountID = tonumber(msg) or 280 -- Default to Stormwind Steed (similar to your screenshot)
    local testData = {
        mountID = mountID,
        id = mountID,
        name = "Test Mount"
    }
    MCLcore.MountCard.Show(testData)
    print("MCL: Showing mount card for mount ID:", mountID)
end

-- Test slash command to show specific mount like Stormwind Steed
SLASH_MCLSTORMWIND1 = "/mclstormwind"
SlashCmdList["MCLSTORMWIND"] = function(msg)
    local testData = {
        mountID = 280, -- Stormwind Steed mount ID
        id = 280,
        name = "Stormwind Steed"
    }
    MCLcore.MountCard.Show(testData)
    print("MCL: Showing Stormwind Steed mount card")
end

-- Test instant show command
SLASH_MCLINSTANT1 = "/mclinstant"
SlashCmdList["MCLINSTANT"] = function(msg)
    local mountID = tonumber(msg) or 280
    local testData = {
        mountID = mountID,
        id = mountID,
        name = "Instant Test Mount"
    }
    MCLcore.MountCard.ShowInstant(testData)
    print("MCL: Showing mount card instantly for mount ID:", mountID)
end

-- Test slash command with full MCL categorization data
SLASH_MCLVENDORTEST1 = "/mclvendor"
SlashCmdList["MCLVENDORTEST"] = function(msg)
    local testData = {
        mountID = 280, -- Stormwind Steed mount ID
        id = 280,
        name = "Stormwind Steed",
        section = "Classic",
        category = "Vendor"
    }
    MCLcore.MountCard.Show(testData)
    print("MCL: Showing vendor test mount card with categorization")
end

-- Test slash command for different categories
SLASH_MCLRAIDTEST1 = "/mclraid"
SlashCmdList["MCLRAIDTEST"] = function(msg)
    local testData = {
        mountID = 213209, -- Example raid mount
        id = 213209,
        name = "Raid Mount Test",
        section = "TWW",
        category = "Raid Drop"
    }
    MCLcore.MountCard.Show(testData)
    print("MCL: Showing raid test mount card")
end
