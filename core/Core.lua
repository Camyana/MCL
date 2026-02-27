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
            
            -- Hide the search dropdown
            self:HideSearchDropdown()
            
            -- Clear search text in navigation frame
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
        end

        function MCLcore.Search:ClearSearchAndGoToOverview()
            self.currentSearchTerm = ""
            self.isSearchActive = false
            self.searchResults = {}
            
            -- Clear any highlighting
            self:ClearHighlighting()
            
            -- Hide the search dropdown
            self:HideSearchDropdown()
            
            -- Clear search text in navigation frame
            if MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.searchBox then
                MCLcore.MCL_MF_Nav.searchBox:SetText("")
                if MCLcore.MCL_MF_Nav.searchPlaceholder then
                    MCLcore.MCL_MF_Nav.searchPlaceholder:Show()
                end
            end
        end
        function MCLcore.Search:DisplaySearchResults()
            if not MCL_mainFrame then return end

            -- Show results as a dropdown list anchored to the search bar
            self:ShowSearchDropdown()
        end

        function MCLcore.Search:HideSearchDropdown()
            if MCLcore.searchDropdown then
                MCLcore.searchDropdown:Hide()
            end
        end

        function MCLcore.Search:ShowSearchDropdown()
            local nav = MCLcore.MCL_MF_Nav
            if not nav or not nav.searchContainer then return end

            -- Create the dropdown frame once, reuse it
            if not MCLcore.searchDropdown then
                local dd = CreateFrame("Frame", "MCLSearchDropdown", UIParent, "BackdropTemplate")
                dd:SetFrameStrata("TOOLTIP")  -- Above everything
                dd:SetFrameLevel(200)
                dd:SetClampedToScreen(true)
                dd:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Buttons\\WHITE8x8",
                    edgeSize = 1
                })
                dd:SetBackdropColor(0.06, 0.06, 0.09, 0.97)
                dd:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.8)

                -- Scroll frame inside the dropdown
                dd.scroll = CreateFrame("ScrollFrame", nil, dd, "UIPanelScrollFrameTemplate")
                dd.scroll:SetPoint("TOPLEFT", dd, "TOPLEFT", 6, -6)
                dd.scroll:SetPoint("BOTTOMRIGHT", dd, "BOTTOMRIGHT", -24, 6)

                dd.scrollChild = CreateFrame("Frame", nil, dd.scroll)
                dd.scrollChild:SetWidth(1) -- will be set properly on show
                dd.scroll:SetScrollChild(dd.scrollChild)

                -- Style the scrollbar
                dd.scroll.ScrollBar:SetPoint("TOPLEFT", dd.scroll, "TOPRIGHT", 2, -16)
                dd.scroll.ScrollBar:SetPoint("BOTTOMLEFT", dd.scroll, "BOTTOMRIGHT", 2, 16)

                MCLcore.searchDropdown = dd
            end

            local dd = MCLcore.searchDropdown

            -- Position dropdown: below the search bar, extending to the right
            dd:ClearAllPoints()
            dd:SetPoint("TOPLEFT", nav.searchContainer, "BOTTOMLEFT", 0, -2)
            -- Width: extend across the main frame
            local ddWidth = 400
            local maxHeight = 420
            dd:SetSize(ddWidth, maxHeight)
            dd.scrollChild:SetWidth(ddWidth - 30)

            -- Clear old rows
            if dd.rows then
                for _, row in ipairs(dd.rows) do
                    row:Hide()
                    row:ClearAllPoints()
                    row:SetParent(nil)
                end
            end
            dd.rows = {}

            -- Hide previous "more" text if it exists
            if dd.moreText then
                dd.moreText:Hide()
            end

            -- Header: result count (reuse existing FontString)
            local headerHeight = 20
            if not dd.header then
                dd.header = dd.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                dd.header:SetPoint("TOPLEFT", dd.scrollChild, "TOPLEFT", 4, -2)
                dd.header:SetTextColor(0.5, 0.55, 0.65, 1)
            end
            local header = dd.header
            header:Show()

            if #self.searchResults == 0 then
                header:SetText("No mounts found matching '" .. self.currentSearchTerm .. "'")
                dd.scrollChild:SetHeight(headerHeight + 8)
                dd:SetHeight(headerHeight + 20)
                dd:Show()
                return
            end

            header:SetText(string.format("%d result%s", #self.searchResults, #self.searchResults == 1 and "" or "s"))

            -- Build rows
            local rowHeight = 24
            local yOffset = -(headerHeight + 4)
            local maxResults = 50  -- Cap displayed results for performance

            for i, result in ipairs(self.searchResults) do
                if i > maxResults then break end

                local row = CreateFrame("Button", nil, dd.scrollChild, "BackdropTemplate")
                row:SetSize(ddWidth - 32, rowHeight)
                row:SetPoint("TOPLEFT", dd.scrollChild, "TOPLEFT", 2, yOffset)

                -- Hover highlight
                row:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                })
                row:SetBackdropColor(0, 0, 0, 0)  -- transparent by default
                row:SetScript("OnEnter", function(self)
                    self:SetBackdropColor(0.15, 0.18, 0.25, 0.6)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    if type(result.mountId) == "number" then
                        GameTooltip:SetItemByID(result.mountId)
                    else
                        GameTooltip:SetMountBySpellID(result.spellID)
                    end
                    GameTooltip:Show()
                end)
                row:SetScript("OnLeave", function(self)
                    self:SetBackdropColor(0, 0, 0, 0)
                    GameTooltip:Hide()
                end)

                -- Click: navigate to mount
                row:SetScript("OnClick", function(_, button)
                    if button == "LeftButton" then
                        dd:Hide()
                        MCLcore.Search:NavigateToMount(result)
                    end
                end)
                row:EnableMouse(true)

                -- Icon
                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(rowHeight - 4, rowHeight - 4)
                icon:SetPoint("LEFT", row, "LEFT", 4, 0)
                icon:SetTexture(result.icon)
                if not result.isCollected then
                    icon:SetDesaturated(true)
                    icon:SetAlpha(0.6)
                end

                -- Mount name
                local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
                nameText:SetWidth(ddWidth - 180)
                nameText:SetJustifyH("LEFT")
                nameText:SetWordWrap(false)
                if result.isCollected then
                    nameText:SetText(result.mountName or "Unknown")
                    nameText:SetTextColor(0.7, 0.78, 0.88, 1)
                else
                    nameText:SetText(result.mountName or "Unknown")
                    nameText:SetTextColor(0.45, 0.5, 0.55, 1)
                end

                -- Source (section > category) on the right
                local sourceText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                sourceText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                sourceText:SetJustifyH("RIGHT")
                sourceText:SetTextColor(0.4, 0.45, 0.5, 1)
                local shortSource = result.category or result.section or ""
                if #shortSource > 20 then
                    shortSource = shortSource:sub(1, 18) .. ".."
                end
                sourceText:SetText(shortSource)

                -- Collected indicator (small green dot)
                if result.isCollected then
                    local dot = row:CreateTexture(nil, "OVERLAY")
                    dot:SetSize(8, 8)
                    dot:SetPoint("RIGHT", sourceText, "LEFT", -4, 0)
                    dot:SetColorTexture(0.3, 0.85, 0.3, 1)
                end

                table.insert(dd.rows, row)
                yOffset = yOffset - rowHeight
            end

            -- "and X more..." line if capped
            if #self.searchResults > maxResults then
                if not dd.moreText then
                    dd.moreText = dd.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
                    dd.moreText:SetTextColor(0.4, 0.45, 0.5, 1)
                end
                dd.moreText:ClearAllPoints()
                dd.moreText:SetPoint("TOPLEFT", dd.scrollChild, "TOPLEFT", 8, yOffset - 4)
                dd.moreText:SetText(string.format("...and %d more", #self.searchResults - maxResults))
                dd.moreText:Show()
                yOffset = yOffset - 20
            end

            -- Size the scroll child and dropdown
            local contentHeight = math.abs(yOffset) + 8
            dd.scrollChild:SetHeight(contentHeight)
            dd:SetHeight(math.min(contentHeight + 14, maxHeight))
            dd:Show()
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
                                t:SetBackdropBorderColor(0.25, 0.25, 0.3, 0.6)
                            end
                        end
                        
                        -- Hide all tab contents using the proper HideAllTabContents function
                        if MCLcore.HideAllTabContents then
                            MCLcore.HideAllTabContents()
                        end
                        
                        -- Select the target tab
                        if tab.SetBackdropBorderColor then
                            tab:SetBackdropBorderColor(0.3, 0.6, 0.9, 1)
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
                    MCLcore.highlightedMountFrame.originalBorderColor = nil
                end
                if MCLcore.highlightedMountFrame.highlightTimer then
                    MCLcore.highlightedMountFrame.highlightTimer:Cancel()
                    MCLcore.highlightedMountFrame.highlightTimer = nil
                end
                if MCLcore.highlightedMountFrame.searchGlowFrame then
                    MCLcore.highlightedMountFrame.searchGlowFrame:Hide()
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
                
                -- Create a glow overlay Frame (not texture) so it renders on top of child icon
                if not mountFrame.searchGlowFrame then
                    mountFrame.searchGlowFrame = CreateFrame("Frame", nil, mountFrame)
                    mountFrame.searchGlowFrame:SetAllPoints(mountFrame)
                    mountFrame.searchGlowFrame:SetFrameLevel(mountFrame:GetFrameLevel() + 20)
                    mountFrame.searchGlowFrame.tex = mountFrame.searchGlowFrame:CreateTexture(nil, "OVERLAY", nil, 7)
                    mountFrame.searchGlowFrame.tex:SetAllPoints(mountFrame.searchGlowFrame)
                    mountFrame.searchGlowFrame.tex:SetColorTexture(1, 1, 0, 0.5)
                end
                mountFrame.searchGlowFrame:Show()
                
                -- Pulse indefinitely until user hovers
                local pulseCount = 0
                local pulseTimer = C_Timer.NewTicker(0.35, function()
                    pulseCount = pulseCount + 1
                    if pulseCount % 2 == 1 then
                        mountFrame:SetBackdropBorderColor(0.4, 0.78, 0.95, 1)  -- House style title blue
                        if mountFrame.searchGlowFrame then mountFrame.searchGlowFrame.tex:SetAlpha(0.5) end
                    else
                        mountFrame:SetBackdropBorderColor(0.2, 0.5, 0.85, 1)  -- House style accent blue
                        if mountFrame.searchGlowFrame then mountFrame.searchGlowFrame.tex:SetAlpha(0.15) end
                    end
                end)
                
                mountFrame.highlightTimer = pulseTimer
                
                -- Helper to stop flashing and restore border
                local function StopHighlight(srcFrame)
                    if mountFrame.highlightTimer then
                        mountFrame.highlightTimer:Cancel()
                        mountFrame.highlightTimer = nil
                    end
                    if mountFrame.searchGlowFrame then mountFrame.searchGlowFrame:Hide() end
                    if mountFrame.originalBorderColor then
                        mountFrame:SetBackdropBorderColor(
                            mountFrame.originalBorderColor[1],
                            mountFrame.originalBorderColor[2],
                            mountFrame.originalBorderColor[3],
                            mountFrame.originalBorderColor[4]
                        )
                        mountFrame.originalBorderColor = nil
                    end
                    MCLcore.highlightedMountFrame = nil
                end
                
                -- Hook OnEnter on the backdrop frame itself
                local origOnEnter = mountFrame:GetScript("OnEnter")
                mountFrame:SetScript("OnEnter", function(self, ...)
                    StopHighlight(self)
                    if origOnEnter then origOnEnter(self, ...) end
                end)
                
                -- Also hook OnEnter on child Button (the actual icon that receives mouse events)
                for i = 1, mountFrame:GetNumChildren() do
                    local child = select(i, mountFrame:GetChildren())
                    if child and child:IsObjectType("Button") and child.mountID then
                        local childOrigOnEnter = child:GetScript("OnEnter")
                        child:SetScript("OnEnter", function(self, ...)
                            StopHighlight(self)
                            if childOrigOnEnter then childOrigOnEnter(self, ...) end
                        end)
                        break
                    end
                end
                
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
            -- No longer needed — dropdown is rebuilt each search
        end
        
        function MCLcore.Search:DestroySearchResultsFrame()
            -- Hide the dropdown if visible
            self:HideSearchDropdown()
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
    local cmd = msg:lower()
    if cmd == "help" then
        print("|cff00CCFFMount Collection Log Commands:")
        print("|cffFF0000Show:|cffFFFFFF Shows your mount collection log")
        print("|cffFF0000Icon:|cffFFFFFF Toggles the minimap icon")
        print("|cffFF0000Config:|cffFFFFFF Opens the settings")
        print("|cffFF0000Help:|cffFFFFFF Shows commands")
    elseif cmd == "show" or cmd == "" then
        MCLcore.Main.Toggle();
    elseif cmd == "icon" then
        MCLcore.Function.MCL_MM();
    elseif cmd == "debug" then
        MCLcore.Function:GetCollectedMounts();
    elseif cmd == "debugmounts" then
        if MCLcore.Main then
            MCLcore.Main:Init(true)
        end
    elseif cmd == "config" or cmd == "settings" then
        MCLcore.Frames:openSettings();
    elseif cmd == "refresh" then
        if MCLcore.Main and type(MCLcore.Main.Init) == "function" then
            MCLcore.Main:Init(true)
        end
    elseif cmd == "cleanup" or cmd == "cleanpinned" then
        if MCLcore.Function and MCLcore.Function.CleanupInvalidPinnedMounts then
            print("|cff00CCFF[MCL]|r Starting cleanup of invalid pinned mounts...")
            MCLcore.Function:CleanupInvalidPinnedMounts()
            print("|cff00CCFF[MCL]|r Cleanup complete. Try viewing the Pinned tab now.")
        else
            print("|cffFF0000[MCL]|r Cleanup function not available.")
        end
    elseif cmd == "testmount" then
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
