local MCL, core = ...;

core.Function = {};
local MCL_functions = core.Function;

core.mounts = {}
core.stats= {}
core.overviewStats = {}
core.overviewFrames = {}

function MCL_functions:getFaction()
    -- * --------------------------------
    -- * Get's player faction
    -- * --------------------------------
	if UnitFactionGroup("player") == "Alliance" then
		return "Horde" -- Inverse
	else
		return "Alliance" -- Inverse
	end
end


-- Tables Mounts into Global List
function MCL_functions:TableMounts(id, frame, section, category)
    local mount = {
        id = id,
        frame = frame,
        section =  section,
        category = category,
    }
    table.insert(core.mounts, mount)
end

function MCL_functions:initSections()
    -- * --------------------------------
    -- * Create variables and assign strings to each section.
    -- * --------------------------------

    -- TODO: Create Frame for Section
    -- TODO: Label name
    -- TODO: GET categories
    -- -- TODO: PUT Mounts in categories
    -- TODO: GET Mounts in categories
    local faction = MCL_functions:getFaction()
    core.sections = {}

    for i, v in ipairs(core.sectionNames) do
        if v.name ~= faction then
            table.insert(core.sections, v.name)
        else
            -- Skip opposite faction
        end
    end

    core.MCL_MF_Nav = core.Frames:createNavFrame(core.MCL_MF, 'Sections')

    local tabFrames, numTabs = core.Frames:SetTabs() 

    local function OverviewStats(relativeFrame)
        core.Frames:createOverviewCategory(core.sections, relativeFrame)
        -- core.Frames:createCategoryFrame(core.sections, relativeFrame)
    end

    core.sectionFrames = {}
    for i=1, numTabs do
        local section_frame = core.Frames:createContentFrame(tabFrames[i], core.sections[i])
        table.insert(core.sectionFrames, section_frame)

        for ii,v in ipairs(core.sectionNames) do
            if v.name == "Overview" then
                core.overview = section_frame
            elseif v.name == core.sections[i] then
                -- ! Create Frame for each category
                if v.mounts then
                    for k,val in pairs(v.mounts) do
                        if k == 'categories' then
                            local section = core.Frames:createCategoryFrame(val, section_frame)
                            table.insert(core.stats, section)
                        end
                    end
                end 
            else
                -- Skip opposite faction
            end            
        end
    end

    OverviewStats(core.overview)


end

function MCL_functions:CreateBorder(frame, side)
    frame.borders = frame:CreateLine(nil, "BACKGROUND", nil, 0)
    local l = frame.borders
    l:SetThickness(1)
    l:SetColorTexture(1, 1, 1, 0.4)
	l:SetStartPoint("BOTTOM"..side)
	l:SetEndPoint("TOP"..side)
    return frame
end

function MCL_functions:TestFunction()
    print("hello world")
end

function MCL_functions:getTableLength(set)
    i = 1
    for k,v in pairs(set) do
        i = i+1
    end
    return i
end

function MCL_functions:LinkMountItem(id, frame)
	--Adding a tooltip for mounts
    if string.sub(id, 1, 1) == "m" then
        id = string.sub(id, 2, -1)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(id)

        frame:HookScript("OnEnter", function()
            if (spellID) then
                GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                GameTooltip:SetSpellByID(spellID)
                GameTooltip:Show()
                frame:SetHyperlinksEnabled(true)
            end
        end)
        frame:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        frame:SetScript("OnMouseDown", function(self, button)
            if button == 'LeftButton' then
                DressUpMount(mountID)
            end			
            if button == 'RightButton' then               
                CastSpellByName(mountName);
            end
        end)          

    else
        local item, itemLink = GetItemInfo(id);
        local mountID = C_MountJournal.GetMountFromItem(id)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountID)
        frame:SetHyperlinksEnabled(true)
        _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)             
        frame:HookScript("OnEnter", function()
            if (itemLink) then
                GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                GameTooltip:SetHyperlink(itemLink)
                GameTooltip:AddLine(source)
                GameTooltip:Show()
            end
        end)
        frame:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)

		frame:SetScript("OnMouseDown", function(self, button)
			if IsControlKeyDown() then
				if button == 'LeftButton' then
					DressUpMount(mountID)
				end
			elseif button=='LeftButton' then
				if (itemLink) then
					print(itemLink)
				end
			end
			if button == 'RightButton' then
				CastSpellByName(mountName);
			end
		end)

    end  
end


