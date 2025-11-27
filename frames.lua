local MCL, MCLcore = ...;

local MCL_Load = MCLcore.Main;

MCLcore.Frames = {};
local MCL_frames = MCLcore.Frames;

MCLcore.TabTable = {}
MCLcore.statusBarFrames  = {}

MCLcore.nav_width = 180
local nav_width = MCLcore.nav_width
local main_frame_width = 800
local main_frame_height = 600

local r,g,b,a

local L = MCLcore.L

-- Performance Throttling Helper Function
local function ThrottledFrameCreation(categoryData, callback)
    if not categoryData or type(categoryData) ~= "table" then
        return
    end
    
    -- Convert categoryData to array if it's not already
    local dataArray = {}
    for k, v in pairs(categoryData) do
        if type(v) == "table" then
            table.insert(dataArray, {key = k, data = v})
        end
    end
    
    if #dataArray == 0 then
        return
    end
    
    local index = 1
    local batchSize = 5  -- Process 5 categories at a time
    local batchDelay = 0.02  -- 20ms delay between batches
    
    local function processNextBatch()
        local processed = 0
        while index <= #dataArray and processed < batchSize do
            local success, error = pcall(callback, dataArray[index].key, dataArray[index].data)
            if not success then
                print("MCL Error processing category:", error)
            end
            index = index + 1
            processed = processed + 1
        end
        
        if index <= #dataArray then
            C_Timer.After(batchDelay, processNextBatch)
        end
    end
    
    processNextBatch()
end

-- Throttled Mount Creation Helper
local function ThrottledMountCreation(mountList, categoryFrame, config, callback)
    if not mountList or #mountList == 0 then
        if callback then callback() end
        return
    end
    
    -- Validate input data
    if not categoryFrame or not config then
        print("MCL Error: Invalid parameters passed to ThrottledMountCreation")
        if callback then callback() end
        return
    end
    
    -- Validate config structure
    local requiredConfigFields = {"maxDisplayMounts", "mountsPerRow", "mountSize", "actualSpacing", "rowSpacing", "mountStartX", "mountStartY"}
    for _, field in ipairs(requiredConfigFields) do
        if not config[field] then
            print("MCL Error: Missing config field: " .. field)
            if callback then callback() end
            return
        end
    end
    
    local index = 1
    local displayedIndex = 0
    local batchSize = 20  -- Process 20 mounts at a time to prevent timeout
    local batchDelay = 0.05  -- 50ms delay between batches
    local processedCount = 0
    local maxMounts = 2000  -- Safety limit to prevent runaway processing
    
    local function processNextBatch()
        local processed = 0
        local startIndex = index
        
        while index <= #mountList and processed < batchSize and processedCount < maxMounts do
            local mountId = mountList[index]
            local shouldProcess = true
            
            -- Validate mount data
            if not mountId or (type(mountId) ~= "number" and type(mountId) ~= "string") then
                print("MCL Warning: Invalid mount ID at index " .. index .. ": " .. tostring(mountId))
                shouldProcess = false
            end
            
            local mount_Id = nil
            if shouldProcess then
                mount_Id = MCLcore.Function and MCLcore.Function.GetMountID and MCLcore.Function:GetMountID(mountId)
                
                -- Skip invalid mount IDs
                if not mount_Id or type(mount_Id) ~= "number" or mount_Id <= 0 then
                    shouldProcess = false
                end
            end
            
            if shouldProcess then
                -- Faction check: Only display mounts that are not faction-specific or match the player's faction
                local allowed = false
                if MCLcore.Function and MCLcore.Function.IsMountFactionSpecific then
                    local faction, faction_specific = MCLcore.Function.IsMountFactionSpecific(mountId)
                    local playerFaction = UnitFactionGroup("player")
                    if faction_specific == false then
                        allowed = true
                    elseif faction_specific == true then
                        if faction == 0 then faction = "Horde" elseif faction == 1 then faction = "Alliance" end
                        allowed = (faction == playerFaction)
                    end
                else
                    allowed = true  -- Allow if faction check function is not available
                end
                
                if allowed and not (mount_Id and MCL_SETTINGS.hideCollectedMounts and IsMountCollected(mount_Id)) then
                displayedIndex = displayedIndex + 1
                if displayedIndex <= config.maxDisplayMounts then
                    -- Create mount frame using the existing logic
                    local success, error = pcall(function()
                        local col = ((displayedIndex-1) % config.mountsPerRow)
                        local row = math.floor((displayedIndex-1) / config.mountsPerRow)
                        
                        local iconX = config.mountStartX + col * (config.mountSize + config.actualSpacing)
                        local iconY = config.mountStartY - row * (config.mountSize + config.rowSpacing)
                        
                        -- Create backdrop frame first
                        local backdropSize = config.mountSize + 2
                        local backdropFrame = CreateFrame("Frame", nil, categoryFrame, "BackdropTemplate")
                        backdropFrame:SetSize(backdropSize, backdropSize)
                        backdropFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", iconX - 1, iconY + 1)
                        backdropFrame.mountID = mountId
                        
                        -- Create mount frame
                        local mountFrame = CreateFrame("Button", nil, backdropFrame)
                        mountFrame:SetSize(config.mountSize, config.mountSize)
                        mountFrame:SetPoint("CENTER", backdropFrame, "CENTER", 0, 0)
                        mountFrame.mountID = mountId
                        mountFrame.category = config.categoryName
                        mountFrame.section = config.sectionName
                        
                        -- Set mount icon and styling
                        if mount_Id and type(mount_Id) == "number" and mount_Id > 0 then
                            local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mount_Id)
                            if icon then
                                mountFrame.tex = mountFrame:CreateTexture(nil, "ARTWORK")
                                mountFrame.tex:SetAllPoints(mountFrame)
                                mountFrame.tex:SetTexture(icon)
                                
                                mountFrame.pin = mountFrame:CreateTexture(nil, "OVERLAY")
                                mountFrame.pin:SetWidth(16)
                                mountFrame.pin:SetHeight(16)
                                mountFrame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
                                mountFrame.pin:SetPoint("TOPRIGHT", mountFrame, "TOPRIGHT", 6, 6)
                                
                                local pin_check = MCLcore.Function and MCLcore.Function.CheckIfPinned and MCLcore.Function:CheckIfPinned("m"..mount_Id)
                                mountFrame.pin:SetAlpha(pin_check and 1 or 0)
                                
                                if IsMountCollected(mount_Id) then
                                    mountFrame.tex:SetVertexColor(1, 1, 1, 1)
                                    backdropFrame:SetBackdrop({
                                        bgFile = "Interface\\Buttons\\WHITE8x8",
                                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                        edgeSize = 3
                                    })
                                    backdropFrame:SetBackdropColor(0, 0.8, 0, 0.6)
                                    backdropFrame:SetBackdropBorderColor(0, 1, 0, 1)
                                else
                                    mountFrame.tex:SetVertexColor(0.4, 0.4, 0.4, 0.7)
                                    backdropFrame:SetBackdrop({
                                        bgFile = "Interface\\Buttons\\WHITE8x8",
                                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                        edgeSize = 2
                                    })
                                    backdropFrame:SetBackdropColor(0.3, 0.1, 0.1, 0.4)
                                    backdropFrame:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
                                end
                                
                                if MCLcore.Function and MCLcore.Function.LinkMountItem then
                                    MCLcore.Function:LinkMountItem(mountId, mountFrame, false, false)
                                end
                            end
                        end
                    end)
                    
                    if not success then
                        print("MCL Error creating mount frame for ID " .. tostring(mountId) .. ": " .. tostring(error))
                    end
                end
            end
            end -- Close the shouldProcess if block
            
            index = index + 1
            processed = processed + 1
            processedCount = processedCount + 1
        end
        
        -- Safety check for runaway processing
        if processedCount >= maxMounts then
            print("MCL Warning: Reached maximum mount processing limit (" .. maxMounts .. "), stopping to prevent performance issues")
            if callback then callback() end
            return
        end
        
        -- Continue with next batch if there are more mounts to process
        if index <= #mountList then
            C_Timer.After(batchDelay, processNextBatch)
        else
            -- All mounts processed, call completion callback
            if callback then callback() end
        end
    end
    
    processNextBatch()
end

-- Helper function to style navigation buttons for both themes
local function StyleNavButton(button, isExpansionIcon)
    if not button then return end
    
    if MCL_SETTINGS.useBlizzardTheme then
        -- Blizzard theme styling with authentic textures
        if isExpansionIcon then
            -- Expansion icons get a Blizzard-style button frame
            button:SetBackdrop({
                bgFile = "Interface\\Buttons\\UI-Panel-Button-Up", 
                edgeFile = "Interface\\Buttons\\UI-Panel-Button-Border", 
                edgeSize = 8,
                insets = {left = 2, right = 2, top = 2, bottom = 2}
            })
            button:SetBackdropColor(0.9, 0.9, 1, 0.4)  -- Light blue-white background
            button:SetBackdropBorderColor(0.7, 0.7, 0.9, 1)  -- Blue border
        else
            -- Regular navigation buttons get Blizzard panel styling
            button:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
                edgeSize = 16,
                insets = {left = 4, right = 4, top = 4, bottom = 4}
            })
            button:SetBackdropColor(0.05, 0.05, 0.2, 0.9)  -- Dark blue background
            button:SetBackdropBorderColor(0.6, 0.6, 0.8, 1)  -- Blue-gray border
        end
        
        -- Blizzard-style text color
        if button.text then
            button.text:SetTextColor(1, 0.82, 0, 1)  -- Gold text
        end
    else
        -- Default theme styling (current)
        button:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8})
        button:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
        button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        if button.text then
            button.text:SetTextColor(1, 1, 1, 1)  -- White text
        end
    end
end


local function ScrollFrame_OnMouseWheel(self, delta)
	local newValue = self:GetVerticalScroll() - (delta * 50);
	
	if (newValue < 0) then
		newValue = 0;
	elseif (newValue > self:GetVerticalScrollRange()) then
		newValue = self:GetVerticalScrollRange();
	end
	
	self:SetVerticalScroll(newValue);
end


function MCL_frames:openSettings()
	Settings.OpenToCategory(MCLcore.addon_name)
	local panel = SettingsPanel or InterfaceOptionsFrame or _G["SettingsPanel"]
	if not panel then return end

	-- Remove old checkboxes if they exist
	if MCLcore.hideCollectedIconCheckbox then
		MCLcore.hideCollectedIconCheckbox:Hide()
		MCLcore.hideCollectedIconCheckbox = nil
	end
	if MCLcore.useBlizzardThemeCheckbox then
		MCLcore.useBlizzardThemeCheckbox:Hide()
		MCLcore.useBlizzardThemeCheckbox = nil
	end

	-- Find the last checkbox in the Unobtainable Settings section to anchor below
	local lastCheckbox = nil
	if MCLcore.hideUnobtainableCheckbox then
		lastCheckbox = MCLcore.hideUnobtainableCheckbox
	elseif MCLcore.hideCollectedMountsCheckbox then
		lastCheckbox = MCLcore.hideCollectedMountsCheckbox
	elseif MCLcore.showMinimapIconCheckbox then
		lastCheckbox = MCLcore.showMinimapIconCheckbox
	end
end

