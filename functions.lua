local MCL, core = ...;

core.Function = {};
local MCL_functions = core.Function;

core.mounts = {}
core.stats= {}
core.overviewStats = {}
core.overviewFrames = {}
core.mountFrames = {}
core.mountCheck = {}


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

local function IsMountFactionSpecific(id)
    if string.sub(id, 1, 1) == "m" then
        mount_Id = string.sub(id, 2, -1)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        return faction, isFactionSpecific
    else
        mount_Id = C_MountJournal.GetMountFromItem(id)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        return faction, isFactionSpecific
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
    local faction = MCL_functions:getFaction()
    core.sections = {}

    for i, v in ipairs(core.sectionNames) do
        if v.name ~= faction then
            local t = {
                name = v.name,
                icon = v.icon
            }
            table.insert(core.sections, t)
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
        local section_frame = core.Frames:createContentFrame(tabFrames[i], core.sections[i].name)
        table.insert(core.sectionFrames, section_frame)

        for ii,v in ipairs(core.sectionNames) do
            if v.name == "Overview" then
                core.overview = section_frame        
            elseif v.name == core.sections[i].name then
                if v.name == "Pinned" then
                    local category = CreateFrame("Frame", "PinnedFrame", section_frame, "BackdropTemplate");
                    category:SetWidth(60);
                    category:SetHeight(60);
                    category:SetPoint("TOPLEFT", section_frame, "TOPLEFT", 0, 0);
                    local overflow, mountFrame = core.Function:CreateMountsForCategory(MCL_PINNED, category, 30, tabFrames[i], true, true)
                    table.insert(core.mountFrames, mountFrame)
                    category.info = category:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    category.info:SetPoint("TOP", 450, -0)
                    category.info:SetText("Ctrl + Right Click to pin uncollected mounts")
                end                   
                -- ! Create Frame for each category
                if v.mounts then
                    for k,val in pairs(v.mounts) do
                        if k == 'categories' then
                            local section = core.Frames:createCategoryFrame(val, section_frame)
                            table.insert(core.stats, section)
                        end
                    end
                end 
            end            
        end
    end

    OverviewStats(core.overview)


end


function MCL_functions:GetCollectedMounts()
    local mounts = {}
    for k,v in pairs(C_MountJournal.GetMountIDs()) do
        local mountName, spellID, icon, _, isUsable, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(v)
        if isCollected then
            if faction then
                if faction == 1 then
                    faction = "Alliance"
                else
                    faction = "Horde"
                end
            end
            if (isFactionSpecific == false) or (isFactionSpecific == true and faction == UnitFactionGroup("player")) then                     
                table.insert(mounts, mountID)
            end   
        end
    end
    for k,v in pairs(mounts) do
        local exists = false
        for kk,vv in pairs(core.mountCheck) do
            if v == vv then
                exists = true
            end
        end
        if exists == false then
            print(v)
        end
    end
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


function MCL_functions:CreateFullBorder(self)
    if not self.borders then
        self.borders = {}
        for i=1, 4 do
            self.borders[i] = self:CreateLine(nil, "BACKGROUND", nil, 0)
            local l = self.borders[i]
            l:SetThickness(2)
            l:SetColorTexture(0, 0, 0, 0.7)
            if i==1 then
                l:SetStartPoint("TOPLEFT", 0, 1)
                l:SetEndPoint("TOPRIGHT", 0, 1)
            elseif i==2 then
                l:SetStartPoint("TOPRIGHT", 0, 1)
                l:SetEndPoint("BOTTOMRIGHT", 0, 2)
            elseif i==3 then
                l:SetStartPoint("BOTTOMRIGHT", 0, 2)
                l:SetEndPoint("BOTTOMLEFT", 0, 2)
            else
                l:SetStartPoint("BOTTOMLEFT", 0, 2)
                l:SetEndPoint("TOPLEFT", 0, 1)
            end
        end
    end
end

function MCL_functions:getTableLength(set)
    local i = 1
    for k,v in pairs(set) do
        i = i+1
    end
    return i
