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

-- Sort modes for mount lists within categories
local SORT_MODES = {
    { key = "default",   label = "Default" },
    { key = "name_asc",  label = "Name A-Z" },
    { key = "name_desc", label = "Name Z-A" },
    { key = "collected", label = "Collected First" },
    { key = "uncollected", label = "Uncollected First" },
}

-- Resolve a mount entry (item ID, "mXXX" string, etc.) into a sortable name and collected flag
local function ResolveMountSortInfo(mountId)
    local mount_Id = MCLcore.Function and MCLcore.Function.GetMountID and MCLcore.Function:GetMountID(mountId)
    if not mount_Id or mount_Id <= 0 then
        return tostring(mountId), false
    end
    local mountName = C_MountJournal.GetMountInfoByID(mount_Id)
    local collected = IsMountCollected(mount_Id)
    return mountName or tostring(mountId), collected or false
end

-- Sort a mount list in-place according to the given sort mode key
local function SortMountList(list, mode)
    if not mode or mode == "default" or not list or #list < 2 then return end
    -- Build a cache of sort info so we only resolve once per mount
    local cache = {}
    for i, id in ipairs(list) do
        local name, collected = ResolveMountSortInfo(id)
        cache[i] = { idx = i, name = name, collected = collected }
    end
    table.sort(cache, function(a, b)
        if mode == "name_asc" then
            return a.name < b.name
        elseif mode == "name_desc" then
            return a.name > b.name
        elseif mode == "collected" then
            if a.collected ~= b.collected then return a.collected end
            return a.name < b.name
        elseif mode == "uncollected" then
            if a.collected ~= b.collected then return not a.collected end
            return a.name < b.name
        end
        return a.idx < b.idx
    end)
    -- Rebuild the list in sorted order
    local sorted = {}
    for _, entry in ipairs(cache) do
        table.insert(sorted, list[entry.idx])
    end
    for i, v in ipairs(sorted) do
        list[i] = v
    end
end

local r,g,b,a

local L = MCLcore.L

-- Recursively release all children of a frame.
-- Children are hidden, stripped of scripts, and orphaned so they stop
-- consuming rendering or event-handling resources. WoW frames cannot be
-- truly destroyed, but orphaning them is the next best thing.
local function ReleaseFrameChildren(frame)
    if not frame then return end
    local children = {frame:GetChildren()}
    for _, child in ipairs(children) do
        ReleaseFrameChildren(child) -- depth-first
        child:Hide()
        child:ClearAllPoints()
        -- Not all frame types support every script handler (e.g. StatusBar
        -- has no OnClick), so guard each call with pcall.
        for _, script in ipairs({"OnClick","OnEnter","OnLeave","OnMouseDown","OnMouseUp"}) do
            pcall(child.SetScript, child, script, nil)
        end
        child:SetParent(nil)
    end