function MCL_frames:CreateMainFrame()
    local frameTemplate = MCL_SETTINGS.useBlizzardTheme and "MCLBlizzardFrameTemplate" or "MCLFrameTemplateWithInset"
    MCL_mainFrame = CreateFrame("Frame", "MCLFrame", UIParent, frameTemplate);
    if MCL_SETTINGS.useBlizzardTheme then
        if MCL_mainFrame.NineSlice then MCL_mainFrame.NineSlice:Hide() end
        if MCL_mainFrame.MCLFrameTopLeft then MCL_mainFrame.MCLFrameTopLeft:Hide() end
        if MCL_mainFrame.MCLFrameTopRight then MCL_mainFrame.MCLFrameTopRight:Hide() end
        if MCL_mainFrame.MCLFrameBottomLeft then MCL_mainFrame.MCLFrameBottomLeft:Hide() end
        if MCL_mainFrame.MCLFrameBottomRight then MCL_mainFrame.MCLFrameBottomRight:Hide() end
        if MCL_mainFrame.MCLFrameTop then MCL_mainFrame.MCLFrameTop:Hide() end
        if MCL_mainFrame.MCLFrameBottom then MCL_mainFrame.MCLFrameBottom:Hide() end
        if MCL_mainFrame.MCLFrameLeft then MCL_mainFrame.MCLFrameLeft:Hide() end
        if MCL_mainFrame.MCLFrameRight then MCL_mainFrame.MCLFrameRight:Hide() end
    end
    if not MCL_SETTINGS.useBlizzardTheme then
        if MCL_mainFrame.Bg then
            MCL_mainFrame.Bg:SetVertexColor(0,0,0,MCL_SETTINGS.opacity)
        end
        if MCL_mainFrame.TitleBg then
            MCL_mainFrame.TitleBg:SetVertexColor(0.1,0.1,0.1,0.95)
        end
    end
    MCL_mainFrame:Show()
    
    -- Create the main frame title
    MCL_mainFrame.title = MCL_mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    
    -- Refresh button
    MCL_mainFrame.refresh = CreateFrame("Button", nil, MCL_mainFrame);
    MCL_mainFrame.refresh:SetSize(14, 14)
    if MCL_SETTINGS.useBlizzardTheme then
        MCL_mainFrame.refresh:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -40, -8)
    else
        MCL_mainFrame.refresh:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -30, 0)
    end
    MCL_mainFrame.refresh.tex = MCL_mainFrame.refresh:CreateTexture()
    MCL_mainFrame.refresh.tex:SetAllPoints(MCL_mainFrame.refresh)
    MCL_mainFrame.refresh.tex:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    MCL_mainFrame.refresh:SetScript("OnClick", function()
        if MCL_frames and MCL_frames.RefreshLayout then
            MCL_frames:RefreshLayout()
        end
    end)
    
    -- Add tooltip for refresh button
    MCL_mainFrame.refresh:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh Layout", 1, 1, 1)
        GameTooltip:AddLine("Refreshes the mount collection display", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    MCL_mainFrame.refresh:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- SA button
    MCL_mainFrame.sa = CreateFrame("Button", nil, MCL_mainFrame);
    MCL_mainFrame.sa:SetSize(60, 15)
    if MCL_SETTINGS.useBlizzardTheme then
        MCL_mainFrame.sa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -80, -8)
    else
        MCL_mainFrame.sa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -80, -1)
    end
    MCL_mainFrame.sa.tex = MCL_mainFrame.sa:CreateTexture()
    MCL_mainFrame.sa.tex:SetAllPoints(MCL_mainFrame.sa)
    MCL_mainFrame.sa.tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    MCL_mainFrame.sa.tex:SetVertexColor(0.1,0.1,0.1,0.95, MCL_SETTINGS.opacity)
    MCL_mainFrame.sa.text = MCL_mainFrame.sa:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    MCL_mainFrame.sa.text:SetPoint("CENTER", MCL_mainFrame.sa, "CENTER", 0, 0);
    MCL_mainFrame.sa.text:SetText("SA")
    MCL_mainFrame.sa.text:SetTextColor(0, 0.7, 0.85)	
    MCL_mainFrame.sa:SetScript("OnClick", function()
        if MCLcore.Function and MCLcore.Function.simplearmoryLink then
            MCLcore.Function:simplearmoryLink()
        end
    end)	
	
    -- DFA button
    MCL_mainFrame.dfa = CreateFrame("Button", nil, MCL_mainFrame);
    MCL_mainFrame.dfa:SetSize(60, 15)
    if MCL_SETTINGS.useBlizzardTheme then
        MCL_mainFrame.dfa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -125, -8)
    else
        MCL_mainFrame.dfa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -125, -1)
    end
    MCL_mainFrame.dfa.tex = MCL_mainFrame.dfa:CreateTexture()
    MCL_mainFrame.dfa.tex:SetAllPoints(MCL_mainFrame.dfa)
    MCL_mainFrame.dfa.tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    MCL_mainFrame.dfa.tex:SetVertexColor(0.1,0.1,0.1,0.95, MCL_SETTINGS.opacity)
    MCL_mainFrame.dfa.text = MCL_mainFrame.dfa:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    MCL_mainFrame.dfa.text:SetPoint("CENTER", MCL_mainFrame.dfa, "CENTER", 0, 0);
    MCL_mainFrame.dfa.text:SetText("DFA")
    MCL_mainFrame.dfa.text:SetTextColor(0, 0.7, 0.85)	
    MCL_mainFrame.dfa:SetScript("OnClick", function()
        if MCLcore.Function and MCLcore.Function.dfaLink then
            MCLcore.Function:dfaLink()
        end
    end)		


	--MCL Frame settings
	MCL_mainFrame:SetSize(main_frame_width, main_frame_height); -- width, height
	MCL_mainFrame:SetPoint("CENTER", UIParent, "CENTER"); -- point, relativeFrame, relativePoint, xOffset, yOffset
	MCL_mainFrame:SetHyperlinksEnabled(true)
	MCL_mainFrame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)
	
	-- Restore saved frame size if available
	MCL_frames:RestoreFrameSize()

	MCL_mainFrame:SetMovable(true)
	MCL_mainFrame:EnableMouse(true)
	MCL_mainFrame:RegisterForDrag("LeftButton")
	MCL_mainFrame:SetScript("OnDragStart", MCL_mainFrame.StartMoving)
	MCL_mainFrame:SetScript("OnDragStop", MCL_mainFrame.StopMovingOrSizing)
	
	-- Make frame resizable
	MCL_mainFrame:SetResizable(true)
	MCL_mainFrame:SetResizeBounds(900, 600, 1600, 1000)  -- min width, min height, max width, max height
	
	-- Create resize grip
	MCL_mainFrame.resizeGrip = CreateFrame("Button", nil, MCL_mainFrame)
	MCL_mainFrame.resizeGrip:SetSize(16, 16)
	MCL_mainFrame.resizeGrip:SetPoint("BOTTOMRIGHT", MCL_mainFrame, "BOTTOMRIGHT", -2, 2)
	MCL_mainFrame.resizeGrip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	MCL_mainFrame.resizeGrip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	MCL_mainFrame.resizeGrip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	MCL_mainFrame.resizeGrip:SetScript("OnMouseDown", function(self)
		MCL_mainFrame:StartSizing("BOTTOMRIGHT")
	end)
	MCL_mainFrame.resizeGrip:SetScript("OnMouseUp", function(self)
		MCL_mainFrame:StopMovingOrSizing()
		-- Save the new size and trigger layout update after resize
		MCL_frames:SaveFrameSize()
		MCL_frames:RefreshLayout()
	end)    

	-- Move title to top center
    if MCL_mainFrame.title then
        MCL_mainFrame.title:ClearAllPoints()
		-- if blizzard theme
		if MCL_SETTINGS.useBlizzardTheme then
			MCL_mainFrame.title:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 10, -8)  -- Moved down 10px from the very top
		else
			MCL_mainFrame.title:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 10, -2)  -- Moved down 5px from the very top
		end
        MCL_mainFrame.title:SetText(L["Mount Collection Log"])

        MCL_mainFrame.title:SetTextColor(0.3, 0.7, 0.9, 1)  -- White text for better visibility
    end
    
    -- Scroll Frame for Main Window
	MCL_mainFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, MCL_mainFrame, "MinimalScrollFrameTemplate");
	-- Anchor scroll frame to the main frame, not Bg
    MCL_mainFrame.ScrollFrame:ClearAllPoints()
    MCL_mainFrame.ScrollFrame:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 10, -40)
    MCL_mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", MCL_mainFrame, "BOTTOMRIGHT", -10, 10)
	MCL_mainFrame.ScrollFrame:SetClipsChildren(true);
	MCL_mainFrame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	MCL_mainFrame.ScrollFrame:EnableMouse(true)
    
	MCL_mainFrame.ScrollFrame.ScrollBar:ClearAllPoints();
	MCL_mainFrame.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", MCL_mainFrame.ScrollFrame, "TOPRIGHT", -8, -19);
	MCL_mainFrame.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", MCL_mainFrame.ScrollFrame, "BOTTOMRIGHT", -8, 17);

    -- Create and assign a dedicated scroll child frame
    if not MCL_mainFrame.ScrollChild then
        MCL_mainFrame.ScrollChild = CreateFrame("Frame", nil, MCL_mainFrame.ScrollFrame)
        MCL_mainFrame.ScrollChild:SetSize(main_frame_width, main_frame_height)
        MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
    end

	MCL_mainFrame:SetFrameStrata("HIGH")
    if not MCL_SETTINGS.useBlizzardTheme then
        if MCLcore.Function and MCLcore.Function.CreateFullBorder then
            MCLcore.Function:CreateFullBorder(MCL_mainFrame)
        end
    end

    tinsert(UISpecialFrames, "MCLFrame")
    
    -- Add OnShow handler to show navigation when main frame is shown
    MCL_mainFrame:SetScript("OnShow", function()
        if MCLcore.MCL_MF_Nav then
            MCLcore.MCL_MF_Nav:Show()
        end
    end)
    
    -- Add OnHide handler to hide navigation when main frame is closed
    MCL_mainFrame:SetScript("OnHide", function()
        if MCLcore.MCL_MF_Nav then
            MCLcore.MCL_MF_Nav:Hide()
        end
    end)
    
    return MCL_mainFrame
end


local function Tab_OnClick(self)
	-- Check if we need to refresh layout when switching away from pinned section
	if MCLcore.Function and MCLcore.Function.CheckAndRefreshAfterPinnedChanges then
		local newSectionName = self.section and self.section.name or "Unknown"
		MCLcore.Function:CheckAndRefreshAfterPinnedChanges(newSectionName)
	end
	
	PanelTemplates_SetTab(self:GetParent(), self:GetID());

	local scrollChild = MCL_mainFrame.ScrollFrame:GetScrollChild();
	if(scrollChild) then
		scrollChild:Hide();
	end

	MCL_mainFrame.ScrollFrame:SetScrollChild(self.content);
	self.content:Show();
	MCL_mainFrame.ScrollFrame:SetVerticalScroll(0);
end


-- Build a nav-ordered list of sections for consistent tab/content mapping
function MCLcore:BuildSectionsOrdered()
    local pinned, overview, expansions, others = nil, nil, {}, {}
    local playerFaction = UnitFactionGroup("player")
    for i = 1, #MCLcore.sectionNames do
        local v = MCLcore.sectionNames[i]
        if v.name == "Pinned" then
            pinned = v
        elseif v.name == "Horde" and playerFaction == "Alliance" then
            -- skip Horde for Alliance players
        elseif v.name == "Alliance" and playerFaction == "Horde" then
            -- skip Alliance for Horde players
        elseif v.name == "Overview" then
            overview = v
        elseif v.isExpansion then
            table.insert(expansions, v)
        else
            table.insert(others, v)
        end
    end
    local ordered = {}
    if overview then table.insert(ordered, overview) end
    for _, v in ipairs(expansions) do table.insert(ordered, v) end
    for _, v in ipairs(others) do table.insert(ordered, v) end
    if pinned then table.insert(ordered, pinned) end
    MCLcore.sectionsOrdered = ordered
end