end

function MCL_functions:SetMouseClickFunctionalityPin(frame, mountID, mountName, itemLink, spellID)
    frame:SetScript("OnMouseDown", function(self, button)
        if IsControlKeyDown() then
            if button == 'LeftButton' then
                DressUpMount(mountID)
            elseif button == 'RightButton' then
                if IsMountCollected(mountID) == false then
                    local pin = false
                    local pin_count = table.getn(MCL_PINNED)
                    if pin_count ~= nil then                     
                        for i=1, pin_count do                      
                            if MCL_PINNED[i].mountID == "m"..mountID then
                                pin = i
                            end
                        end
                    end
                                          
                    table.remove(MCL_PINNED, pin)
                    local index = 0
                    for k,v in pairs(core.mountFrames[1]) do
                        index = index + 1
                        if tostring(v.mountID) == tostring(mountID) then
                            table.remove(core.mountFrames[1],  index)
                            for kk,vv in ipairs(core.mountFrames[1]) do
                                if kk == 1 then
                                    vv:SetParent(_G["PinnedFrame"])
                                else
                                    vv:SetParent(core.mountFrames[1][kk-1])
                                end
                            end
                            frame:Hide()
                            core.Function:UpdateCollection()
                        end
                    end
                end
            end               
        elseif button=='LeftButton' then
            if (itemLink) then
                frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow(_, itemLink, itemLink, _))
            elseif (spellID) then
                frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow(_, GetSpellLink(spellID), GetSpellLink(spellID), _))
            end
        end
        if button == 'RightButton' then
            CastSpellByName(mountName);
        end
    end)
end

function MCL_functions:SetMouseClickFunctionality(frame, mountID, mountName, itemLink, spellID) -- * Mount Frames
    frame:SetScript("OnMouseDown", function(self, button)
        if IsControlKeyDown() then
            if button == 'LeftButton' then
                DressUpMount(mountID)
            elseif button == 'RightButton' then
                if IsMountCollected(mountID) == false then
                    local pin = false
                    local pin_count = table.getn(MCL_PINNED)
                    if pin_count ~= nil then                     
                        for i=1, pin_count do                      
                            if MCL_PINNED[i].mountID == "m"..mountID then
                                pin = i
                            end
                        end
                    end
                    if pin ~= false then
                        frame.pin:SetAlpha(0)
                        table.remove(MCL_PINNED, pin)
                        local index = 0
                        for k,v in pairs(core.mountFrames[1]) do
                            index = index + 1
                            if tostring(v.mountID) == tostring(mountID) then
                                core.mountFrames[1][index]:Hide()                                
                                table.remove(core.mountFrames[1],  index)
                                for kk,vv in ipairs(core.mountFrames[1]) do
                                    if kk == 1 then
                                        vv:SetParent(_G["PinnedFrame"])
                                        vv:Show()
                                    else
                                        vv:SetParent(core.mountFrames[1][kk-1])
                                        vv:Show()
                                    end
                                end                                
                            end
                        end
                    else	                            
                        frame.pin:SetAlpha(1)
                        local t = {
                            mountID = "m"..mountID,
                            category = frame.category,
                            section = frame.section
                        }
                        if pin_count == nil then
                            MCL_PINNED[1] = t
                        else
                            MCL_PINNED[pin_count+1] = t
                        end
                        core.Function:CreatePinnedMount(mountID, frame.category, frame.section)

                    end
                end
            end               
        elseif button=='LeftButton' then
            if (itemLink) then
                frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow(_, itemLink, itemLink, _))
            elseif (spellID) then
                frame:SetScript("OnHyperlinkClick", ChatFrame_OnHyperlinkShow(_, GetSpellLink(spellID), GetSpellLink(spellID), _))
            end
        end
        if button == 'RightButton' then
            CastSpellByName(mountName);
        end
    end)
end