function MCL_functions:CreateMountsForCategory(set, relativeFrame, frame_size, tab)

    local category = relativeFrame
    local count = 0
    local first_frame
    local overflow = 0

    for kk,vv in pairs(set) do
        local mount_Id
        if count == 12 then
            overflow = overflow + frame_size + 10
        end            
        local frame = CreateFrame("Button", nil, relativeFrame, "BackdropTemplate");
        frame:SetWidth(frame_size);
        frame:SetHeight(frame_size);
        frame:SetBackdrop({
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = frame_size + 2,
        })           
        frame:SetBackdropBorderColor(1, 0, 0, 0.03)	-- ! Default Red Backdrop
        
        if count == 12 then
            frame:SetPoint("BOTTOMLEFT", first_frame, "BOTTOMLEFT", 0, -overflow);
            count = 0           
        elseif relativeFrame == category then
            frame:SetPoint("BOTTOMLEFT", category, "BOTTOMLEFT", 0, -35);
            first_frame = frame
        else
            frame:SetPoint("RIGHT", relativeFrame, "RIGHT", frame_size+10, 0);
        end

        frame.tex = frame:CreateTexture()
        frame.tex:SetAllPoints(frame)
        if string.sub(vv, 1, 1) == "m" then
            mount_Id = string.sub(vv, 2, -1)
            local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
            frame.tex:SetTexture(icon)
        else
            mount_Id = C_MountJournal.GetMountFromItem(vv)
            frame.tex:SetTexture(GetItemIcon(vv))
        end
     
        frame.tex:SetVertexColor(0.75, 0.75, 0.75, 0.3);	

        core.Function:LinkMountItem(vv, frame)

        relativeFrame = frame
        count = count + 1

        MCL_functions:TableMounts(mount_Id, frame, tab, category)         
    end   
    return overflow
end

function MCL_functions:GetMountID(id)
    if string.sub(id, 1, 1) == "m" then
        mount_Id = string.sub(id, 2, -1)
    else
        mount_Id = C_MountJournal.GetMountFromItem(id)
    end
    return mount_Id
end

function IsMountCollected(id)
    local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(id)
    return isCollected
end

function UpdateBackground(frame)
    frame:SetBackdropBorderColor(0, 0.45, 0, 0.4)
    frame.tex:SetVertexColor(1, 1, 1, 1);	
end


function UpdateProgressBar(frame, total, collected)
	frame:SetValue((collected/total)*100)
    frame.Text:SetText(collected.."/"..total.." ("..math.floor(((collected/total)*100)).."%)")

	if ((collected/total)*100) < 66 then
		frame:SetStatusBarColor(0.941, 0.658, 0.019)
	end
	if ((collected/total)*100) < 33 then
		frame:SetStatusBarColor(0.929, 0.007, 0.019)
	end
	if collected == total then
		frame:SetStatusBarColor(0, 0.5, 0.9) --blue
	end

end

local function clearOverviewStats()
    for k in pairs (core.overviewStats) do
        core.overviewStats[k] = nil
    end
end

function MCL_functions:UpdateCollection()
    clearOverviewStats()
    core.total = 0
    core.collected = 0
    for k,v in pairs(core.mounts) do
        core.total = core.total + 1
        if IsMountCollected(v.id) then
            UpdateBackground(v.frame)
            core.collected = core.collected + 1
        end
        -- * Check if mount is collected
        -- * Change colour of background
        -- * Add to total
    end
    for k,v in pairs(core.stats) do
        local section_total = 0
        local section_collected = 0
        -- if (type(v) == "table") then
        for kk,vv in pairs(v) do
            local collected = 0
            local total = 0
            local isCollected

            if (type(vv) == "table") then
                if vv["mounts"] then
                    for kkk, vvv in pairs(vv.mounts) do
                        if string.sub(vvv, 1, 1 ) == "m" then
                            isCollected = IsMountCollected(string.sub(vvv, 2, -1))
                        end
                            local id = core.Function:GetMountID(vvv)
                            isCollected = IsMountCollected(id)
                        -- end
                        if isCollected then
                            collected = collected +1
                        end
                        total = total +1
                    end
                    UpdateProgressBar(vv.pBar, total, collected)
                    section_total = section_total + total
                    section_collected = section_collected + collected
                else
                    UpdateProgressBar(vv.pBar, section_total, section_collected)
                end
                if vv["rel"] then
                    for q,e in pairs(core.overviewFrames) do
                        if e.name == vv.rel.title:GetText() then
                            UpdateProgressBar(e.frame, section_total, section_collected)
                        end
                    end                     
                end                
            end             
        end     
    end
    UpdateProgressBar(core.overview.pBar, core.total, core.collected)
end