function MCL_frames:SetTabs()
    -- Always update stats before building tabs/UI
    if MCLcore.Function and MCLcore.Function.UpdateCollection then
        MCLcore.Function:UpdateCollection()
    end
    if MCLcore.BuildSectionsOrdered then
        MCLcore:BuildSectionsOrdered()
    end
    if MCLcore.Function and MCLcore.Function.CalculateSectionStats then
        MCLcore.Function:CalculateSectionStats()
    end
    
    -- Refresh overview stats after calculation
    if MCLcore.overviewFrames then
        for _, overviewFrame in ipairs(MCLcore.overviewFrames) do
            local sectionName = overviewFrame.name
            local pBar = overviewFrame.frame
            local sectionStats = MCLcore.stats and MCLcore.stats[sectionName]
            
            if sectionStats and sectionStats.collected and sectionStats.total then
                UpdateProgressBar(pBar, sectionStats.total, sectionStats.collected)
            end
        end
    end

    local tabFrame
    if MCL_SETTINGS.useBlizzardTheme then
        -- Blizzard theme should ALSO use the separate navigation frame
        tabFrame = MCLcore.MCL_MF_Nav
    else
        tabFrame = MCLcore.MCL_MF_Nav
    end

    -- Store reference for overview navigation
    if not tabFrame.tabs then
        tabFrame.tabs = {}
    end

    local sections = MCLcore.sectionsOrdered or MCLcore.sections
    -- Find Overview, Pinned, expansions, and others
    local overviewSection, pinnedSection, expansionSections, otherSections = nil, nil, {}, {}
    for _, v in ipairs(sections) do
        if v.name == "Overview" then
            overviewSection = v
        elseif v.name == "Pinned" then
            pinnedSection = v
        elseif v.isExpansion then
            table.insert(expansionSections, v)
        else
            table.insert(otherSections, v)
        end
    end

    if tabFrame.tabs then
        for _, tab in ipairs(tabFrame.tabs) do
            tab:Hide()
            if tab.content then tab.content:Hide() end
        end
    end
    tabFrame.tabs = {}
    MCLcore.sectionFrames = {}

    local navYOffset = -55  -- Adjusted to account for search bar
    local tabIndex = 1
    local selectedTab = nil

    local function HideAllTabContents()
        -- Hide all tab content frames
        for _, t in ipairs(tabFrame.tabs) do
            if t.content then 
                t.content:Hide() 
            end
        end
        
        -- Hide all section frames that might be stored globally
        if MCLcore.sectionFrames then
            for _, contentFrame in ipairs(MCLcore.sectionFrames) do
                if contentFrame and contentFrame.Hide then
                    contentFrame:Hide()
                end
            end
        end
        
        -- Hide overview frame specifically
        if MCLcore.overview then
            MCLcore.overview:Hide()
        end
        
        -- Also properly destroy search results content if it exists
        if MCLcore.Search and MCLcore.Search.DestroySearchResultsFrame then
            MCLcore.Search:DestroySearchResultsFrame()
        end
    end
    
    -- Expose HideAllTabContents globally for access from other files
    MCLcore.HideAllTabContents = HideAllTabContents
    local function DeselectAllTabs()
        for _, t in ipairs(tabFrame.tabs) do
            t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end
    local function SelectTab(tab)
        -- Check if we need to refresh layout when switching away from pinned section
        if MCLcore.Function and MCLcore.Function.CheckAndRefreshAfterPinnedChanges then
            local newSectionName = tab.section and tab.section.name or "Unknown"
            MCLcore.Function:CheckAndRefreshAfterPinnedChanges(newSectionName)
        end
        
        DeselectAllTabs()
        HideAllTabContents()
        
        -- Clear any active search when switching tabs manually
        if MCLcore.Search and MCLcore.Search.isSearchActive then
            -- Clear search state without restoring previous tab
            MCLcore.Search.currentSearchTerm = ""
            MCLcore.Search.isSearchActive = false
            MCLcore.Search.searchResults = {}
            
            -- Clear any highlighting
            if MCLcore.Search.ClearHighlighting then
                MCLcore.Search:ClearHighlighting()
            end
            
            -- Properly destroy search results content frame
            if MCLcore.Search.DestroySearchResultsFrame then
                MCLcore.Search:DestroySearchResultsFrame()
            end
            
            -- Clear search box text
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
            
            -- Clear the previously selected tab reference
            MCLcore.Search.previouslySelectedTab = nil
        end
        
        tab:SetBackdropBorderColor(1, 0.82, 0, 1)
        
        -- Always ensure the main scroll child is the scroll child
        if MCL_mainFrame.ScrollChild then
            MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
        end
        
        -- Show only the selected tab's content
        if tab.content then
            tab.content:Show()
        end
        
        MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
        -- Store the currently selected tab globally for search functionality
        MCLcore.currentlySelectedTab = tab
    end

    -- 1. Overview tab (always first)
    if overviewSection then
        local tab = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        tab:SetSize(nav_width + 8, 32)  -- Use nav width for sidebar tabs
        tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 1, navYOffset)
        StyleNavButton(tab, false)  -- Use our styling function
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tab.text:SetPoint("LEFT", 10, 0)
        tab.text:SetText(L[overviewSection.name] or overviewSection.name)
        tab.section = overviewSection
        tab.content = MCLcore.overview
        if tab.content then tab.content:Hide() end
        tab:SetScript("OnClick", function(self)
            SelectTab(self)
        end)
        tab:EnableMouse(true)
        tab:SetFrameStrata("HIGH")
        tab:SetFrameLevel(100)
        tab:Show()
        table.insert(tabFrame.tabs, tab)
        -- Also store in navigation frame for overview navigation
        if MCLcore.MCL_MF_Nav and not MCLcore.MCL_MF_Nav.tabs then
            MCLcore.MCL_MF_Nav.tabs = {}
        end
        if MCLcore.MCL_MF_Nav then
            table.insert(MCLcore.MCL_MF_Nav.tabs, tab)
        end
        table.insert(MCLcore.sectionFrames, tab.content)
        tabIndex = tabIndex + 1
        navYOffset = navYOffset - 36
        selectedTab = tab
        -- Store globally for search functionality
        MCLcore.currentlySelectedTab = tab
    end
    -- 2. Expansion grid (icon-only, 3 per row)
    local gridCols, iconSize, iconPad = 3, 36, 8
    local gridStartY = navYOffset
    
    -- Calculate centering for expansion icons within the nav sidebar
    local totalGridWidth = gridCols * iconSize + (gridCols - 1) * iconPad
    local navFrameWidth = nav_width + 10  -- Use the nav frame width
    local gridStartX = (navFrameWidth - totalGridWidth) / 2  -- Center within nav frame
    
    for i, v in ipairs(expansionSections) do
        local col = ((i-1) % gridCols)
        local row = math.floor((i-1) / gridCols)
        local btn = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        btn:SetSize(iconSize, iconSize)
        btn:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", gridStartX + col * (iconSize + iconPad), gridStartY - row * (iconSize + iconPad))
        StyleNavButton(btn, true)  -- Use our styling function for expansion icons
        btn.icon = btn:CreateTexture(nil, "ARTWORK")
        btn.icon:SetAllPoints(btn)
        btn.icon:SetTexture(v.icon)
        btn.section = v
        btn.content = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, v.name)
        -- Populate expansion tab content
        if v.mounts then
            if v.mounts.categories then
                MCLcore.Frames:createCategoryFrame(v.mounts.categories, btn.content, v.name)
            else
                -- For some sections, mounts might be directly in v.mounts
                MCLcore.Frames:createCategoryFrame(v.mounts, btn.content, v.name)
            end
        end
        btn.content:Hide()
        btn:SetScript("OnClick", function(self)
            SelectTab(self)
        end)
        btn:EnableMouse(true)
        btn:SetFrameStrata("HIGH")
        btn:SetFrameLevel(100)
        btn:Show()
        table.insert(tabFrame.tabs, btn)
        -- Also store in navigation frame for overview navigation
        if MCLcore.MCL_MF_Nav then
            table.insert(MCLcore.MCL_MF_Nav.tabs, btn)
        end
        table.insert(MCLcore.sectionFrames, btn.content)
        tabIndex = tabIndex + 1
    end
    navYOffset = gridStartY - math.ceil(#expansionSections / gridCols) * (iconSize + iconPad) - 10
    -- 3. Remaining full-width tabs
    for _, v in ipairs(otherSections) do
        local tab = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        tab:SetSize(nav_width + 8, 32)  -- Use nav width for sidebar tabs
        tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 1, navYOffset)
        StyleNavButton(tab, false)  -- Use our styling function
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tab.text:SetPoint("LEFT", 10, 0)
        tab.text:SetText(L[v.name] or v.name)
        tab.section = v
        tab.content = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, v.name)
        -- Populate other tab content if available
        if v.mounts then
            if v.mounts.categories then
                MCLcore.Frames:createCategoryFrame(v.mounts.categories, tab.content, v.name)
            else
                MCLcore.Frames:createCategoryFrame(v.mounts, tab.content, v.name)
            end
        end
        tab.content:Hide()
        tab:SetScript("OnClick", function(self)
            SelectTab(self)
        end)
        tab:EnableMouse(true)
        tab:SetFrameStrata("HIGH")
        tab:SetFrameLevel(100)
        tab:Show()
        table.insert(tabFrame.tabs, tab)
        -- Also store in navigation frame for overview navigation (other sections)
        if MCLcore.MCL_MF_Nav then
            table.insert(MCLcore.MCL_MF_Nav.tabs, tab)
        end
        table.insert(MCLcore.sectionFrames, tab.content)
        tabIndex = tabIndex + 1
        navYOffset = navYOffset - 28
    end
    -- 4. Pinned tab (always last)
    if pinnedSection then
        local tab = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        tab:SetSize(nav_width + 8, 32)  -- Use nav width for sidebar tabs
        tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 1, navYOffset)
        StyleNavButton(tab, false)  -- Use our styling function
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tab.text:SetPoint("LEFT", 10, 0)
        tab.text:SetText(L[pinnedSection.name] or pinnedSection.name)
        tab.section = pinnedSection
        tab.content = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, pinnedSection.name)
                
        -- Set global reference for pinned content frame (used by functions.lua)
        _G["PinnedFrame"] = tab.content
        _G["PinnedTab"] = tab
        
        -- Populate pinned tab content after creating the frame
        -- Initialize MCL_PINNED if it doesn't exist
        if not MCL_PINNED then
            MCL_PINNED = {}
        end
        
        -- Clean up any invalid pinned mounts before creating the content
        if MCLcore.Function and MCLcore.Function.CleanupInvalidPinnedMounts then
            MCLcore.Function:CleanupInvalidPinnedMounts()
        end
        
        if MCL_PINNED and next(MCL_PINNED) then
            -- Clear any existing mount frames for pinned section
            if MCLcore.mountFrames[1] then
                MCLcore.mountFrames[1] = {}
            end
            -- Create the pinned section content
            if MCLcore.Function and MCLcore.Function.CreateMountsForCategory then
                local overflow, mountFrame = MCLcore.Function:CreateMountsForCategory(MCL_PINNED, _G["PinnedFrame"], 30, _G["PinnedTab"], true, true)
                MCLcore.mountFrames[1] = mountFrame
            end
        end
        
        tab.content:Hide()
        tab:SetScript("OnClick", function(self)
            SelectTab(self)
        end)
        tab:EnableMouse(true)
        tab:SetFrameStrata("HIGH")
        tab:SetFrameLevel(100)
        tab:Show()
        table.insert(tabFrame.tabs, tab)
        -- Also store in navigation frame for overview navigation (pinned)
        if MCLcore.MCL_MF_Nav then
            table.insert(MCLcore.MCL_MF_Nav.tabs, tab)
        end
        table.insert(MCLcore.sectionFrames, tab.content)
        tabIndex = tabIndex + 1
        navYOffset = navYOffset - 28
    end
    
    -- 5. Settings tab (always last)
    do
        local tab = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        tab:SetSize(nav_width + 8, 32)  -- Use nav width for sidebar tabs
        tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 1, navYOffset)
        StyleNavButton(tab, false)  -- Use our styling function
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tab.text:SetPoint("LEFT", 10, 0)
        tab.text:SetText(L["Settings"] or "Settings")
        tab.section = {name = "Settings"}  -- Create a fake section for consistency
        tab.content = MCLcore.Frames:createSettingsFrame(MCL_mainFrame.ScrollChild)
        tab.content:Hide()
        tab:SetScript("OnClick", function(self)
            SelectTab(self)
        end)
        tab:EnableMouse(true)
        tab:SetFrameStrata("HIGH")
        tab:SetFrameLevel(100)
        tab:Show()
        table.insert(tabFrame.tabs, tab)
        -- Also store in navigation frame for settings navigation
        if MCLcore.MCL_MF_Nav then
            table.insert(MCLcore.MCL_MF_Nav.tabs, tab)
        end
        table.insert(MCLcore.sectionFrames, tab.content)
        tabIndex = tabIndex + 1
        navYOffset = navYOffset - 28
    end
    
    -- Select Overview by default
    if selectedTab then
        SelectTab(selectedTab)
    elseif tabFrame.tabs[1] then
        SelectTab(tabFrame.tabs[1])
    end
    return MCLcore.sectionFrames, #tabFrame.tabs
end


