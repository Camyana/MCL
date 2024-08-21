
local MCL, core = ...;

core.Frames = {};
local MCL_frames = core.Frames;

core.TabTable = {}
core.statusBarFrames  = {}

local nav_width = 180
local main_frame_width = 1250
local main_frame_height = 640

local r,g,b,a


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
	Settings.OpenToCategory(core.addon_name)
end

function MCL_frames:CreateMainFrame()
    MCL_mainFrame = CreateFrame("Frame", "MCLFrame", UIParent, "MCLFrameTemplateWithInset");
    MCL_mainFrame.Bg:SetVertexColor(0,0,0,MCL_SETTINGS.opacity)
    MCL_mainFrame.TitleBg:SetVertexColor(0.1,0.1,0.1,0.95)
    MCL_mainFrame:Show()
	
	MCL_mainFrame.settings = CreateFrame("Button", nil, MCL_mainFrame);
	MCL_mainFrame.settings:SetSize(15, 15)
	MCL_mainFrame.settings:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -30, 0)
	MCL_mainFrame.settings.tex = MCL_mainFrame.settings:CreateTexture()
	MCL_mainFrame.settings.tex:SetAllPoints(MCL_mainFrame.settings)
	MCL_mainFrame.settings.tex:SetTexture("Interface\\AddOns\\MCL\\icons\\settings.blp")
	MCL_mainFrame.settings:SetScript("OnClick", function()MCL_frames:openSettings()end)


	MCL_mainFrame.sa = CreateFrame("Button", nil, MCL_mainFrame);
	MCL_mainFrame.sa:SetSize(60, 15)
	MCL_mainFrame.sa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -60, -1)
	MCL_mainFrame.sa.tex = MCL_mainFrame.sa:CreateTexture()
	MCL_mainFrame.sa.tex:SetAllPoints(MCL_mainFrame.sa)
	MCL_mainFrame.sa.tex:SetTexture("Interface\\Buttons\\WHITE8x8")
	MCL_mainFrame.sa.tex:SetVertexColor(0.1,0.1,0.1,0.95, MCL_SETTINGS.opacity)
	MCL_mainFrame.sa.text = MCL_mainFrame.sa:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	MCL_mainFrame.sa.text:SetPoint("CENTER", MCL_mainFrame.sa, "CENTER", 0, 0);
	MCL_mainFrame.sa.text:SetText("SA")
	MCL_mainFrame.sa.text:SetTextColor(0, 0.7, 0.85)	
	MCL_mainFrame.sa:SetScript("OnClick", function()core.Function:simplearmoryLink()end)	
	
	MCL_mainFrame.dfa = CreateFrame("Button", nil, MCL_mainFrame);
	MCL_mainFrame.dfa:SetSize(60, 15)
	MCL_mainFrame.dfa:SetPoint("TOPRIGHT", MCL_mainFrame, "TOPRIGHT", -125, -1)
	MCL_mainFrame.dfa.tex = MCL_mainFrame.dfa:CreateTexture()
	MCL_mainFrame.dfa.tex:SetAllPoints(MCL_mainFrame.dfa)
	MCL_mainFrame.dfa.tex:SetTexture("Interface\\Buttons\\WHITE8x8")
	MCL_mainFrame.dfa.tex:SetVertexColor(0.1,0.1,0.1,0.95, MCL_SETTINGS.opacity)
	MCL_mainFrame.dfa.text = MCL_mainFrame.dfa:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	MCL_mainFrame.dfa.text:SetPoint("CENTER", MCL_mainFrame.dfa, "CENTER", 0, 0);
	MCL_mainFrame.dfa.text:SetText("DFA")
	MCL_mainFrame.dfa.text:SetTextColor(0, 0.7, 0.85)	
	MCL_mainFrame.dfa:SetScript("OnClick", function()core.Function:dfaLink()end)		


	--MCL Frame settings
	MCL_mainFrame:SetSize(main_frame_width, main_frame_height); -- width, height
	MCL_mainFrame:SetPoint("CENTER", UIParent, "CENTER"); -- point, relativeFrame, relativePoint, xOffset, yOffset
	MCL_mainFrame:SetHyperlinksEnabled(true)
	MCL_mainFrame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow)

	MCL_mainFrame:SetMovable(true)
	MCL_mainFrame:EnableMouse(true)
	MCL_mainFrame:RegisterForDrag("LeftButton")
	MCL_mainFrame:SetScript("OnDragStart", MCL_mainFrame.StartMoving)
	MCL_mainFrame:SetScript("OnDragStop", MCL_mainFrame.StopMovingOrSizing)    

	--Creating title for frame
	MCL_mainFrame.title = MCL_mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight");
	MCL_mainFrame.title:SetPoint("LEFT", MCL_mainFrame.TitleBg, "LEFT", 5, 2);
	MCL_mainFrame.title:SetText("Mount Collection Log");
	MCL_mainFrame.title:SetTextColor(0, 0.7, 0.85)
    
    -- Scroll Frame for Main Window
	MCL_mainFrame.ScrollFrame = CreateFrame("ScrollFrame", nil, MCL_mainFrame, "MinimalScrollFrameTemplate");
	MCL_mainFrame.ScrollFrame:SetPoint("TOPLEFT", MCL_mainFrame.Bg, "TOPLEFT", 4, -7);
	MCL_mainFrame.ScrollFrame:SetPoint("BOTTOMRIGHT", MCL_mainFrame.Bg, "BOTTOMRIGHT", -3, 6);
	MCL_mainFrame.ScrollFrame:SetClipsChildren(true);
	MCL_mainFrame.ScrollFrame:SetScript("OnMouseWheel", ScrollFrame_OnMouseWheel);
	MCL_mainFrame.ScrollFrame:EnableMouse(true)
    
	MCL_mainFrame.ScrollFrame.ScrollBar:ClearAllPoints();
	MCL_mainFrame.ScrollFrame.ScrollBar:SetPoint("TOPLEFT", MCL_mainFrame.ScrollFrame, "TOPRIGHT", -8, -19);
	MCL_mainFrame.ScrollFrame.ScrollBar:SetPoint("BOTTOMRIGHT", MCL_mainFrame.ScrollFrame, "BOTTOMRIGHT", -8, 17);

	MCL_mainFrame:SetFrameStrata("HIGH")

	core.Function:CreateFullBorder(MCL_mainFrame)

    tinsert(UISpecialFrames, "MCLFrame")
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