function MCL_functions:LinkMountItem(id, frame, pin)
	--Adding a tooltip for mounts
    if string.sub(id, 1, 1) == "m" then
        id = string.sub(id, 2, -1)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(id)

        frame:HookScript("OnEnter", function()
            if (spellID) then
                _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(id) 
                GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
                GameTooltip:SetSpellByID(spellID)
                GameTooltip:AddLine(source) 
                GameTooltip:Show()
                frame:SetHyperlinksEnabled(true)
            end
        end)
        frame:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        if pin == true then
            core.Function:SetMouseClickFunctionalityPin(frame, mountID, mountName, itemLink, spellID)
        else
            core.Function:SetMouseClickFunctionality(frame, mountID, mountName, itemLink, spellID)
        end  
    else
        local item, itemLink = GetItemInfo(id);
        local mountID = C_MountJournal.GetMountFromItem(id)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(mountID)
     
        frame:HookScript("OnEnter", function()
            if (itemLink) then
                frame:SetHyperlinksEnabled(true)
                _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)                     
                GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                GameTooltip:SetHyperlink(itemLink)
                GameTooltip:AddLine(source)   
                GameTooltip:Show()
            end
        end)
        frame:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        if pin == true then
            core.Function:SetMouseClickFunctionalityPin(frame, mountID, mountName, itemLink)
        else
            core.Function:SetMouseClickFunctionality(frame, mountID, mountName, itemLink)
        end    
    end
     
end


function MCL_functions:CompareMountJournal()
    print("Comparing Mount Journal to Addon")
    local mounts = {}
    local i = 1
    for k,v in pairs(C_MountJournal.GetMountIDs()) do
        mounts[i] = v
        for kk,vv in pairs(core.mounts) do
            if vv.id == mounts[i] then
                mounts[i] = nil
            end
        end
    end
    for x,y in ipairs(mounts) do
        if y ~= nil then
            local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(y)
            print(mountName, mountID)
        end
    end
end


function MCL_functions:CheckIfPinned(mountID)
    if MCL_PINNED == nil then
        MCL_PINNED = {}
    end
    for k,v in pairs(MCL_PINNED) do
        if v.mountID == mountID then
            return true, k
        end
    end
    return false, nil
end