function MCL_frames:createNavFrame(relativeFrame, title)
    -- Nav frame is parented to the main frame so it opens/closes together
    -- Don't use insetFrameTemplate for default theme as it has its own styling that conflicts
    local frameTemplate = MCL_SETTINGS.useBlizzardTheme and "MCLBlizzardNavTemplate" or "BackdropTemplate"
    local frame = CreateFrame("Frame", "Nav", relativeFrame, frameTemplate);
    frame:SetWidth(nav_width + 10)  -- Keep original nav width as sidebar
    
    -- Set height to match current main frame height
    local _, currentHeight = MCL_frames:GetCurrentFrameDimensions()
    frame:SetHeight(currentHeight+1)
    
    frame:ClearAllPoints()
    
    -- Consistent positioning for both themes - account for any frame insets
    local xOffset = -1
    local yOffset = 2


    if MCL_SETTINGS.useBlizzardTheme then
        -- Blizzard theme has a different inset, adjust accordingly
        xOffset = 3  -- Adjusted for Blizzard theme
        yOffset = -5
        frame:SetHeight(currentHeight-9)
    end

    
    -- Get the actual frame dimensions and adjust for any template differences
    if MCL_SETTINGS.useBlizzardTheme then
        -- UIPanelDialogTemplate frames have different insets, get actual boundaries
        local left, bottom, width, height = relativeFrame:GetRect()
        if left then
            -- Position relative to the actual frame boundaries
            frame:SetPoint("TOPRIGHT", relativeFrame, "TOPLEFT", xOffset, yOffset)
        else
            -- Fallback positioning
            frame:SetPoint("TOPRIGHT", relativeFrame, "TOPLEFT", xOffset, yOffset)
        end
    else
        -- Default theme - standard positioning
        frame:SetPoint("TOPRIGHT", relativeFrame, "TOPLEFT", xOffset, yOffset)
    end
    
    -- Apply styling after frame creation to ensure it sticks
    if MCL_SETTINGS.useBlizzardTheme then
        -- Blizzard-style backdrop with proper textures
        if frame.SetBackdrop then
            frame:SetBackdrop({
                bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", 
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
                edgeSize = 16,
                insets = {left = 4, right = 4, top = 4, bottom = 4}
            })
            frame:SetBackdropColor(0.05, 0.05, 0.15, 0.95)  -- Dark blue tint with higher opacity
            frame:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)  -- Blue-gray border
        end
    else
        -- Default theme - dark background with proper opacity
        if frame.SetBackdrop then
            frame:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 8})
            frame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)  -- Increased opacity to ensure visibility
            frame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        end
    end
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -8)
    frame.title:SetText(title or "")
    
    -- Style the title text for Blizzard theme
    if MCL_SETTINGS.useBlizzardTheme then
        frame.title:SetTextColor(1, 0.82, 0, 1)  -- Gold color like Blizzard UI
    else
        frame.title:SetTextColor(1, 1, 1, 1)  -- White for default theme
    end
    
    -- Create search bar
    frame.searchContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.searchContainer:SetSize(nav_width - 10, 25)
    frame.searchContainer:SetPoint("TOP", frame.title, "BOTTOM", 0, -5)
    frame.searchContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 2
    })
    frame.searchContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame.searchContainer:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Create search editbox
    frame.searchBox = CreateFrame("EditBox", nil, frame.searchContainer)
    frame.searchBox:SetSize(nav_width - 20, 20)
    frame.searchBox:SetPoint("CENTER", frame.searchContainer, "CENTER", 0, 0)
    frame.searchBox:SetFontObject("GameFontHighlightSmall")
    frame.searchBox:SetTextColor(1, 1, 1, 1)
    frame.searchBox:SetAutoFocus(false)
    frame.searchBox:SetMaxLetters(50)
    frame.searchBox:EnableMouse(true)
    frame.searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        MCLcore.Search:PerformSearch(self:GetText())
    end)
    frame.searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        MCLcore.Search:ClearSearchAndGoToOverview()
    end)
    frame.searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local text = self:GetText()
            if text == "" then
                MCLcore.Search:ClearSearchAndGoToOverview()
            end
        end
    end)
    
    -- Create search placeholder text
    frame.searchPlaceholder = frame.searchContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.searchPlaceholder:SetPoint("LEFT", frame.searchBox, "LEFT", 5, 0)
    frame.searchPlaceholder:SetText(L["Search mounts..."])
    frame.searchPlaceholder:SetTextColor(0.6, 0.6, 0.6, 1)
    
    -- Show/hide placeholder based on editbox focus and content
    frame.searchBox:SetScript("OnEditFocusGained", function(self)
        frame.searchPlaceholder:Hide()
    end)
    frame.searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            frame.searchPlaceholder:Show()
        end
    end)
    
    -- Create clear search button
    frame.clearButton = CreateFrame("Button", nil, frame.searchContainer)
    frame.clearButton:SetSize(16, 16)
    frame.clearButton:SetPoint("RIGHT", frame.searchContainer, "RIGHT", -3, 0)
    frame.clearButton:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    frame.clearButton:SetScript("OnClick", function()
        frame.searchBox:SetText("")
        frame.searchBox:ClearFocus()
        MCLcore.Search:ClearSearchAndGoToOverview()
        frame.searchPlaceholder:Show()
    end)
    frame.clearButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(L["Clear Search"], 1, 1, 1)
        GameTooltip:Show()
    end)
    frame.clearButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Ensure the frame is visible and at the correct strata
    frame:SetFrameStrata("HIGH")
    frame:Show()
    
    return frame;
end

-- IMPORTANT: Ensure SetTabs is called before any code that uses MCLcore.overview

function MCL_frames:progressBar(relativeFrame, top)
    MyStatusBar = CreateFrame("StatusBar", nil, relativeFrame, "BackdropTemplate")
    
    -- Safe texture handling with fallback
    local textureToUse = "Interface\\TargetingFrame\\UI-StatusBar"  -- Good default that colors well
    if MCLcore.media and MCL_SETTINGS and MCL_SETTINGS.statusBarTexture then
        local settingsTexture = MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture)
        if settingsTexture then
            textureToUse = settingsTexture
        end
    end
    
    MyStatusBar:SetStatusBarTexture(textureToUse)
    MyStatusBar:GetStatusBarTexture():SetHorizTile(false)
    MyStatusBar:SetMinMaxValues(0, 100)
    MyStatusBar:SetValue(0)
    MyStatusBar:SetWidth(150)
    MyStatusBar:SetHeight(15)
    if top then
        MyStatusBar:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", 0, 10)
    else
        MyStatusBar:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", 0, 10)
    end

    MyStatusBar:SetStatusBarColor(0.1, 0.9, 0.1)

    MyStatusBar.bg = MyStatusBar:CreateTexture(nil, "BACKGROUND")
    MyStatusBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-Status-Bar")
    MyStatusBar.bg:SetAllPoints(true)
    MyStatusBar.bg:SetVertexColor(0.843, 0.874, 0.898, 0.5)
    MyStatusBar.Text = MyStatusBar:CreateFontString()
    MyStatusBar.Text:SetFontObject(GameFontWhite)
    MyStatusBar.Text:SetPoint("CENTER")
    MyStatusBar.Text:SetJustifyH("CENTER")
    MyStatusBar.Text:SetText()

    table.insert(MCLcore.statusBarFrames, MyStatusBar)

    return MyStatusBar
end

function MCL_frames:createContentFrame(relativeFrame, title)
    -- Calculate dynamic width based on current main frame width
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 60  -- 60px for padding
    
    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)  -- Use current available width
    frame:SetHeight(50)  -- Increased height to accommodate title padding
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 30, 0)  -- Remove nav_width since nav is outside
    
    -- Set opaque background for search results to prevent bleed-through
    if title == "Search Results" then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0.05, 0.05, 0.05, 1)  -- Opaque dark background
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    else
        frame:SetBackdropColor(0, 0, 0, 0)  -- Transparent background for other content
    end
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)  -- Added padding: 15px from left and top
    frame.title:SetText(L[title]) -- Localized for display
    frame.name = title -- Store non-localized name

    -- Add pin instructions for all sections except Overview
    if title == "Pinned" then
        local instructionsFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        instructionsFrame:SetSize(availableWidth - 30, 20)  -- Smaller height for compact display
        instructionsFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)  -- Position below title
        instructionsFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 2
        })
        instructionsFrame:SetBackdropColor(0.1, 0.1, 0.2, 0.6)  -- Subtle background
        instructionsFrame:SetBackdropBorderColor(0.4, 0.4, 0.6, 0.8)  -- Subtle border
        
        -- Create the instruction text with color formatting
        local instructionsText = instructionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        instructionsText:SetPoint("LEFT", instructionsFrame, "LEFT", 10, 0)
        -- Use color codes to make "Ctrl + Right Click" bold and orange
        instructionsText:SetText(L["Pin Instructions Text"] or "|cffFF8800|TInterface\\GossipFrame\\AvailableQuestIcon:0:0:0:0:32:32:0:32:0:32|t Ctrl + Right Click|r to pin/unpin mounts")
        instructionsText:SetTextColor(0.9, 0.9, 1, 1)  -- Light blue-white for the rest of the text
        
        -- Adjust frame height to accommodate instructions
        frame:SetHeight(85)  -- Increased to make room for instructions
    end

    if title ~= "Pinned" then
        frame.pBar = MCLcore.Frames:progressBar(frame)
        local yOffset = title == "Overview" and -15 or -55  -- Adjust based on whether instructions are present
        frame.pBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, yOffset)  -- Aligned with title padding
        frame.pBar:SetWidth(availableWidth - 30)  -- Account for padding on both sides
        frame.pBar:SetHeight(20)
    end

    return frame
end