function MCL_frames:SetTabs()
    local tabFrame = core.MCL_MF_Nav
    numTabs = 0
    for k,v in pairs(core.sections) do
        numTabs = numTabs + 1
    end
	local contents = {};
	local frameName = tabFrame:GetName();
    local i = 1
    tabFrame.numTabs = numTabs;  
	for k,v in pairs(core.sections) do
		local tab = CreateFrame("Button", frameName.."Tab"..k, tabFrame, "MCLTabButtonTemplate");
        tab:SetID(k);
        tab.title = tab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tab.title:SetPoint("LEFT", 0, 0)       

		tab.title:SetText(tostring(v.name));
		if v.icon ~= nil then
			tab.icon = CreateFrame("Frame", nil, tab);
			tab.icon:SetSize(32, 32)
			tab.icon:SetPoint("RIGHT", tab, "RIGHT", 0, 0)
			tab.icon.tex = tab.icon:CreateTexture()
			tab.icon.tex:SetAllPoints(tab.icon)
			tab.icon.tex:SetTexture(v.icon)
		end
		tab:SetScript("OnClick", Tab_OnClick);
        tab:SetWidth(nav_width)
		if v.name == "Pinned" then
			tab.content = CreateFrame("Frame", "PinnedTab", tabFrame.ScrollFrame);
		else
			tab.content = CreateFrame("Frame", nil, tabFrame.ScrollFrame);
		end
		tab.content:SetSize(1100, 550);
		tab.content:Hide();		

		table.insert(contents, tab.content);

		if tab.title:GetText() == "Overview" then
			tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, 20);
		elseif (i == 1) or tab.title:GetText() == "Overview" then
			tab:SetPoint("TOPLEFT", tabFrame, "TOPLEFT", 0, -10);
		else
			tab:SetPoint("BOTTOM", _G[frameName.."Tab"..(i-1)], "BOTTOM", 0, -30);
		end
		core.TabTable[i] = v.name

        i = i+1
		
	end

	Tab_OnClick(_G[frameName.."Tab1"]);

	return contents, numTabs;
end


function MCL_frames:createNavFrame(relativeFrame, title)
	--Creating a frame to place expansion content in.
	local frame = CreateFrame("Frame", "Nav", relativeFrame, "BackdropTemplate");
	frame:SetWidth(nav_width)
	frame:SetHeight(main_frame_height)
	frame:SetPoint("TOPLEFT", relativeFrame, 5, -38);
    frame:SetBackdropColor(1, 1, 1)
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("LEFT", 0, 0)	
	return frame;
end


function MCL_frames:progressBar(relativeFrame, top)
	MyStatusBar = CreateFrame("StatusBar", nil, relativeFrame, "BackdropTemplate")
	MyStatusBar:SetStatusBarTexture(core.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture))
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
	MyStatusBar.bg:SetTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
	MyStatusBar.bg:SetAllPoints(true)
	MyStatusBar.bg:SetVertexColor(0.843, 0.874, 0.898, 0.5)
	MyStatusBar.Text = MyStatusBar:CreateFontString()
	MyStatusBar.Text:SetFontObject(GameFontWhite)
	MyStatusBar.Text:SetPoint("CENTER")
	MyStatusBar.Text:SetJustifyH("CENTER")
	-- MyStatusBar.Text:SetJustifyV("CENTER")
	MyStatusBar.Text:SetText()

	table.insert(core.statusBarFrames, MyStatusBar)

	return MyStatusBar
end