end

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
    -- Optional debug logging: enable with /run MCL_SETTINGS.debugRender=true then /reload
    local function isDebugCategory()
        if not (MCL_SETTINGS and MCL_SETTINGS.debugRender) then
            return false
        end
        local name = tostring(config and config.categoryName or ""):lower()
        return (name == "quest" or name == "dungeon drop" or name == "dungeondrop" or name == "dungeon")
    end

    local debugCategory = isDebugCategory()
    if debugCategory then
        print(string.format("MCL DEBUG: Rendering category '%s' (%s mounts in data)", tostring(config and config.categoryName or "?"), tostring(mountList and #mountList or 0)))
    end

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
            local skipReason = nil
            
            -- Validate mount data
            if not mountId or (type(mountId) ~= "number" and type(mountId) ~= "string") then
                print("MCL Warning: Invalid mount ID at index " .. index .. ": " .. tostring(mountId))
                shouldProcess = false
                skipReason = "invalid mountId type"
            end
            
            local mount_Id = nil
            if shouldProcess then
                mount_Id = MCLcore.Function and MCLcore.Function.GetMountID and MCLcore.Function:GetMountID(mountId)
                
                -- Skip invalid mount IDs
                if not mount_Id or type(mount_Id) ~= "number" or mount_Id <= 0 then
                    shouldProcess = false
                    skipReason = "GetMountID returned nil/invalid"
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
                    if debugCategory then
                        local collected = (mount_Id and IsMountCollected(mount_Id)) and "collected" or "uncollected"
                        print(string.format(
                            "MCL DEBUG: show mountId=%s -> mountID=%s (%s) [%d/%d]",
                            tostring(mountId),
                            tostring(mount_Id),
                            collected,
                            displayedIndex,
                            config.maxDisplayMounts
                        ))
                    end
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
                                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                                        edgeSize = 1
                                    })
                                    backdropFrame:SetBackdropColor(0.12, 0.18, 0.12, 0.5)
                                    backdropFrame:SetBackdropBorderColor(0.25, 0.65, 0.25, 0.8)
                                else
                                    mountFrame.tex:SetVertexColor(0.45, 0.45, 0.45, 0.75)
                                    backdropFrame:SetBackdrop({
                                        bgFile = "Interface\\Buttons\\WHITE8x8",
                                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                                        edgeSize = 1
                                    })
                                    backdropFrame:SetBackdropColor(0.08, 0.08, 0.1, 0.4)
                                    backdropFrame:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.5)
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

                if debugCategory and (not shouldProcess) then
                    print(string.format(
                        "MCL DEBUG: skip mountId=%s (reason=%s)",
                        tostring(mountId),
                        tostring(skipReason or "filtered")
                    ))
                end
            
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
    
    if isExpansionIcon then
        -- Expansion icon buttons: subtle dark frame with 1px border
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        button:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
        button:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
    else
        -- Full-width nav buttons: matching header button style
        button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        button:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
        button:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
        
        if button.text then
            button.text:SetTextColor(0.7, 0.78, 0.88, 1)
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
	-- Modern WoW Settings.OpenToCategory requires a numeric ID, but
	-- AceConfigDialog registers with a string ID. Open the panel and
	-- select the category manually.
	if SettingsPanel then
		SettingsPanel:Show()
		local category = Settings.GetCategory(MCLcore.addon_name)
		if category then
			SettingsPanel:SelectCategory(category)
		end
	end
	local panel = SettingsPanel or InterfaceOptionsFrame or _G["SettingsPanel"]
	if not panel then return end

	-- Remove old checkboxes if they exist
	if MCLcore.hideCollectedIconCheckbox then
		MCLcore.hideCollectedIconCheckbox:Hide()
		MCLcore.hideCollectedIconCheckbox = nil
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
    MCL_mainFrame = CreateFrame("Frame", "MCLFrame", UIParent, "MCLCleanFrameTemplate");
    MCL_mainFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    MCL_mainFrame:SetBackdropColor(0.10, 0.10, 0.18, MCL_SETTINGS.opacity)
    MCL_mainFrame:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
    
    -- =====================================================
    -- TITLE BAR
    -- =====================================================
    local HEADER_HEIGHT = 30
    
    -- Header background bar
    MCL_mainFrame.headerBar = CreateFrame("Frame", nil, MCL_mainFrame, "BackdropTemplate")
    MCL_mainFrame.headerBar:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 0, 0)
    MCL_mainFrame.headerBar:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", 0, 0)
    MCL_mainFrame.headerBar:SetHeight(HEADER_HEIGHT)
    MCL_mainFrame.headerBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    MCL_mainFrame.headerBar:SetBackdropColor(0.08, 0.08, 0.12, MCL_SETTINGS.opacity)
    MCL_mainFrame.headerBar:SetFrameLevel(MCL_mainFrame:GetFrameLevel() + 3)
    
    -- Accent line at bottom of header
    MCL_mainFrame.headerAccent = MCL_mainFrame.headerBar:CreateTexture(nil, "OVERLAY")
    MCL_mainFrame.headerAccent:SetHeight(1)
    MCL_mainFrame.headerAccent:SetPoint("BOTTOMLEFT", MCL_mainFrame.headerBar, "BOTTOMLEFT", 0, 0)
    MCL_mainFrame.headerAccent:SetPoint("BOTTOMRIGHT", MCL_mainFrame.headerBar, "BOTTOMRIGHT", 0, 0)
    MCL_mainFrame.headerAccent:SetColorTexture(0.2, 0.6, 0.9, 0.6)
    
    -- Make header bar draggable (inherits from parent)
    MCL_mainFrame.headerBar:EnableMouse(true)
    MCL_mainFrame.headerBar:RegisterForDrag("LeftButton")
    MCL_mainFrame.headerBar:SetScript("OnDragStart", function() MCL_mainFrame:StartMoving() end)
    MCL_mainFrame.headerBar:SetScript("OnDragStop", function() MCL_mainFrame:StopMovingOrSizing() end)
    
    -- Title text
    MCL_mainFrame.title = MCL_mainFrame.headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    MCL_mainFrame.title:SetPoint("LEFT", MCL_mainFrame.headerBar, "LEFT", 10, 0)
    MCL_mainFrame.title:SetText(L["Mount Collection Log"])
    MCL_mainFrame.title:SetTextColor(0.4, 0.78, 0.95, 1)
    
    -- Helper: consistent title bar button styling
    local TBAR_BTN_HEIGHT = 18
    local TBAR_BTN_PADDING = 5
    
    local function CreateHeaderButton(parent, width, labelText, tooltipTitle, tooltipBody, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(width, TBAR_BTN_HEIGHT)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        btn:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
        btn:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        btn.text:SetPoint("CENTER", 0, 0)
        btn.text:SetText(labelText)
        btn.text:SetTextColor(0.65, 0.75, 0.85, 1)
        
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.18, 0.22, 0.3, 1)
            self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
            self.text:SetTextColor(0.5, 0.85, 1, 1)
            if tooltipTitle then
                GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
                GameTooltip:SetText(tooltipTitle, 1, 1, 1)
                if tooltipBody then
                    GameTooltip:AddLine(tooltipBody, 0.7, 0.7, 0.7, true)
                end
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
            self:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
            self.text:SetTextColor(0.65, 0.75, 0.85, 1)
            GameTooltip:Hide()
        end)
        btn:SetScript("OnClick", onClick)
        
        return btn
    end
    
    -- Close button (X) - rightmost
    MCL_mainFrame.customClose = CreateHeaderButton(
        MCL_mainFrame.headerBar, 22, "X",
        nil, nil,
        function() MCL_mainFrame:Hide() end
    )
    MCL_mainFrame.customClose:SetPoint("RIGHT", MCL_mainFrame.headerBar, "RIGHT", -TBAR_BTN_PADDING, 0)
    -- Make close button red on hover
    MCL_mainFrame.customClose:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.6, 0.1, 0.1, 1)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    MCL_mainFrame.customClose:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
        self.text:SetTextColor(0.65, 0.75, 0.85, 1)
    end)
    
    -- Refresh button
    MCL_mainFrame.refresh = CreateHeaderButton(
        MCL_mainFrame.headerBar, 22, "",
        L["Refresh Layout"], L["Refreshes the mount collection display"],
        function()
            if MCL_frames and MCL_frames.RefreshLayout then
                MCL_frames:RefreshLayout()
            end
        end
    )
    MCL_mainFrame.refresh:SetPoint("RIGHT", MCL_mainFrame.customClose, "LEFT", -3, 0)
    -- Use refresh icon instead of text
    MCL_mainFrame.refresh.text:Hide()
    MCL_mainFrame.refresh.icon = MCL_mainFrame.refresh:CreateTexture(nil, "OVERLAY")
    MCL_mainFrame.refresh.icon:SetSize(12, 12)
    MCL_mainFrame.refresh.icon:SetPoint("CENTER", 0, 0)
    MCL_mainFrame.refresh.icon:SetTexture("Interface\\Buttons\\UI-RefreshButton")
    MCL_mainFrame.refresh.icon:SetVertexColor(0.65, 0.75, 0.85, 1)
    -- Override hover to also tint the icon
    MCL_mainFrame.refresh:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.22, 0.3, 1)
        self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
        self.icon:SetVertexColor(0.5, 0.85, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L["Refresh Layout"], 1, 1, 1)
        GameTooltip:AddLine(L["Refreshes the mount collection display"], 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    MCL_mainFrame.refresh:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
        self.icon:SetVertexColor(0.65, 0.75, 0.85, 1)
        GameTooltip:Hide()
    end)
    
    -- SA button
    MCL_mainFrame.sa = CreateHeaderButton(
        MCL_mainFrame.headerBar, 30, "SA",
        L["Simple Armory"] or "Simple Armory",
        L["Copy your Simple Armory profile link"] or "Copy your Simple Armory profile link",
        function()
            if MCLcore.Function and MCLcore.Function.simplearmoryLink then
                MCLcore.Function:simplearmoryLink()
            end
        end
    )
    MCL_mainFrame.sa:SetPoint("RIGHT", MCL_mainFrame.refresh, "LEFT", -3, 0)
    
    -- DFA button
    MCL_mainFrame.dfa = CreateHeaderButton(
        MCL_mainFrame.headerBar, 30, "DFA",
        L["Data for Azeroth"] or "Data for Azeroth",
        L["Copy your Data for Azeroth profile link"] or "Copy your Data for Azeroth profile link",
        function()
            if MCLcore.Function and MCLcore.Function.dfaLink then
                MCLcore.Function:dfaLink()
            end
        end
    )
    MCL_mainFrame.dfa:SetPoint("RIGHT", MCL_mainFrame.sa, "LEFT", -3, 0)

    -- Report button (bug icon)
    MCL_mainFrame.report = CreateHeaderButton(
        MCL_mainFrame.headerBar, 22, "",
        "Report Issue",
        "Report a missing or incorrect mount",
        function()
            if MCLcore.Function and MCLcore.Function.reportLink then
                MCLcore.Function:reportLink()
            end
        end
    )
    MCL_mainFrame.report:SetPoint("RIGHT", MCL_mainFrame.dfa, "LEFT", -3, 0)
    -- Use bug icon instead of text
    MCL_mainFrame.report.text:Hide()
    MCL_mainFrame.report.icon = MCL_mainFrame.report:CreateTexture(nil, "OVERLAY")
    MCL_mainFrame.report.icon:SetSize(12, 12)
    MCL_mainFrame.report.icon:SetPoint("CENTER", 0, 0)
    MCL_mainFrame.report.icon:SetTexture("Interface\\HELPFRAME\\HelpIcon-Bug")
    MCL_mainFrame.report.icon:SetVertexColor(0.9, 0.4, 0.4, 1)
    -- Override hover to also tint the icon
    MCL_mainFrame.report:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.22, 0.3, 1)
        self:SetBackdropBorderColor(0.9, 0.3, 0.3, 1)
        self.icon:SetVertexColor(1, 0.5, 0.5, 1)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText("Report Issue", 1, 1, 1)
        GameTooltip:AddLine("Report a missing or incorrect mount", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)
    MCL_mainFrame.report:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.12, 0.12, 0.16, 0.9)
        self:SetBackdropBorderColor(0.3, 0.3, 0.35, 0.8)
        self.icon:SetVertexColor(0.9, 0.4, 0.4, 1)
        GameTooltip:Hide()
    end)


	--MCL Frame settings
	MCL_mainFrame:SetSize(main_frame_width, main_frame_height); -- width, height
	MCL_mainFrame:ClearAllPoints()
	MCL_mainFrame:SetPoint("CENTER", UIParent, "CENTER"); -- point, relativeFrame, relativePoint, xOffset, yOffset
	MCL_mainFrame:Show()
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
    
    -- Scroll Frame for Main Window
	MCL_mainFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, MCL_mainFrame, "MinimalScrollFrameTemplate");
	-- Anchor scroll frame to the main frame, not Bg
    MCL_mainFrame.ScrollFrame:ClearAllPoints()
    MCL_mainFrame.ScrollFrame:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 10, -40)
    MCL_mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", MCL_mainFrame, "BOTTOMRIGHT", -18, 10)
	MCL_mainFrame.ScrollFrame:SetClipsChildren(true);
	MCL_mainFrame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	MCL_mainFrame.ScrollFrame:EnableMouse(true)
    
	-- Slim scrollbar positioned outside the scroll frame viewport
	MCL_mainFrame.ScrollFrame.ScrollBar:ClearAllPoints();
	MCL_mainFrame.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", MCL_mainFrame.ScrollFrame, "TOPRIGHT", 2, -2);
	MCL_mainFrame.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", MCL_mainFrame.ScrollFrame, "BOTTOMRIGHT", 6, 2);
	MCL_mainFrame.ScrollFrame.ScrollBar:SetWidth(4)

	-- Style the scrollbar thumb to be a slim house-style bar
	local scrollThumb = MCL_mainFrame.ScrollFrame.ScrollBar:GetThumbTexture()
	if scrollThumb then
		scrollThumb:SetColorTexture(0.25, 0.3, 0.4, 0.7)
		scrollThumb:SetWidth(4)
		scrollThumb:SetHeight(40)
	end
	-- Hide the up/down scroll buttons for a clean look
	local scrollUp = MCL_mainFrame.ScrollFrame.ScrollBar.ScrollUpButton or MCL_mainFrame.ScrollFrame.ScrollBar.Back
	local scrollDown = MCL_mainFrame.ScrollFrame.ScrollBar.ScrollDownButton or MCL_mainFrame.ScrollFrame.ScrollBar.Forward
	if scrollUp then scrollUp:SetAlpha(0); scrollUp:SetSize(1,1) end
	if scrollDown then scrollDown:SetAlpha(0); scrollDown:SetSize(1,1) end

    -- Create and assign a dedicated scroll child frame
    if not MCL_mainFrame.ScrollChild then
        MCL_mainFrame.ScrollChild = CreateFrame("Frame", nil, MCL_mainFrame.ScrollFrame)
        MCL_mainFrame.ScrollChild:SetSize(main_frame_width - 20, main_frame_height)
        MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
    end

	MCL_mainFrame:SetFrameStrata("HIGH")

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
        -- Hide search dropdown when main frame closes
        if MCLcore.Search and MCLcore.Search.HideSearchDropdown then
            MCLcore.Search:HideSearchDropdown()
        end
        -- Hide mount card when main frame closes
        if MCL_MountCard and MCL_MountCard:IsShown() then
            MCL_MountCard:Hide()
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

    local tabFrame = MCLcore.MCL_MF_Nav

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
            -- Properly release content frame children before discarding
            if tab.content then
                ReleaseFrameChildren(tab.content)
                tab.content:Hide()
                -- Don't orphan the overview frame — it's reused across SetTabs calls
                if tab.content ~= MCLcore.overview then
                    tab.content:ClearAllPoints()
                    tab.content:SetParent(nil)
                end
                tab.content = nil
            end
            tab:Hide()
            tab:ClearAllPoints()
            tab:SetScript("OnClick", nil)
            tab:SetParent(nil)
        end
    end
    tabFrame.tabs = {}
    MCLcore.sectionFrames = {}
    -- Reset status bar tracking since content frames are being rebuilt
    MCLcore.statusBarFrames = {}

    local navYOffset = -66  -- Below header (30) + search bar (26) + spacing (10)
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
            t:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
            t:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
            if t.text then t.text:SetTextColor(0.7, 0.78, 0.88, 1) end
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
        
        -- Hide search dropdown when switching tabs
        if MCLcore.Search then
            MCLcore.Search:HideSearchDropdown()
            MCLcore.Search.isSearchActive = false
            MCLcore.Search.searchResults = {}
            if MCLcore.Search.ClearHighlighting then
                MCLcore.Search:ClearHighlighting()
            end
            -- Clear search box text
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
        end
        
        tab:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
        tab:SetBackdropColor(0.15, 0.18, 0.25, 1)
        if tab.text then tab.text:SetTextColor(0.5, 0.85, 1, 1) end
        
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
        if tab.content then
            -- Re-anchor the overview frame with current dimensions
            tab.content:ClearAllPoints()
            tab.content:SetParent(MCL_mainFrame.ScrollChild)
            local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
            tab.content:SetSize(currentWidth - 40, 550)
            tab.content:SetPoint("TOPLEFT", MCL_mainFrame.ScrollChild, "TOPLEFT", 10, 0)
            tab.content:Hide()
        end
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
        -- Green checkmark for completed sections
        local btnStats = MCLcore.stats and MCLcore.stats[v.name]
        if btnStats and btnStats.collected and btnStats.total and btnStats.collected >= btnStats.total and btnStats.total > 0 then
            btn.checkmark = btn:CreateTexture(nil, "OVERLAY")
            btn.checkmark:SetSize(14, 14)
            btn.checkmark:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 3, -3)
            btn.checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        end
        -- Add tooltip with name and mount count on hover
        btn:SetScript("OnEnter", function(self)
            -- Only highlight if not the selected tab
            if MCLcore.currentlySelectedTab ~= self then
                self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
                self:SetBackdropColor(0.15, 0.18, 0.25, 1)
            end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local sectionStats = MCLcore.stats and MCLcore.stats[v.name]
            if sectionStats and sectionStats.collected and sectionStats.total then
                GameTooltip:SetText((L[v.name] or v.name) .. string.format(" (%d/%d)", sectionStats.collected, sectionStats.total), 1, 1, 1)
            else
                GameTooltip:SetText(L[v.name] or v.name, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
            if MCLcore.currentlySelectedTab ~= self then
                self:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
                self:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
            end
            GameTooltip:Hide()
        end)
        btn.content = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, v.name, v.icon)
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
        local displayName = L[v.name] or v.name
        tab.text:SetText(displayName)
        -- Right-aligned checkmark slot (always reserved for alignment)
        tab.checkmark = tab:CreateTexture(nil, "OVERLAY")
        tab.checkmark:SetSize(12, 12)
        tab.checkmark:SetPoint("RIGHT", tab, "RIGHT", -6, 0)
        tab.checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        tab.checkmark:Hide()  -- hidden by default, shown when section is complete

        -- Right-aligned count (always offset to leave room for checkmark)
        tab.countText = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tab.countText:SetPoint("RIGHT", tab.checkmark, "LEFT", -2, 0)
        tab.countText:SetTextColor(0.5, 0.55, 0.65, 1)
        local sectionStats = MCLcore.stats and MCLcore.stats[v.name]
        if sectionStats and sectionStats.collected and sectionStats.total then
            tab.countText:SetText(string.format("%d/%d", sectionStats.collected, sectionStats.total))
            -- Show checkmark for completed sections
            if sectionStats.collected >= sectionStats.total and sectionStats.total > 0 then
                tab.checkmark:Show()
            end
        end
        tab.section = v
        tab.content = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, v.name, v.icon)
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
        local pinnedLabel = L[pinnedSection.name] or pinnedSection.name
        tab.text:SetText(pinnedLabel)
        -- Right-aligned checkmark slot (reserved for alignment with other tabs)
        tab.checkmark = tab:CreateTexture(nil, "OVERLAY")
        tab.checkmark:SetSize(12, 12)
        tab.checkmark:SetPoint("RIGHT", tab, "RIGHT", -6, 0)
        tab.checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        tab.checkmark:Hide()

        -- Right-aligned count (offset to match other tabs)
        tab.countText = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        tab.countText:SetPoint("RIGHT", tab.checkmark, "LEFT", -2, 0)
        tab.countText:SetTextColor(0.5, 0.55, 0.65, 1)
        local pinnedCount = MCL_PINNED and #MCL_PINNED or 0
        if pinnedCount > 0 then
            tab.countText:SetText(tostring(pinnedCount))
        end
        tab.section = pinnedSection
        tab.content = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, pinnedSection.name, pinnedSection.icon)
                
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
        tab.section = {name = "Settings"}
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

    -- 8. About tab
    do
        local tab = CreateFrame("Button", nil, tabFrame, "BackdropTemplate")
        tab:SetSize(nav_width + 8, 32)
        tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 1, navYOffset)
        StyleNavButton(tab, false)
        tab.text = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tab.text:SetPoint("LEFT", 10, 0)
        tab.text:SetText("About")
        tab.section = {name = "About"}
        tab.content = MCLcore.Frames:createAboutFrame(MCL_mainFrame.ScrollChild)
        tab.content:Hide()
        tab:SetScript("OnClick", function(self)
            SelectTab(self)
        end)
        tab:EnableMouse(true)
        tab:SetFrameStrata("HIGH")
        tab:SetFrameLevel(100)
        tab:Show()
        table.insert(tabFrame.tabs, tab)
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
    local frame = CreateFrame("Frame", "Nav", relativeFrame, "BackdropTemplate");
    frame:SetWidth(nav_width + 10)
    
    -- Set height to match current main frame height
    local _, currentHeight = MCL_frames:GetCurrentFrameDimensions()
    frame:SetHeight(currentHeight)
    
    frame:ClearAllPoints()
    frame:SetPoint("TOPRIGHT", relativeFrame, "TOPLEFT", 1, 0)
    
    -- Apply backdrop styling (same for both themes)
    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        frame:SetBackdropColor(0.06, 0.06, 0.09, MCL_SETTINGS.opacity)
        frame:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
    end
    
    -- Header bar (matches main frame header exactly)
    frame.headerBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.headerBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.headerBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 1, 0)  -- extend 1px right to cover main frame left border
    frame.headerBar:SetHeight(30)
    frame.headerBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
    })
    frame.headerBar:SetBackdropColor(0.08, 0.08, 0.12, MCL_SETTINGS.opacity)
    frame.headerBar:SetFrameLevel(frame:GetFrameLevel() + 5)  -- above main frame's borderFrame
    
    frame.title = frame.headerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("CENTER", frame.headerBar, "CENTER", 0, 0)
    frame.title:SetText(title or "")
    frame.title:SetTextColor(0.4, 0.78, 0.95, 1)
    
    -- Accent line at bottom of header (same alpha as main header: 0.6)
    frame.titleAccent = frame.headerBar:CreateTexture(nil, "OVERLAY")
    frame.titleAccent:SetHeight(1)
    frame.titleAccent:SetPoint("BOTTOMLEFT", frame.headerBar, "BOTTOMLEFT", 0, 0)
    frame.titleAccent:SetPoint("BOTTOMRIGHT", frame.headerBar, "BOTTOMRIGHT", 0, 0)
    frame.titleAccent:SetColorTexture(0.2, 0.6, 0.9, 0.6)
    
    -- Create search bar (flush with nav frame inner border)
    frame.searchContainer = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    frame.searchContainer:SetHeight(26)
    frame.searchContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 1, -37)
    frame.searchContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -1, -37)
    frame.searchContainer:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    frame.searchContainer:SetBackdropColor(0.1, 0.1, 0.14, 0.95)
    frame.searchContainer:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)

    -- Search icon (magnifying glass)
    frame.searchIcon = frame.searchContainer:CreateTexture(nil, "OVERLAY")
    frame.searchIcon:SetSize(14, 14)
    frame.searchIcon:SetPoint("LEFT", frame.searchContainer, "LEFT", 6, 0)
    frame.searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")
    frame.searchIcon:SetVertexColor(0.5, 0.5, 0.5, 0.8)

    -- Create search editbox (shifted right for icon)
    frame.searchBox = CreateFrame("EditBox", nil, frame.searchContainer)
    frame.searchBox:SetHeight(20)
    frame.searchBox:SetPoint("LEFT", frame.searchIcon, "RIGHT", 3, 0)
    frame.searchBox:SetPoint("RIGHT", frame.searchContainer, "RIGHT", -6, 0)
    frame.searchBox:SetFontObject("GameFontHighlightSmall")
    frame.searchBox:SetTextColor(1, 1, 1, 1)
    frame.searchBox:SetAutoFocus(false)
    frame.searchBox:SetMaxLetters(50)
    frame.searchBox:EnableMouse(true)
    frame.searchBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        -- Cancel any pending debounce and search immediately
        if self.searchTimer then
            self.searchTimer:Cancel()
            self.searchTimer = nil
        end
        MCLcore.Search:PerformSearch(self:GetText())
    end)
    frame.searchBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText("")
        if self.searchTimer then
            self.searchTimer:Cancel()
            self.searchTimer = nil
        end
        MCLcore.Search:ClearSearch()
        if frame.searchPlaceholder then frame.searchPlaceholder:Show() end
    end)
    frame.searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local text = self:GetText()
            -- Cancel any pending debounce timer
            if self.searchTimer then
                self.searchTimer:Cancel()
                self.searchTimer = nil
            end
            if text == "" then
                MCLcore.Search:HideSearchDropdown()
                MCLcore.Search.isSearchActive = false
                MCLcore.Search.searchResults = {}
                if frame.searchPlaceholder then frame.searchPlaceholder:Show() end
            elseif #text >= 2 then
                -- Debounce: wait 0.3s after last keystroke before searching
                self.searchTimer = C_Timer.NewTimer(0.3, function()
                    self.searchTimer = nil
                    MCLcore.Search:PerformSearch(text)
                end)
            else
                -- 1 character: hide dropdown but keep typing
                MCLcore.Search:HideSearchDropdown()
            end
        end
    end)

    -- Create search placeholder text (positioned after icon)
    frame.searchPlaceholder = frame.searchContainer:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    frame.searchPlaceholder:SetPoint("LEFT", frame.searchIcon, "RIGHT", 5, 0)
    frame.searchPlaceholder:SetText(L["Search mounts..."])
    frame.searchPlaceholder:SetTextColor(0.45, 0.45, 0.45, 0.8)

    -- Show/hide placeholder based on editbox focus and content, plus glow effect
    frame.searchBox:SetScript("OnEditFocusGained", function(self)
        frame.searchPlaceholder:Hide()
        frame.searchContainer:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
        frame.searchIcon:SetVertexColor(0.4, 0.78, 0.95, 1)
    end)
    frame.searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            frame.searchPlaceholder:Show()
        end
        frame.searchContainer:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
        frame.searchIcon:SetVertexColor(0.5, 0.5, 0.5, 0.8)
    end)
    
    -- Create clear search button
    frame.clearButton = CreateFrame("Button", nil, frame.searchContainer)
    frame.clearButton:SetSize(16, 16)
    frame.clearButton:SetPoint("RIGHT", frame.searchContainer, "RIGHT", -3, 0)
    frame.clearButton:SetNormalTexture("Interface\\FriendsFrame\\ClearBroadcastIcon")
    frame.clearButton:SetScript("OnClick", function()
        frame.searchBox:SetText("")
        frame.searchBox:ClearFocus()
        MCLcore.Search:ClearSearch()
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

function MCL_frames:createContentFrame(relativeFrame, title, sectionIcon)
    -- Calculate dynamic width based on current main frame width
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 40  -- Symmetric padding within scroll viewport
    
    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)  -- Use current available width
    frame:SetHeight(50)  -- Increased height to accommodate title padding
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 10, 0)  -- Centered in scroll viewport
    
    -- Set opaque background for search results to prevent bleed-through
    if title == "Search Results" then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        frame:SetBackdropColor(0.06, 0.06, 0.09, 1)
        frame:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
    else
        frame:SetBackdropColor(0, 0, 0, 0)  -- Transparent background for other content
    end
    
    -- Title text (placed first so icon can anchor to it)
    local titleAnchorX = 0
    if sectionIcon then
        titleAnchorX = 24  -- Shift title right to accommodate icon
    end
    
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", titleAnchorX, -10)
    frame.title:SetText(L[title]) -- Localized for display
    frame.title:SetTextColor(0.4, 0.78, 0.95, 1)  -- House style blue
    
    -- Section icon (anchored to title for vertical centering)
    if sectionIcon then
        frame.sectionIcon = frame:CreateTexture(nil, "ARTWORK")
        frame.sectionIcon:SetSize(20, 20)
        frame.sectionIcon:SetPoint("RIGHT", frame.title, "LEFT", -4, 0)
        frame.sectionIcon:SetTexture(sectionIcon)
    end
    frame.name = title -- Store non-localized name

    -- Add pin instructions for all sections except Overview
    if title == "Pinned" then
        local instructionsFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
        instructionsFrame:SetSize(availableWidth - 30, 20)  -- Smaller height for compact display
        instructionsFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)  -- Position below title
        instructionsFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        instructionsFrame:SetBackdropColor(0.08, 0.08, 0.14, 0.6)
        instructionsFrame:SetBackdropBorderColor(0.2, 0.4, 0.7, 0.6)
        
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

    -- Add sort control and filter toggle for category-based sections (not Overview, Pinned, or Settings)
    if title ~= "Overview" and title ~= "Pinned" and title ~= "Settings" then
        if not MCL_SETTINGS.mountSortMode then
            MCL_SETTINGS.mountSortMode = "default"
        end

        -- Sort label (rightmost)
        local sortLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sortLabel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -15, -10)
        sortLabel:SetText("Sort:")
        sortLabel:SetTextColor(0.5, 0.55, 0.65, 1)

        local sortBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        sortBtn:SetSize(120, 20)
        sortBtn:SetPoint("RIGHT", sortLabel, "LEFT", -4, 0)
        sortBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        sortBtn:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
        sortBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)

        sortBtn.text = sortBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sortBtn.text:SetPoint("CENTER")
        -- Find current label
        local currentLabel = "Default"
        for _, m in ipairs(SORT_MODES) do
            if m.key == MCL_SETTINGS.mountSortMode then
                currentLabel = m.label
                break
            end
        end
        sortBtn.text:SetText(currentLabel)
        sortBtn.text:SetTextColor(0.7, 0.78, 0.88, 1)

        sortBtn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
            self:SetBackdropColor(0.15, 0.18, 0.25, 0.9)
        end)
        sortBtn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
            self:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
        end)
        sortBtn:SetScript("OnClick", function(self)
            -- Cycle to next sort mode
            local curIdx = 1
            for i, m in ipairs(SORT_MODES) do
                if m.key == MCL_SETTINGS.mountSortMode then
                    curIdx = i
                    break
                end
            end
            curIdx = (curIdx % #SORT_MODES) + 1
            MCL_SETTINGS.mountSortMode = SORT_MODES[curIdx].key
            self.text:SetText(SORT_MODES[curIdx].label)
            -- Refresh the entire layout to re-sort
            C_Timer.After(0.05, function()
                if MCLcore.Frames and MCLcore.Frames.RefreshLayout then
                    MCLcore.Frames:RefreshLayout()
                end
            end)
        end)

        -- Filter collected toggle button (to the left of the sort button)
        local filterBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
        filterBtn:SetSize(130, 20)
        filterBtn:SetPoint("RIGHT", sortBtn, "LEFT", -12, 0)
        filterBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        filterBtn:SetBackdropColor(0.1, 0.1, 0.14, 0.9)

        local function updateFilterBtnState(btn)
            if MCL_SETTINGS.hideCollectedMounts then
                btn:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
                btn.text:SetText("Uncollected Only")
                btn.text:SetTextColor(0.5, 0.85, 1, 1)
            else
                btn:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
                btn.text:SetText("Show All")
                btn.text:SetTextColor(0.7, 0.78, 0.88, 1)
            end
        end

        filterBtn.text = filterBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        filterBtn.text:SetPoint("CENTER")
        updateFilterBtnState(filterBtn)

        filterBtn:SetScript("OnEnter", function(self)
            if not MCL_SETTINGS.hideCollectedMounts then
                self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
            end
            self:SetBackdropColor(0.15, 0.18, 0.25, 0.9)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Filter Collected", 1, 1, 1)
            if MCL_SETTINGS.hideCollectedMounts then
                GameTooltip:AddLine("Currently hiding collected mounts.\nClick to show all mounts.", 0.7, 0.7, 0.7, true)
            else
                GameTooltip:AddLine("Currently showing all mounts.\nClick to hide collected mounts.", 0.7, 0.7, 0.7, true)
            end
            GameTooltip:Show()
        end)
        filterBtn:SetScript("OnLeave", function(self)
            if not MCL_SETTINGS.hideCollectedMounts then
                self:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
            end
            self:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
            GameTooltip:Hide()
        end)
        filterBtn:SetScript("OnClick", function(self)
            MCL_SETTINGS.hideCollectedMounts = not MCL_SETTINGS.hideCollectedMounts
            updateFilterBtnState(self)
            C_Timer.After(0.05, function()
                if MCLcore.Frames and MCLcore.Frames.RefreshLayout then
                    MCLcore.Frames:RefreshLayout()
                end
            end)
        end)
    end

    return frame
end

-- ========================================================
-- Zone Drops  –  shows farmable mounts in the player's
--                current zone, powered by MCL_Guide data
-- ========================================================
function MCL_frames:createZoneDropsFrame(relativeFrame)
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth   = currentWidth - 40

    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)
    frame:SetHeight(50)
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 10, 0)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame.name = "Current Zone"

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -10)
    frame.title:SetText(L["Current Zone"] or "Current Zone")
    frame.title:SetTextColor(0.4, 0.78, 0.95, 1)

    -- Map icon next to title
    frame.mapIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.mapIcon:SetSize(20, 20)
    frame.mapIcon:SetPoint("RIGHT", frame.title, "LEFT", -4, 0)
    frame.mapIcon:SetTexture("Interface\\Minimap\\Tracking\\None")

    -- Sub-title showing current zone name (updated on refresh)
    frame.zoneLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.zoneLabel:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.zoneLabel:SetTextColor(0.6, 0.65, 0.75, 1)

    -- Container for mount rows (will be cleared/rebuilt on refresh)
    frame.mountContainer = CreateFrame("Frame", nil, frame)
    frame.mountContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -55)
    frame.mountContainer:SetWidth(availableWidth)
    frame.mountContainer:SetHeight(1) -- grows dynamically

    -- Store reference for refresh
    MCLcore._zoneDropsFrame = frame

    -- Register for zone changes so we can auto-refresh when visible
    local zoneWatcher = CreateFrame("Frame")
    zoneWatcher:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    zoneWatcher:RegisterEvent("ZONE_CHANGED")
    zoneWatcher:RegisterEvent("ZONE_CHANGED_INDOORS")
    zoneWatcher:SetScript("OnEvent", function()
        if frame:IsVisible() and MCLcore.Frames.RefreshZoneDrops then
            MCLcore.Frames:RefreshZoneDrops()
        end
    end)

    return frame