function MCL_frames:createSettingsFrame(relativeFrame)
    -- Calculate dynamic width based on current main frame width
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 60  -- 60px for padding
    
    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)
    frame:SetHeight(750)  -- Increased height for better spacing
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 30, 0)
    
    -- Set background for settings
    frame:SetBackdropColor(0, 0, 0, 0)  -- Transparent background
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)
    frame.title:SetText(L["Settings"] or "Settings")
    frame.name = "Settings"
    
    -- Create two-column layout
    local leftColumn = CreateFrame("Frame", nil, frame)
    leftColumn:SetSize(math.floor(availableWidth / 2) - 20, 700)
    leftColumn:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -50)
    
    local rightColumn = CreateFrame("Frame", nil, frame)
    rightColumn:SetSize(math.floor(availableWidth / 2) - 20, 700)
    rightColumn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -50)
    
    local leftYOffset = 0
    local rightYOffset = 0
    local sectionSpacing = 45  -- Increased spacing between sections
    
    -- Custom styling function for checkboxes
    local function styleCheckbox(checkbox)
        -- Remove default template visuals
        checkbox:SetNormalTexture("")
        checkbox:SetPushedTexture("")
        checkbox:SetHighlightTexture("")
        checkbox:SetCheckedTexture("")
        
        -- Create custom background
        local bg = checkbox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        bg:SetSize(20, 20)
        
        -- Create custom border
        local border = checkbox:CreateTexture(nil, "BORDER")
        border:SetAllPoints()
        border:SetColorTexture(0.4, 0.4, 0.4, 1)
        border:SetSize(22, 22)
        
        checkbox.customBg = bg
        checkbox.customBorder = border
        
        -- Update visuals based on state
        local function updateVisuals()
            if checkbox:GetChecked() then
                bg:SetColorTexture(0.2, 0.6, 1, 0.9)  -- Solid blue when checked
                border:SetColorTexture(0.4, 0.8, 1, 1)
            else
                bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
                border:SetColorTexture(0.4, 0.4, 0.4, 1)
            end
        end
        
        checkbox:SetScript("OnClick", function(self)
            updateVisuals()
            if self.originalOnClick then
                self.originalOnClick(self)
            end
        end)
        
        -- Hover effects
        checkbox:SetScript("OnEnter", function(self)
            if self:GetChecked() then
                border:SetColorTexture(0.5, 0.9, 1, 1)
                bg:SetColorTexture(0.3, 0.7, 1, 0.95)
            else
                border:SetColorTexture(0.6, 0.6, 0.6, 1)
            end
        end)
        
        checkbox:SetScript("OnLeave", function(self)
            if self:GetChecked() then
                border:SetColorTexture(0.4, 0.8, 1, 1)
                bg:SetColorTexture(0.2, 0.6, 1, 0.9)
            else
                border:SetColorTexture(0.4, 0.4, 0.4, 1)
            end
        end)
        
        updateVisuals()
        return updateVisuals
    end
    
    -- Custom styling function for sliders
    local function styleSlider(slider, showInputBox, isPercentage)
        -- Style the thumb with horizontal texture
        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
            thumb:SetSize(16, 16)
        else
            -- Create a custom thumb if none exists
            thumb = slider:CreateTexture(nil, "OVERLAY")
            thumb:SetTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal")
            thumb:SetSize(16, 16)
            slider:SetThumbTexture(thumb)
        end
        
        -- Enable mouse interaction
        slider:EnableMouse(true)
        slider:EnableMouseWheel(true)
        
        -- Create custom track background
        local trackBg = slider:CreateTexture(nil, "BACKGROUND")
        trackBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
        trackBg:SetHeight(4)
        trackBg:SetPoint("LEFT", slider, "LEFT", 10, 0)
        trackBg:SetPoint("RIGHT", slider, "RIGHT", -10, 0)
        
        -- Create progress indicator
        local progress = slider:CreateTexture(nil, "ARTWORK")
        progress:SetColorTexture(0.2, 0.6, 0.8, 1)
        progress:SetHeight(4)
        progress:SetPoint("LEFT", trackBg, "LEFT")
        
        local function updateProgress()
            local value = slider:GetValue()
            local min, max = slider:GetMinMaxValues()
            if max > min then
                local percent = (value - min) / (max - min)
                progress:SetWidth(trackBg:GetWidth() * percent)
            end
        end
        
        -- Create input box if requested
        if showInputBox then
            local inputBox = CreateFrame("EditBox", nil, slider:GetParent(), "BackdropTemplate")
            inputBox:SetSize(50, 20)
            inputBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
            
            -- Input box styling
            inputBox:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                tile = true, tileSize = 8, edgeSize = 8,
                insets = { left = 2, right = 2, top = 2, bottom = 2 }
            })
            inputBox:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
            inputBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            inputBox:SetFontObject(GameFontHighlightSmall)
            inputBox:SetTextColor(1, 1, 1, 1)
            inputBox:SetAutoFocus(false)
            inputBox:SetNumeric(true)
            
            local function getDisplayValue(sliderValue)
                if isPercentage then
                    return tostring(math.floor(sliderValue * 100))
                else
                    return tostring(math.floor(sliderValue))
                end
            end
            
            local function getSliderValue(displayValue)
                local value = tonumber(displayValue)
                if not value then return nil end
                
                if isPercentage then
                    return value / 100
                else
                    return value
                end
            end
            
            inputBox:SetText(getDisplayValue(slider:GetValue()))
            
            -- Input box scripts
            inputBox:SetScript("OnEnterPressed", function(self)
                local sliderValue = getSliderValue(self:GetText())
                if sliderValue then
                    local min, max = slider:GetMinMaxValues()
                    sliderValue = math.max(min, math.min(max, sliderValue))
                    slider:SetValue(sliderValue)
                    self:SetText(getDisplayValue(sliderValue))
                end
                self:ClearFocus()
            end)
            
            inputBox:SetScript("OnEscapePressed", function(self)
                self:SetText(getDisplayValue(slider:GetValue()))
                self:ClearFocus()
            end)
            
            inputBox:SetScript("OnEditFocusLost", function(self)
                self:SetText(getDisplayValue(slider:GetValue()))
            end)
            
            slider.inputBox = inputBox
            slider.getDisplayValue = getDisplayValue
        end
        
        slider:SetScript("OnValueChanged", function(self, value)
            updateProgress()
            if self.inputBox and self.getDisplayValue then
                self.inputBox:SetText(self.getDisplayValue(value))
            end
            if self.originalOnValueChanged then
                self.originalOnValueChanged(self, value)
            end
        end)
        
        -- Mouse wheel support for horizontal scrolling
        slider:SetScript("OnMouseWheel", function(self, delta)
            local step = self:GetValueStep()
            local value = self:GetValue()
            local min, max = self:GetMinMaxValues()
            local newValue = value + (delta * step)
            self:SetValue(math.max(min, math.min(max, newValue)))
        end)
        
        updateProgress()
    end
    
    -- LEFT COLUMN: Theme Selection Section
    local themeTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    themeTitle:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, leftYOffset)
    themeTitle:SetText(L["Theme"] or "Theme:")
    themeTitle:SetTextColor(0.2, 0.8, 1, 1)  -- MCL blue color
    themeTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    leftYOffset = leftYOffset - 30
    
    -- Blizzard Theme Checkbox
    local blizzardThemeCheck = CreateFrame("CheckButton", nil, leftColumn)
    blizzardThemeCheck:SetSize(20, 20)
    blizzardThemeCheck:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    blizzardThemeCheck:SetChecked(MCL_SETTINGS.useBlizzardTheme or false)
    
    local blizzardThemeText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    blizzardThemeText:SetPoint("LEFT", blizzardThemeCheck, "RIGHT", 8, 0)
    blizzardThemeText:SetText(L["Use Blizzard Theme"] or "Use Blizzard Theme")
    
    blizzardThemeCheck.originalOnClick = function(self)
        MCL_SETTINGS.useBlizzardTheme = self:GetChecked()
        StaticPopup_Show("MCL_RELOAD_WARNING")
    end
    
    styleCheckbox(blizzardThemeCheck)
    leftYOffset = leftYOffset - sectionSpacing
    
    -- Display Options Section (Left Column)
    local displayTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    displayTitle:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, leftYOffset)
    displayTitle:SetText(L["Display Options"] or "Display Options:")
    displayTitle:SetTextColor(0.2, 0.8, 1, 1)
    displayTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    leftYOffset = leftYOffset - 30
    
    -- Hide Collected Mounts Checkbox
    local hideCollectedCheck = CreateFrame("CheckButton", nil, leftColumn)
    hideCollectedCheck:SetSize(20, 20)
    hideCollectedCheck:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    hideCollectedCheck:SetChecked(MCL_SETTINGS.hideCollectedMounts or false)
    
    local hideCollectedText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hideCollectedText:SetPoint("LEFT", hideCollectedCheck, "RIGHT", 8, 0)
    hideCollectedText:SetText(L["Hide Collected Mounts"] or "Hide Collected Mounts")
    
    hideCollectedCheck.originalOnClick = function(self)
        MCL_SETTINGS.hideCollectedMounts = self:GetChecked()
    end
    
    styleCheckbox(hideCollectedCheck)
    leftYOffset = leftYOffset - 35
    
    -- Show Unobtainable Mounts Checkbox
    local showUnobtainableCheck = CreateFrame("CheckButton", nil, leftColumn)
    showUnobtainableCheck:SetSize(20, 20)
    showUnobtainableCheck:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    showUnobtainableCheck:SetChecked(not MCL_SETTINGS.unobtainable)
    
    local showUnobtainableText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    showUnobtainableText:SetPoint("LEFT", showUnobtainableCheck, "RIGHT", 8, 0)
    showUnobtainableText:SetText(L["Show Unobtainable Mounts"] or "Show Unobtainable Mounts")
    
    showUnobtainableCheck.originalOnClick = function(self)
        MCL_SETTINGS.unobtainable = not self:GetChecked()
    end
    
    styleCheckbox(showUnobtainableCheck)
    leftYOffset = leftYOffset - 35
    
    -- Enable Mount Card Hover Checkbox
    local enableMountCardCheck = CreateFrame("CheckButton", nil, leftColumn)
    enableMountCardCheck:SetSize(20, 20)
    enableMountCardCheck:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    enableMountCardCheck:SetChecked(not (MCL_SETTINGS.enableMountCardHover == false))
    
    local enableMountCardText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    enableMountCardText:SetPoint("LEFT", enableMountCardCheck, "RIGHT", 8, 0)
    enableMountCardText:SetText(L["Enable Mount Card on Hover"] or "Enable Mount Card on Hover")
    
    enableMountCardCheck.originalOnClick = function(self)
        MCL_SETTINGS.enableMountCardHover = self:GetChecked()
    end
    
    styleCheckbox(enableMountCardCheck)
    leftYOffset = leftYOffset - sectionSpacing
    
    -- Layout Options Section (Left Column)
    local layoutTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    layoutTitle:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, leftYOffset)
    layoutTitle:SetText(L["Layout Options"] or "Layout Options:")
    layoutTitle:SetTextColor(0.2, 0.8, 1, 1)
    layoutTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    leftYOffset = leftYOffset - 30
    
    -- Mounts Per Row Slider
    local mountsPerRowLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mountsPerRowLabel:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    mountsPerRowLabel:SetText((L["Mounts Per Row"] or "Mounts Per Row") .. ": " .. (MCL_SETTINGS.mountsPerRow or 12))
    mountsPerRowLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    leftYOffset = leftYOffset - 25
    
    local mountsPerRowSlider = CreateFrame("Slider", nil, leftColumn)
    mountsPerRowSlider:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    mountsPerRowSlider:SetOrientation("HORIZONTAL")
    mountsPerRowSlider:SetMinMaxValues(6, 24)
    mountsPerRowSlider:SetValue(MCL_SETTINGS.mountsPerRow or 12)
    mountsPerRowSlider:SetValueStep(1)
    mountsPerRowSlider:SetObeyStepOnDrag(true)
    mountsPerRowSlider:SetWidth(200)
    mountsPerRowSlider:SetHeight(20)
    
    -- Add min/max labels for the slider
    local minLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    minLabel:SetPoint("LEFT", mountsPerRowSlider, "LEFT", 0, -20)
    minLabel:SetText("6")
    minLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    local maxLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    maxLabel:SetPoint("RIGHT", mountsPerRowSlider, "RIGHT", 0, -20)
    maxLabel:SetText("24")
    maxLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    mountsPerRowSlider.originalOnValueChanged = function(self, value)
        MCL_SETTINGS.mountsPerRow = math.floor(value)
        mountsPerRowLabel:SetText((L["Mounts Per Row"] or "Mounts Per Row") .. ": " .. MCL_SETTINGS.mountsPerRow)
        
        -- Show reload warning
        if not self.reloadWarning then
            self.reloadWarning = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.reloadWarning:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -45)
            self.reloadWarning:SetText("|cFFFF6B6BReload UI required (/reload)|r")
        end
        self.reloadWarning:Show()
    end
    
    styleSlider(mountsPerRowSlider, true)  -- Enable input box for mounts per row
    
    -- RIGHT COLUMN: Progress Bar Options Section
    local progressTitle = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressTitle:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, rightYOffset)
    progressTitle:SetText(L["Progress Bar Options"] or "Progress Bar Options:")
    progressTitle:SetTextColor(0.2, 0.8, 1, 1)
    progressTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    rightYOffset = rightYOffset - 30
    
    -- Initialize LibSharedMedia if not already done
    if not MCLcore.media then
        local success, media = pcall(LibStub, "LibSharedMedia-3.0")
        if success and media then
            MCLcore.media = media
        end
    end
    
    -- Enhanced Texture Selector with Full-Width Previews
    if MCLcore.media then
        local textureLabel = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textureLabel:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, rightYOffset)
        textureLabel:SetText(L["Progress Bar Texture"] or "Progress Bar Texture:")
        textureLabel:SetTextColor(0.9, 0.9, 0.9, 1)
        rightYOffset = rightYOffset - 25
        
        -- Create custom dropdown container
        local dropdownContainer = CreateFrame("Frame", nil, rightColumn, "BackdropTemplate")
        local containerWidth = rightColumn:GetWidth() - 10
        dropdownContainer:SetSize(containerWidth, 35)
        dropdownContainer:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, rightYOffset)
        dropdownContainer:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        dropdownContainer:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
        dropdownContainer:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)
        
        -- Selected texture preview (full width)
        local selectedPreview = dropdownContainer:CreateTexture(nil, "ARTWORK")
        selectedPreview:SetSize(containerWidth - 30, 12)
        selectedPreview:SetPoint("LEFT", dropdownContainer, "LEFT", 8, 0)
        
        -- Selected texture name overlay
        local selectedText = dropdownContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        selectedText:SetPoint("CENTER", selectedPreview, "CENTER", 0, 0)
        selectedText:SetTextColor(1, 1, 1, 1)
        selectedText:SetJustifyH("CENTER")
        
        -- Text shadow for better readability
        local selectedTextShadow = dropdownContainer:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
        selectedTextShadow:SetPoint("CENTER", selectedPreview, "CENTER", 1, -1)
        selectedTextShadow:SetTextColor(0, 0, 0, 0.8)
        selectedTextShadow:SetJustifyH("CENTER")
        
        -- Dropdown arrow
        local dropdownArrow = dropdownContainer:CreateTexture(nil, "OVERLAY")
        dropdownArrow:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
        dropdownArrow:SetSize(16, 16)
        dropdownArrow:SetPoint("RIGHT", dropdownContainer, "RIGHT", -8, 0)
        
        -- Dropdown list frame (initially hidden)
        local dropdownList = CreateFrame("Frame", nil, rightColumn, "BackdropTemplate")
        dropdownList:SetSize(containerWidth, 250)  -- Increased height
        dropdownList:SetPoint("TOPLEFT", dropdownContainer, "BOTTOMLEFT", 0, -2)
        dropdownList:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 16, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        dropdownList:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        dropdownList:SetBackdropBorderColor(0.4, 0.6, 0.8, 1)
        dropdownList:SetFrameStrata("DIALOG")
        dropdownList:Hide()
        
        -- Scroll frame for the texture list
        local scrollFrame = CreateFrame("ScrollFrame", nil, dropdownList)
        scrollFrame:SetSize(containerWidth - 20, 230)
        scrollFrame:SetPoint("TOPLEFT", dropdownList, "TOPLEFT", 10, -10)
        
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollFrame:SetScrollChild(scrollChild)
        
        -- Get textures and create preview buttons
        local textures = MCLcore.media:List("statusbar") or {}
        table.sort(textures)
        
        local textureButtons = {}
        local buttonHeight = 30  -- Increased height for better preview
        local totalHeight = #textures * buttonHeight + 10
        scrollChild:SetSize(containerWidth - 40, math.max(totalHeight, 230))
        
        -- Enable mouse wheel scrolling
        scrollFrame:EnableMouseWheel(true)
        scrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local current = self:GetVerticalScroll()
            local maxScroll = math.max(0, scrollChild:GetHeight() - self:GetHeight())
            local newScroll = math.max(0, math.min(maxScroll, current - (delta * 30)))
            self:SetVerticalScroll(newScroll)
        end)
        
        -- Create scroll bar
        local scrollBar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
        scrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", 4, -16)
        scrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", 4, 16)
        scrollBar:SetWidth(16)
        
        -- Function to update scrollbar after content is created
        local function updateScrollBar()
            local maxScroll = math.max(0, scrollChild:GetHeight() - scrollFrame:GetHeight())
            if maxScroll > 0 then
                scrollBar:Show()
                scrollBar:SetMinMaxValues(0, maxScroll)
                scrollBar:SetValueStep(buttonHeight)
            else
                scrollBar:Hide()
            end
        end
        
        -- Scrollbar functionality
        scrollBar:SetScript("OnValueChanged", function(self, value)
            if scrollFrame:GetVerticalScroll() ~= value then
                scrollFrame:SetVerticalScroll(value)
            end
        end)
        
        -- Update scrollbar when content scrolls
        scrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            scrollBar:SetValue(offset)
        end)
        
        for i, textureName in ipairs(textures) do
            local button = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
            button:SetSize(containerWidth - 30, buttonHeight - 2)
            button:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 5, -(i-1) * buttonHeight - 5)
            
            -- Button background
            button:SetBackdrop({
                bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                tile = true, tileSize = 16,
            })
            button:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
            
            -- Full-width texture preview
            local preview = button:CreateTexture(nil, "ARTWORK")
            preview:SetSize(containerWidth - 40, 18)  -- Full width minus padding
            preview:SetPoint("CENTER", button, "CENTER", 0, 0)
            
            -- Set the texture safely
            local textureFile = MCLcore.media:Fetch("statusbar", textureName)
            if textureFile then
                preview:SetTexture(textureFile)
            end
            
            -- Texture name overlay on the preview
            local nameText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            nameText:SetPoint("CENTER", preview, "CENTER", 0, 0)
            nameText:SetText(textureName)
            nameText:SetTextColor(1, 1, 1, 1)
            nameText:SetJustifyH("CENTER")
            
            -- Text shadow for better readability
            local nameShadow = button:CreateFontString(nil, "BACKGROUND", "GameFontHighlight")
            nameShadow:SetPoint("CENTER", preview, "CENTER", 1, -1)
            nameShadow:SetText(textureName)
            nameShadow:SetTextColor(0, 0, 0, 0.8)
            nameShadow:SetJustifyH("CENTER")
            
            -- Button scripts
            button:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.2, 0.4, 0.6, 0.5)
                nameText:SetTextColor(1, 1, 1, 1)
            end)
            
            button:SetScript("OnLeave", function(self)
                if MCL_SETTINGS.statusBarTexture == textureName then
                    self:SetBackdropColor(0.2, 0.6, 1, 0.4)
                    nameText:SetTextColor(1, 1, 1, 1)
                else
                    self:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
                    nameText:SetTextColor(1, 1, 1, 1)
                end
            end)
            
            button:SetScript("OnClick", function(self)
                MCL_SETTINGS.statusBarTexture = textureName
                selectedText:SetText(textureName)
                selectedTextShadow:SetText(textureName)
                if textureFile then
                    selectedPreview:SetTexture(textureFile)
                end
                dropdownList:Hide()
                
                -- Update all button states
                for _, btn in ipairs(textureButtons) do
                    if btn.textureName == textureName then
                        btn:SetBackdropColor(0.2, 0.6, 1, 0.4)
                    else
                        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.3)
                    end
                end
            end)
            
            button.textureName = textureName
            button.nameText = nameText
            table.insert(textureButtons, button)
            
            -- Set initial selection state
            if MCL_SETTINGS.statusBarTexture == textureName then
                button:SetBackdropColor(0.2, 0.6, 1, 0.4)
            end
        end
        
        -- Update scrollbar after content is created
        updateScrollBar()
        
        -- Set current selection
        local currentTexture = MCL_SETTINGS.statusBarTexture or "Blizzard"
        selectedText:SetText(currentTexture)
        selectedTextShadow:SetText(currentTexture)
        local currentTextureFile = MCLcore.media:Fetch("statusbar", currentTexture)
        if currentTextureFile then
            selectedPreview:SetTexture(currentTextureFile)
        end
        
        -- Dropdown toggle functionality
        dropdownContainer:SetScript("OnMouseDown", function(self)
            if dropdownList:IsShown() then
                dropdownList:Hide()
            else
                dropdownList:Show()
            end
        end)
        
        -- Close dropdown when clicking outside
        local function closeDropdown()
            dropdownList:Hide()
        end
        
        frame:SetScript("OnMouseDown", closeDropdown)
        
        rightYOffset = rightYOffset - 60
    else
        -- Fallback when LibSharedMedia is not available
        local textureNote = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        textureNote:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, rightYOffset)
        textureNote:SetText(L["Progress Bar Texture: Default (LibSharedMedia not available)"] or "Progress Bar Texture: Default (LibSharedMedia not available)")
        textureNote:SetTextColor(0.8, 0.4, 0.4, 1)
        rightYOffset = rightYOffset - 40
    end
    
    -- Window Opacity Section (Right Column)
    local opacityTitle = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityTitle:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, rightYOffset)
    opacityTitle:SetText(L["Window Opacity"] or "Window Opacity:")
    opacityTitle:SetTextColor(0.2, 0.8, 1, 1)
    opacityTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    rightYOffset = rightYOffset - 30
    
    -- Opacity Slider
    local opacityValue = MCL_SETTINGS.opacity or 0.85
    local opacityLabel = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    opacityLabel:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, rightYOffset)
    opacityLabel:SetText((L["Opacity"] or "Opacity") .. ": " .. math.floor(opacityValue * 100) .. "%")
    opacityLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    rightYOffset = rightYOffset - 25
    
    local opacitySlider = CreateFrame("Slider", nil, rightColumn)
    opacitySlider:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, rightYOffset)
    opacitySlider:SetOrientation("HORIZONTAL")
    opacitySlider:SetMinMaxValues(0.1, 1.0)
    opacitySlider:SetValue(opacityValue)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetWidth(200)
    opacitySlider:SetHeight(20)
    
    -- Add min/max labels for the opacity slider
    local opacityMinLabel = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opacityMinLabel:SetPoint("LEFT", opacitySlider, "LEFT", 0, -20)
    opacityMinLabel:SetText("10%")
    opacityMinLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    local opacityMaxLabel = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opacityMaxLabel:SetPoint("RIGHT", opacitySlider, "RIGHT", 0, -20)
    opacityMaxLabel:SetText("100%")
    opacityMaxLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    opacitySlider.originalOnValueChanged = function(self, value)
        MCL_SETTINGS.opacity = value
        opacityLabel:SetText((L["Opacity"] or "Opacity") .. ": " .. math.floor(value * 100) .. "%")
        
        -- Apply opacity change immediately to main frame background
        if MCL_mainFrame and MCL_mainFrame.Bg then
            MCL_mainFrame.Bg:SetVertexColor(0, 0, 0, value)
        end
    end
    
    styleSlider(opacitySlider, true, true)  -- Enable input box for opacity with percentage
    rightYOffset = rightYOffset - 60
    
    -- Custom Reset Button (Right Column)
    local resetButton = CreateFrame("Button", nil, rightColumn, "BackdropTemplate")
    resetButton:SetSize(140, 35)
    resetButton:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 5, rightYOffset)
    
    -- Button backdrop
    resetButton:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    resetButton:SetBackdropColor(0.6, 0.1, 0.1, 0.8)
    resetButton:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
    
    -- Button text
    local resetText = resetButton:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    resetText:SetPoint("CENTER", resetButton, "CENTER")
    resetText:SetText(L["Reset Settings"] or "Reset Settings")
    resetText:SetTextColor(1, 1, 1, 1)
    
    -- Button hover effects
    resetButton:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.8, 0.2, 0.2, 0.9)
        self:SetBackdropBorderColor(1, 0.4, 0.4, 1)
        resetText:SetTextColor(1, 1, 1, 1)
    end)
    
    resetButton:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.6, 0.1, 0.1, 0.8)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        resetText:SetTextColor(1, 1, 1, 1)
    end)
    
    resetButton:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.4, 0.1, 0.1, 0.9)
    end)
    
    resetButton:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.8, 0.2, 0.2, 0.9)
    end)
    
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("MCL_RESET_SETTINGS")
    end)
    
    -- Create reset confirmation popup
    StaticPopupDialogs["MCL_RESET_SETTINGS"] = {
        text = L["Are you sure you want to reset all MCL settings?"] or "Are you sure you want to reset all MCL settings?",
        button1 = L["Yes"] or "Yes",
        button2 = L["No"] or "No",
        OnAccept = function()
            -- Reset to defaults
            MCL_SETTINGS.useBlizzardTheme = false
            MCL_SETTINGS.hideCollectedMounts = false
            MCL_SETTINGS.unobtainable = false
            MCL_SETTINGS.mountsPerRow = 12
            MCL_SETTINGS.statusBarTexture = "Blizzard"
            MCL_SETTINGS.opacity = 0.85
            MCL_SETTINGS.enableMountCardHover = true
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    -- Create reload warning popup
    StaticPopupDialogs["MCL_RELOAD_WARNING"] = {
        text = L["This setting requires a UI reload to take effect. Reload now?"] or "This setting requires a UI reload to take effect. Reload now?",
        button1 = L["Reload Now"] or "Reload Now",
        button2 = L["Later"] or "Later",
        OnAccept = function()
            ReloadUI()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
    
    return frame
end


function MCL_frames:createOverviewCategory(set, relativeFrame)
    if not set or not relativeFrame then
        return
    end

    -- Use the same layout calculations as createCategoryFrame for consistency
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 60  -- Total content width
    local columnSpacing = 25  -- Spacing between columns
    local numColumns = 2
    local columnWidth = math.floor((availableWidth - columnSpacing * (numColumns - 1)) / numColumns)
    
    local leftColumnX = 15  -- Start with padding from left edge
    local rightColumnX = leftColumnX + columnWidth + columnSpacing
    
    local leftColumnY = -30  -- Reduced from -60 for tighter spacing
    local rightColumnY = -30
    local sectionIndex = 0

    -- Create sections similar to how categories are created in other tabs
    for k, v in pairs(set) do
        if (v.name ~= "Overview") and (v.name ~= "Pinned") then
            sectionIndex = sectionIndex + 1
            
            -- Determine which column to use (alternate left/right)
            local isLeftColumn = (sectionIndex % 2 == 1)
            local xPos = isLeftColumn and leftColumnX or rightColumnX
            local yPos = isLeftColumn and leftColumnY or rightColumnY
            
            -- Get actual stats for this section
            local sectionStats = MCLcore.stats and MCLcore.stats[v.name]
            local totalMounts = (sectionStats and sectionStats.total) or 0
            local collectedMounts = (sectionStats and sectionStats.collected) or 0
            
            -- Create section frame without background
            local sectionFrame = CreateFrame("Frame", nil, relativeFrame)
            sectionFrame:SetWidth(columnWidth)  -- Use calculated column width
            sectionFrame:SetHeight(50)  -- Reduced from 65 to 50 for even tighter spacing
            sectionFrame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", xPos, yPos)
            
            -- Section title with smaller font
            sectionFrame.title = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            sectionFrame.title:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 5, -2)  -- Reduced padding
            sectionFrame.title:SetText(L[v.name] or v.name)
            sectionFrame.title:SetTextColor(1, 1, 1, 1)
            
            -- Create progress bar container with dynamic width based on column width
            local progressContainer = CreateFrame("Frame", nil, sectionFrame)
            progressContainer:SetWidth(columnWidth - 10)  -- Use column width with padding
            progressContainer:SetHeight(16)  -- Smaller height
            progressContainer:SetPoint("TOPLEFT", sectionFrame.title, "BOTTOMLEFT", 0, -5)  -- Reduced spacing
            
            -- Create progress bar with background
            local pBar = CreateFrame("StatusBar", nil, progressContainer, "BackdropTemplate")
            
            -- Add dark background to the progress bar
            pBar:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                edgeSize = 1
            })
            pBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)  -- Dark background
            pBar:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)  -- Subtle border
            
            -- Use settings texture if available, otherwise fallback to TargetingFrame
            local textureToUse = "Interface\\TargetingFrame\\UI-StatusBar"  -- Good default that colors well
            if MCL_SETTINGS and MCL_SETTINGS.statusBarTexture and MCLcore.media then
                local settingsTexture = MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture)
                if settingsTexture then
                    textureToUse = settingsTexture
                end
            end
            
            pBar:SetStatusBarTexture(textureToUse)
            pBar:GetStatusBarTexture():SetHorizTile(false)
            pBar:GetStatusBarTexture():SetVertTile(false)
            pBar:SetMinMaxValues(0, 100)
            pBar:SetValue(0)
            pBar:SetAllPoints(progressContainer)
            
            -- Text for progress bar
            pBar.Text = pBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            pBar.Text:SetPoint("CENTER", pBar, "CENTER", 0, 0)
            pBar.Text:SetJustifyH("CENTER")
            pBar.Text:SetTextColor(1, 1, 1, 1)
            
            -- Update progress bar with actual data
            if totalMounts > 0 then
                local percentage = (collectedMounts / totalMounts) * 100
                pBar:SetValue(percentage)
                pBar.Text:SetText(string.format("%d/%d (%d%%)", collectedMounts, totalMounts, math.floor(percentage)))
                
                -- Use the same color logic as other progress bars
                pBar.val = percentage
                UpdateProgressBar(pBar, totalMounts, collectedMounts)
            else
                pBar:SetValue(0)
                pBar.Text:SetText("0/0 (0%)")
                pBar:SetStatusBarColor(0.5, 0.5, 0.5)  -- Gray for no data
            end
            
            -- Store this in the same way other progress bars are stored
            -- Check if this progress bar is already in the table to prevent duplicates
            local alreadyExists = false
            if MCLcore.statusBarFrames then
                for _, existingBar in ipairs(MCLcore.statusBarFrames) do
                    if existingBar == pBar then
                        alreadyExists = true
                        break
                    end
                end
            end
            if not alreadyExists then
                table.insert(MCLcore.statusBarFrames, pBar)
            end
            
            -- Add hover effects like other sections
            pBar:HookScript("OnEnter", function()
                -- Store the current color before changing to hover color
                local r, g, b, a = pBar:GetStatusBarColor()
                pBar.originalR = r
                pBar.originalG = g
                pBar.originalB = b
                pBar:SetStatusBarColor(0.8, 0.5, 0.9, 1)  -- Purple hover color
            end)
            pBar:HookScript("OnLeave", function()
                -- Restore the stored original color
                if pBar.originalR and pBar.originalG and pBar.originalB then
                    pBar:SetStatusBarColor(pBar.originalR, pBar.originalG, pBar.originalB)
                else
                    -- Fallback: recalculate the color if we don't have stored values
                    if totalMounts > 0 then
                        local percentage = (collectedMounts / totalMounts) * 100
                        if percentage < 33 then
                            pBar:SetStatusBarColor(MCL_SETTINGS.progressColors.low.r, MCL_SETTINGS.progressColors.low.g, MCL_SETTINGS.progressColors.low.b)
                        elseif percentage < 66 then
                            pBar:SetStatusBarColor(MCL_SETTINGS.progressColors.medium.r, MCL_SETTINGS.progressColors.medium.g, MCL_SETTINGS.progressColors.medium.b)
                        elseif percentage < 100 then
                            pBar:SetStatusBarColor(MCL_SETTINGS.progressColors.high.r, MCL_SETTINGS.progressColors.high.g, MCL_SETTINGS.progressColors.high.b)
                        else
                            pBar:SetStatusBarColor(MCL_SETTINGS.progressColors.complete.r, MCL_SETTINGS.progressColors.complete.g, MCL_SETTINGS.progressColors.complete.b)
                        end
                    else
                        pBar:SetStatusBarColor(0.5, 0.5, 0.5)  -- Gray for no data
                    end
                end
            end)
            
            -- Handle unobtainable sections
            if v.name == "Unobtainable" then
                pBar.unobtainable = MCL_SETTINGS.unobtainable
                if MCL_SETTINGS.unobtainable == true then
                    sectionFrame:Hide()
                end
            end

            -- Add click functionality to navigate to the section
            pBar:SetScript("OnMouseDown", function(self, button)
                if button == 'LeftButton' then
                    -- Find the corresponding tab and select it
                    local navFrame = MCLcore.MCL_MF_Nav
                    if navFrame and navFrame.tabs then
                        for _, tab in ipairs(navFrame.tabs) do
                            if tab.section and tab.section.name == v.name then
                                -- Use the same selection logic as in SetTabs
                                for _, t in ipairs(navFrame.tabs) do
                                    if t.content then t.content:Hide() end
                                    if t.SetBackdropBorderColor then
                                        t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                                    end
                                end
                                if tab.SetBackdropBorderColor then
                                    tab:SetBackdropBorderColor(1, 0.82, 0, 1)
                                end
                                if MCL_mainFrame and MCL_mainFrame.ScrollFrame then
                                    -- Always keep the main scroll child as the scroll child
                                    MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                                    if tab.content then
                                        tab.content:Show()
                                    end
                                    MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
                                end
                                break
                            end
                        end
                    end
                end
            end)
            
            -- Store frame reference for updates
            local t = {
                name = v.name, -- Use non-localized name for identification
                frame = pBar
            }
            
            -- Initialize overviewFrames if it doesn't exist
            if not MCLcore.overviewFrames then
                MCLcore.overviewFrames = {}
            end
            
            -- Check for duplicates before adding
            local alreadyExists = false
            for _, existingFrame in ipairs(MCLcore.overviewFrames) do
                if existingFrame.name == v.name then
                    alreadyExists = true
                    break
                end
            end
            
            if not alreadyExists then
                table.insert(MCLcore.overviewFrames, t)
            end
            
            -- Update column positions for next section
            if isLeftColumn then
                leftColumnY = leftColumnY - 55  -- Reduced from 75 to 55 (section height 50 + 5 spacing)
            else
                rightColumnY = rightColumnY - 55
            end
        end
    end
    
    -- Adjust parent frame height to accommodate all sections with proper padding
    local maxY = math.min(leftColumnY, rightColumnY)
    local requiredHeight = math.abs(maxY) + 40  -- Add more padding for better spacing
    relativeFrame:SetHeight(requiredHeight)