function MCL_frames:createContentFrame(relativeFrame, title)
	--Creating a frame to place expansion content in.
	local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate");

	--category:SetSize(490, boxSize);
	frame:SetWidth(490)
	frame:SetHeight(30)
	frame:SetPoint("TOPLEFT", relativeFrame, nav_width+30, 0);
    frame:SetBackdropColor(0, 1, 0)
	frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	frame.title:SetPoint("LEFT", 0, 0)
	frame.title:SetText(title)


	if title ~= "Pinned" then
		frame.pBar = core.Frames:progressBar(frame)
		frame.pBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, -15)
		frame.pBar:SetWidth(880)
		frame.pBar:SetHeight(20)
	end

	return frame;
end



function MCL_frames:createOverviewCategory(set, relativeFrame)
    local first = true
    local col = 1
    local oddFrame, evenFrame = false, false
    local oddOverFlow, evenOverFlow = 0, 0

	for k,v in pairs(set) do
		if (v.name ~= "Overview") and (v.name ~= "Pinned") then
			local frame = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate")
			frame:SetWidth(60);
			frame:SetHeight(60);

			if (first == true) then
				frame:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 0, -80);
			elseif (col % 2 == 0) then
				if evenFrame then
					frame:SetPoint("TOPRIGHT", evenFrame, "TOPRIGHT", 0, -50);
				else
					frame:SetPoint("TOPRIGHT", oddFrame, "TOPRIGHT", 480, 0);
				end
			else
				frame:SetPoint("BOTTOMLEFT", oddFrame, "BOTTOMLEFT", 0, -50);
			end

			first = false
			frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
			frame.title:SetPoint("TOPLEFT", 0, 0)
			frame.title:SetText(v.name)
			
			local pBar = core.Frames:progressBar(frame)
			pBar:SetWidth(400)
			pBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 30)

			pBar:HookScript("OnEnter", function()
				r,g,b,a = pBar:GetStatusBarColor()
				local temp = pBar:SetStatusBarColor(0.8, 0.5, 0.9, 1)
			end)
			pBar:HookScript("OnLeave", function()
				pBar:SetStatusBarColor(r, g, b, a)
			end)
			if v.name == "Unobtainable" then
				pBar.unobtainable = MCL_SETTINGS.unobtainable
				if MCL_SETTINGS.unobtainable == true then
					pBar:GetParent():Hide()
				end
			end

			pBar:SetScript("OnMouseDown", function(self, button)
				if button == 'LeftButton' then
					for i,tab in ipairs(core.TabTable) do
						if tab == v.name then
							Tab_OnClick(_G["NavTab"..i]);
						end
					end
				end			
			end)

			if (col % 2 == 0) then
				evenFrame = frame
				evenOverFlow = overflow
			else
				oddFrame = frame
				oddOverFlow = overflow
			end
			col = col + 1

			local t = {
				name = v.name,
				frame = pBar
			}
	
			table.insert(core.overviewFrames, t)			
		end	

	end


end


----------------------------------------------------------------
-- Creating a placeholder for each category, this is where we attach each mount to.
----------------------------------------------------------------

function MCL_frames:createCategoryFrame(set, relativeFrame)
	--Creating a frame to place expansion content in.
    local first = true
    local frame_size = 30
    local col = 1
    local oddFrame, evenFrame = false, false
    local oddOverFlow, evenOverFlow = 0, 0
    local section = {}
    local total_mounts = 0

    for k,v in pairs(set) do
        local category = CreateFrame("Frame", nil, relativeFrame, "BackdropTemplate");
        category:SetWidth(60);
        category:SetHeight(60);


        if (first == true) then
            category:SetPoint("TOPLEFT", relativeFrame, "TOPLEFT", 0, -60);
        elseif (col % 2 == 0) then
            if evenFrame then
                category:SetPoint("TOPRIGHT", evenFrame, "TOPRIGHT", 0, -(frame_size+evenOverFlow)-80);
            else
                category:SetPoint("TOPRIGHT", oddFrame, "TOPRIGHT", ((frame_size + 10) * 12) + 20, 0);
            end
        else
            category:SetPoint("BOTTOMLEFT", oddFrame, "BOTTOMLEFT", 0, -(frame_size+oddOverFlow)-80);
        end
        first = false
        category.title = category:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        category.title:SetPoint("TOPLEFT", 0, 0)
		category.title:SetText(v.name)

		category.section = relativeFrame.title:GetText()
		category.category = v.name

        local pBar = core.Frames:progressBar(category) 
		local overflow = core.Function:CreateMountsForCategory(v.mounts, category, frame_size, relativeFrame, category, false, false)

            
        category:SetSize(((frame_size + 10) * 12),45)

        if (col % 2 == 0) then
            evenFrame = category
            evenOverFlow = overflow
        else
            oddFrame = category
            oddOverFlow = overflow
        end
        col = col + 1

        -- ! Cosntruct Stats Here

        local stats = {
            frame = category,
            mounts = v.mounts,
            collected = 0,
            pBar = pBar,
			rel = relativeFrame
        }

        table.insert(section, stats)
        total_mounts = total_mounts + core.Function:getTableLength(v.mounts)

    end
    table.insert(section, total_mounts)
    table.insert(section, relativeFrame)
    return section
end