end

-- --------------------------------------------------------
-- Refresh / rebuild the zone drops mount list
-- --------------------------------------------------------
function MCL_frames:RefreshZoneDrops()
    local frame = MCLcore._zoneDropsFrame
    if not frame then return end

    local container = frame.mountContainer
    -- Clear old rows
    if container.rows then
        for _, row in ipairs(container.rows) do
            row:Hide()
            row:SetParent(nil)
        end
    end
    container.rows = {}

    -- Current map
    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = mapID and C_Map.GetMapInfo(mapID)
    local zoneName = mapInfo and mapInfo.name or "Unknown"
    frame.zoneLabel:SetText(zoneName)

    -- Look up mounts for this map
    local guideZones = MCL_GUIDE and MCL_GUIDE.zoneMounts
    local spellIds = guideZones and guideZones[mapID]
    if not spellIds or #spellIds == 0 then
        -- Also try the parent map (continent->zone hierarchy)
        if mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 then
            spellIds = guideZones and guideZones[mapInfo.parentMapID]
        end
    end

    if not spellIds or #spellIds == 0 then
        -- Show "no mounts" message
        local noData = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noData:SetPoint("TOPLEFT", container, "TOPLEFT", 15, 0)
        noData:SetText(L["No drop mounts found for this zone."] or "No drop mounts found for this zone.")
        noData:SetTextColor(0.5, 0.55, 0.65, 1)
        local dummyRow = CreateFrame("Frame", nil, container)
        dummyRow:SetSize(1, 30)
        dummyRow.fontStr = noData
        table.insert(container.rows, dummyRow)
        frame:SetHeight(100)
        return
    end

    -- Sort by drop chance (rarest first) — higher chance number = rarer
    local guideLookup = MCL_GUIDE and MCL_GUIDE.mountLookup or {}
    local sorted = {}
    for _, sid in ipairs(spellIds) do
        local info = guideLookup[sid]
        if info then
            table.insert(sorted, info)
        end
    end
    table.sort(sorted, function(a, b)
        return (a.chance or 0) > (b.chance or 0)
    end)

    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local rowWidth = currentWidth - 70
    local yOffset = 0
    local uncollectedCount = 0
    local collectedCount = 0

    for _, info in ipairs(sorted) do
        local mountID = info.mountID
        if not mountID then
            -- skip mounts we can't resolve
        else
            local mountName, spellID, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            if mountName then
                -- Apply hide-collected filter
                local show = true
                if MCL_SETTINGS.hideCollectedMounts and isCollected then
                    show = false
                end

                if isCollected then
                    collectedCount = collectedCount + 1
                else
                    uncollectedCount = uncollectedCount + 1
                end

                if show then
                    local row = CreateFrame("Button", nil, container, "BackdropTemplate")
                    row:SetSize(rowWidth, 44)
                    row:SetPoint("TOPLEFT", container, "TOPLEFT", 10, yOffset)
                    row:SetBackdrop({
                        bgFile   = "Interface\\Buttons\\WHITE8x8",
                        edgeFile = "Interface\\Buttons\\WHITE8x8",
                        edgeSize = 1,
                    })

                    if isCollected then
                        row:SetBackdropColor(0.04, 0.14, 0.04, 0.6)
                        row:SetBackdropBorderColor(0.1, 0.4, 0.1, 0.5)
                    else
                        row:SetBackdropColor(0.08, 0.08, 0.14, 0.8)
                        row:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
                    end

                    -- Mount icon
                    row.icon = row:CreateTexture(nil, "ARTWORK")
                    row.icon:SetSize(32, 32)
                    row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
                    row.icon:SetTexture(icon)
                    if not isCollected then
                        row.icon:SetVertexColor(0.7, 0.7, 0.7, 0.9)
                    end

                    -- Collected check
                    if isCollected then
                        row.check = row:CreateTexture(nil, "OVERLAY")
                        row.check:SetSize(14, 14)
                        row.check:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 2, -2)
                        row.check:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                    end

                    -- Mount name
                    row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                    row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 8, 4)
                    row.nameText:SetText(mountName)
                    if isCollected then
                        row.nameText:SetTextColor(0.3, 0.9, 0.3, 1)
                    else
                        row.nameText:SetTextColor(0.95, 0.95, 1, 1)
                    end

                    -- Source method
                    row.sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    row.sourceText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -1)
                    local methodText = (MCL_GUIDE and MCL_GUIDE.GetMethodText) and MCL_GUIDE:GetMethodText(info.method) or info.method or "Unknown"
                    row.sourceText:SetText(methodText)
                    row.sourceText:SetTextColor(0.4, 0.65, 0.85, 1)

                    -- Drop rate (right side)
                    if info.chance and info.chance > 0 then
                        local pct = 100 / info.chance
                        local r, g, b
                        if pct >= 10 then
                            r, g, b = 0.3, 0.9, 0.3
                        elseif pct >= 1 then
                            r, g, b = 1, 0.85, 0.2
                        elseif pct >= 0.1 then
                            r, g, b = 1, 0.5, 0.15
                        else
                            r, g, b = 1, 0.25, 0.25
                        end
                        row.chanceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        row.chanceText:SetPoint("RIGHT", row, "RIGHT", -10, 4)
                        local pctStr = pct >= 1 and string.format("%d", pct) or (pct >= 0.1 and string.format("%.1f", pct) or string.format("%.2f", pct))
                        row.chanceText:SetText(string.format("1/%d (%s%%)", info.chance, pctStr))
                        row.chanceText:SetTextColor(r, g, b, 1)
                    end

                    -- NPC / Boss name below chance
                    local npcName = info.lockBossName or (info.coords and info.coords[1] and info.coords[1].n)
                    if npcName then
                        row.npcText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                        row.npcText:SetPoint("TOPRIGHT", row.chanceText or row, row.chanceText and "BOTTOMRIGHT" or "RIGHT", 0, row.chanceText and -1 or -4)
                        row.npcText:SetText(npcName)
                        row.npcText:SetTextColor(0.6, 0.6, 0.7, 1)
                    end

                    -- Waypoint button if coords available for this map
                    if info.coords then
                        local bestCoord
                        for _, c in ipairs(info.coords) do
                            if c.m == mapID then
                                bestCoord = c
                                break
                            end
                        end
                        if bestCoord and bestCoord.x and bestCoord.y then
                            row.wpBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
                            row.wpBtn:SetSize(60, 16)
                            row.wpBtn:SetPoint("RIGHT", row, "RIGHT", -10, -12)
                            row.wpBtn:SetBackdrop({
                                bgFile   = "Interface\\Buttons\\WHITE8x8",
                                edgeFile = "Interface\\Buttons\\WHITE8x8",
                                edgeSize = 1,
                            })
                            row.wpBtn:SetBackdropColor(0.12, 0.12, 0.2, 0.9)
                            row.wpBtn:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
                            row.wpBtn.label = row.wpBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            row.wpBtn.label:SetPoint("CENTER")
                            row.wpBtn.label:SetText(L["Waypoint"] or "Waypoint")
                            row.wpBtn.label:SetTextColor(0.4, 0.78, 0.95, 1)
                            row.wpBtn:SetScript("OnClick", function(self)
                                local wx, wy = bestCoord.x / 100, bestCoord.y / 100
                                if TomTom and TomTom.AddWaypoint then
                                    TomTom:AddWaypoint(bestCoord.m, wx, wy, { title = mountName })
                                else
                                    local point = UiMapPoint.CreateFromCoordinates(bestCoord.m, wx, wy)
                                    C_Map.SetUserWaypoint(point)
                                    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                                end
                                -- Open map to target zone
                                OpenWorldMap(bestCoord.m)
                                self.label:SetText("Set!")
                                self.label:SetTextColor(0.3, 0.9, 0.3, 1)
                                C_Timer.After(1.5, function()
                                    if self.label then
                                        self.label:SetText(L["Waypoint"] or "Waypoint")
                                        self.label:SetTextColor(0.4, 0.78, 0.95, 1)
                                    end
                                end)
                            end)
                            row.wpBtn:SetScript("OnEnter", function(self)
                                self:SetBackdropBorderColor(0.5, 0.8, 1, 1)
                                self:SetBackdropColor(0.18, 0.18, 0.28, 1)
                            end)
                            row.wpBtn:SetScript("OnLeave", function(self)
                                self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
                                self:SetBackdropColor(0.12, 0.12, 0.2, 0.9)
                            end)
                        end
                    end

                    -- Hover effects
                    row:SetScript("OnEnter", function(self)
                        self:SetBackdropColor(0.14, 0.14, 0.22, 1)
                        self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
                        -- Show tooltip
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        if spellID then
                            GameTooltip:SetSpellByID(spellID)
                        end
                        GameTooltip:Show()
                        -- Show MountCard on hover
                        if MCLcore and MCLcore.MountCard and MCL_SETTINGS.enableMountCardHover then
                            local mountData = {
                                mountID = mountID,
                                id = mountID,
                                name = mountName,
                                category = "Current Zone",
                                section = zoneName
                            }
                            MCLcore.MountCard.ShowOnHover(mountData, self, 0.2)
                        end
                    end)
                    row:SetScript("OnLeave", function(self)
                        if isCollected then
                            self:SetBackdropColor(0.04, 0.14, 0.04, 0.6)
                            self:SetBackdropBorderColor(0.1, 0.4, 0.1, 0.5)
                        else
                            self:SetBackdropColor(0.08, 0.08, 0.14, 0.8)
                            self:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
                        end
                        GameTooltip:Hide()
                    end)
                    row:SetScript("OnClick", function(self, button)
                        if button == "RightButton" then
                            if MCLcore and MCLcore.MountCard then
                                local mountData = {
                                    mountID = mountID,
                                    id = mountID,
                                    name = mountName,
                                    category = "Current Zone",
                                    section = zoneName
                                }
                                MCLcore.MountCard.Toggle(mountData, self)
                            end
                        elseif button == "MiddleButton" then
                            if isCollected then
                                CastSpellByName(mountName)
                            end
                        end
                    end)
                    row:RegisterForClicks("AnyUp")

                    table.insert(container.rows, row)
                    yOffset = yOffset - 50
                end
            end
        end
    end

    -- Summary line
    local totalInZone = uncollectedCount + collectedCount
    if totalInZone > 0 then
        frame.zoneLabel:SetText(string.format("%s  —  %d/%d " .. (L["collected"] or "collected"),
            zoneName, collectedCount, totalInZone))
    end

    -- Adjust frame height to fit all rows
    local totalHeight = math.abs(yOffset) + 70
    frame:SetHeight(math.max(totalHeight, 100))
    container:SetHeight(math.abs(yOffset) + 10)