end


----------------------------------------------------------------
-- Creating a placeholder for each category, this is where we attach each mount to.
----------------------------------------------------------------

function MCL_frames:createCategoryFrame(set, relativeFrame, sectionName)
    if not set then
        return
    end

    -- Check if set has any data
    local hasData = false
    for k, v in pairs(set) do
        hasData = true
        break
    end
    
    if not hasData then
        return
    end

    -- Add loop protection and debugging
    local debugCounter = 0
    local maxIterations = 10000  -- Reasonable limit for mount processing
    local maxCategories = 50     -- Reasonable limit for categories per section
    
    local function safeLoopCheck(operation)
        debugCounter = debugCounter + 1
        if debugCounter > maxIterations then
            error("MCL: Infinite loop detected in createCategoryFrame during " .. (operation or "unknown operation"))
        end
    end

    -- Dynamic layout calculation based on current frame width
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 60  -- Total content width
    local columnSpacing = 25  -- Reduced spacing between columns to use more space
    local numColumns = 2
    local columnWidth = math.floor((availableWidth - columnSpacing * (numColumns - 1)) / numColumns)
    
    local leftColumnX = 0
    local rightColumnX = leftColumnX + columnWidth + columnSpacing
    
    local leftColumnY = -50
    local rightColumnY = -50
    local categoryIndex = 0

    -- Get sorted category names with loop protection
