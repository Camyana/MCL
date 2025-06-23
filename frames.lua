local MCL, MCLcore = ...;

local MCL_Load = MCLcore.Main;

MCLcore.Frames = {};
local MCL_frames = MCLcore.Frames;

MCLcore.TabTable = {}
MCLcore.statusBarFrames  = {}

MCLcore.nav_width = 180
local nav_width = MCLcore.nav_width
local main_frame_width = 900
local main_frame_height = 500

local r,g,b,a

local L = MCLcore.L

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
    
    -- Settings button
    MCL_mainFrame.settings = CreateFrame("Button", nil, MCL_mainFrame);
    MCL_mainFrame.settings:SetSize(14, 14)
    if MCL_SETTINGS.useBlizzardTheme then
        MCL_mainFrame.settings:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -40, -8)
    else
        MCL_mainFrame.settings:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -30, 0)
    end
    MCL_mainFrame.settings.tex = MCL_mainFrame.settings:CreateTexture()
    MCL_mainFrame.settings.tex:SetAllPoints(MCL_mainFrame.settings)
    MCL_mainFrame.settings.tex:SetTexture("Interface\\AddOns\\MCL\\icons\\settings.blp")
    MCL_mainFrame.settings:SetScript("OnClick", function()MCL_frames:openSettings()end)

    -- SA button
    MCL_mainFrame.sa = CreateFrame("Button", nil, MCL_mainFrame);
    MCL_mainFrame.sa:SetSize(60, 15)
    if MCL_SETTINGS.useBlizzardTheme then
        MCL_mainFrame.sa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -60, -8)
    else
        MCL_mainFrame.sa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -60, -1)
    end
    MCL_mainFrame.sa.tex = MCL_mainFrame.sa:CreateTexture()
    MCL_mainFrame.sa.tex:SetAllPoints(MCL_mainFrame.sa)
    MCL_mainFrame.sa.tex:SetTexture("Interface\\Buttons\\WHITE8x8")
    MCL_mainFrame.sa.tex:SetVertexColor(0.1,0.1,0.1,0.95, MCL_SETTINGS.opacity)
    MCL_mainFrame.sa.text = MCL_mainFrame.sa:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
    MCL_mainFrame.sa.text:SetPoint("CENTER", MCL_mainFrame.sa, "CENTER", 0, 0);
    MCL_mainFrame.sa.text:SetText("SA")
    MCL_mainFrame.sa.text:SetTextColor(0, 0.7, 0.85)	
    MCL_mainFrame.sa:SetScript("OnClick", function()MCLcore.Function:simplearmoryLink()end)	
	
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
    MCL_mainFrame.dfa:SetScript("OnClick", function()MCLcore.Function:dfaLink()end)		


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
        MCL_mainFrame.title:SetText("Mount Collection Log")

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
        MCLcore.Function:CreateFullBorder(MCL_mainFrame)
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
        for _, t in ipairs(tabFrame.tabs) do
            if t.content then t.content:Hide() end
        end
    end
    local function DeselectAllTabs()
        for _, t in ipairs(tabFrame.tabs) do
            t:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        end
    end
    local function SelectTab(tab)
        DeselectAllTabs()
        HideAllTabContents()
        tab:SetBackdropBorderColor(1, 0.82, 0, 1)
        MCL_mainFrame.ScrollFrame:SetScrollChild(tab.content)
        tab.content:Show()
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
        -- Optionally, populate pinned tab content if you have a function for it
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
        GameTooltip:SetText("Clear Search", 1, 1, 1)
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
    MyStatusBar:SetStatusBarTexture(MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture))
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
    frame:SetBackdropColor(0, 0, 0, 0)  -- Transparent background
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, -15)  -- Added padding: 15px from left and top
    frame.title:SetText(L[title]) -- Localized for display
    frame.name = title -- Store non-localized name

    if title ~= "Pinned" then
        frame.pBar = MCLcore.Frames:progressBar(frame)
        frame.pBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 15, -15)  -- Aligned with title padding
        frame.pBar:SetWidth(availableWidth - 30)  -- Account for padding on both sides
        frame.pBar:SetHeight(20)
    end

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
                                    MCL_mainFrame.ScrollFrame:SetScrollChild(tab.content)
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

    -- Dynamic layout calculation based on current frame width
    local currentWidth, _ = MCL_frames:GetCurrentFrameDimensions()
    local availableWidth = currentWidth - 60  -- Total content width
    local columnSpacing = 25  -- Reduced spacing between columns to use more space
    local numColumns = 2
    local columnWidth = math.floor((availableWidth - columnSpacing * (numColumns - 1)) / numColumns)
    
    local leftColumnX = 0
    local rightColumnX = leftColumnX + columnWidth + columnSpacing
    
    local leftColumnY = -10
    local rightColumnY = -10
    local categoryIndex = 0

    for categoryName, categoryData in pairs(set) do
        
        -- Skip if categoryData is not a table
        if type(categoryData) == "table" then
            categoryIndex = categoryIndex + 1
            
            -- Determine which column to use (alternate left/right)
            local isLeftColumn = (categoryIndex % 2 == 1)
            local xPos = isLeftColumn and leftColumnX or rightColumnX
            local yPos = isLeftColumn and leftColumnY or rightColumnY
            
            -- Calculate mount stats for this category first (needed for dynamic height)
            local totalMounts = 0
            local collectedMounts = 0
            local displayedMounts = 0  -- Track mounts that will actually be displayed
            local mountList = categoryData.mounts or categoryData.mountID or {}
            
            for _, mountId in ipairs(mountList) do
                local mount_Id = MCLcore.Function:GetMountID(mountId)
                if mount_Id then
                    local isCollected = IsMountCollected(mount_Id)
                    totalMounts = totalMounts + 1
                    if isCollected then
                        collectedMounts = collectedMounts + 1
                    end
                    
                    -- Only count towards displayed mounts if we're not hiding collected mounts, or if it's not collected
                    if not (MCL_SETTINGS.hideCollectedMounts and isCollected) then
                        displayedMounts = displayedMounts + 1
                    end
                end
            end
            
            -- Calculate optimal mounts per row based on column width (same calculation as later)
            local categoryPadding = 20  -- Total padding (10px on each side)
            local availableMountWidth = columnWidth - categoryPadding
            local minMountSize = 32  -- Minimum reasonable mount icon size
            local baseSpacing = 4  -- Base spacing between mount icons (reduced from 6)
            
            -- Calculate maximum mounts per row that fit comfortably
            local mountsPerRow = math.floor((availableMountWidth + baseSpacing) / (minMountSize + baseSpacing))
            mountsPerRow = math.max(8, math.min(mountsPerRow, 12))  -- Between 8-12 mounts per row
            
            -- Calculate mount size and spacing based on available width
            local mountSize = math.floor((availableMountWidth - baseSpacing * (mountsPerRow - 1)) / mountsPerRow)
            mountSize = math.max(32, math.min(mountSize, 48))  -- Reasonable size bounds
            
            -- Calculate actual spacing to distribute remaining width evenly
            local remainingWidth = availableMountWidth - (mountSize * mountsPerRow)
            local spacingBetween = mountsPerRow > 1 and math.floor(remainingWidth / (mountsPerRow - 1)) or 0
            spacingBetween = math.max(2, spacingBetween)  -- Minimum 2px spacing
            
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
            categoryFrame.title:SetText(categoryData.name or categoryName)
            categoryFrame.title:SetTextColor(1, 1, 1, 1)
            
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
            local minMountSize = 32  -- Minimum reasonable mount icon size
            local baseSpacing = 4  -- Base spacing between mount icons (same as height calc)
            
            -- Calculate maximum mounts per row that fit comfortably
            local mountsPerRow = math.floor((availableMountWidth + baseSpacing) / (minMountSize + baseSpacing))
            mountsPerRow = math.max(8, math.min(mountsPerRow, 12))  -- Between 8-12 mounts per row
            
            -- Calculate mount size and spacing based on available width
            local mountSize = math.floor((availableMountWidth - baseSpacing * (mountsPerRow - 1)) / mountsPerRow)
            mountSize = math.max(32, math.min(mountSize, 48))  -- Reasonable size bounds
            
            -- Calculate actual spacing to distribute remaining width evenly
            local remainingWidth = availableMountWidth - (mountSize * mountsPerRow)
            local spacingBetween = mountsPerRow > 1 and math.floor(remainingWidth / (mountsPerRow - 1)) or 0
            spacingBetween = math.max(2, spacingBetween)  -- Minimum 2px spacing
            
            -- Y-axis spacing (only affected by height changes)
            local rowSpacing = 4  -- Minimal Y-axis spacing between rows
            
            local maxDisplayMounts = displayedMounts  -- Show all displayed mounts instead of limiting to 24
            local mountStartX = 10
            local displayedIndex = 0  -- Track the actual displayed position
            
            for i, mountId in ipairs(mountList) do
                -- Check if we should skip this mount due to hide collected mounts setting
                local mount_Id = MCLcore.Function:GetMountID(mountId)
                if not (mount_Id and MCL_SETTINGS.hideCollectedMounts and IsMountCollected(mount_Id)) then
                    -- Only process this mount if it's not collected or if hideCollectedMounts is disabled
                    displayedIndex = displayedIndex + 1
                    if displayedIndex <= maxDisplayMounts then
                    local col = ((displayedIndex-1) % mountsPerRow)
                    local row = math.floor((displayedIndex-1) / mountsPerRow)
                    
                    -- Calculate exact position for this icon
                    local iconX = mountStartX + col * (mountSize + spacingBetween)
                    local iconY = mountStartY - row * (mountSize + rowSpacing)  -- Use rowSpacing for Y
                    
                    -- Create backdrop frame first (smaller than spacing to create visual gaps)
                    local backdropSize = mountSize + 2  -- Only 1px overhang on each side for visual separation
                    local backdropFrame = CreateFrame("Frame", nil, categoryFrame, "BackdropTemplate")
                    backdropFrame:SetSize(backdropSize, backdropSize)
                    backdropFrame:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 
                        iconX - 1, -- Minimal offset for overhang
                        iconY + 1) -- Minimal offset for overhang
                    
                    -- Store the mount ID for search functionality
                    backdropFrame.mountID = mountId
                    
                    -- Create mount frame (for icon) centered in backdrop
                    local mountFrame = CreateFrame("Button", nil, backdropFrame)
                    mountFrame:SetSize(mountSize, mountSize)
                    mountFrame:SetPoint("CENTER", backdropFrame, "CENTER", 0, 0)                            -- Store the mount ID for search functionality
                            mountFrame.mountID = mountId
                            
                            -- Set category and section for pinning functionality
                            mountFrame.category = categoryData.name or categoryName
                            mountFrame.section = sectionName or "Unknown"
                            
                            -- Get mount info and set icon
                        local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mount_Id)
                        if icon then
                            -- Create the icon texture
                            mountFrame.tex = mountFrame:CreateTexture(nil, "ARTWORK")
                            mountFrame.tex:SetAllPoints(mountFrame)
                            mountFrame.tex:SetTexture(icon)
                            
                            -- Create pin icon for this mount frame
                            mountFrame.pin = mountFrame:CreateTexture(nil, "OVERLAY")
                            mountFrame.pin:SetWidth(16)
                            mountFrame.pin:SetHeight(16)
                            mountFrame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
                            mountFrame.pin:SetPoint("TOPRIGHT", mountFrame, "TOPRIGHT", 6, 6)
                            
                            -- Check if this mount is pinned and set pin visibility
                            local pin_check = MCLcore.Function:CheckIfPinned("m"..mount_Id)
                            if pin_check == true then
                                mountFrame.pin:SetAlpha(1)
                            else
                                mountFrame.pin:SetAlpha(0)
                            end
                            
                            -- Check if mount is collected and style backdrop accordingly
                            if IsMountCollected(mount_Id) then
                                -- Collected mount styling - green background with thick border
                                mountFrame.tex:SetVertexColor(1, 1, 1, 1)
                                backdropFrame:SetBackdrop({
                                    bgFile = "Interface\\Buttons\\WHITE8x8",
                                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                    edgeSize = 3  -- Thicker border
                                })
                                backdropFrame:SetBackdropColor(0, 0.8, 0, 0.6)  -- Brighter green background
                                backdropFrame:SetBackdropBorderColor(0, 1, 0, 1)  -- Bright green border
                            else
                                -- Uncollected mount styling - red/dark background
                                mountFrame.tex:SetVertexColor(0.4, 0.4, 0.4, 0.7)
                                backdropFrame:SetBackdrop({
                                    bgFile = "Interface\\Buttons\\WHITE8x8",
                                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                                    edgeSize = 2  -- Slightly thinner border for uncollected
                                })
                                backdropFrame:SetBackdropColor(0.3, 0.1, 0.1, 0.4)  -- Reddish background
                                backdropFrame:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)  -- Red border
                            end
                            
                            -- Add mount interaction to the mount frame
                            if MCLcore.Function and MCLcore.Function.LinkMountItem then
                                MCLcore.Function:LinkMountItem(mountId, mountFrame, false, false)
                            end
                        end
                    end
                end  -- Close the if block for non-hidden mounts
            end
            
            -- Update column positions for next category
            if isLeftColumn then
                leftColumnY = leftColumnY - (categoryHeight + 8)  -- Reduced spacing between categories
            else
                rightColumnY = rightColumnY - (categoryHeight + 8)  -- Reduced spacing between categories
            end
            
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
    local navFrame = MCLcore.MCL_MF_Nav
    if navFrame and navFrame.tabs then
        for _, tab in ipairs(navFrame.tabs) do
            if tab.content and tab.content:IsShown() then
                selectedTabName = tab.section and tab.section.name
                break
            end
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
        
        -- Restore the previously selected tab
        if selectedTabName and navFrame and navFrame.tabs then
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
                        MCL_mainFrame.ScrollFrame:SetScrollChild(tab.content)
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
end

-- Function to save frame size to settings
function MCL_frames:SaveFrameSize()
    if MCL_mainFrame and MCL_SETTINGS then
        MCL_SETTINGS.frameWidth = MCL_mainFrame:GetWidth()
        MCL_SETTINGS.frameHeight = MCL_mainFrame:GetHeight()
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