end

-- ============================================================
-- Reputation / Renown filter tab
-- ============================================================
function MCL_frames:createRepFilterFrame(relativeFrame)
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth   = currentWidth - 40

    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)
    frame:SetHeight(50)
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 10, 0)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame.name = "Reputation"

    -- Title
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -10)
    frame.title:SetText("Reputation Mounts")
    frame.title:SetTextColor(0.4, 0.78, 0.95, 1)

    -- Reputation icon next to title
    frame.repIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.repIcon:SetSize(20, 20)
    frame.repIcon:SetPoint("RIGHT", frame.title, "LEFT", -4, 0)
    frame.repIcon:SetTexture("Interface\\Icons\\Achievement_Reputation_08")

    -- Sub-title (updated on refresh)
    frame.subLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.subLabel:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    frame.subLabel:SetTextColor(0.6, 0.65, 0.75, 1)

    -- "Can Afford" checkbox — filters to mounts the player can actually purchase
    frame.canAfford = false
    frame.affordCheck = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    frame.affordCheck:SetSize(24, 24)
    frame.affordCheck:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -8)
    frame.affordCheck:SetChecked(false)
    frame.affordCheck.text = frame.affordCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    frame.affordCheck.text:SetPoint("RIGHT", frame.affordCheck, "LEFT", -4, 0)
    frame.affordCheck.text:SetText("Can Afford")
    frame.affordCheck.text:SetTextColor(0.7, 0.78, 0.88, 1)
    frame.affordCheck:SetScript("OnClick", function(self)
        frame.canAfford = self:GetChecked()
        MCLcore.Frames:RefreshRepFilter()
    end)
    frame.affordCheck:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Can Afford", 1, 1, 1)
        GameTooltip:AddLine("Only show mounts you have the currency/gold to purchase right now.", 0.7, 0.78, 0.88, true)
        GameTooltip:Show()
    end)
    frame.affordCheck:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Container for mount rows
    frame.mountContainer = CreateFrame("Frame", nil, frame)
    frame.mountContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -55)
    frame.mountContainer:SetWidth(availableWidth)
    frame.mountContainer:SetHeight(1)

    MCLcore._repFilterFrame = frame
    return frame
end

-- --------------------------------------------------------
-- Refresh / rebuild the reputation filter mount list
-- Shows only: unlocked (rep met) AND uncollected mounts
-- --------------------------------------------------------
function MCL_frames:RefreshRepFilter()
    local frame = MCLcore._repFilterFrame
    if not frame then return end

    local container = frame.mountContainer
    -- Properly destroy old rows and their children
    if container.rows then
        for _, row in ipairs(container.rows) do
            row:Hide()
            row:ClearAllPoints()
            row:SetParent(nil)
        end
    end
    container.rows = {}
    -- Also destroy any leftover "no data" font strings from previous refreshes
    if container._noDataText then
        container._noDataText:Hide()
        container._noDataText:SetText("")
        container._noDataText = nil
    end

    -- Need rep data
    if not MCL_GUIDE_REP_DATA then
        local noData = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noData:SetPoint("TOPLEFT", container, "TOPLEFT", 15, 0)
        noData:SetText("MCL_Guide reputation data not loaded.")
        noData:SetTextColor(0.5, 0.55, 0.65, 1)
        container._noDataText = noData
        local dummyRow = CreateFrame("Frame", nil, container)
        dummyRow:SetSize(1, 30)
        table.insert(container.rows, dummyRow)
        frame:SetHeight(100)
        return
    end

    -- Standing name -> ID for comparison
    local STANDING_IDS = {
        Hated = 1, Hostile = 2, Unfriendly = 3, Neutral = 4,
        Friendly = 5, Honored = 6, Revered = 7, Exalted = 8,
    }
    local STANDING_LABELS = {
        [1]="Hated",[2]="Hostile",[3]="Unfriendly",[4]="Neutral",
        [5]="Friendly",[6]="Honored",[7]="Revered",[8]="Exalted",
    }

    -- Inline helper: resolve current rep/renown status
    local function GetRepStatus(repInfo)
        if not repInfo or not repInfo.factionId then return nil end
        local result = {
            factionName  = repInfo.factionName or "Unknown",
            isRenown     = repInfo.renown or false,
            isMet        = false,
            currentText  = "Unknown",
            requiredText = "Unknown",
        }
        if repInfo.renown then
            local required = repInfo.level or 0
            result.requiredText = "Renown " .. required
            if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
                local data = C_MajorFactions.GetMajorFactionData(repInfo.factionId)
                if data then
                    local current = data.renownLevel or 0
                    result.currentText = "Renown " .. current
                    result.isMet = current >= required
                end
            end
        else
            local reqId = STANDING_IDS[repInfo.levelName] or 8
            result.requiredText = repInfo.levelName or "Exalted"
            if C_Reputation and C_Reputation.GetFactionDataByID then
                local data = C_Reputation.GetFactionDataByID(repInfo.factionId)
                if data then
                    local standingName = STANDING_LABELS[data.reaction] or ("Standing " .. (data.reaction or "?"))
                    local progressText = ""
                    if data.nextReactionThreshold and data.nextReactionThreshold > 0 then
                        progressText = " (" .. (data.currentStanding or 0) .. "/" .. data.nextReactionThreshold .. ")"
                    end
                    result.currentText = standingName .. progressText
                    result.isMet = (data.reaction or 0) >= reqId
                end
            elseif GetFactionInfoByID then
                local name, _, standingId = GetFactionInfoByID(repInfo.factionId)
                if name then
                    result.currentText = STANDING_LABELS[standingId] or "Unknown"
                    result.isMet = (standingId or 0) >= reqId
                end
            end
        end
        return result
    end

    -- Helper: check if player can afford all costs for a mount
    local function CanAffordMount(spellId)
        local costs = MCL_GUIDE_CURRENCY_DATA and MCL_GUIDE_CURRENCY_DATA[spellId]
        if not costs then return true end  -- no cost data = assume affordable
        for _, cost in ipairs(costs) do
            if cost.type == "gold" then
                local playerGold = GetMoney() or 0
                local needed = (cost.amount or 0) * 10000  -- amount is in gold, GetMoney is in copper
                if playerGold < needed then return false end
            elseif cost.type == "currency" then
                if C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo then
                    local info = C_CurrencyInfo.GetCurrencyInfo(cost.id)
                    if info then
                        if (info.quantity or 0) < (cost.amount or 0) then return false end
                    else
                        return false
                    end
                end
            elseif cost.type == "item" then
                local count = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(cost.id, true) or GetItemCount(cost.id, true) or 0
                if count < (cost.amount or 0) then return false end
            end
        end
        return true
    end

    -- Collect all rep mounts and resolve their info
    local mounts = {}
    local playerFaction = UnitFactionGroup("player")
    for spellId, repInfo in pairs(MCL_GUIDE_REP_DATA) do
        local mountID = C_MountJournal.GetMountFromSpell(spellId)
        if mountID and mountID > 0 then
            local mountName, mountSpellID, icon, _, _, _, _, _, isFactionSpecific, faction, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            if mountName then
                local show = true
                if isFactionSpecific then
                    if (faction == 0 and playerFaction ~= "Horde") or (faction == 1 and playerFaction ~= "Alliance") then
                        show = false
                    end
                end
                if show then
                    local repStatus = GetRepStatus(repInfo)
                    local isMet = repStatus and repStatus.isMet or false
                    -- Only include mounts that are unlocked (rep met) and NOT collected
                    if isMet and not isCollected then
                        table.insert(mounts, {
                            spellId     = spellId,
                            mountID     = mountID,
                            mountName   = mountName,
                            icon        = icon,
                            isCollected = isCollected,
                            repInfo     = repInfo,
                            repStatus   = repStatus,
                            factionName = repInfo.factionName or "Unknown",
                            isRenown    = repInfo.renown or false,
                            canAfford   = CanAffordMount(spellId),
                        })
                    end
                end
            end
        end
    end

    -- Sort: faction name, then by mount name
    table.sort(mounts, function(a, b)
        if a.factionName ~= b.factionName then
            return a.factionName < b.factionName
        end
        return a.mountName < b.mountName
    end)

    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local rowWidth = currentWidth - 70
    local yOffset = 0
    local shownCount = 0
    local lastFaction = nil

    for _, m in ipairs(mounts) do
        -- Apply "Can Afford" filter
        if frame.canAfford and not m.canAfford then
            -- skip this mount
        else
            -- Faction header
            if m.factionName ~= lastFaction then
                lastFaction = m.factionName
                local header = CreateFrame("Frame", nil, container)
                header:SetSize(rowWidth, 24)
                header:SetPoint("TOPLEFT", container, "TOPLEFT", 10, yOffset - 6)
                header.text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                header.text:SetPoint("LEFT", header, "LEFT", 0, 0)
                local headerLabel = m.factionName
                if m.isRenown then
                    headerLabel = headerLabel .. "  |cFF1FB7EB(Renown)|r"
                end
                header.text:SetText(headerLabel)
                header.text:SetTextColor(0.9, 0.8, 0.5, 1)
                header.line = header:CreateTexture(nil, "ARTWORK")
                header.line:SetHeight(1)
                header.line:SetPoint("LEFT", header.text, "RIGHT", 8, 0)
                header.line:SetPoint("RIGHT", header, "RIGHT", 0, 0)
                header.line:SetColorTexture(0.3, 0.3, 0.35, 0.5)
                table.insert(container.rows, header)
                yOffset = yOffset - 30
            end

            -- Mount row
            local row = CreateFrame("Button", nil, container, "BackdropTemplate")
            row:SetSize(rowWidth, 44)
            row:SetPoint("TOPLEFT", container, "TOPLEFT", 10, yOffset)
            row:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            })
            row:SetBackdropColor(0.08, 0.08, 0.14, 0.8)
            row:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)

            -- Mount icon
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(32, 32)
            row.icon:SetPoint("LEFT", row, "LEFT", 6, 0)
            row.icon:SetTexture(m.icon)
            row.icon:SetVertexColor(0.7, 0.7, 0.7, 0.9)

            -- Mount name
            row.nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 8, 4)
            row.nameText:SetText(m.mountName)
            row.nameText:SetTextColor(0.95, 0.95, 1, 1)

            -- Required standing (below name)
            local reqLabel
            if m.isRenown then
                reqLabel = "Renown " .. (m.repInfo.level or "?")
            else
                reqLabel = m.repInfo.levelName or "Exalted"
            end
            row.reqText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.reqText:SetPoint("TOPLEFT", row.nameText, "BOTTOMLEFT", 0, -1)
            row.reqText:SetText(m.factionName .. " — " .. reqLabel)
            row.reqText:SetTextColor(0.4, 0.65, 0.85, 1)

            -- Cost info (right side)
            local costs = MCL_GUIDE_CURRENCY_DATA and MCL_GUIDE_CURRENCY_DATA[m.spellId]
            if costs then
                local costParts = {}
                for _, cost in ipairs(costs) do
                    if cost.type == "gold" then
                        table.insert(costParts, string.format("%dg", cost.amount))
                    elseif cost.type == "currency" then
                        local info = C_CurrencyInfo and C_CurrencyInfo.GetCurrencyInfo(cost.id)
                        local cname = info and info.name or ("Currency " .. cost.id)
                        local have = info and info.quantity or 0
                        table.insert(costParts, string.format("%d/%d %s", have, cost.amount, cname))
                    elseif cost.type == "item" then
                        local iname = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(cost.id) or ("Item " .. cost.id)
                        local have = C_Item and C_Item.GetItemCount and C_Item.GetItemCount(cost.id, true) or GetItemCount(cost.id, true) or 0
                        table.insert(costParts, string.format("%d/%d %s", have, cost.amount, iname))
                    end
                end
                if #costParts > 0 then
                    row.costText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    row.costText:SetPoint("RIGHT", row, "RIGHT", -10, 0)
                    row.costText:SetText(table.concat(costParts, "  "))
                    if m.canAfford then
                        row.costText:SetTextColor(0.3, 0.9, 0.3, 1)
                    else
                        row.costText:SetTextColor(1, 0.3, 0.3, 1)
                    end
                end
            end

            -- Hover / click
            local spellId = m.spellId
            local mountID = m.mountID
            local mountName = m.mountName
            row:SetScript("OnEnter", function(self)
                self:SetBackdropColor(0.14, 0.14, 0.22, 1)
                self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                if spellId then GameTooltip:SetSpellByID(spellId) end
                GameTooltip:Show()
                if MCLcore and MCLcore.MountCard and MCL_SETTINGS.enableMountCardHover then
                    MCLcore.MountCard.ShowOnHover({
                        mountID = mountID, id = mountID, name = mountName,
                        category = "Reputation", section = "Reputation"
                    }, self, 0.2)
                end
            end)
            row:SetScript("OnLeave", function(self)
                self:SetBackdropColor(0.08, 0.08, 0.14, 0.8)
                self:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
                GameTooltip:Hide()
            end)
            row:SetScript("OnClick", function(self, button)
                if button == "RightButton" then
                    if MCLcore and MCLcore.MountCard then
                        MCLcore.MountCard.Toggle({
                            mountID = mountID, id = mountID, name = mountName,
                            category = "Reputation", section = "Reputation"
                        }, self)
                    end
                end
            end)
            row:RegisterForClicks("AnyUp")

            table.insert(container.rows, row)
            yOffset = yOffset - 50
            shownCount = shownCount + 1
        end
    end

    -- Summary
    local totalUnlocked = #mounts
    frame.subLabel:SetText(string.format("%d unlocked uncollected", totalUnlocked) ..
        (frame.canAfford and string.format("  —  %d affordable", shownCount) or ""))

    if shownCount == 0 then
        local noData = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noData:SetPoint("TOPLEFT", container, "TOPLEFT", 15, 0)
        if frame.canAfford then
            noData:SetText("No affordable mounts found. Uncheck 'Can Afford' to see all unlocked mounts.")
        elseif totalUnlocked == 0 then
            noData:SetText("No unlocked uncollected reputation mounts found.")
        end
        noData:SetTextColor(0.5, 0.55, 0.65, 1)
        container._noDataText = noData
        local dummyRow = CreateFrame("Frame", nil, container)
        dummyRow:SetSize(1, 30)
        table.insert(container.rows, dummyRow)
    end

    -- Adjust frame height
    local totalHeight = math.abs(yOffset) + 70
    frame:SetHeight(math.max(totalHeight, 100))
    container:SetHeight(math.abs(yOffset) + 10)