local sortedCategoryNames = {}
for k, v in pairs(set) do
    safeLoopCheck("building category list")
    if type(v) == "table" then
        table.insert(sortedCategoryNames, k)
    end
end

-- Validate category count
if #sortedCategoryNames > maxCategories then
    print("MCL Warning: Too many categories (" .. #sortedCategoryNames .. "), limiting to " .. maxCategories)
    local truncatedList = {}
    for i = 1, maxCategories do
        table.insert(truncatedList, sortedCategoryNames[i])
    end
    sortedCategoryNames = truncatedList
end

table.sort(sortedCategoryNames)

local leftColumnY = -50
local rightColumnY = -50
local categoryIndex = 0

for _, categoryName in ipairs(sortedCategoryNames) do
    safeLoopCheck("processing category: " .. tostring(categoryName))
    local categoryData = set[categoryName]
    -- Calculate mount stats for this category first (needed for dynamic height)
    local totalMounts = 0
    local collectedMounts = 0
    local displayedMounts = 0  -- Track mounts that will actually be displayed
    
    -- Combine both mounts and mountID arrays
    local mountList = {}
    if categoryData.mounts then
        for _, mount in ipairs(categoryData.mounts) do
            table.insert(mountList, mount)
        end
    end
    if categoryData.mountID then
        for _, mount in ipairs(categoryData.mountID) do
            table.insert(mountList, mount)
        end
    end
    
    for _, mountId in ipairs(mountList) do
        safeLoopCheck("counting mounts in category: " .. tostring(categoryName))
        local mount_Id = MCLcore.Function:GetMountID(mountId)
        if mount_Id then
            -- Faction check: Only count mounts that are not faction-specific or match the player's faction
            local faction, faction_specific = MCLcore.Function.IsMountFactionSpecific(mountId)
            local playerFaction = UnitFactionGroup("player")
            local allowed = false
            if faction_specific == false then
                allowed = true
            elseif faction_specific == true then
                if faction == 0 then faction = "Horde" elseif faction == 1 then faction = "Alliance" end
                allowed = (faction == playerFaction)
            end
            if allowed then
                local isCollected = IsMountCollected(mount_Id)
                totalMounts = totalMounts + 1
                if isCollected then
                    collectedMounts = collectedMounts + 1
                end
                if not (MCL_SETTINGS.hideCollectedMounts and isCollected) then
                    displayedMounts = displayedMounts + 1
                end
                
            end
        end
    end

    -- Only increment categoryIndex if the category is actually displayed (e.g., displayedMounts > 0)
    if displayedMounts > 0 then
        categoryIndex = categoryIndex + 1
        -- Determine which column to use (alternate left/right)
        local isLeftColumn = (categoryIndex % 2 == 1)
        local xPos = isLeftColumn and leftColumnX or rightColumnX
        local yPos = isLeftColumn and leftColumnY or rightColumnY
        
        -- Calculate optimal mounts per row based on column width (same calculation as later)
        local categoryPadding = 20  -- Total padding (10px on each side)
        local availableMountWidth = columnWidth - categoryPadding
        
        -- Start with user's preferred mounts per row
        local mountsPerRow = MCL_SETTINGS.mountsPerRow or 12  -- Use setting or default to 12
        -- Ensure it's within bounds
        mountsPerRow = math.max(6, math.min(mountsPerRow, 24))
        
        -- Calculate mount size to fit exactly within available width
        local desiredSpacing = 4  -- Fixed spacing between mounts
        local minMountSize = 16  -- Absolute minimum mount size (reduced from 24)
        local maxMountSize = 48  -- Maximum mount size
        
        -- Try the preferred mounts per row first
        local totalSpacingWidth = desiredSpacing * (mountsPerRow - 1)
        local availableForMounts = availableMountWidth - totalSpacingWidth
        local mountSize = math.floor(availableForMounts / mountsPerRow)
        
        -- If mount size is too small, reduce mounts per row until we get acceptable size
        while mountSize < minMountSize and mountsPerRow > 6 do
            mountsPerRow = mountsPerRow - 1
            totalSpacingWidth = desiredSpacing * (mountsPerRow - 1)
            availableForMounts = availableMountWidth - totalSpacingWidth
            mountSize = math.floor(availableForMounts / mountsPerRow)
        end
        
        -- Ensure mount size is within bounds
        mountSize = math.max(minMountSize, math.min(mountSize, maxMountSize))
        
        -- Recalculate actual spacing to center the grid
        local actualMountWidth = mountSize * mountsPerRow
        local actualSpacing = mountsPerRow > 1 and math.floor((availableMountWidth - actualMountWidth) / (mountsPerRow - 1)) or 0
        actualSpacing = math.max(1, actualSpacing)  -- Minimum 1px spacing (reduced from 2)
        
        -- Calculate dynamic height based on actual mount layout
        local numRows = math.ceil(displayedMounts / mountsPerRow)
        local baseHeight = 80  -- Base height (title + progress bar + padding)
        local rowSpacing = 4  -- Minimal Y-axis spacing between rows (reduced)
        local rowHeight = mountSize + rowSpacing  -- Actual row height based on calculated mount size
        local categoryHeight = baseHeight + (numRows * rowHeight) + 10  -- Reduced bottom padding
        
        -- Create category frame with dynamic height
        local categoryFrame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")

        categoryFrame:SetWidth(columnWidth)
        categoryFrame:SetHeight(categoryHeight)  -- Dynamic height
        categoryFrame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", xPos, yPos)
        categoryFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8
        })
        categoryFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
        categoryFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        -- Category title
        categoryFrame.title = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        categoryFrame.title:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 10, -8)
        categoryFrame.title:SetText(L[categoryData.name] or L[categoryName] or categoryData.name or categoryName)
        categoryFrame.title:SetTextColor(1, 1, 1, 1)
        
        -- Immediately update the column Y position so subsequent categories use the correct anchor.
        -- Previously this was deferred until the ThrottledMountCreation callback, causing overlap because
        -- the loop continued positioning later categories before the Y offsets were adjusted.
        if isLeftColumn then
            leftColumnY = leftColumnY - (categoryHeight + 8)
        else
            rightColumnY = rightColumnY - (categoryHeight + 8)
        end

        -- Create progress bar container
        local progressContainer = CreateFrame("Frame", nil, categoryFrame)
        progressContainer:SetWidth(columnWidth - 20)  -- Now 500px wide
        progressContainer:SetHeight(18)
        progressContainer:SetPoint("TOPLEFT", categoryFrame.title, "BOTTOMLEFT", 0, -5)
        
        -- Create progress bar using proper texture fallback
        local pBar = CreateFrame("StatusBar", nil, progressContainer, "BackdropTemplate")
        
        -- Use settings texture if available, otherwise fallback to TargetingFrame
        local textureToUse = "Interface\\TargetingFrame\\UI-StatusBar"  -- Good default that colors well
        if MCL_SETTINGS and MCL_SETTINGS.statusBarTexture and MCLcore.media then
            local settingsTexture = MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture)
            if settingsTexture then
                textureToUse = settingsTexture
            end
        end
        
        pBar:SetStatusBarTexture(textureToUse)
        pBar:GetStatusBarTexture():SetHorizTile(false)
        pBar:GetStatusBarTexture():SetVertTile(false)
        pBar:SetMinMaxValues(0, 100)
        pBar:SetValue(0)
        pBar:SetAllPoints(progressContainer)
        
        -- Background for progress bar
        pBar:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 1
        })
        pBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        pBar:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
        
        -- Text for progress bar
        pBar.Text = pBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pBar.Text:SetPoint("CENTER", pBar, "CENTER", 0, 0)
        pBar.Text:SetTextColor(1, 1, 1, 1)
        
        -- Update progress bar
        local percentage = totalMounts > 0 and (collectedMounts / totalMounts) * 100 or 0
        pBar:SetValue(percentage)
        pBar.Text:SetText(string.format("%d/%d (%d%%)", collectedMounts, totalMounts, percentage))
        
        -- Use the UpdateProgressBar function for consistent coloring
        pBar.val = percentage
        UpdateProgressBar(pBar, totalMounts, collectedMounts)
        
        -- Store this progress bar in the statusBarFrames table for settings updates
        table.insert(MCLcore.statusBarFrames, pBar)
        
        -- Mount grid within category - positioned below progress bar
        local mountStartY = -60  -- More padding below progress bar
        
        -- Use the same calculations as in height calculation for consistency
        local categoryPadding = 20  -- Total padding (10px on each side)
        local availableMountWidth = columnWidth - categoryPadding
        
        -- Start with user's preferred mounts per row
        local mountsPerRow = MCL_SETTINGS.mountsPerRow or 12  -- Use setting or default to 12
        -- Ensure it's within bounds
        mountsPerRow = math.max(6, math.min(mountsPerRow, 24))
        
        -- Calculate mount size to fit exactly within available width
        local desiredSpacing = 4  -- Fixed spacing between mounts
        local minMountSize = 16  -- Absolute minimum mount size (reduced from 24)
        local maxMountSize = 48  -- Maximum mount size
        
        -- Try the preferred mounts per row first
        local totalSpacingWidth = desiredSpacing * (mountsPerRow - 1)
        local availableForMounts = availableMountWidth - totalSpacingWidth
        local mountSize = math.floor(availableForMounts / mountsPerRow)
        
        -- If mount size is too small, reduce mounts per row until we get acceptable size
        while mountSize < minMountSize and mountsPerRow > 6 do
            mountsPerRow = mountsPerRow - 1
            totalSpacingWidth = desiredSpacing * (mountsPerRow - 1)
            availableForMounts = availableMountWidth - totalSpacingWidth
            mountSize = math.floor(availableForMounts / mountsPerRow)
        end
        
        -- Ensure mount size is within bounds
        mountSize = math.max(minMountSize, math.min(mountSize, maxMountSize))
        
        -- Recalculate actual spacing to center the grid
        local actualMountWidth = mountSize * mountsPerRow
        local actualSpacing = mountsPerRow > 1 and math.floor((availableMountWidth - actualMountWidth) / (mountsPerRow - 1)) or 0
        actualSpacing = math.max(1, actualSpacing)  -- Minimum 1px spacing (reduced from 2)
        
        -- Y-axis spacing (only affected by height changes)
        local rowSpacing = 4  -- Minimal Y-axis spacing between rows
        
        local maxDisplayMounts = displayedMounts  -- Show all displayed mounts instead of limiting to 24
        local mountStartX = 10
        
        -- Use throttled mount creation to prevent "script ran too long" errors
        local mountConfig = {
            maxDisplayMounts = maxDisplayMounts,
            mountsPerRow = mountsPerRow,
            mountSize = mountSize,
            actualSpacing = actualSpacing,
            rowSpacing = rowSpacing,
            mountStartX = mountStartX,
            mountStartY = mountStartY,
            categoryName = categoryData.name or categoryName,
            sectionName = sectionName or "Unknown"
        }
        
        -- We no longer adjust column Y in the callback; it's done immediately after frame creation above.
        ThrottledMountCreation(mountList, categoryFrame, mountConfig, function() end)
        
    end