function MCL_functions:CreateMountsForCategory(set, relativeFrame, frame_size, tab, skip_total, pin)

    local category = relativeFrame
    local previous_frame = relativeFrame
    local count = 0
    local first_frame
    local overflow = 0
    local mountFrames = {}
    local val
    local mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, sourceText

    for kk,vv in pairs(set) do
        local mount_Id
        if pin then
            val = vv.mountID
        else
            val = vv
        end
        if string.sub(val, 1, 1) == "m" then
            mount_Id = string.sub(val, 2, -1)
            mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
            _,_, sourceText =  C_MountJournal.GetMountInfoExtraByID(mount_Id)
        else
            mount_Id = C_MountJournal.GetMountFromItem(val)
        end        
        local faction, faction_specific = IsMountFactionSpecific(val)
        if faction then
            if faction == 1 then
                faction = "Alliance"
            else
                faction = "Horde"
            end
        end
        if (faction_specific == false) or (faction_specific == true and faction == UnitFactionGroup("player")) then
            if count == 12 then
                overflow = overflow + frame_size + 10
            end            
            local frame = CreateFrame("Button", nil, relativeFrame, "BackdropTemplate");
            frame:SetWidth(frame_size);
            frame:SetHeight(frame_size);
            frame:SetBackdrop({
                edgeFile = [[Interface\Buttons\WHITE8x8]],
                edgeSize = frame_size + 2,
                bgFile = [[Interface\Buttons\WHITE8x8]],
                tileSize = frame_size + 2,                
            })

            frame.pin = frame:CreateTexture()
            frame.pin:SetWidth(24)
            frame.pin:SetHeight(24)
            frame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
            frame.pin:SetPoint("TOPLEFT", frame, "TOPLEFT", 20,12)
            frame.pin:SetAlpha(0)

            frame.category = category.category
            frame.section = category.section

            frame:SetBackdropBorderColor(1, 0, 0, 0.03)
            frame:SetBackdropColor(0, 0, 0, 1)


            frame.tex = frame:CreateTexture()
            frame.tex:SetSize(frame_size, frame_size)
            frame.tex:SetPoint("LEFT")

            if string.sub(val, 1, 1) == "m" then
                frame.tex:SetTexture(icon)
            else
                frame.tex:SetTexture(GetItemIcon(val))
            end
        
            frame.tex:SetVertexColor(0.75, 0.75, 0.75, 0.3);

            frame.mountID = mount_Id            

            local pin_check = core.Function:CheckIfPinned("m"..frame.mountID)
            if pin_check == true then
                frame.pin:SetAlpha(1)
            else
                frame.pin:SetAlpha(0)
            end              

            if pin then
                local y = 30
                if previous_frame == category then
                    y = 0
                end

                frame.sectionName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.sectionName:SetPoint("LEFT", 650, 0)
                frame.sectionName:SetText(vv.section)

                frame.categoryName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.categoryName:SetPoint("LEFT", 850, 0)
                frame.categoryName:SetText(vv.category)  
                
                frame.mountName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.mountName:SetPoint("LEFT", 50, 0)
                frame.mountName:SetText(mountName)  
                
                frame.sourceText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.sourceText:SetPoint("LEFT", 250, 0)
                frame.sourceText:SetText(sourceText)  
                
                frame.border = frame:CreateLine(nil, "BACKGROUND", nil, 0)
                frame.border:SetThickness(3)
                frame.border:SetColorTexture(1, 1, 1, 0.3)
                frame.border:SetStartPoint("BOTTOMLEFT")
                frame.border:SetEndPoint("BOTTOMRIGHT")
                frame:SetWidth(1000)
                frame:SetHeight(frame.sourceText:GetStringHeight()+20)
                
                frame:SetBackdropBorderColor(0, 0, 0, 0.8)
                frame:SetBackdropColor(0, 0, 0, 0.8)
                frame.tex:SetVertexColor(1, 1, 1, 1)

                frame.pin:SetAlpha(0)

                frame:SetPoint("BOTTOMLEFT", previous_frame, "BOTTOMLEFT", 0, -frame.sourceText:GetStringHeight()-y);
                
                frame.sourceText:SetJustifyH("LEFT")              
                
                previous_frame = frame
            elseif count == 12 then
                frame:SetPoint("BOTTOMLEFT", first_frame, "BOTTOMLEFT", 0, -overflow);
                count = 0           
            elseif relativeFrame == category then
                frame:SetPoint("BOTTOMLEFT", category, "BOTTOMLEFT", 0, -35);
                first_frame = frame
            else
                frame:SetPoint("RIGHT", relativeFrame, "RIGHT", frame_size+10, 0);
            end          

            core.Function:LinkMountItem(val, frame, pin)

            relativeFrame = frame
            count = count + 1
            if skip_total == true then
            else
                if tab then
                    MCL_functions:TableMounts(mount_Id, frame, tab, category)
                end
            end
            table.insert(mountFrames, frame)
        end  
    end   
    return overflow, mountFrames
end