end

-- ============================================================
-- About / Disclaimer panel
-- ============================================================
function MCL_frames:createAboutFrame(relativeFrame)
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth   = currentWidth - 40

    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)
    frame:SetHeight(700)
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 10, 0)
    frame:SetBackdropColor(0, 0, 0, 0)
    frame.name = "About"

    -- ── Helper: card container (same style as Settings cards) ──
    local function createCard(parent, title, yOffset, height)
        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetWidth(availableWidth)
        card:SetHeight(height)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
        card:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        card:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
        card:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)

        local header = CreateFrame("Frame", nil, card, "BackdropTemplate")
        header:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
        header:SetHeight(26)
        header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        header:SetBackdropColor(0.08, 0.08, 0.12, 1)

        local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerText:SetPoint("LEFT", header, "LEFT", 10, 0)
        headerText:SetText(title)
        headerText:SetTextColor(0.4, 0.78, 0.95, 1)

        local accent = card:CreateTexture(nil, "ARTWORK")
        accent:SetHeight(1)
        accent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
        accent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
        accent:SetColorTexture(0.2, 0.5, 0.8, 0.3)

        return card
    end

    -- ── Helper: clickable link row inside a card ──
    local function createLinkRow(parent, yOff, label, url)
        local row = CreateFrame("Frame", nil, parent)
        row:SetHeight(22)
        row:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOff)
        row:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -12, yOff)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", row, "LEFT", 0, 0)
        lbl:SetText(label)
        lbl:SetTextColor(0.7, 0.78, 0.88, 1)

        local link = CreateFrame("Button", nil, row)
        link:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
        link:SetSize(math.min(400, availableWidth - 160), 18)
        link.text = link:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        link.text:SetPoint("LEFT")
        link.text:SetText("|cFF1FB7EB" .. url .. "|r")
        link.text:SetJustifyH("LEFT")
        link:SetScript("OnClick", function()
            if KethoEditBox_Show then
                KethoEditBox_Show(url)
            end
        end)
        link:SetScript("OnEnter", function(self)
            self.text:SetText("|cFF66DDFF" .. url .. "|r")
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:AddLine("Click to copy link", 1, 1, 1)
            GameTooltip:Show()
        end)
        link:SetScript("OnLeave", function(self)
            self.text:SetText("|cFF1FB7EB" .. url .. "|r")
            GameTooltip:Hide()
        end)

        return row
    end

    local yOffset = -10

    -- ── Title ──
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, yOffset)
    frame.title:SetText("About MCL")
    frame.title:SetTextColor(0.4, 0.78, 0.95, 1)

    frame.aboutIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.aboutIcon:SetSize(20, 20)
    frame.aboutIcon:SetPoint("RIGHT", frame.title, "LEFT", -4, 0)
    frame.aboutIcon:SetTexture("Interface\\AddOns\\MCL\\mcl-logo-32")

    -- Version
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    versionText:SetPoint("TOPLEFT", frame.title, "BOTTOMLEFT", 0, -4)
    versionText:SetTextColor(0.6, 0.65, 0.75, 1)
    local tocVersion = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("MCL", "Version")
    versionText:SetText("Version: " .. (tocVersion or "unknown"))

    yOffset = -50

    -- ══════════════════════════════════════════════════════
    -- Card 1 — Disclaimer / Data Quality
    -- ══════════════════════════════════════════════════════
    local disclaimerCard = createCard(frame, "Data Disclaimer", yOffset, 150)

    local disclaimerLines = {
        "|cFFFFCC00This addon's location and source data is a work in progress.|r",
        "",
        "Zone coordinates, vendor locations, drop sources and reputation requirements",
        "are continuously being reviewed and corrected. Some entries may be inaccurate,",
        "outdated, or missing entirely — especially for older content and faction-specific",
        "NPCs that have been relocated across patches.",
        "",
        "If you spot something wrong, please let us know using the links below!",
    }

    local textY = -34
    for _, line in ipairs(disclaimerLines) do
        local fs = disclaimerCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", disclaimerCard, "TOPLEFT", 12, textY)
        fs:SetPoint("RIGHT", disclaimerCard, "RIGHT", -12, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        fs:SetSpacing(2)
        if line == "" then
            textY = textY - 6
        else
            fs:SetText(line)
            fs:SetTextColor(0.75, 0.78, 0.85, 1)
            textY = textY - 16
        end
    end

    disclaimerCard:SetHeight(math.abs(textY) + 10)
    yOffset = yOffset - disclaimerCard:GetHeight() - 12

    -- ══════════════════════════════════════════════════════
    -- Card 2 — How to Help
    -- ══════════════════════════════════════════════════════
    local helpCard = createCard(frame, "Help Improve MCL", yOffset, 180)

    local helpLines = {
        "Community contributions are what make this addon better for everyone.",
        "Whether it's a wrong zone name, a missing mount, or coordinates that",
        "point to the wrong NPC — every report helps.",
        "",
        "Here's how you can contribute:",
    }

    textY = -34
    for _, line in ipairs(helpLines) do
        local fs = helpCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", helpCard, "TOPLEFT", 12, textY)
        fs:SetPoint("RIGHT", helpCard, "RIGHT", -12, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        fs:SetSpacing(2)
        if line == "" then
            textY = textY - 6
        else
            fs:SetText(line)
            fs:SetTextColor(0.75, 0.78, 0.85, 1)
            textY = textY - 16
        end
    end

    textY = textY - 8

    -- Discord invite link
    createLinkRow(helpCard, textY, "|cFF5865F2\226\151\143|r  Discord:", "https://discord.gg/YvrpHSyqtj")
    textY = textY - 26

    -- CurseForge link
    createLinkRow(helpCard, textY, "|cFFF16436\226\151\143|r  CurseForge:", "https://www.curseforge.com/wow/addons/mount-collection-log-mcl")
    textY = textY - 26

    textY = textY - 0

    helpCard:SetHeight(math.abs(textY) + 10)
    yOffset = yOffset - helpCard:GetHeight() - 12

    -- ══════════════════════════════════════════════════════
    -- Card 3 — Credits / Thank You
    -- ══════════════════════════════════════════════════════
    local creditsCard = createCard(frame, "Credits", yOffset, 100)

    local creditsLines = {
        "Created by |cFF1FB7EBCamyam|r",
        "",
        "Data sourced from Wowhead, wago.tools, and community contributions.",
        "Thank you to everyone who has submitted corrections and reports!",
    }

    textY = -34
    for _, line in ipairs(creditsLines) do
        local fs = creditsCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        fs:SetPoint("TOPLEFT", creditsCard, "TOPLEFT", 12, textY)
        fs:SetPoint("RIGHT", creditsCard, "RIGHT", -12, 0)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(true)
        fs:SetSpacing(2)
        if line == "" then
            textY = textY - 6
        else
            fs:SetText(line)
            fs:SetTextColor(0.75, 0.78, 0.85, 1)
            textY = textY - 16
        end
    end

    creditsCard:SetHeight(math.abs(textY) + 10)
    yOffset = yOffset - creditsCard:GetHeight() - 12

    -- Set total frame height
    frame:SetHeight(math.abs(yOffset) + 20)

    return frame
end


function MCL_frames:createSettingsFrame(relativeFrame)
    -- Calculate dynamic width based on current main frame width
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 40  -- Symmetric padding within scroll viewport
    
    local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
    frame:SetWidth(availableWidth)
    frame:SetHeight(750)
    frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 10, 0)
    frame:SetBackdropColor(0, 0, 0, 0)
    
    -- Title text (placed first so icon can anchor to it)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -10)
    frame.title:SetText(L["Settings"] or "Settings")
    frame.title:SetTextColor(0.4, 0.78, 0.95, 1)
    frame.name = "Settings"
    
    -- Section icon (anchored to title for vertical centering)
    frame.sectionIcon = frame:CreateTexture(nil, "ARTWORK")
    frame.sectionIcon:SetSize(20, 20)
    frame.sectionIcon:SetPoint("RIGHT", frame.title, "LEFT", -4, 0)
    frame.sectionIcon:SetTexture("Interface\\AddOns\\MCL\\icons\\settings.blp")
    
    -- =====================================================
    -- HELPER: Create a settings card (grouped section)
    -- =====================================================
    local function createCard(parent, title, yOffset, height)
        local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
        card:SetWidth(availableWidth)
        card:SetHeight(height)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, yOffset)
        card:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        card:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
        card:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
        
        -- Card header bar
        local header = CreateFrame("Frame", nil, card, "BackdropTemplate")
        header:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
        header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)
        header:SetHeight(26)
        header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        header:SetBackdropColor(0.08, 0.08, 0.12, 1)
        
        local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        headerText:SetPoint("LEFT", header, "LEFT", 10, 0)
        headerText:SetText(title)
        headerText:SetTextColor(0.4, 0.78, 0.95, 1)
        
        -- Accent line under header
        local accent = card:CreateTexture(nil, "ARTWORK")
        accent:SetHeight(1)
        accent:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, 0)
        accent:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, 0)
        accent:SetColorTexture(0.2, 0.5, 0.8, 0.3)
        
        return card
    end
    
    -- =====================================================
    -- HELPER: Style a checkbox (house style)
    -- =====================================================
    local function styleCheckbox(checkbox)
        checkbox:SetNormalTexture("")
        checkbox:SetPushedTexture("")
        checkbox:SetHighlightTexture("")
        checkbox:SetCheckedTexture("")
        
        local bg = checkbox:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.1, 0.8)
        
        local border = CreateFrame("Frame", nil, checkbox, "BackdropTemplate")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        border:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        checkbox.borderFrame = border
        
        -- Checkmark texture
        local check = checkbox:CreateTexture(nil, "OVERLAY")
        check:SetSize(14, 14)
        check:SetPoint("CENTER")
        check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:SetDesaturated(true)
        check:SetVertexColor(0.4, 0.78, 0.95, 1)
        check:Hide()
        checkbox.checkMark = check
        
        local function updateVisuals()
            if checkbox:GetChecked() then
                bg:SetColorTexture(0.15, 0.25, 0.4, 0.9)
                border:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
                check:Show()
            else
                bg:SetColorTexture(0.08, 0.08, 0.1, 0.8)
                border:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                check:Hide()
            end
        end
        
        checkbox:SetScript("OnClick", function(self)
            updateVisuals()
            if self.originalOnClick then self.originalOnClick(self) end
        end)
        checkbox:SetScript("OnEnter", function(self)
            border:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
        end)
        checkbox:SetScript("OnLeave", function(self)
            updateVisuals()
        end)
        
        updateVisuals()
        return updateVisuals
    end
    
    -- =====================================================
    -- HELPER: Style a slider (house style)
    -- =====================================================
    local function styleSlider(slider, showInputBox, isPercentage)
        local thumb = slider:GetThumbTexture()
        if thumb then
            thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
            thumb:SetSize(12, 16)
            thumb:SetVertexColor(0.4, 0.78, 0.95, 1)
        end
        
        slider:EnableMouse(true)
        slider:EnableMouseWheel(true)
        
        -- Track background
        local trackBg = slider:CreateTexture(nil, "BACKGROUND")
        trackBg:SetColorTexture(0.08, 0.08, 0.1, 1)
        trackBg:SetHeight(4)
        trackBg:SetPoint("LEFT", slider, "LEFT", 10, 0)
        trackBg:SetPoint("RIGHT", slider, "RIGHT", -10, 0)
        
        -- Track border
        local trackBorder = CreateFrame("Frame", nil, slider, "BackdropTemplate")
        trackBorder:SetPoint("TOPLEFT", trackBg, "TOPLEFT", -1, 1)
        trackBorder:SetPoint("BOTTOMRIGHT", trackBg, "BOTTOMRIGHT", 1, -1)
        trackBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        trackBorder:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
        
        -- Progress fill
        local progress = slider:CreateTexture(nil, "ARTWORK")
        progress:SetColorTexture(0.2, 0.45, 0.75, 0.8)
        progress:SetHeight(4)
        progress:SetPoint("LEFT", trackBg, "LEFT")
        
        local function updateProgress()
            local value = slider:GetValue()
            local min, max = slider:GetMinMaxValues()
            if max > min then
                local pct = (value - min) / (max - min)
                local w = trackBg:GetWidth() * pct
                if w < 1 then w = 1 end
                progress:SetWidth(w)
            end
        end
        
        -- Input box
        if showInputBox then
            local inputBox = CreateFrame("EditBox", nil, slider:GetParent(), "BackdropTemplate")
            inputBox:SetSize(50, 22)
            inputBox:SetPoint("LEFT", slider, "RIGHT", 10, 0)
            inputBox:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            inputBox:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
            inputBox:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
            inputBox:SetFontObject(GameFontHighlightSmall)
            inputBox:SetTextColor(0.7, 0.78, 0.88, 1)
            inputBox:SetJustifyH("CENTER")
            inputBox:SetAutoFocus(false)
            inputBox:SetNumeric(true)
            
            local function getDisplayValue(v)
                return isPercentage and tostring(math.floor(v * 100)) or tostring(math.floor(v))
            end
            local function getSliderValue(d)
                local n = tonumber(d)
                if not n then return nil end
                return isPercentage and n / 100 or n
            end
            
            inputBox:SetText(getDisplayValue(slider:GetValue()))
            inputBox:SetScript("OnEnterPressed", function(self)
                local sv = getSliderValue(self:GetText())
                if sv then
                    local mn, mx = slider:GetMinMaxValues()
                    slider:SetValue(math.max(mn, math.min(mx, sv)))
                    self:SetText(getDisplayValue(slider:GetValue()))
                end
                self:ClearFocus()
            end)
            inputBox:SetScript("OnEscapePressed", function(self)
                self:SetText(getDisplayValue(slider:GetValue())); self:ClearFocus()
            end)
            inputBox:SetScript("OnEditFocusLost", function(self)
                self:SetText(getDisplayValue(slider:GetValue()))
            end)
            
            -- Focus styling
            inputBox:SetScript("OnEditFocusGained", function(self)
                self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
            end)
            
            slider.inputBox = inputBox
            slider.getDisplayValue = getDisplayValue
        end
        
        slider:SetScript("OnValueChanged", function(self, value)
            updateProgress()
            if self.inputBox and self.getDisplayValue then
                self.inputBox:SetText(self.getDisplayValue(value))
            end
            if self.originalOnValueChanged then self.originalOnValueChanged(self, value) end
        end)
        slider:SetScript("OnMouseWheel", function(self, delta)
            local step = self:GetValueStep()
            local mn, mx = self:GetMinMaxValues()
            self:SetValue(math.max(mn, math.min(mx, self:GetValue() + delta * step)))
        end)
        
        updateProgress()
    end
    
    local yPos = -45
    
    -- =====================================================
    -- CARD 1: Display Options
    -- =====================================================
    local displayCard = createCard(frame, L["Display Options"] or "Display Options", yPos, 130)
    
    local displayY = -34
    
    -- Hide Collected
    local hideCheck = CreateFrame("CheckButton", nil, displayCard)
    hideCheck:SetSize(18, 18)
    hideCheck:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 12, displayY)
    hideCheck:SetChecked(MCL_SETTINGS.hideCollectedMounts or false)
    hideCheck.originalOnClick = function(self) MCL_SETTINGS.hideCollectedMounts = self:GetChecked() end
    styleCheckbox(hideCheck)
    local hideLabel = displayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hideLabel:SetPoint("LEFT", hideCheck, "RIGHT", 8, 0)
    hideLabel:SetText(L["Hide Collected Mounts"] or "Hide Collected Mounts")
    hideLabel:SetTextColor(0.7, 0.78, 0.88, 1)
    displayY = displayY - 30
    
    -- Show Unobtainable
    local unobtCheck = CreateFrame("CheckButton", nil, displayCard)
    unobtCheck:SetSize(18, 18)
    unobtCheck:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 12, displayY)
    unobtCheck:SetChecked(not MCL_SETTINGS.unobtainable)
    unobtCheck.originalOnClick = function(self) MCL_SETTINGS.unobtainable = not self:GetChecked() end
    styleCheckbox(unobtCheck)
    local unobtLabel = displayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    unobtLabel:SetPoint("LEFT", unobtCheck, "RIGHT", 8, 0)
    unobtLabel:SetText(L["Show Unobtainable Mounts"] or "Show Unobtainable Mounts")
    unobtLabel:SetTextColor(0.7, 0.78, 0.88, 1)
    displayY = displayY - 30
    
    -- Enable Mount Card Hover
    local hoverCheck = CreateFrame("CheckButton", nil, displayCard)
    hoverCheck:SetSize(18, 18)
    hoverCheck:SetPoint("TOPLEFT", displayCard, "TOPLEFT", 12, displayY)
    hoverCheck:SetChecked(not (MCL_SETTINGS.enableMountCardHover == false))
    hoverCheck.originalOnClick = function(self) MCL_SETTINGS.enableMountCardHover = self:GetChecked() end
    styleCheckbox(hoverCheck)
    local hoverLabel = displayCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    hoverLabel:SetPoint("LEFT", hoverCheck, "RIGHT", 8, 0)
    hoverLabel:SetText(L["Enable Mount Card on Hover"] or "Enable Mount Card on Hover")
    hoverLabel:SetTextColor(0.7, 0.78, 0.88, 1)
    
    yPos = yPos - 140
    
    -- =====================================================
    -- CARD 3: Layout
    -- =====================================================
    local layoutCard = createCard(frame, L["Layout Options"] or "Layout", yPos, 120)
    
    local mountsLabel = layoutCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    mountsLabel:SetPoint("TOPLEFT", layoutCard, "TOPLEFT", 12, -34)
    mountsLabel:SetText((L["Mounts Per Row"] or "Mounts Per Row") .. ": " .. (MCL_SETTINGS.mountsPerRow or 12))
    mountsLabel:SetTextColor(0.7, 0.78, 0.88, 1)
    
    local mountsSlider = CreateFrame("Slider", nil, layoutCard)
    mountsSlider:SetPoint("TOPLEFT", layoutCard, "TOPLEFT", 12, -58)
    mountsSlider:SetOrientation("HORIZONTAL")
    mountsSlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    mountsSlider:SetMinMaxValues(6, 24)
    mountsSlider:SetValue(MCL_SETTINGS.mountsPerRow or 12)
    mountsSlider:SetValueStep(1)
    mountsSlider:SetObeyStepOnDrag(true)
    mountsSlider:SetWidth(200)
    mountsSlider:SetHeight(20)
    
    -- Min/max labels
    local mprMin = layoutCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mprMin:SetPoint("LEFT", mountsSlider, "LEFT", 0, -15)
    mprMin:SetText("6")
    mprMin:SetTextColor(0.5, 0.55, 0.65, 1)
    local mprMax = layoutCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mprMax:SetPoint("RIGHT", mountsSlider, "RIGHT", 0, -15)
    mprMax:SetText("24")
    mprMax:SetTextColor(0.5, 0.55, 0.65, 1)
    
    mountsSlider.originalOnValueChanged = function(self, value)
        MCL_SETTINGS.mountsPerRow = math.floor(value)
        mountsLabel:SetText((L["Mounts Per Row"] or "Mounts Per Row") .. ": " .. MCL_SETTINGS.mountsPerRow)
        if not self.reloadNote then
            self.reloadNote = layoutCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            self.reloadNote:SetPoint("TOPLEFT", mountsSlider, "BOTTOMLEFT", 0, -20)
            self.reloadNote:SetText("|cFFFF6B6BReload UI required (/reload)|r")
        end
        self.reloadNote:Show()
    end
    styleSlider(mountsSlider, true)
    
    yPos = yPos - 130
    
    -- =====================================================
    -- CARD 4: Progress Bar
    -- =====================================================
    local progressCard = createCard(frame, L["Progress Bar Options"] or "Progress Bar", yPos, 100)
    
    -- Texture selector
    if not MCLcore.media then
        local success, media = pcall(LibStub, "LibSharedMedia-3.0")
        if success and media then MCLcore.media = media end
    end
    
    if MCLcore.media then
        local texLabel = progressCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        texLabel:SetPoint("TOPLEFT", progressCard, "TOPLEFT", 12, -34)
        texLabel:SetText(L["Progress Bar Texture"] or "Texture:")
        texLabel:SetTextColor(0.7, 0.78, 0.88, 1)
        
        -- Dropdown button
        local ddBtn = CreateFrame("Button", nil, progressCard, "BackdropTemplate")
        ddBtn:SetSize(220, 30)
        ddBtn:SetPoint("TOPLEFT", progressCard, "TOPLEFT", 12, -54)
        ddBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        ddBtn:SetBackdropColor(0.08, 0.08, 0.1, 0.9)
        ddBtn:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
        
        -- Preview texture inside dropdown button
        local ddPreview = ddBtn:CreateTexture(nil, "ARTWORK")
        ddPreview:SetSize(190, 14)
        ddPreview:SetPoint("LEFT", ddBtn, "LEFT", 8, 0)
        
        local ddText = ddBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ddText:SetPoint("CENTER", ddPreview, "CENTER")
        ddText:SetTextColor(0.9, 0.9, 0.95, 1)
        
        -- Shadow for readability
        local ddShadow = ddBtn:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
        ddShadow:SetPoint("CENTER", ddPreview, "CENTER", 1, -1)
        ddShadow:SetTextColor(0, 0, 0, 0.8)
        
        -- Arrow
        local ddArrow = ddBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ddArrow:SetPoint("RIGHT", ddBtn, "RIGHT", -8, 0)
        ddArrow:SetText("\226\150\188")  -- ▼
        ddArrow:SetTextColor(0.5, 0.55, 0.65, 1)
        
        -- Set current selection
        local curTex = MCL_SETTINGS.statusBarTexture or "Blizzard"
        ddText:SetText(curTex)
        ddShadow:SetText(curTex)
        local curFile = MCLcore.media:Fetch("statusbar", curTex)
        if curFile then ddPreview:SetTexture(curFile) end
        
        -- Dropdown list
        local ddList = CreateFrame("Frame", nil, progressCard, "BackdropTemplate")
        ddList:SetSize(220, 250)
        ddList:SetPoint("TOPLEFT", ddBtn, "BOTTOMLEFT", 0, -2)
        ddList:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        ddList:SetBackdropColor(0.06, 0.06, 0.09, 0.98)
        ddList:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.8)
        ddList:SetFrameStrata("DIALOG")
        ddList:Hide()
        
        local ddScroll = CreateFrame("ScrollFrame", nil, ddList)
        ddScroll:SetSize(200, 230)
        ddScroll:SetPoint("TOPLEFT", ddList, "TOPLEFT", 10, -10)
        
        local ddScrollChild = CreateFrame("Frame", nil, ddScroll)
        ddScroll:SetScrollChild(ddScrollChild)
        
        local textures = MCLcore.media:List("statusbar") or {}
        table.sort(textures)
        
        local btnHeight = 28
        ddScrollChild:SetSize(200, math.max(#textures * btnHeight + 10, 230))
        
        ddScroll:EnableMouseWheel(true)
        ddScroll:SetScript("OnMouseWheel", function(self, delta)
            local cur = self:GetVerticalScroll()
            local maxS = math.max(0, ddScrollChild:GetHeight() - self:GetHeight())
            self:SetVerticalScroll(math.max(0, math.min(maxS, cur - delta * 30)))
        end)
        
        local texBtns = {}
        for i, tName in ipairs(textures) do
            local btn = CreateFrame("Button", nil, ddScrollChild, "BackdropTemplate")
            btn:SetSize(180, btnHeight - 2)
            btn:SetPoint("TOPLEFT", ddScrollChild, "TOPLEFT", 5, -(i-1) * btnHeight - 5)
            btn:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background" })
            btn:SetBackdropColor(0.08, 0.08, 0.1, 0.3)
            
            local prev = btn:CreateTexture(nil, "ARTWORK")
            prev:SetSize(170, 16)
            prev:SetPoint("CENTER")
            local tFile = MCLcore.media:Fetch("statusbar", tName)
            if tFile then prev:SetTexture(tFile) end
            
            local nText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            nText:SetPoint("CENTER", prev, "CENTER")
            nText:SetText(tName)
            nText:SetTextColor(0.9, 0.9, 0.95, 1)
            
            local nShadow = btn:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
            nShadow:SetPoint("CENTER", prev, "CENTER", 1, -1)
            nShadow:SetText(tName)
            nShadow:SetTextColor(0, 0, 0, 0.8)
            
            btn:SetScript("OnEnter", function(self) self:SetBackdropColor(0.15, 0.25, 0.4, 0.6) end)
            btn:SetScript("OnLeave", function(self)
                self:SetBackdropColor(MCL_SETTINGS.statusBarTexture == tName and 0.15 or 0.08, MCL_SETTINGS.statusBarTexture == tName and 0.3 or 0.08, MCL_SETTINGS.statusBarTexture == tName and 0.5 or 0.1, MCL_SETTINGS.statusBarTexture == tName and 0.5 or 0.3)
            end)
            btn:SetScript("OnClick", function()
                MCL_SETTINGS.statusBarTexture = tName
                ddText:SetText(tName); ddShadow:SetText(tName)
                if tFile then ddPreview:SetTexture(tFile) end
                ddList:Hide()
                for _, b in ipairs(texBtns) do
                    b:SetBackdropColor(b.texName == tName and 0.15 or 0.08, b.texName == tName and 0.3 or 0.08, b.texName == tName and 0.5 or 0.1, b.texName == tName and 0.5 or 0.3)
                end
            end)
            btn.texName = tName
            table.insert(texBtns, btn)
            if MCL_SETTINGS.statusBarTexture == tName then btn:SetBackdropColor(0.15, 0.3, 0.5, 0.5) end
        end
        
        ddBtn:SetScript("OnClick", function() if ddList:IsShown() then ddList:Hide() else ddList:Show() end end)
        ddBtn:SetScript("OnEnter", function(self) self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8) end)
        ddBtn:SetScript("OnLeave", function(self) self:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6) end)
        frame:SetScript("OnMouseDown", function() ddList:Hide() end)
    else
        local texNote = progressCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        texNote:SetPoint("TOPLEFT", progressCard, "TOPLEFT", 12, -34)
        texNote:SetText("LibSharedMedia not available")
        texNote:SetTextColor(0.5, 0.4, 0.4, 1)
    end
    
    yPos = yPos - 110
    
    -- =====================================================
    -- CARD 5: Window Opacity
    -- =====================================================
    local opacityCard = createCard(frame, L["Window Opacity"] or "Window Opacity", yPos, 100)
    
    local opacityValue = MCL_SETTINGS.opacity or 0.85
    local opacityLabel = opacityCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    opacityLabel:SetPoint("TOPLEFT", opacityCard, "TOPLEFT", 12, -34)
    opacityLabel:SetText((L["Opacity"] or "Opacity") .. ": " .. math.floor(opacityValue * 100) .. "%")
    opacityLabel:SetTextColor(0.7, 0.78, 0.88, 1)
    
    local opacitySlider = CreateFrame("Slider", nil, opacityCard)
    opacitySlider:SetPoint("TOPLEFT", opacityCard, "TOPLEFT", 12, -56)
    opacitySlider:SetOrientation("HORIZONTAL")
    opacitySlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    opacitySlider:SetMinMaxValues(0.1, 1.0)
    opacitySlider:SetValue(opacityValue)
    opacitySlider:SetValueStep(0.05)
    opacitySlider:SetObeyStepOnDrag(true)
    opacitySlider:SetWidth(200)
    opacitySlider:SetHeight(20)
    
    -- Min/max labels
    local opMin = opacityCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opMin:SetPoint("LEFT", opacitySlider, "LEFT", 0, -15)
    opMin:SetText("10%"); opMin:SetTextColor(0.5, 0.55, 0.65, 1)
    local opMax = opacityCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    opMax:SetPoint("RIGHT", opacitySlider, "RIGHT", 0, -15)
    opMax:SetText("100%"); opMax:SetTextColor(0.5, 0.55, 0.65, 1)
    
    opacitySlider.originalOnValueChanged = function(self, value)
        MCL_SETTINGS.opacity = value
        opacityLabel:SetText((L["Opacity"] or "Opacity") .. ": " .. math.floor(value * 100) .. "%")
        -- Main frame body
        if MCL_mainFrame and MCL_mainFrame.SetBackdropColor then
            MCL_mainFrame:SetBackdropColor(0.10, 0.10, 0.18, value)
        end
        -- Main frame header bar
        if MCL_mainFrame and MCL_mainFrame.headerBar then
            MCL_mainFrame.headerBar:SetBackdropColor(0.08, 0.08, 0.12, value)
        end
        -- Side-nav frame
        if MCLcore.MCL_MF_Nav then
            MCLcore.MCL_MF_Nav:SetBackdropColor(0.06, 0.06, 0.09, value)
            -- Nav header bar
            if MCLcore.MCL_MF_Nav.headerBar then
                MCLcore.MCL_MF_Nav.headerBar:SetBackdropColor(0.08, 0.08, 0.12, value)
            end
        end
    end
    styleSlider(opacitySlider, true, true)
    
    yPos = yPos - 110
    
    -- =====================================================
    -- CARD 6: Collection Toast
    -- =====================================================
    local toastCardHeight = (MCL_GUIDE_DATA and MCL_GUIDE_DATA.zones) and 400 or 350
    local toastCard = createCard(frame, L["Collection Toast"] or "Collection Toast", yPos, toastCardHeight)
    
    local toastY = -34
    local toastXInput, toastYInput  -- forward declarations for coord inputs
    
    -- Helper: add a toast checkbox row
    local function addToastCheckbox(parent, yOff, settingKey, labelKey, labelColor, defaultOn)
        if defaultOn == nil then defaultOn = true end
        local cb = CreateFrame("CheckButton", nil, parent)
        cb:SetSize(18, 18)
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOff)
        cb:SetChecked(defaultOn and MCL_SETTINGS[settingKey] ~= false or MCL_SETTINGS[settingKey] == true)
        cb.originalOnClick = function(self) MCL_SETTINGS[settingKey] = self:GetChecked() end
        styleCheckbox(cb)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        lbl:SetPoint("LEFT", cb, "RIGHT", 8, 0)
        lbl:SetText(L[labelKey] or labelKey)
        lbl:SetTextColor(unpack(labelColor or {0.7, 0.78, 0.88, 1}))
        return cb
    end
    
    -- Mount Collected  (blue section)
    local mountHeader = toastCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mountHeader:SetPoint("TOPLEFT", toastCard, "TOPLEFT", 12, toastY)
    mountHeader:SetText("|cFF33AAEE" .. (L["Mount Collected"] or "Mount Collected") .. "|r")
    toastY = toastY - 20
    
    addToastCheckbox(toastCard, toastY, "enableCollectedToast", "Collection Toast", {0.7, 0.78, 0.88, 1})
    toastY = toastY - 24
    addToastCheckbox(toastCard, toastY, "enableCollectedSound", "Toast Sound", {0.7, 0.78, 0.88, 1})
    toastY = toastY - 30
    
    -- Category Complete  (purple section)
    local catHeader = toastCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catHeader:SetPoint("TOPLEFT", toastCard, "TOPLEFT", 12, toastY)
    catHeader:SetText("|cFFAA55FF" .. (L["Category Complete"] or "Category Complete") .. "|r")
    toastY = toastY - 20
    
    addToastCheckbox(toastCard, toastY, "enableCategoryCompleteToast", "Category Complete Toast", {0.7, 0.78, 0.88, 1})
    toastY = toastY - 24
    addToastCheckbox(toastCard, toastY, "enableCategoryCompleteSound", "Category Complete Sound", {0.7, 0.78, 0.88, 1})
    toastY = toastY - 30
    
    -- Section Complete  (orange section)
    local secHeader = toastCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    secHeader:SetPoint("TOPLEFT", toastCard, "TOPLEFT", 12, toastY)
    secHeader:SetText("|cFFFF8800" .. (L["Section Complete"] or "Section Complete") .. "|r")
    toastY = toastY - 20
    
    addToastCheckbox(toastCard, toastY, "enableSectionCompleteToast", "Section Complete Toast", {0.7, 0.78, 0.88, 1})
    toastY = toastY - 24
    addToastCheckbox(toastCard, toastY, "enableSectionCompleteSound", "Section Complete Sound", {0.7, 0.78, 0.88, 1})
    toastY = toastY - 30
    
    -- Zone Alert  (teal section) — only if MCL_Guide drop data is loaded
    if MCL_GUIDE_DATA and MCL_GUIDE_DATA.zones then
        local zoneHeader = toastCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        zoneHeader:SetPoint("TOPLEFT", toastCard, "TOPLEFT", 12, toastY)
        zoneHeader:SetText("|cFF33CCAA" .. (L["Zone Alert"] or "Zone Alert") .. "|r")
        toastY = toastY - 20
        
        addToastCheckbox(toastCard, toastY, "enableZoneToast", "Zone Alert Toast", {0.7, 0.78, 0.88, 1}, false)
        toastY = toastY - 30
    end
    
    -- Unlock / Lock Toast Position button
    local unlockBtn = CreateFrame("Button", nil, toastCard, "BackdropTemplate")
    unlockBtn:SetSize(160, 26)
    unlockBtn:SetPoint("TOPLEFT", toastCard, "TOPLEFT", 12, toastY)
    unlockBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    unlockBtn:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
    unlockBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
    
    local unlockText = unlockBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    unlockText:SetPoint("CENTER")
    unlockText:SetText(L["Unlock Toast Position"] or "Unlock Toast Position")
    unlockText:SetTextColor(0.4, 0.78, 0.95, 1)
    
    unlockBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.25, 0.4, 0.9)
        self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
    end)
    unlockBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
        self:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
    end)
    unlockBtn:SetScript("OnClick", function()
        if MCLcore.Toast then
            local isUnlocked = MCLcore.Toast:ToggleUnlock()
            if isUnlocked then
                unlockText:SetText(L["Lock Toast Position"] or "Lock Toast Position")
                unlockBtn:SetBackdropColor(0.25, 0.15, 0.08, 0.8)
                unlockBtn:SetBackdropBorderColor(0.8, 0.6, 0.2, 0.8)
            else
                unlockText:SetText(L["Unlock Toast Position"] or "Unlock Toast Position")
                unlockBtn:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
                unlockBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
                -- Refresh X/Y inputs after dragging
                if toastXInput and toastYInput and MCLcore.Toast.GetPosition then
                    local cx, cy = MCLcore.Toast:GetPosition()
                    toastXInput:SetText(tostring(math.floor(cx)))
                    toastYInput:SetText(tostring(math.floor(cy)))
                end
            end
        end
    end)
    
    -- Reset Position button (next to unlock)
    local resetPosBtn = CreateFrame("Button", nil, toastCard, "BackdropTemplate")
    resetPosBtn:SetSize(100, 26)
    resetPosBtn:SetPoint("LEFT", unlockBtn, "RIGHT", 8, 0)
    resetPosBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    resetPosBtn:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
    resetPosBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
    local resetPosText = resetPosBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetPosText:SetPoint("CENTER")
    resetPosText:SetText(L["Reset Position"] or "Reset Position")
    resetPosText:SetTextColor(0.4, 0.78, 0.95, 1)
    resetPosBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.25, 0.4, 0.9)
        self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
    end)
    resetPosBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
        self:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
    end)
    resetPosBtn:SetScript("OnClick", function()
        if MCLcore.Toast then
            MCLcore.Toast:ResetPosition()
            if toastXInput then toastXInput:SetText("0") end
            if toastYInput then toastYInput:SetText("-120") end
        end
    end)
    
    toastY = toastY - 36
    
    -- X / Y coordinate inputs
    local coordLabel = toastCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    coordLabel:SetPoint("TOPLEFT", toastCard, "TOPLEFT", 12, toastY)
    coordLabel:SetText(L["Toast Position"] or "Toast Position")
    coordLabel:SetTextColor(0.7, 0.78, 0.88, 1)
    toastY = toastY - 22
    
    -- Get current position
    local curX, curY = 0, -120
    if MCLcore.Toast and MCLcore.Toast.GetPosition then
        curX, curY = MCLcore.Toast:GetPosition()
    end
    
    -- Helper to create a coordinate input box
    local function createCoordInput(parent, labelText, defaultVal, yOff)
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOff)
        lbl:SetText(labelText)
        lbl:SetTextColor(0.5, 0.55, 0.65, 1)
        
        local input = CreateFrame("EditBox", nil, parent, "BackdropTemplate")
        input:SetSize(60, 22)
        input:SetPoint("LEFT", lbl, "RIGHT", 6, 0)
        input:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        input:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
        input:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
        input:SetFontObject(GameFontHighlightSmall)
        input:SetTextColor(0.7, 0.78, 0.88, 1)
        input:SetJustifyH("CENTER")
        input:SetAutoFocus(false)
        input:SetText(tostring(math.floor(defaultVal)))
        
        input:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
        end)
        input:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.2, 0.2, 0.25, 0.6)
        end)
        
        return input
    end
    
    toastXInput = createCoordInput(toastCard, "X:", curX, toastY)
    toastYInput = createCoordInput(toastCard, "Y:", curY, toastY)
    toastYInput:ClearAllPoints()
    local yLbl = toastCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    yLbl:SetPoint("LEFT", toastXInput, "RIGHT", 16, 0)
    yLbl:SetText("Y:")
    yLbl:SetTextColor(0.5, 0.55, 0.65, 1)
    toastYInput:SetPoint("LEFT", yLbl, "RIGHT", 6, 0)
    
    -- Apply button
    local applyBtn = CreateFrame("Button", nil, toastCard, "BackdropTemplate")
    applyBtn:SetSize(60, 22)
    applyBtn:SetPoint("LEFT", toastYInput, "RIGHT", 12, 0)
    applyBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    applyBtn:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
    applyBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
    local applyText = applyBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    applyText:SetPoint("CENTER")
    applyText:SetText(L["Apply"] or "Apply")
    applyText:SetTextColor(0.4, 0.78, 0.95, 1)
    applyBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.15, 0.25, 0.4, 0.9)
        self:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
    end)
    applyBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.1, 0.15, 0.25, 0.8)
        self:SetBackdropBorderColor(0.2, 0.5, 0.8, 0.6)
    end)
    applyBtn:SetScript("OnClick", function()
        if MCLcore.Toast then
            local x = tonumber(toastXInput:GetText()) or 0
            local y = tonumber(toastYInput:GetText()) or -120
            MCLcore.Toast:SetPosition(x, y)
        end
    end)
    
    -- Also apply on Enter key
    local function onEnterPressed(self)
        if MCLcore.Toast then
            local x = tonumber(toastXInput:GetText()) or 0
            local y = tonumber(toastYInput:GetText()) or -120
            MCLcore.Toast:SetPosition(x, y)
        end
        self:ClearFocus()
    end
    toastXInput:SetScript("OnEnterPressed", onEnterPressed)
    toastYInput:SetScript("OnEnterPressed", onEnterPressed)
    toastXInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    toastYInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    yPos = yPos - (toastCardHeight + 20)
    
    -- =====================================================
    -- CARD 7: Map Pin Options
    -- =====================================================
    if MCL_GUIDE_DATA and MCL_GUIDE_DATA.zones then
        local pinCard = createCard(frame, "Map Pin Options", yPos, 200)
        
        local pinY = -34
        
        -- Checkbox: Show Map Icons
        local showPinsCheck = CreateFrame("CheckButton", nil, pinCard)
        showPinsCheck:SetSize(18, 18)
        showPinsCheck:SetPoint("TOPLEFT", pinCard, "TOPLEFT", 12, pinY)
        showPinsCheck:SetChecked(MCL_GUIDE_SETTINGS.showMapPins ~= false)
        showPinsCheck.originalOnClick = function(self)
            MCL_GUIDE_SETTINGS.showMapPins = self:GetChecked()
            if MCL_GUIDE and MCL_GUIDE.MapPins and MCL_GUIDE.MapPins.RefreshPins then
                MCL_GUIDE.MapPins:RefreshPins()
            end
        end
        styleCheckbox(showPinsCheck)
        local showPinsLabel = pinCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        showPinsLabel:SetPoint("LEFT", showPinsCheck, "RIGHT", 8, 0)
        showPinsLabel:SetText("Show Map Icons")
        showPinsLabel:SetTextColor(0.7, 0.78, 0.88, 1)
        pinY = pinY - 30
        
        -- Checkbox: Show Mount List on Map
        local showPanelCheck = CreateFrame("CheckButton", nil, pinCard)
        showPanelCheck:SetSize(18, 18)
        showPanelCheck:SetPoint("TOPLEFT", pinCard, "TOPLEFT", 12, pinY)
        showPanelCheck:SetChecked(MCL_GUIDE_SETTINGS.showZonePanel ~= false)
        showPanelCheck.originalOnClick = function(self)
            MCL_GUIDE_SETTINGS.showZonePanel = self:GetChecked()
            if MCL_GUIDE and MCL_GUIDE.ZonePanel then
                if self:GetChecked() then
                    MCL_GUIDE.ZonePanel:Refresh()
                else
                    MCL_GUIDE.ZonePanel:OnMapHide()
                end
            end
        end
        styleCheckbox(showPanelCheck)
        local showPanelLabel = pinCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        showPanelLabel:SetPoint("LEFT", showPanelCheck, "RIGHT", 8, 0)
        showPanelLabel:SetText("Show Mount List on Map")
        showPanelLabel:SetTextColor(0.7, 0.78, 0.88, 1)
        pinY = pinY - 30
        
        -- Checkbox: Show Child-Map Mounts
        local showChildCheck = CreateFrame("CheckButton", nil, pinCard)
        showChildCheck:SetSize(18, 18)
        showChildCheck:SetPoint("TOPLEFT", pinCard, "TOPLEFT", 12, pinY)
        showChildCheck:SetChecked(MCL_GUIDE_SETTINGS.showChildMapPins == true)
        showChildCheck.originalOnClick = function(self)
            MCL_GUIDE_SETTINGS.showChildMapPins = self:GetChecked()
            if MCL_GUIDE and MCL_GUIDE.MapPins and MCL_GUIDE.MapPins.RefreshPins then
                MCL_GUIDE.MapPins:RefreshPins()
            end
            if MCL_GUIDE and MCL_GUIDE.ZonePanel then
                MCL_GUIDE.ZonePanel:Refresh()
            end
        end
        styleCheckbox(showChildCheck)
        local showChildLabel = pinCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        showChildLabel:SetPoint("LEFT", showChildCheck, "RIGHT", 8, 0)
        showChildLabel:SetText("Show Child-Map Mounts")
        showChildLabel:SetTextColor(0.7, 0.78, 0.88, 1)
        pinY = pinY - 30
        
        -- Slider: Map Pin Size
        local pinScaleValue = (MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.mapPinScale) or 2.0
        local pinLabel = pinCard:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        pinLabel:SetPoint("TOPLEFT", pinCard, "TOPLEFT", 12, pinY)
        pinLabel:SetText("Map Pin Size: " .. string.format("%.1fx", pinScaleValue))
        pinLabel:SetTextColor(0.7, 0.78, 0.88, 1)
        
        local pinSlider = CreateFrame("Slider", nil, pinCard)
        pinSlider:SetPoint("TOPLEFT", pinCard, "TOPLEFT", 12, pinY - 22)
        pinSlider:SetOrientation("HORIZONTAL")
        pinSlider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
        pinSlider:SetMinMaxValues(0.5, 4.0)
        pinSlider:SetValue(pinScaleValue)
        pinSlider:SetValueStep(0.1)
        pinSlider:SetObeyStepOnDrag(true)
        pinSlider:SetWidth(200)
        pinSlider:SetHeight(20)
        
        local pinMin = pinCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pinMin:SetPoint("LEFT", pinSlider, "LEFT", 0, -15)
        pinMin:SetText("0.5x"); pinMin:SetTextColor(0.5, 0.55, 0.65, 1)
        local pinMax = pinCard:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pinMax:SetPoint("RIGHT", pinSlider, "RIGHT", 0, -15)
        pinMax:SetText("4.0x"); pinMax:SetTextColor(0.5, 0.55, 0.65, 1)
        
        pinSlider.originalOnValueChanged = function(self, value)
            value = math.floor(value * 10 + 0.5) / 10  -- round to 1 decimal
            if MCL_GUIDE_SETTINGS then
                MCL_GUIDE_SETTINGS.mapPinScale = value
            end
            pinLabel:SetText("Map Pin Size: " .. string.format("%.1fx", value))
            -- Live-refresh map pins if the map is open
            if MCL_GUIDE and MCL_GUIDE.MapPins and MCL_GUIDE.MapPins.RefreshPins then
                MCL_GUIDE.MapPins:RefreshPins()
            end
        end
        styleSlider(pinSlider, false)
        
        yPos = yPos - 210
    end
    
    -- =====================================================
    -- CARD 8: Reset
    -- =====================================================
    local resetCard = createCard(frame, L["Danger Zone"] or "Danger Zone", yPos, 60)
    -- Red accent line for danger zone
    local dangerAccent = resetCard:CreateTexture(nil, "ARTWORK", nil, 2)
    dangerAccent:SetHeight(1)
    dangerAccent:SetPoint("TOPLEFT", resetCard, "TOPLEFT", 1, -27)
    dangerAccent:SetPoint("TOPRIGHT", resetCard, "TOPRIGHT", -1, -27)
    dangerAccent:SetColorTexture(0.6, 0.15, 0.15, 0.5)
    
    local resetBtn = CreateFrame("Button", nil, resetCard, "BackdropTemplate")
    resetBtn:SetSize(130, 26)
    resetBtn:SetPoint("TOPLEFT", resetCard, "TOPLEFT", 12, -32)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1
    })
    resetBtn:SetBackdropColor(0.4, 0.08, 0.08, 0.7)
    resetBtn:SetBackdropBorderColor(0.55, 0.12, 0.12, 0.8)
    
    local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetText:SetPoint("CENTER")
    resetText:SetText(L["Reset Settings"] or "Reset Settings")
    resetText:SetTextColor(0.9, 0.6, 0.6, 1)
    
    resetBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.55, 0.12, 0.12, 0.9)
        self:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
        resetText:SetTextColor(1, 0.8, 0.8, 1)
    end)
    resetBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.4, 0.08, 0.08, 0.7)
        self:SetBackdropBorderColor(0.55, 0.12, 0.12, 0.8)
        resetText:SetTextColor(0.9, 0.6, 0.6, 1)
    end)
    resetBtn:SetScript("OnClick", function() StaticPopup_Show("MCL_RESET_SETTINGS") end)
    
    -- Popup dialogs
    StaticPopupDialogs["MCL_RESET_SETTINGS"] = {
        text = L["Are you sure you want to reset all MCL settings?"] or "Are you sure you want to reset all MCL settings?",
        button1 = L["Yes"] or "Yes",
        button2 = L["No"] or "No",
        OnAccept = function()
            MCL_SETTINGS.hideCollectedMounts = false
            MCL_SETTINGS.unobtainable = false
            MCL_SETTINGS.mountsPerRow = 12
            MCL_SETTINGS.statusBarTexture = "Blizzard"
            MCL_SETTINGS.opacity = 0.85
            MCL_SETTINGS.enableMountCardHover = true
            MCL_SETTINGS.enableCollectedToast = true
            MCL_SETTINGS.enableCollectedSound = true
            MCL_SETTINGS.enableCategoryCompleteToast = true
            MCL_SETTINGS.enableCategoryCompleteSound = true
            MCL_SETTINGS.enableSectionCompleteToast = true
            MCL_SETTINGS.enableSectionCompleteSound = true
            MCL_SETTINGS.enableZoneToast = false
            MCL_SETTINGS.toastPosition = nil
            ReloadUI()
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    StaticPopupDialogs["MCL_RELOAD_WARNING"] = {
        text = L["This setting requires a UI reload to take effect. Reload now?"] or "This setting requires a UI reload to take effect. Reload now?",
        button1 = L["Reload Now"] or "Reload Now",
        button2 = L["Later"] or "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
    }
    
    return frame
end


function MCL_frames:createOverviewCategory(set, relativeFrame)
    if not set or not relativeFrame then
        return
    end

    -- Use the same layout calculations as createCategoryFrame for consistency
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 40  -- Match content frame width
    local columnSpacing = 25  -- Spacing between columns
    local numColumns = 2
    local columnWidth = math.floor((availableWidth - columnSpacing * (numColumns - 1)) / numColumns)
    
    local leftColumnX = 10  -- Start with padding from left edge
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
            
            -- Create section frame with subtle backdrop
            local sectionFrame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
            sectionFrame:SetWidth(columnWidth)
            sectionFrame:SetHeight(52)
            sectionFrame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", xPos, yPos)
            sectionFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            sectionFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.7)
            sectionFrame:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)

            -- Section icon (use expansion icon if available)
            local iconXOffset = 5
            if v.icon then
                sectionFrame.icon = sectionFrame:CreateTexture(nil, "ARTWORK")
                sectionFrame.icon:SetSize(16, 16)
                sectionFrame.icon:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 6, -4)
                sectionFrame.icon:SetTexture(v.icon)
                iconXOffset = 26  -- shift title right to make room for icon
            end

            -- Section title
            sectionFrame.title = sectionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            sectionFrame.title:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", iconXOffset, -4)
            sectionFrame.title:SetText(L[v.name] or v.name)
            sectionFrame.title:SetTextColor(0.7, 0.78, 0.88, 1)
            
            -- Create progress bar container with dynamic width based on column width
            local progressContainer = CreateFrame("Frame", nil, sectionFrame)
            progressContainer:SetWidth(columnWidth - 14)
            progressContainer:SetHeight(18)
            progressContainer:SetPoint("TOPLEFT", sectionFrame, "TOPLEFT", 6, -22)
            
            -- Create progress bar with background
            local pBar = CreateFrame("StatusBar", nil, progressContainer, "BackdropTemplate")
            
            -- Add dark background to the progress bar
            pBar:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            pBar:SetBackdropColor(0.08, 0.08, 0.1, 0.8)
            pBar:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
            
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
            pBar.Text:SetTextColor(0.85, 0.9, 0.95, 1)
            
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
                                        t:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
                                        t:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
                                        if t.text then t.text:SetTextColor(0.7, 0.78, 0.88, 1) end
                                    end
                                end
                                if tab.SetBackdropBorderColor then
                                    tab:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
                                    tab:SetBackdropColor(0.15, 0.18, 0.25, 1)
                                    if tab.text then tab.text:SetTextColor(0.5, 0.85, 1, 1) end
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
                leftColumnY = leftColumnY - 58  -- section height 52 + 6 spacing
            else
                rightColumnY = rightColumnY - 58
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
    local availableWidth = currentWidth - 40  -- Match content frame width
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

