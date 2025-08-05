local _, MCLcore = ...;

-- Initialize search functionality when the addon loads
local function InitializeSearch()
    if not MCLcore.Search then
        -- Search functionality namespace
        MCLcore.Search = {}

        -- Search state
        MCLcore.Search.searchResults = {}
        MCLcore.Search.currentSearchTerm = ""
        MCLcore.Search.isSearchActive = false

        -- Search functionality
        function MCLcore.Search:PerformSearch(searchTerm)
            if not searchTerm or searchTerm == "" then
                self:ClearSearch()
                return
            end
            
            -- Remove leading and trailing whitespace
            searchTerm = searchTerm:gsub("^%s*(.-)%s*$", "%1")
            if searchTerm == "" then
                self:ClearSearch()
                return
            end
            
            self.currentSearchTerm = searchTerm:lower()
            self.isSearchActive = true
            self.searchResults = {}
            
            -- Search through all mounts in all sections
            for sectionIndex, section in ipairs(MCLcore.sectionNames) do
                if section.mounts then
                    -- Handle different mount data structures
                    local categories = section.mounts.categories or section.mounts
                    if categories then
                        for categoryName, categoryData in pairs(categories) do
                            if type(categoryData) == "table" then
                                -- Combine both mounts and mountID arrays for search
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
                                    local mount_Id = MCLcore.Function:GetMountID(mountId)
                                    if mount_Id then
                                        local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mount_Id)
                                        local isCollected = IsMountCollected(mount_Id)
                                        
                                        -- Skip collected mounts if the setting is enabled
                                        if MCL_SETTINGS.hideCollectedMounts and isCollected then
                                            -- Skip this mount entirely
                                        else
                                            -- Search both mount name and item name (if applicable)
                                            local matchFound = false
                                            local matchedName = nil
                                            local searchTerm = self.currentSearchTerm
                                            
                                            -- Check mount name
                                            if mountName and mountName:lower():find(searchTerm, 1, true) then
                                                matchFound = true
                                                matchedName = mountName
                                            end
                                            
                                            -- If mount has an item ID, also check the item name
                                            if not matchFound and type(mountId) == "number" then
                                                local itemName = GetItemInfo(mountId)
                                                if itemName and itemName:lower():find(searchTerm, 1, true) then
                                                    matchFound = true
                                                    matchedName = itemName
                                                end
                                            end
                                            
                                            if matchFound then
                                                table.insert(self.searchResults, {
                                                    mountId = mountId,
                                                    mountName = mountName,
                                                    matchedName = matchedName,
                                                    icon = icon,
                                                    spellID = spellID,
                                                    section = section.name,
                                                    category = categoryData.name or categoryName,
                                                    isCollected = isCollected
                                                })
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            -- Display search results
            self:DisplaySearchResults()
        end        function MCLcore.Search:ClearSearch()
            self.currentSearchTerm = ""
            self.isSearchActive = false
            self.searchResults = {}
            
            -- Clear any highlighting
            self:ClearHighlighting()
            
            -- Properly destroy search results content frame
            self:DestroySearchResultsFrame()
            
            -- Clear search text in navigation frame
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
            
            -- Restore the previously selected tab using the proper SelectTab function
            if self.previouslySelectedTab then
                -- We need to call the SelectTab function from frames.lua
                -- Since it's local, we'll replicate its logic here
                if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                    -- Deselect all tabs first
                    for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                        if t.SetBackdropBorderColor then
                            t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                        end
                    end
                    -- Hide all tab contents
                    for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                        if t.content then
                            t.content:Hide()
                        end
                    end
                    -- Restore the selected tab
                    if self.previouslySelectedTab.SetBackdropBorderColor then
                        self.previouslySelectedTab:SetBackdropBorderColor(1, 0.82, 0, 1)
                    end
                    if self.previouslySelectedTab.content and MCL_mainFrame.ScrollFrame then
                        -- Always keep the main scroll child as the scroll child
                        MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                        self.previouslySelectedTab.content:Show()
                        MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
                    end
                    -- Update global reference
                    MCLcore.currentlySelectedTab = self.previouslySelectedTab
                end
                self.previouslySelectedTab = nil
            end
        end

        function MCLcore.Search:ClearSearchAndGoToOverview()
            self.currentSearchTerm = ""
            self.isSearchActive = false
            self.searchResults = {}
            
            -- Clear any highlighting
            self:ClearHighlighting()
            
            -- Properly destroy search results content frame
            self:DestroySearchResultsFrame()
            
            -- Clear search text in navigation frame
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
            
            -- Always go to Overview tab regardless of previous selection
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                -- Find the Overview tab (should be the first one)
                local overviewTab = nil
                for _, tab in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                    if tab.section and tab.section.name == "Overview" then
                        overviewTab = tab
                        break
                    end
                end
                
                if overviewTab then
                    -- Deselect all tabs first
                    for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                        if t.SetBackdropBorderColor then
                            t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                        end
                    end
                    -- Hide all tab contents using the proper HideAllTabContents function
                    if MCLcore.HideAllTabContents then
                        MCLcore.HideAllTabContents()
                    else
                        -- Fallback: Hide all tab contents manually
                        for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                            if t.content then
                                t.content:Hide()
                            end
                        end
                    end
                    -- Select the Overview tab
                    if overviewTab.SetBackdropBorderColor then
                        overviewTab:SetBackdropBorderColor(1, 0.82, 0, 1)
                    end
                    if overviewTab.content and MCL_mainFrame.ScrollFrame then
                        -- Always keep the main scroll child as the scroll child
                        MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                        overviewTab.content:Show()
                        MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
                    end
                    -- Update global reference
                    MCLcore.currentlySelectedTab = overviewTab
                end
            end
            
            -- Clear the previously selected tab since we're defaulting to Overview
            self.previouslySelectedTab = nil
        end
        function MCLcore.Search:DisplaySearchResults()
            if not MCL_mainFrame then return end
            
            -- Store the currently selected tab so we can restore it later
            if MCLcore.currentlySelectedTab and not self.previouslySelectedTab then
                self.previouslySelectedTab = MCLcore.currentlySelectedTab
            end
            
            -- Hide all tab contents first
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                    if t.content then
                        t.content:Hide()
                    end
                end
                -- Deselect all tabs visually
                for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                    if t.SetBackdropBorderColor then
                        t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                    end
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
            
            -- Create or get search results content frame
            if not MCLcore.searchResultsContent then
                MCLcore.searchResultsContent = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, "Search Results")
                -- Ensure search results content is properly layered
                MCLcore.searchResultsContent:SetFrameStrata("MEDIUM")
                MCLcore.searchResultsContent:SetFrameLevel(10)
            end
            
            -- Update search results content
            self:UpdateSearchResultsContent()
            
            -- Show search results in main frame
            if MCL_mainFrame.ScrollFrame then
                -- Always keep the main scroll child as the scroll child
                MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                MCLcore.searchResultsContent:Show()
                MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
            end
        end        function MCLcore.Search:UpdateSearchResultsContent()
            if not MCLcore.searchResultsContent then return end
            
            local content = MCLcore.searchResultsContent
            
            -- Clear existing content more thoroughly
            -- First hide and remove all children except the title
            for i = content:GetNumChildren(), 1, -1 do
                local child = select(i, content:GetChildren())
                if child and child ~= content.title then
                    child:Hide()
                    child:SetParent(nil)
                end
            end
            
            -- Also clear any FontStrings that were created directly on the content frame
            -- We need to track and clear these separately since they're not children
            if content.searchFontStrings then
                for _, fontString in ipairs(content.searchFontStrings) do
                    if fontString then
                        fontString:Hide()
                        fontString:SetParent(nil)
                    end
                end
            end
            content.searchFontStrings = {}
            
            -- Update title
            content.title:SetText(string.format("Search Results: '%s' (%d found)", self.currentSearchTerm, #self.searchResults))
            
            if #self.searchResults == 0 then
                -- Show no results message
                if not content.noResultsText then
                    content.noResultsText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    content.noResultsText:SetPoint("TOP", content.title, "BOTTOM", 0, -20)
                    content.noResultsText:SetTextColor(0.7, 0.7, 0.7, 1)
                    table.insert(content.searchFontStrings, content.noResultsText)
                end
                content.noResultsText:SetText("No mounts found matching your search.")
                content.noResultsText:Show()
                return
            else
                if content.noResultsText then
                    content.noResultsText:Hide()
                end
            end
            
            -- Group results by section, then by category
            local groupedResults = {}
            for _, result in ipairs(self.searchResults) do
                if not groupedResults[result.section] then
                    groupedResults[result.section] = {}
                end
                if not groupedResults[result.section][result.category] then
                    groupedResults[result.section][result.category] = {}
                end
                table.insert(groupedResults[result.section][result.category], result)
            end
            
            -- Calculate layout dimensions
            local currentWidth, _ = MCLcore.Frames:GetCurrentFrameDimensions()
            local availableWidth = currentWidth - 60
            
            -- Start with user's preferred mounts per row
            local mountsPerRow = MCL_SETTINGS.mountsPerRow or 12  -- Use setting or default to 12
            -- Ensure it's within bounds
            mountsPerRow = math.max(6, math.min(mountsPerRow, 24))
            
            -- Calculate mount size to fit exactly within available width
            local desiredSpacing = 4  -- Fixed spacing between mounts
            local minMountSize = 16  -- Absolute minimum mount size
            local maxMountSize = 48  -- Maximum mount size
            
            -- Try the preferred mounts per row first
            local totalSpacingWidth = desiredSpacing * (mountsPerRow - 1)
            local availableForMounts = availableWidth - totalSpacingWidth
            local mountSize = math.floor(availableForMounts / mountsPerRow)
            
            -- If mount size is too small, reduce mounts per row until we get acceptable size
            while mountSize < minMountSize and mountsPerRow > 6 do
                mountsPerRow = mountsPerRow - 1
                totalSpacingWidth = desiredSpacing * (mountsPerRow - 1)
                availableForMounts = availableWidth - totalSpacingWidth
                mountSize = math.floor(availableForMounts / mountsPerRow)
            end
            
            -- Ensure mount size is within bounds
            mountSize = math.max(minMountSize, math.min(mountSize, maxMountSize))
            
            -- Recalculate actual spacing to center the grid
            local actualMountWidth = mountSize * mountsPerRow
            local spacing = mountsPerRow > 1 and math.floor((availableWidth - actualMountWidth) / (mountsPerRow - 1)) or 0
            spacing = math.max(1, spacing)  -- Minimum 1px spacing
            
            local currentY = -80 -- Start below title
            local mountIndex = 0
            
            -- Display results grouped by section and category
            for sectionName, sectionData in pairs(groupedResults) do
                -- Create section header
                local sectionHeader = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                sectionHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 10, currentY)
                sectionHeader:SetText(sectionName)
                sectionHeader:SetTextColor(1, 0.82, 0, 1) -- Gold color like Blizzard UI
                table.insert(content.searchFontStrings, sectionHeader)
                currentY = currentY - 25
                
                for categoryName, categoryMounts in pairs(sectionData) do
                    -- Create category header
                    local categoryHeader = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    categoryHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 20, currentY)
                    categoryHeader:SetText(categoryName .. " (" .. #categoryMounts .. ")")
                    categoryHeader:SetTextColor(0.8, 0.8, 1, 1) -- Light blue color
                    table.insert(content.searchFontStrings, categoryHeader)
                    currentY = currentY - 20
                    
                    -- Display mounts for this category
                    local categoryStartY = currentY
                    local categoryMountIndex = 0
                    
                    for _, result in ipairs(categoryMounts) do
                        local col = (categoryMountIndex % mountsPerRow)
                        local row = math.floor(categoryMountIndex / mountsPerRow)
                        
                        local x = spacing + col * (mountSize + spacing)
                        local y = categoryStartY - row * (mountSize + 10)
                          -- Create mount frame
                        local mountFrame = CreateFrame("Button", nil, content, "BackdropTemplate")
                        mountFrame:SetSize(mountSize, mountSize)
                        mountFrame:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
                        
                        -- Set mount icon
                        mountFrame.tex = mountFrame:CreateTexture(nil, "ARTWORK")
                        mountFrame.tex:SetAllPoints(mountFrame)
                        mountFrame.tex:SetTexture(result.icon)
                          -- Add pin functionality (required for pin/unpin operations)
                        mountFrame.pin = mountFrame:CreateTexture(nil, "OVERLAY")
                        mountFrame.pin:SetWidth(16)
                        mountFrame.pin:SetHeight(16)
                        mountFrame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
                        mountFrame.pin:SetPoint("TOPRIGHT", mountFrame, "TOPRIGHT", -2, -2)
                        mountFrame.pin:SetAlpha(0)
                        
                        -- Set mount properties for functionality
                        mountFrame.mountID = result.mountId
                        mountFrame.category = result.category
                        mountFrame.section = result.section
                        
                        -- Check if mount is already pinned and show pin icon if needed
                        local isPinned, pinIndex = MCLcore.Function:CheckIfPinned("m" .. result.mountId)
                        if isPinned then
                            mountFrame.pin:SetAlpha(1)
                        end                        -- Style based on collection status
                        -- Note: With hideCollectedMounts enabled, collected mounts won't be in search results
                        if result.isCollected then
                            mountFrame.tex:SetVertexColor(1, 1, 1, 1)
                            mountFrame:SetBackdrop({
                                bgFile = "Interface\\Buttons\\WHITE8x8",
                                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                edgeSize = 2
                            })
                            mountFrame:SetBackdropColor(0, 0.8, 0, 0.6)
                            mountFrame:SetBackdropBorderColor(0, 1, 0, 1)
                        else
                            mountFrame.tex:SetVertexColor(0.4, 0.4, 0.4, 0.7)
                            mountFrame:SetBackdrop({
                                bgFile = "Interface\\Buttons\\WHITE8x8",
                                edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                edgeSize = 2
                            })
                            mountFrame:SetBackdropColor(0.8, 0, 0, 0.4)
                            mountFrame:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
                        end                        -- Add tooltip and click functionality
                        mountFrame:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            
                            -- Check if this mount has an item ID (number) vs mount ID (string starting with "m")
                            -- If it's an item ID, show the item tooltip; otherwise show the mount spell tooltip
                            if type(result.mountId) == "number" then
                                -- This is an item ID, show item tooltip
                                GameTooltip:SetItemByID(result.mountId)
                            else
                                -- This is a mount ID or spell ID, show mount spell tooltip
                                GameTooltip:SetMountBySpellID(result.spellID)
                            end
                            
                            GameTooltip:AddLine(" ")
                            GameTooltip:AddLine("Found in: " .. result.section .. " > " .. result.category, 0.7, 0.7, 1, 1)
                            
                            -- Show what was matched if it's different from the mount name
                            if result.matchedName and result.matchedName ~= result.mountName then
                                GameTooltip:AddLine("Matched: " .. result.matchedName, 0.7, 1, 0.7, 1)
                            end
                            
                            GameTooltip:AddLine("Click to navigate to this mount's location", 1, 1, 0, 1)
                            GameTooltip:AddLine("Ctrl+Right-Click to pin/unpin this mount", 1, 1, 0, 1)
                            GameTooltip:Show()
                        end)
                        mountFrame:SetScript("OnLeave", function()
                            GameTooltip:Hide()
                        end)
                        
                        -- Set up proper mouse click functionality including pinning
                        MCLcore.Function:SetMouseClickFunctionality(mountFrame, result.mountId, result.mountName, nil, result.spellID, false)
                        
                        -- Override the OnMouseDown handler to include navigation for search results
                        local originalOnMouseDown = mountFrame:GetScript("OnMouseDown")
                        mountFrame:SetScript("OnMouseDown", function(self, button)
                            if button == "LeftButton" and not IsControlKeyDown() and not IsShiftKeyDown() then
                                -- Navigate to the mount's location for search results
                                MCLcore.Search:NavigateToMount(result)
                            else
                                -- Call the original OnMouseDown handler for other functionality
                                if originalOnMouseDown then
                                    originalOnMouseDown(self, button)
                                end
                            end
                        end)
                        
                        -- Ensure mouse interaction is enabled
                        mountFrame:EnableMouse(true)
                        mountFrame:SetFrameStrata("HIGH")
                        mountFrame:SetFrameLevel(10)
                        
                        categoryMountIndex = categoryMountIndex + 1
                    end
                    
                    -- Calculate how much Y space this category used
                    local categoryRows = math.ceil(#categoryMounts / mountsPerRow)
                    currentY = categoryStartY - categoryRows * (mountSize + 10) - 10 -- Add some spacing after category
                end
                
                -- Add extra spacing after each section
                currentY = currentY - 10
            end
        end
        function MCLcore.Search:NavigateToMount(result)
            -- Store the target section for navigation
            local targetSection = result.section
            
            -- Clear search state without restoring previous tab
            self.currentSearchTerm = ""
            self.isSearchActive = false
            self.searchResults = {}
            
            -- Clear any highlighting
            self:ClearHighlighting()
            
            -- Properly destroy search results content frame
            self:DestroySearchResultsFrame()
            
            -- Clear search box text
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
            
            -- Clear the previously selected tab reference
            self.previouslySelectedTab = nil
            
            -- Find and select the correct tab for this section
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                for i, tab in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                    if tab.section and tab.section.name == targetSection then
                        -- Use the proper tab selection logic (same as SelectTab function)
                        -- Deselect all tabs first
                        for _, t in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                            if t.SetBackdropBorderColor then
                                t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
                            end
                        end
                        
                        -- Hide all tab contents using the proper HideAllTabContents function
                        if MCLcore.HideAllTabContents then
                            MCLcore.HideAllTabContents()
                        end
                        
                        -- Select the target tab
                        if tab.SetBackdropBorderColor then
                            tab:SetBackdropBorderColor(1, 0.82, 0, 1)
                        end
                        if tab.content and MCL_mainFrame.ScrollFrame then
                            -- Always keep the main scroll child as the scroll child
                            MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                            tab.content:Show()
                            MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
                        end
                        -- Update global reference
                        MCLcore.currentlySelectedTab = tab
                        break
                    end
                end
            end
            
            -- Store the mount to highlight for later
            MCLcore.Search.highlightMountId = result.mountId
            
            -- Schedule highlighting for next frame to ensure content is loaded
            C_Timer.After(0.1, function()
                MCLcore.Search:HighlightMount(result.mountId)
            end)
            
            -- Print info for user feedback
            print("|cff00CCFFMount Collection Log:|r Found '" .. result.mountName .. "' in " .. result.section .. " > " .. result.category)
        end

        function MCLcore.Search:ClearHighlighting()
            -- Clear any existing highlighting effects
            if MCLcore.highlightedMountFrame then
                if MCLcore.highlightedMountFrame.originalBorderColor then
                    MCLcore.highlightedMountFrame:SetBackdropBorderColor(
                        MCLcore.highlightedMountFrame.originalBorderColor[1],
                        MCLcore.highlightedMountFrame.originalBorderColor[2],
                        MCLcore.highlightedMountFrame.originalBorderColor[3],
                        MCLcore.highlightedMountFrame.originalBorderColor[4]
                    )
                end
                if MCLcore.highlightedMountFrame.highlightTimer then
                    MCLcore.highlightedMountFrame.highlightTimer:Cancel()
                end
                MCLcore.highlightedMountFrame = nil
            end
        end

        function MCLcore.Search:HighlightMount(mountId)
            -- Clear any existing highlighting
            self:ClearHighlighting()
            
            -- Find the mount frame in the current content
            local currentContent = MCL_mainFrame.ScrollFrame:GetScrollChild()
            if not currentContent then return end
            
            -- Look for mount frames that match our target mount
            local function FindMountFrame(parent)
                for i = 1, parent:GetNumChildren() do
                    local child = select(i, parent:GetChildren())
                    if child and child.mountID then
                        local mount_Id = MCLcore.Function:GetMountID(child.mountID)
                        local target_Id = MCLcore.Function:GetMountID(mountId)
                        if mount_Id and target_Id and mount_Id == target_Id then
                            return child
                        end
                    end
                    -- Recursively search children
                    local found = FindMountFrame(child)
                    if found then return found end
                end
            end
            
            local mountFrame = FindMountFrame(currentContent)
            if mountFrame then
                -- Store original border color
                local r, g, b, a = mountFrame:GetBackdropBorderColor()
                mountFrame.originalBorderColor = {r, g, b, a}
                
                -- Store reference for cleanup
                MCLcore.highlightedMountFrame = mountFrame
                
                -- Create pulsing highlight effect
                local pulseTimer
                local pulseCount = 0
                local maxPulses = 6
                
                pulseTimer = C_Timer.NewTicker(0.5, function()
                    pulseCount = pulseCount + 1
                    if pulseCount > maxPulses then
                        -- Restore original color and stop
                        if mountFrame.originalBorderColor then
                            mountFrame:SetBackdropBorderColor(
                                mountFrame.originalBorderColor[1],
                                mountFrame.originalBorderColor[2],
                                mountFrame.originalBorderColor[3],
                                mountFrame.originalBorderColor[4]
                            )
                        end
                        pulseTimer:Cancel()
                        MCLcore.highlightedMountFrame = nil
                        return
                    end
                    
                    -- Pulse between yellow and original color
                    if pulseCount % 2 == 1 then
                        mountFrame:SetBackdropBorderColor(1, 1, 0, 1) -- Bright yellow
                    else
                        mountFrame:SetBackdropBorderColor(
                            mountFrame.originalBorderColor[1],
                            mountFrame.originalBorderColor[2],
                            mountFrame.originalBorderColor[3],
                            mountFrame.originalBorderColor[4]
                        )
                    end
                end)
                
                mountFrame.highlightTimer = pulseTimer
                
                -- Scroll to the mount if needed
                local frameTop = currentContent:GetTop()
                local frameBottom = currentContent:GetBottom()
                local mountTop = mountFrame:GetTop()
                local mountBottom = mountFrame:GetBottom()
                
                if frameTop and frameBottom and mountTop and mountBottom then
                    local scrollFrame = MCL_mainFrame.ScrollFrame
                    local scrollTop = scrollFrame:GetTop()
                    local scrollBottom = scrollFrame:GetBottom()
                    
                    -- Check if mount is not visible in scroll area
                    if mountTop > scrollTop or mountBottom < scrollBottom then
                        -- Calculate scroll position to center the mount
                        local scrollHeight = scrollFrame:GetVerticalScrollRange()
                        local contentHeight = frameTop - frameBottom
                        local mountCenter = (mountTop + mountBottom) / 2
                        local targetScroll = (frameTop - mountCenter) / contentHeight * scrollHeight
                        
                        -- Clamp to valid scroll range
                        targetScroll = math.max(0, math.min(targetScroll, scrollHeight))
                        scrollFrame:SetVerticalScroll(targetScroll)
                    end
                end
            end
        end
        
        function MCLcore.Search:RecreateSearchResultsFrame()
            if not MCLcore.searchResultsContent then return end
            
            -- Hide and remove the old search results content frame
            MCLcore.searchResultsContent:Hide()
            MCLcore.searchResultsContent:SetParent(nil)
            MCLcore.searchResultsContent = nil
            
            -- Create new search results content frame with updated dimensions
            MCLcore.searchResultsContent = MCLcore.Frames:createContentFrame(MCL_mainFrame.ScrollChild, "Search Results")
            
            -- Update the content
            self:UpdateSearchResultsContent()
            
            -- Show the new frame
            if MCL_mainFrame.ScrollFrame then
                -- Always keep the main scroll child as the scroll child
                MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                MCLcore.searchResultsContent:Show()
                MCL_mainFrame.ScrollFrame:SetVerticalScroll(0)
            end
        end
        
        function MCLcore.Search:DestroySearchResultsFrame()
            if MCLcore.searchResultsContent then
                -- Hide and remove the search results content frame
                MCLcore.searchResultsContent:Hide()
                MCLcore.searchResultsContent:SetParent(nil)
                MCLcore.searchResultsContent = nil
                
                -- Ensure the main scroll child is set as the scroll child
                if MCL_mainFrame.ScrollFrame and MCL_mainFrame.ScrollChild then
                    MCL_mainFrame.ScrollFrame:SetScrollChild(MCL_mainFrame.ScrollChild)
                end
            end
        end
    end
end

-- Make InitializeSearch available globally so it can be called when addon loads
MCLcore = MCLcore or {}
MCLcore.InitializeSearch = InitializeSearch

-- Namespace
-------------------------------------------------------------

SLASH_MCL1 = "/mcl";

SlashCmdList["MCL"] = function(msg)
    if msg:lower() == "help" then
        print(MCLcore.L["|cff00CCFFMount Collection Log Commands:\n|cffFF0000Show:|cffFFFFFF Shows your mount collection log\n|cffFF0000Icon:|cffFFFFFF Toggles the minimap icon\n|cffFF0000Config:|cffFFFFFF Opens the settings\n|cffFF0000Help:|cffFFFFFF Shows commands"])
    end
    if msg:lower() == "show" then
        MCLcore.Main.Toggle();
    end
    if msg:lower() == "icon" then
        MCLcore.Function.MCL_MM();
    end        
    if msg:lower() == "" then
        MCLcore.Main.Toggle();
    end
    if msg:lower() == "debug" then
        MCLcore.Function:GetCollectedMounts();
    end
    if msg:lower() == "debugmounts" then
        -- Re-run mount validation with debug enabled
        if MCLcore.Main then
            MCLcore.Main:Init(true)  -- Force re-initialization with debug
        end
    end
    if msg:lower() == "config" or msg == "settings" then
        MCLcore.Frames:openSettings();
    end
    if msg:lower() == "refresh" then
        if MCLcore.Main and type(MCLcore.Main.Init) == "function" then
            MCLcore.Main:Init(true)  -- True to force re-initialization.
        end
    end
    if msg:lower() == "cleanup" or msg:lower() == "cleanpinned" then
        if MCLcore.Function and MCLcore.Function.CleanupInvalidPinnedMounts then
            print("|cff00CCFF[MCL]|r Starting cleanup of invalid pinned mounts...")
            MCLcore.Function:CleanupInvalidPinnedMounts()
            print("|cff00CCFF[MCL]|r Cleanup complete. Try viewing the Pinned tab now.")
        else
            print("|cffFF0000[MCL]|r Cleanup function not available.")
        end
    end
    if msg:lower() == "testmount" then
        -- Test a known mount ID to see what the API returns
        local testId = 230  -- Swift Palomino - a basic mount that should exist
        local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(testId)
            
        -- Also test one of the problematic IDs if MCL_PINNED exists
        if MCL_PINNED and #MCL_PINNED > 0 then
            local firstPinned = MCL_PINNED[1]
            if firstPinned and firstPinned.mountID then
                local mountId = firstPinned.mountID
                local mount_Id = nil
                if string.sub(tostring(mountId), 1, 1) == "m" then
                    mount_Id = tonumber(string.sub(tostring(mountId), 2, -1))
                end
                if mount_Id then
                    local pMountName, pSpellID, pIcon = C_MountJournal.GetMountInfoByID(mount_Id)
                end
            end
        end
    end
 end