function MCL_functions:CreatePinnedMount(mount_Id, category, section)

    local frame_size = 30
    local mountFrames = {}
    local total_pinned = table.getn(core.mountFrames[1])
    if total_pinned == 0 then
        local overflow, mountFrame = core.Function:CreateMountsForCategory(MCL_PINNED, _G["PinnedFrame"], 30, _G["PinnedTab"], true, true)
        core.mountFrames[1] = mountFrame
    else
        local relativeFrame = core.mountFrames[1][total_pinned]

        local mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        _,_, sourceText =  C_MountJournal.GetMountInfoExtraByID(mount_Id)

        local frame = CreateFrame("Button", nil, relativeFrame, "BackdropTemplate");
        frame:SetWidth(frame_size);
        frame:SetHeight(frame_size);
        frame:SetBackdrop({
            edgeFile = [[Interface\Buttons\WHITE8x8]],
            edgeSize = frame_size + 2,
            bgFile = [[Interface\Buttons\WHITE8x8]],
            tileSize = frame_size + 2,    
        })

        frame.pin = frame:CreateTexture()
        frame.pin:SetWidth(24)
        frame.pin:SetHeight(24)
        frame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
        frame.pin:SetPoint("TOPLEFT", frame, "TOPLEFT", 20,12)
        frame.pin:SetAlpha(1)

        frame.tex = frame:CreateTexture()
        frame.tex:SetSize(frame_size, frame_size)
        frame.tex:SetPoint("LEFT")
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        frame.tex:SetTexture(icon)

        frame.tex:SetVertexColor(0.75, 0.75, 0.75, 0.3);        

        frame.category = category
        frame.section = section

        frame.sectionName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.sectionName:SetPoint("LEFT", 650, 0)
        frame.sectionName:SetText(section)

        frame.categoryName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.categoryName:SetPoint("LEFT", 850, 0)
        frame.categoryName:SetText(category)
        
        frame.mountName = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.mountName:SetPoint("LEFT", 50, 0)
        frame.mountName:SetText(mountName)  
        
        frame.sourceText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.sourceText:SetPoint("LEFT", 250, 0)
        frame.sourceText:SetText(sourceText)          

        frame.border = frame:CreateLine(nil, "BACKGROUND", nil, 0)
        frame.border:SetThickness(1)
        frame.border:SetColorTexture(1, 1, 1, 0.8)
        frame.border:SetStartPoint("BOTTOMLEFT")
        frame.border:SetEndPoint("BOTTOMRIGHT")
        frame:SetWidth(1000)
        frame:SetHeight(frame.sourceText:GetStringHeight()+20)
        frame:SetBackdropBorderColor(0, 0, 0, 0.8)
        frame:SetBackdropColor(0, 0, 0, 0.8)
        frame.tex:SetVertexColor(1, 1, 1, 1)

        frame.pin:SetAlpha(0)

        frame:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", 0, -frame.sourceText:GetStringHeight()-30);

        frame.sourceText:SetJustifyH("LEFT") 

        frame.mountID = mount_Id

        core.Function:LinkMountItem("m"..tostring(mount_Id), frame, true)

        table.insert(core.mountFrames[1], frame)
  
    end
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
    local pinned, pin = core.Function:CheckIfPinned(frame.mountID)
    if pinned == true then
        table.remove(MCL_PINNED, pin)
    end
    frame:SetBackdropBorderColor(0, 0.45, 0, 0.4)
    frame.tex:SetVertexColor(1, 1, 1, 1);	
end


function UpdateProgressBar(frame, total, collected)
    if total == 0 then
        return
    end
	frame:SetValue((collected/total)*100)
    frame.Text:SetText(collected.."/"..total.." ("..math.floor(((collected/total)*100)).."%)")


	if ((collected/total)*100) < 33 then
		frame:SetStatusBarColor(0.929, 0.007, 0.019)  -- red
    elseif ((collected/total)*100) < 66 then
		frame:SetStatusBarColor(0.941, 0.658, 0.019) -- orange
    elseif ((collected/total)*100) < 99 then
		frame:SetStatusBarColor(0.1, 0.9, 0.1) -- green
	elseif collected == total then
		frame:SetStatusBarColor(0, 0.5, 0.9) --blue
	end

end

function UpdateProgressBarColor(frame)
	frame:SetStatusBarColor(0, 0.5, 0.9)
end

local function clearOverviewStats()
    for k in pairs (core.overviewStats) do
        core.overviewStats[k] = nil
    end
end

local function IsMountPinned(id)
    for k,v in pairs(core.mountFrames[1]) do
        if v.mountID == id then
            return true 
        end
    end
end

local function UpdatePin(frame)
    local pinned, pin = core.Function:CheckIfPinned("m"..tostring(frame.mountID))
    if pinned == true then
        frame.pin:SetAlpha(1)
    else
        frame.pin:SetAlpha(0)
    end