-- Initialize collapsed categories storage
if not MCL_SETTINGS.collapsedCategories then
    MCL_SETTINGS.collapsedCategories = {}
end

-- Track all category frames for reflow
local categoryFramesList = {}
local COLLAPSED_HEIGHT = 30

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

    -- Hide fully-collected categories when the "Hide Collected Mounts" filter is active.
    -- Otherwise, show a category as long as it has mounts defined in data (even when
    -- totalMounts is 0 because the mount journal isn't ready yet).
    if MCL_SETTINGS.hideCollectedMounts and totalMounts > 0 and displayedMounts == 0 then
        -- All mounts collected & filter is on — skip this category entirely
    else

    -- Apply user-selected sort mode to the mount list
    SortMountList(mountList, MCL_SETTINGS.mountSortMode)

    if #mountList > 0 then
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
        
        -- Calculate dynamic height based on actual mount layout.
        -- displayedMounts can be 0 temporarily (e.g., mount journal not ready or hide-collected enabled).
        -- Ensure we reserve space when there are mounts in data.
        local mountCountForLayout = displayedMounts
        if mountCountForLayout == 0 and #mountList > 0 then
            mountCountForLayout = math.min(#mountList, mountsPerRow)
        end
        local numRows = math.ceil(mountCountForLayout / mountsPerRow)
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
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        categoryFrame:SetBackdropColor(0.06, 0.06, 0.09, 0.9)
        categoryFrame:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)

        -- Category title
        categoryFrame.title = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        categoryFrame.title:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 22, -8)
        categoryFrame.title:SetText(L[categoryData.name] or L[categoryName] or categoryData.name or categoryName)
        categoryFrame.title:SetTextColor(0.7, 0.78, 0.88, 1)

        -- Collapse/expand state
        local collapseKey = (sectionName or "Unknown") .. ":" .. (categoryData.name or categoryName)
        categoryFrame.collapseKey = collapseKey
        categoryFrame.expandedHeight = categoryHeight
        categoryFrame.isCollapsed = MCL_SETTINGS.collapsedCategories[collapseKey] or false
        categoryFrame.columnIndex = categoryIndex

        -- House-style +/− toggle button
        categoryFrame.toggleBtn = CreateFrame("Frame", nil, categoryFrame, "BackdropTemplate")
        categoryFrame.toggleBtn:SetSize(16, 16)
        categoryFrame.toggleBtn:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 4, -6)
        categoryFrame.toggleBtn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        categoryFrame.toggleBtn:SetBackdropColor(0.10, 0.10, 0.15, 0.9)
        categoryFrame.toggleBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
        categoryFrame.toggleLabel = categoryFrame.toggleBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        categoryFrame.toggleLabel:SetPoint("CENTER", 0, 1)
        categoryFrame.toggleLabel:SetTextColor(0.5, 0.55, 0.65, 1)
        if categoryFrame.isCollapsed then
            categoryFrame.toggleLabel:SetText("+")
        else
            categoryFrame.toggleLabel:SetText("\226\136\146")  -- minus sign U+2212
        end

        -- Clickable title bar for toggling
        categoryFrame.titleBtn = CreateFrame("Button", nil, categoryFrame)
        categoryFrame.titleBtn:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 0, 0)
        categoryFrame.titleBtn:SetPoint("TOPRIGHT", categoryFrame, "TOPRIGHT", 0, 0)
        categoryFrame.titleBtn:SetHeight(28)
        categoryFrame.titleBtn:SetFrameLevel(categoryFrame:GetFrameLevel() + 5)
        categoryFrame.titleBtn:SetScript("OnEnter", function()
            categoryFrame.title:SetTextColor(0.4, 0.78, 0.95, 1)
            categoryFrame:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
            categoryFrame.toggleBtn:SetBackdropBorderColor(0.3, 0.6, 0.9, 0.8)
            categoryFrame.toggleLabel:SetTextColor(0.4, 0.78, 0.95, 1)
        end)
        categoryFrame.titleBtn:SetScript("OnLeave", function()
            categoryFrame.title:SetTextColor(0.7, 0.78, 0.88, 1)
            categoryFrame:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
            categoryFrame.toggleBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
            categoryFrame.toggleLabel:SetTextColor(0.5, 0.55, 0.65, 1)
        end)

        -- Store in list for reflow
        table.insert(categoryFramesList, categoryFrame)
        
        -- Immediately update the column Y position so subsequent categories use the correct anchor.
        -- Use collapsed height if category starts collapsed
        local effectiveHeight = categoryFrame.isCollapsed and COLLAPSED_HEIGHT or categoryHeight
        if isLeftColumn then
            leftColumnY = leftColumnY - (effectiveHeight + 8)
        else
            rightColumnY = rightColumnY - (effectiveHeight + 8)
        end

        -- Create progress bar container
        local progressContainer = CreateFrame("Frame", nil, categoryFrame)
        progressContainer:SetHeight(18)
        progressContainer:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 10, -30)
        progressContainer:SetPoint("TOPRIGHT", categoryFrame, "TOPRIGHT", -10, -30)
        categoryFrame.progressContainer = progressContainer
        
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
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1
        })
        pBar:SetBackdropColor(0.08, 0.08, 0.1, 0.8)
        pBar:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)
        
        -- Text for progress bar
        pBar.Text = pBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pBar.Text:SetPoint("CENTER", pBar, "CENTER", 0, 0)
        pBar.Text:SetTextColor(0.85, 0.9, 0.95, 1)
        
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
        
        -- Allow rendering up to the number of mounts defined in data.
        -- ThrottledMountCreation applies faction + hide-collected filtering while incrementing displayedIndex.
        local maxDisplayMounts = #mountList
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

        -- Mount count shown next to title (always visible)
        categoryFrame.inlineCount = categoryFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        categoryFrame.inlineCount:SetPoint("LEFT", categoryFrame.title, "RIGHT", 6, 0)
        categoryFrame.inlineCount:SetText(string.format("|cff888888(%d/%d)|r", collectedMounts, totalMounts))
        categoryFrame.inlineCount:SetTextColor(0.5, 0.5, 0.5, 1)

        -- Apply initial collapsed state
        local function SetCategoryCollapsed(cf, collapsed)
            cf.isCollapsed = collapsed
            if collapsed then
                cf:SetHeight(COLLAPSED_HEIGHT)
                cf.toggleLabel:SetText("+")
                -- Hide all children except titleBtn and toggleBtn
                for _, child in ipairs({cf:GetChildren()}) do
                    if child ~= cf.titleBtn and child ~= cf.toggleBtn then
                        child:Hide()
                    end
                end
            else
                cf:SetHeight(cf.expandedHeight)
                cf.toggleLabel:SetText("\226\136\146")  -- minus sign U+2212
                -- Show all children
                for _, child in ipairs({cf:GetChildren()}) do
                    child:Show()
                end
            end
        end
        categoryFrame.SetCollapsed = SetCategoryCollapsed

        if categoryFrame.isCollapsed then
            SetCategoryCollapsed(categoryFrame, true)
        end

        -- Toggle click handler
        categoryFrame.titleBtn:SetScript("OnClick", function()
            local newState = not categoryFrame.isCollapsed
            MCL_SETTINGS.collapsedCategories[categoryFrame.collapseKey] = newState or nil
            SetCategoryCollapsed(categoryFrame, newState)
            -- Reflow all categories in this section
            local leftY = -50
            local rightY = -50
            for idx, cf in ipairs(categoryFramesList) do
                local isLeft = (idx % 2 == 1)
                local x = isLeft and leftColumnX or rightColumnX
                local y = isLeft and leftY or rightY
                cf:ClearAllPoints()
                cf:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", x, y)
                local h = cf.isCollapsed and COLLAPSED_HEIGHT or cf.expandedHeight
                if isLeft then
                    leftY = leftY - (h + 8)
                else
                    rightY = rightY - (h + 8)
                end
            end
            -- Update parent height
            local maxY = math.min(leftY, rightY)
            relativeFrame:SetHeight(math.abs(maxY) + 20)
        end)
        
    end
    end -- hideCollected else
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
    local navFrame = MCLcore.MCL_MF_Nav
    if navFrame and navFrame.tabs then
        for _, tab in ipairs(navFrame.tabs) do
            if tab.content and tab.content:IsShown() then
                selectedTabName = tab.section and tab.section.name
                break
            end
        end
    end
    
    -- Hide search dropdown during refresh (it's an overlay, will reappear if user searches again)
    if MCLcore.Search and MCLcore.Search.HideSearchDropdown then
        MCLcore.Search:HideSearchDropdown()
    end
    
    -- Update scroll frame size
    MCL_mainFrame.ScrollFrame:ClearAllPoints()
    MCL_mainFrame.ScrollFrame:SetPoint("TOPLEFT", MCL_mainFrame, "TOPLEFT", 10, -40)
    MCL_mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", MCL_mainFrame, "BOTTOMRIGHT", -10, 10)
    
    -- Update scroll child size (width matches ScrollFrame viewport)
    if MCL_mainFrame.ScrollChild then
        local currentWidth, currentHeight = MCL_frames:GetCurrentFrameDimensions()
        MCL_mainFrame.ScrollChild:SetSize(currentWidth - 20, currentHeight)
    end
    
    -- Update navigation frame height to match main frame
    if MCLcore.MCL_MF_Nav then
        local _, currentHeight = MCL_frames:GetCurrentFrameDimensions()
        MCLcore.MCL_MF_Nav:SetHeight(currentHeight)
    end
    
    -- Recreate tabs with new dimensions
    if MCL_frames.SetTabs then
        MCL_frames:SetTabs()
        
        -- If we're on the overview page, we need to refresh it since it has dynamic content
        if selectedTabName == "Overview" and MCLcore.overview then
            -- Clear existing overview content using shared helper
            ReleaseFrameChildren(MCLcore.overview)
            
            -- Clear the overview frames array to prevent duplicates
            if MCLcore.overviewFrames then
                MCLcore.overviewFrames = {}
            end
            
            -- Recreate overview content with new dimensions
            if MCLcore.sections and MCL_frames.createOverviewCategory then
                MCL_frames:createOverviewCategory(MCLcore.sections, MCLcore.overview)
            end
        end
        
        -- Restore the previously selected tab
        if selectedTabName and navFrame and navFrame.tabs then
            for _, tab in ipairs(navFrame.tabs) do
                if tab.section and tab.section.name == selectedTabName then
                    -- Use the same selection logic as in SetTabs
                    for _, t in ipairs(navFrame.tabs) do
                        if t.content then t.content:Hide() end
                        if t.SetBackdropBorderColor then
                            t:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
                            t:SetBackdropColor(0.1, 0.1, 0.14, 0.9)
                            if t.text then t.text:SetTextColor(0.7, 0.78, 0.88, 1) end
                        end
                    end
                    if tab.SetBackdropBorderColor then
                        tab:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
                        tab:SetBackdropColor(0.15, 0.18, 0.25, 1)
                        if tab.text then tab.text:SetTextColor(0.5, 0.85, 1, 1) end
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