end
    
    -- Adjust parent frame height to accommodate all categories with proper padding
    local maxY = math.min(leftColumnY, rightColumnY)
    local requiredHeight = math.abs(maxY) + 20  -- Reduced padding for tighter layout
    relativeFrame:SetHeight(requiredHeight)
end

-- Helper function to get current frame dimensions
function MCL_frames:GetCurrentFrameDimensions()
    if MCL_mainFrame then
        local width = MCL_mainFrame:GetWidth()
        local height = MCL_mainFrame:GetHeight()
        return width, height
    end
    return main_frame_width, main_frame_height  -- Fallback to defaults
end

-- Function to refresh layout after resize
function MCL_frames:RefreshLayout()
    if not MCL_mainFrame then return end
    
    -- Remember which tab was selected before refresh
    local selectedTabName = nil
    local wasShowingSearchResults = false
    local navFrame = MCLcore.MCL_MF_Nav
    if navFrame and navFrame.tabs then
        for _, tab in ipairs(navFrame.tabs) do
            if tab.content and tab.content:IsShown() then
                selectedTabName = tab.section and tab.section.name
                break
            end
        end
        -- Check if search results are currently being shown
        if MCLcore.searchResultsContent and MCLcore.searchResultsContent:IsShown() then
            wasShowingSearchResults = true
        end
    end
    
    -- Update scroll frame size
    MCL_mainFrame.ScrollFrame:ClearAllPoints()
    MCL_mainFrame.ScrollFrame:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 10, -40)
    MCL_mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", MCL_mainFrame, "BOTTOMRIGHT", -10, 10)
    
    -- Update scroll child size
    if MCL_mainFrame.ScrollChild then
        local currentWidth, currentHeight = MCL_frames:GetCurrentFrameDimensions()
        MCL_mainFrame.ScrollChild:SetSize(currentWidth, currentHeight)
    end
    
    -- Update navigation frame height to match main frame
    if MCLcore.MCL_MF_Nav then
        local _, currentHeight = MCL_frames:GetCurrentFrameDimensions()
        MCLcore.MCL_MF_Nav:SetHeight(currentHeight)
    end
    
    -- Recreate tabs with new dimensions
    if MCL_frames.SetTabs then
        MCL_frames:SetTabs()
        
        -- Recreate search results content frame if it exists and is currently showing
        if MCLcore.searchResultsContent and wasShowingSearchResults then
            -- If search is active, recreate the search results with new dimensions
            if MCLcore.Search and MCLcore.Search.isSearchActive then
                C_Timer.After(0.1, function()
                    MCLcore.Search:RecreateSearchResultsFrame()
                end)
            end
        end
        
        -- If we're on the overview page, we need to refresh it since it has dynamic content
        if selectedTabName == "Overview" and MCLcore.overview then
            -- Clear existing overview content more thoroughly
            local children = {MCLcore.overview:GetChildren()}
            for i = 1, #children do
                local child = children[i]
                if child then
                    child:Hide()
                    child:ClearAllPoints()
                    child:SetParent(nil)
                end
            end
            
            -- Clear the overview frames array to prevent duplicates
            if MCLcore.overviewFrames then
                MCLcore.overviewFrames = {}
            end
            
            -- Recreate overview content with new dimensions
            if MCLcore.sections and MCL_frames.createOverviewCategory then
                MCL_frames:createOverviewCategory(MCLcore.sections, MCLcore.overview)
            end
        end
        
        -- Restore the previously selected tab (unless we're showing search results)
        if selectedTabName and navFrame and navFrame.tabs and not wasShowingSearchResults then
            for _, tab in ipairs(navFrame.tabs) do
                if tab.section and tab.section.name == selectedTabName then
                    -- Use the same selection logic as in SetTabs
                    for _, t in ipairs(navFrame.tabs) do
                        if t.content then t.content:Hide() end
                        if t.SetBackdropBorderColor then
                            t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                        end
                    end
                    if tab.SetBackdropBorderColor then
                        tab:SetBackdropBorderColor(1, 0.82, 0, 1)
                    end
                    if MCL_mainFrame and MCL_mainFrame.ScrollFrame then
                        -- Always keep the main scroll child as the scroll child
                        MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                        if tab.content then
                            tab.content:Show()
                        end
                        MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
                    end
                    break
                end
            end
        end
    end
    
    -- Resize mount card if it exists to match new frame dimensions
    if MCLcore.MountCard and MCLcore.MountCard.Resize then
        MCLcore.MountCard.Resize()
    end
    
    collectgarbage("collect")    
end



-- Function to save frame size to settings
function MCL_frames:SaveFrameSize()
    if MCL_mainFrame and MCL_SETTINGS then
        MCL_SETTINGS.frameWidth = MCL_mainFrame:GetWidth()
        MCL_SETTINGS.frameHeight = MCL_mainFrame:GetHeight()
        
        -- Also resize mount card to match new dimensions
        if MCLcore.MountCard and MCLcore.MountCard.Resize then
            MCLcore.MountCard.Resize()
        end
    end
end

-- Function to restore frame size from settings
function MCL_frames:RestoreFrameSize()
    if MCL_mainFrame and MCL_SETTINGS then
        local width = MCL_SETTINGS.frameWidth or main_frame_width
       
        local height = MCL_SETTINGS.frameHeight or main_frame_height
        MCL_mainFrame:SetSize(width, height)
    end
end

-- Function to calculate minimum height based on navigation content
function MCL_frames:CalculateMinHeight()
    local baseHeight = 100  -- Base height for frame borders, title, etc.
    local navStartY = -20   -- Starting Y position for nav items
    local currentY = navStartY
    
    -- Calculate sections like in SetTabs
    local sections = MCLcore.sectionsOrdered or MCLcore.sections
    if not sections then
        return baseHeight + 200  -- Fallback minimum
    end
    
    local overviewSection, pinnedSection, expansionSections, otherSections = nil, nil, {}, {}
    for _, v in ipairs(sections) do
        if v.name == "Overview" then
            overviewSection = v
        elseif v.name == "Pinned" then
            pinnedSection = v
        elseif v.isExpansion then
            table.insert(expansionSections, v)
        else
            table.insert(otherSections, v)
        end
    end
    
    -- 1. Overview section (32px height + 4px spacing)
    if overviewSection then
        currentY = currentY - 36
    end
    
    -- 2. Expansion grid (calculate rows needed)
    if #expansionSections > 0 then
        local gridCols = 3
        local iconSize = 36
        local iconPad = 8
        local gridRows = math.ceil(#expansionSections / gridCols)
        local gridHeight = gridRows * (iconSize + iconPad)
        currentY = currentY - gridHeight - 10  -- 10px spacing after grid
    end
    
    -- 3. Other sections (28px each)
    for _, v in ipairs(otherSections) do
        currentY = currentY - 28
    end
    
    -- 4. Pinned section (28px)
    if pinnedSection then
        currentY = currentY - 28
    end
    
    -- Convert negative Y offset to positive height requirement
    local requiredNavHeight = math.abs(currentY) + 40  -- 40px bottom padding
    local totalMinHeight = baseHeight + requiredNavHeight
    
    return math.max(totalMinHeight, 300)  -- Ensure at least 300px minimum
end