end   

function MCL_functions:UpdateCollection()
    clearOverviewStats()
    core.total = 0
    core.collected = 0
    for k,v in pairs(core.mounts) do
        core.total = core.total + 1
        if IsMountCollected(v.id) then
            table.insert(core.mountCheck, v.id)
            UpdateBackground(v.frame)
            core.collected = core.collected + 1
            local pin = false
            local pin_count = table.getn(MCL_PINNED)
            if pin_count ~= nil then                     
                for i=1, pin_count do                      
                    if MCL_PINNED[i].mountID == "m"..v.frame.mountID then
                        table.remove(MCL_PINNED, i)
                    end
                end
            end
            UpdatePin(v.frame)                
            local index = 0
            for kk,vv in pairs(core.mountFrames[1]) do
                index = index + 1
                if tostring(vv.mountID) == tostring(v.frame.mountID) then
                    local f = core.mountFrames[1][index]
                    table.remove(core.mountFrames[1],  index)
                    for kkk,vvv in ipairs(core.mountFrames[1]) do
                        if kkk == 1 then
                            vvv:SetParent(_G["PinnedFrame"])
                        else
                            vvv:SetParent(core.mountFrames[1][kkk-1])
                        end
                    end
                    f:Hide()
                end
            end            

        else
            UpdatePin(v.frame)
        end
    end
    for k,v in pairs(core.stats) do
        local section_total = 0
        local section_collected = 0
        local section_name
        -- if (type(v) == "table") then
        for kk,vv in pairs(v) do
            local collected = 0
            local total = 0
            local isCollected

            if (type(vv) == "table") then
                if vv["mounts"] then
                    for kkk, vvv in pairs(vv.mounts) do
                        local faction, faction_specific = IsMountFactionSpecific(vvv)
                        if faction then
                            if faction == 1 then
                                faction = "Alliance"
                            else
                                faction = "Horde"
                            end
                        end
                        if (faction_specific == false) or (faction_specific == true and faction == UnitFactionGroup("player")) then                     
                            if string.sub(vvv, 1, 1 ) == "m" then
                                isCollected = IsMountCollected(string.sub(vvv, 2, -1))
                            else
                                local id = core.Function:GetMountID(vvv)
                                isCollected = IsMountCollected(id)
                            end
                            if isCollected then
                                collected = collected +1
                            end
                            total = total +1
                        end
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
                            section_name = vv.rel.title:GetText()
                        end
                    end                     
                end               
            end            
        end
        if section_name == "Unobtainable" then
            core.total = core.total + section_collected - section_total
        end
    end
    UpdateProgressBar(core.overview.pBar, core.total, core.collected)
end

--------------------------------------------------
-- Minimap Icon
--------------------------------------------------


local MCL_MM = LibStub("AceAddon-3.0"):NewAddon("MCL_MM", "AceConsole-3.0")
local MCL_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("MCL!", {
type = "data source",
text = "MCL!",
icon = "Interface\\AddOns\\MCL\\mcl-logo-32",
OnClick = function(_, button) 
	core.Main:Toggle() 
end,
})
local icon = LibStub("LibDBIcon-1.0")

function MCL_MM:OnInitialize() -- Obviously you'll need a ## SavedVariables: BunniesDB line in your TOC, duh!
	self.db = LibStub("AceDB-3.0"):New("MCL_DB", { profile = { minimap = { hide = false, }, }, }) icon:Register("MCL!", MCL_LDB, self.db.profile.minimap) self:RegisterChatCommand("mcl", "UpdateMinimapButton")
end

function MCL_MM:MCL_MM()
	self.db.profile.minimap.hide = not self.db.profile.minimap.hide
	if self.db.profile.minimap.hide then
		icon:Hide("MCL!")
	else
		icon:Show("MCL!")
	end
end

function MCL_functions:MCL_MM()
	MCL_MM:MCL_MM()
end