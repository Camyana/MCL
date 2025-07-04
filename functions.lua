local MCL, MCLcore = ...;

MCLcore.Function = {};
local MCL_functions = MCLcore.Function;
local L = MCLcore.L

MCLcore.mounts = {}
MCLcore.stats= {}
MCLcore.overviewStats = {}
MCLcore.overviewFrames = {}
MCLcore.mountFrames = {}
MCLcore.mountCheck = {}
MCLcore.addon_name = L["MCL | Mount Collection Log"]


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

-- local function IsMountFactionSpecific(id)
--     if string.sub(id, 1, 1) == "m" then
--         mount_Id = string.sub(id, 2, -1)
--         local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
--         return faction, isFactionSpecific
--     else
--         mount_Id = C_MountJournal.GetMountFromItem(id)
--         local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
--         return faction, isFactionSpecific
--     end
-- end

local function GetMountInfoByIDChecked(mount_Id)
    local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
    return faction, isFactionSpecific
end

local function IsMountFactionSpecific(id)
    local mount_Id, ok, faction, isFactionSpecific

    if string.sub(id, 1, 1) == "m" then
        mount_Id = string.sub(id, 2, -1)
    else
        mount_Id = C_MountJournal.GetMountFromItem(id)
    end

    -- Use pcall to execute GetMountInfoByIDChecked and capture any error
    ok, faction, isFactionSpecific = pcall(GetMountInfoByIDChecked, mount_Id)

    -- If an error occurred, print the error message along with the id that caused the error
    if not ok then
        return nil, nil
    else
        return faction, isFactionSpecific
    end
end

MCLcore.Function.IsMountFactionSpecific = IsMountFactionSpecific

function MCL_functions:resetToDefault(setting)
    if setting == nil then
        MCL_SETTINGS = {}        
        MCL_SETTINGS.unobtainable = false
        MCL_SETTINGS.hideCollectedMounts = false
    end
    if setting == "Opacity" or setting == nil then
        MCL_SETTINGS.opacity = 0.95
    end
    if setting == "Texture" or setting == nil then
        MCL_SETTINGS.statusBarTexture = nil
    end
    if setting == "Colors" or setting == nil then
        MCL_SETTINGS.progressColors = {
            low = {
                ["a"] = 1,
                ["r"] = 0.929,
                ["g"] = 0.007,
                ["b"] = 0.019,
            },
            high = {
                ["a"] = 1,
                ["r"] = 0.1,
                ["g"] = 0.9,
                ["b"] = 0.1,
            },
            medium = {
                ["a"] = 1,
                ["r"] = 0.941,
                ["g"] = 0.658,
                ["b"] = 0.019,
            },
            complete = {
                ["a"] = 1,
                ["r"] = 0,
                ["g"] = 0.5,
                ["b"] = 0.9,
            },
        }
    end
    if setting == "HideCollectedMounts" or setting == nil then
        MCL_SETTINGS.hideCollectedMounts = false
    end
    if setting == "BlizzardTheme" or setting == nil then
        MCL_SETTINGS.useBlizzardTheme = false
    end
    if setting == "MountsPerRow" or setting == nil then
        MCL_SETTINGS.mountsPerRow = 12
    end
end

if MCL_SETTINGS == nil then
    MCLcore.Function:resetToDefault()
end

-- Ensure mountsPerRow setting exists for existing users
if MCL_SETTINGS.mountsPerRow == nil then
    MCL_SETTINGS.mountsPerRow = 12
end

-- Tables Mounts into Global List
function MCL_functions:TableMounts(id, frame, section, category)
    local mount = {
        id = id,
        frame = frame,
        section =  section,
        category = category,
    }
    table.insert(MCLcore.mounts, mount)
end

function MCL_functions:simplearmoryLink()
    local region = GetCVar("portal")

    local realmName = GetRealmName()

    local playerName = UnitName("player")

    local string = "https://simplearmory.com/#/"..region.."/"..realmName.."/"..playerName

    KethoEditBox_Show(string)

end

function MCL_functions:dfaLink()
    local region = GetCVar("portal")

    local realmName = GetRealmName()

    local playerName = UnitName("player")

    local string = "https://www.dataforazeroth.com/characters/"..region.."/"..realmName.."/"..playerName

    KethoEditBox_Show(string)

end

function MCL_functions:compareLink()
    local region = GetCVar("portal")

    local realmName = GetRealmName()

    local playerName = UnitName("player")
    local targetName, targetRealm
    if UnitIsPlayer("target") then
        targetName, targetRealm = UnitName("target")
        if targetRealm == nil then
            targetRealm = realmName
        end
    else
        KethoEditBox_Show("Mount off requires a target")
        return
    end
    
    local string = "https://wow-mcl.herokuapp.com/?realma="..region.."."..realmName.."&charactera="..playerName.."&realmb="..region.."."..targetRealm.."&characterb="..targetName
    
    KethoEditBox_Show(string)
end


function KethoEditBox_Show(text)
    if not KethoEditBox then
        local f = CreateFrame("Frame", "KethoEditBox", UIParent, "DialogBoxFrame")
        f:SetPoint("CENTER")
        f:SetSize(700, 100)
        
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\PVPFrame\\UI-Character-PVP-Highlight", -- this one is neat
            edgeSize = 16,
            insets = { left = 8, right = 6, top = 8, bottom = 8 },
        })
        f:SetBackdropBorderColor(0, .44, .87, 0.5) -- darkblue
        
        -- Movable
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self:StartMoving()
            end
        end)
        f:SetScript("OnMouseUp", f.StopMovingOrSizing)
        
        -- ScrollFrame
        local sf = CreateFrame("ScrollFrame", "KethoEditBoxScrollFrame", KethoEditBox, "UIPanelScrollFrameTemplate")
        sf:SetPoint("LEFT", 16, 0)
        sf:SetPoint("RIGHT", -32, 0)
        sf:SetPoint("TOP", 0, -16)
        sf:SetPoint("BOTTOM", KethoEditBoxButton, "TOP", 0, 0)
        
        -- EditBox
        local eb = CreateFrame("EditBox", "KethoEditBoxEditBox", KethoEditBoxScrollFrame)
        eb:SetSize(sf:GetSize())
        eb:SetMultiLine(true)
        eb:SetAutoFocus(false) -- dont automatically focus
        eb:SetFontObject("ChatFontNormal")
        eb:SetScript("OnEscapePressed", function() f:Hide() end)
        sf:SetScrollChild(eb)
        
        -- Resizable
        f:SetResizable(true)
        f:SetFrameStrata("HIGH")
        
        f:Show()
    end
    
    if text then
        KethoEditBoxEditBox:SetText(text)
    end
    KethoEditBox:Show()
    MCLcore.MCL_MF:Hide()
end

function MCL_functions:initSections()
    -- * --------------------------------
    -- * Create variables and assign strings to each section.
    -- * --------------------------------

    local faction = MCL_functions:getFaction()
    MCLcore.sections = {}

    for i, v in ipairs(MCLcore.sectionNames) do
        -- Skip opposite faction section
        if v.name ~= faction then
            table.insert(MCLcore.sections, v)
        end
    end

    MCLcore.MCL_MF_Nav = MCLcore.Frames:createNavFrame(MCLcore.MCL_MF, MCLcore.L["Sections"])

    -- Create the overview parent frame before SetTabs
    if not MCLcore.overview or not MCLcore.overview:IsObjectType("Frame") then
        -- Use the same width calculations from frames.lua for consistency
        local main_frame_width = 1250  -- Match the width from frames.lua
        MCLcore.overview = CreateFrame("Frame", nil, MCL_mainFrame.ScrollChild, "BackdropTemplate")
        MCLcore.overview:SetSize(main_frame_width - 60, 550)  -- Use consistent width calculation
        MCLcore.overview:SetPoint("TOPLEFT", MCL_mainFrame.ScrollChild, "TOPLEFT", 30, 0)  -- Consistent with other content frames
        MCLcore.overview:SetBackdropColor(0, 0, 0, 0)
    end
    -- Build the overview content into the overview frame
    MCLcore.Frames:createOverviewCategory(MCLcore.sections, MCLcore.overview)

    local tabFrames, numTabs = MCLcore.Frames:SetTabs() 

    MCLcore.sectionFrames = {}
    for i=1, numTabs do
        -- The section frames are already created in SetTabs, just reference them
        if tabFrames and tabFrames[i] then
            table.insert(MCLcore.sectionFrames, tabFrames[i])
        end
    end    
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
        for kk,vv in pairs(MCLcore.mountCheck) do
            if v == vv then
                exists = true
            end
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

function MCL_functions:SetMouseClickFunctionalityPin(frame, mountID, mountName, itemLink, spellID, isSteadyFlight)
    frame:SetScript("OnMouseDown", function(self, button)
        if IsControlKeyDown() then
            if button == 'LeftButton' then
                DressUpMount(mountID)
            elseif button == 'RightButton' then
                if IsMountCollected(mountID) == false then
                    -- Initialize MCL_PINNED if it doesn't exist
                    if not MCL_PINNED then
                        MCL_PINNED = {}
                    end
                    
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
                    -- Initialize MCLcore.mountFrames[1] if it doesn't exist
                    if not MCLcore.mountFrames[1] then
                        MCLcore.mountFrames[1] = {}
                    end
                    for k,v in pairs(MCLcore.mountFrames[1]) do
                        index = index + 1
                        if tostring(v.mountID) == tostring(mountID) then
                            table.remove(MCLcore.mountFrames[1],  index)
                            for kk,vv in ipairs(MCLcore.mountFrames[1]) do
                                if kk == 1 then
                                    vv:SetParent(_G["PinnedFrame"])
                                else
                                    vv:SetParent(MCLcore.mountFrames[1][kk-1])
                                end
                            end
                            frame:Hide()
                            MCLcore.Function:UpdateCollection()
                        end
                    end
                end
            end               
        elseif button=='LeftButton' then
            if IsShiftKeyDown() then
                -- Handle shift-click to link mount in chat
                if itemLink and ChatEdit_GetActiveWindow() then
                    ChatEdit_InsertLink(itemLink)
                elseif spellID then
                    local spellLink = C_Spell.GetSpellLink(spellID)
                    if spellLink and ChatEdit_GetActiveWindow() then
                        ChatEdit_InsertLink(spellLink)
                    end
                end
            end
        end
        if button == 'RightButton' then
            CastSpellByName(mountName);
        end
    end)
end

function MCL_functions:SetMouseClickFunctionality(frame, mountID, mountName, itemLink, spellID, isSteadyFlight) -- * Mount Frames

    frame:SetScript("OnMouseDown", function(self, button)
        if IsControlKeyDown() then
            if button == 'LeftButton' then
                DressUpMount(mountID)
            elseif button == 'RightButton' then
                if IsMountCollected(mountID) == false then
                    -- Initialize MCL_PINNED if it doesn't exist
                    if not MCL_PINNED then
                        MCL_PINNED = {}
                    end
                    
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
                        if frame.pin then
                            frame.pin:SetAlpha(0)
                        end
                        table.remove(MCL_PINNED, pin)
                        -- Update all pin icons for this mount
                        MCLcore.Function:UpdateAllPinIcons(mountID)
                        local index = 0
                        -- Initialize MCLcore.mountFrames[1] if it doesn't exist
                        if not MCLcore.mountFrames[1] then
                            MCLcore.mountFrames[1] = {}
                        end
                        for k,v in pairs(MCLcore.mountFrames[1]) do
                            index = index + 1
                            if tostring(v.mountID) == tostring(mountID) then
                                MCLcore.mountFrames[1][index]:Hide()                                
                                table.remove(MCLcore.mountFrames[1],  index)
                                for kk,vv in ipairs(MCLcore.mountFrames[1]) do
                                    if kk == 1 then
                                        vv:SetParent(_G["PinnedFrame"])
                                        vv:Show()
                                    else
                                        vv:SetParent(MCLcore.mountFrames[1][kk-1])
                                        vv:Show()
                                    end
                                end                                
                            end
                        end
                    else	                            
                        if frame.pin then
                            frame.pin:SetAlpha(1)
                        end
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
                        MCLcore.Function:CreatePinnedMount(mountID, frame.category, frame.section)
                        -- Update all pin icons for this mount
                        MCLcore.Function:UpdateAllPinIcons(mountID)

                    end
                end
            end               
        elseif button=='LeftButton' then
            if IsShiftKeyDown() then
                -- Handle shift-click to link mount in chat
                if itemLink and ChatEdit_GetActiveWindow() then
                    ChatEdit_InsertLink(itemLink)
                elseif spellID then
                    local spellLink = C_Spell.GetSpellLink(spellID)
                    if spellLink and ChatEdit_GetActiveWindow() then
                        ChatEdit_InsertLink(spellLink)
                    end
                end
            elseif isSteadyFlight then
                if frame.pop and frame.pop:IsShown() then 
                    frame.pop:Hide()
                elseif frame.pop then
                    frame.pop:Show()
                end
            else
                -- Don't add conflicting OnClick handlers here since OnMouseDown is already handling mouse events
                -- Shift-click functionality is handled in SetMouseClickFunctionality
            end
        end
        if button == 'RightButton' then
            CastSpellByName(mountName);
        end
    end)
end

function MCL_functions:LinkMountItem(id, frame, pin, dragonriding)
	--Adding a tooltip for mounts
    if string.sub(id, 1, 1) == "m" then
        id = string.sub(id, 2, -1)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(id)

        frame:HookScript("OnEnter", function()
            GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
            if (spellID) then
                _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(id) 

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
            MCLcore.Function:SetMouseClickFunctionalityPin(frame, mountID, mountName, itemLink, spellID, isSteadyFlight)
        else
            MCLcore.Function:SetMouseClickFunctionality(frame, mountID, mountName, itemLink, spellID, isSteadyFlight)
        end  
    else
        local item, itemLink = GetItemInfo(id);
        if dragonriding then
            frame:HookScript("OnEnter", function()
                GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
                if (id) then
                    GameTooltip:SetItemByID(id)
                    GameTooltip:AddLine(frame.source)
                    GameTooltip:Show()
                    frame:SetHyperlinksEnabled(true)
                end
            end)
            frame:HookScript("OnLeave", function()
                GameTooltip:Hide()
            end)

        else
            local mountID = C_MountJournal.GetMountFromItem(id)
            local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
        
            frame:HookScript("OnEnter", function()
                GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                if (itemLink) then
                    frame:SetHyperlinksEnabled(true)
                    _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)                     
                    GameTooltip:SetHyperlink(itemLink)
                    GameTooltip:AddLine(source)
                    GameTooltip:Show()
                end
            end)
            frame:HookScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            if pin == true then
                MCLcore.Function:SetMouseClickFunctionalityPin(frame, mountID, mountName, itemLink, _, isSteadyFlight)
            else
                MCLcore.Function:SetMouseClickFunctionality(frame, mountID, mountName, itemLink, _, isSteadyFlight)
            end
        end
    end
     
end


function MCL_functions:CompareMountJournal()
    local mounts = {}
    local i = 1
    for k,v in pairs(C_MountJournal.GetMountIDs()) do
        mounts[i] = v
        for kk,vv in pairs(MCLcore.mounts) do
            if vv.id == mounts[i] then
                mounts[i] = nil
            end
        end
    end
    for x,y in ipairs(mounts) do
        if y ~= nil then
            local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(y)
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
    local mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, sourceText, isSteadyFlight

    for kk,vv in pairs(set) do
        local mount_Id
        if pin then
            val = vv.mountID
        else
            val = vv
        end
        if string.sub(val, 1, 1) == "m" then
            mount_Id = string.sub(val, 2, -1)
            mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mount_Id)
            _,_, sourceText =  C_MountJournal.GetMountInfoExtraByID(mount_Id)
        else
            mount_Id = C_MountJournal.GetMountFromItem(val)
            mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mount_Id)
        end        
        local faction, faction_specific = IsMountFactionSpecific(val)
        if faction then
            if faction == 0 then
                faction = "Horde"
            elseif faction == 1 then
                faction = "Alliance"
            end
        end
        -- NEW: Hide collected mounts if setting is enabled
        if MCL_SETTINGS.hideCollectedMounts and IsMountCollected(mount_Id) then
            -- skip rendering this mount
        else
            if (faction_specific == false) or (faction_specific == true and faction == UnitFactionGroup("player")) then
                local mountsPerRow = MCL_SETTINGS.mountsPerRow or 12  -- Use setting or default to 12
                if count == mountsPerRow then
                    overflow = overflow + frame_size + 10
                end            
                local frame = CreateFrame("Button", nil, relativeFrame, "BackdropTemplate");
                frame:SetWidth(frame_size);
                frame:SetHeight(frame_size);
                frame:SetBackdrop({
                    edgeFile = [[Interface\Buttons\WHITE8x8]],
                    edgeSize = frame_size + 2,
                    bgFile = [[Interface\Buttons\WHITE8x8]],              
                })

                frame.pin = frame:CreateTexture(nil, "OVERLAY")
                frame.pin:SetWidth(16)
                frame.pin:SetHeight(16)
                frame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
                frame.pin:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
                frame.pin:SetAlpha(0)

                -- Handle category and section assignment based on context
                if pin and vv.category and vv.section then
                    -- For pinned mounts, use the data from the pinned mount entry
                    frame.category = vv.category
                    frame.section = vv.section
                elseif category and category.category and category.section then
                    -- For regular mounts, use the category data
                    frame.category = category.category
                    frame.section = category.section
                else
                    -- Fallback to prevent errors
                    frame.category = "Unknown"
                    frame.section = "Unknown"
                end

                frame.dragonRidable = isSteadyFlight


                frame:SetBackdropBorderColor(1, 0, 0, 0.03)
                frame:SetBackdropColor(0, 0, 0, MCL_SETTINGS.opacity)


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
                frame.itemID = val            

                local pin_check = MCLcore.Function:CheckIfPinned("m"..frame.mountID)
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
                    
                    frame:SetBackdrop({
                        bgFile = [[Interface\Buttons\WHITE8x8]],              
                    })

                    frame:SetBackdropBorderColor(0, 0, 0, MCL_SETTINGS.opacity)
                    frame:SetBackdropColor(0, 0, 0, MCL_SETTINGS.opacity)
                    frame.tex:SetVertexColor(1, 1, 1, 1)

                    -- Pin icon is already set correctly above, don't hide it

                    frame:SetPoint("BOTTOMLEFT", previous_frame, "BOTTOMLEFT", 0, -frame.sourceText:GetStringHeight()-y);
                    
                    frame.sourceText:SetJustifyH("LEFT")              
                    
                    previous_frame = frame
                elseif count == (MCL_SETTINGS.mountsPerRow or 12) then
                    frame:SetPoint("BOTTOMLEFT", first_frame, "BOTTOMLEFT", 0, -overflow);
                    count = 0           
                elseif relativeFrame == category then
                    frame:SetPoint("BOTTOMLEFT", category, "BOTTOMLEFT", 0, -35);
                    first_frame = frame
                else
                    frame:SetPoint("RIGHT", relativeFrame, "RIGHT", frame_size+10, 0);
                end          

                MCLcore.Function:LinkMountItem(val, frame, pin)

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
    end
    
    return overflow, mountFrames
end


function MCL_functions:CreatePinnedMount(mount_Id, category, section)

    local frame_size = 30
    local mountFrames = {}
    
    -- Initialize MCLcore.mountFrames[1] if it doesn't exist
    if not MCLcore.mountFrames[1] then
        MCLcore.mountFrames[1] = {}
    end
    
    local total_pinned = table.getn(MCLcore.mountFrames[1])
    if total_pinned == 0 then
        -- Initialize MCL_PINNED if it doesn't exist
        if not MCL_PINNED then
            MCL_PINNED = {}
        end
        local overflow, mountFrame = MCLcore.Function:CreateMountsForCategory(MCL_PINNED, _G["PinnedFrame"], 30, _G["PinnedTab"], true, true)
        MCLcore.mountFrames[1] = mountFrame
    else
        local relativeFrame = MCLcore.mountFrames[1][total_pinned]

        local mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        _,_, sourceText =  C_MountJournal.GetMountInfoExtraByID(mount_Id)

        -- Create frame parented to the Pinned section, not to the previous frame
        local frame = CreateFrame("Button", nil, _G["PinnedFrame"], "BackdropTemplate");
        frame:SetWidth(frame_size);
        frame:SetHeight(frame_size);
        frame:SetBackdrop({
            -- edgeFile = [[Interface\Buttons\WHITE8x8]],
            -- edgeSize = frame_size + 2,
            bgFile = [[Interface\Buttons\WHITE8x8]],
            tileSize = frame_size + 2,    
        })

        frame.pin = frame:CreateTexture(nil, "OVERLAY")
        frame.pin:SetWidth(16)
        frame.pin:SetHeight(16)
        frame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
        frame.pin:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
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
        frame:SetBackdropBorderColor(0, 0, 0, MCL_SETTINGS.opacity)
        frame:SetBackdropColor(0, 0, 0, MCL_SETTINGS.opacity)
        frame.tex:SetVertexColor(1, 1, 1, 1)

        frame.pin:SetAlpha(0)

        frame:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", 0, -frame.sourceText:GetStringHeight()-30);

        frame.sourceText:SetJustifyH("LEFT") 

        frame.mountID = mount_Id

        MCLcore.Function:LinkMountItem("m"..tostring(mount_Id), frame, true)

        table.insert(MCLcore.mountFrames[1], frame)
  
    end
end


function MCL_functions:GetMountID(id)
    local mount_Id
    local inputType = type(id)
    local isStringWithM = (inputType == "string" and string.sub(tostring(id), 1, 1) == "m")
    local isNumber = (inputType == "number")
    
    if isStringWithM then
        mount_Id = tonumber(string.sub(tostring(id), 2, -1))
    elseif isNumber and id > 100000 then
        -- Likely an item ID (large number)
        mount_Id = C_MountJournal.GetMountFromItem(id)
    elseif isNumber and id < 10000 then
        -- Likely a mount ID (small number)
        mount_Id = id
    else
        -- Default to item lookup
        mount_Id = C_MountJournal.GetMountFromItem(id)
    end
    
    return mount_Id
end

function IsMountCollected(id)
    local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = C_MountJournal.GetMountInfoByID(id)
    return isCollected
end

function UpdateBackground(frame)
    local pinned, pin = MCLcore.Function:CheckIfPinned(frame.mountID)
    if pinned == true then
        table.remove(MCL_PINNED, pin)
    end
    frame:SetBackdropBorderColor(0, 0.45, 0, 0.4)
    frame.tex:SetVertexColor(1, 1, 1, 1);	
end


function UpdateProgressBar(frame, total, collected)
    if not frame then
        return
    end    
    
    if total == nil and collected == nil then
        return frame
    else
        if total == 0 then
            -- Handle zero total case properly
            frame:SetValue(0)
            frame.Text:SetText("0/0 (0%)")
            frame:SetStatusBarColor(0.3, 0.3, 0.3)  -- Dark gray for no data
            return frame
        end
        frame.collected = collected
        frame.total = total
        frame:SetValue((collected/total)*100)
        frame.Text:SetText(collected.."/"..total.." ("..math.floor(((collected/total)*100)).."%)")
        frame.val = (collected/total)*100
    end
    
    if frame.val == nil then
        return frame
    end
    
    if not MCL_SETTINGS or not MCL_SETTINGS.progressColors then
        -- Fallback colors
        if frame.val < 33 then
            frame:SetStatusBarColor(1, 0, 0) -- red
        elseif frame.val < 66 then
            frame:SetStatusBarColor(1, 0.65, 0) -- orange
        elseif frame.val < 100 then
            frame:SetStatusBarColor(0, 1, 0) -- green
        else
            frame:SetStatusBarColor(0, 0.5, 1) -- blue
        end
        return frame
    end
    
    if frame.val < 33 then
        frame:SetStatusBarColor(MCL_SETTINGS.progressColors.low.r, MCL_SETTINGS.progressColors.low.g, MCL_SETTINGS.progressColors.low.b) -- red
    elseif frame.val < 66 then
        frame:SetStatusBarColor(MCL_SETTINGS.progressColors.medium.r, MCL_SETTINGS.progressColors.medium.g, MCL_SETTINGS.progressColors.medium.b) -- orange
    elseif frame.val < 100 then
        frame:SetStatusBarColor(MCL_SETTINGS.progressColors.high.r, MCL_SETTINGS.progressColors.high.g, MCL_SETTINGS.progressColors.high.b) -- green
    elseif frame.val == 100 then
        frame:SetStatusBarColor(MCL_SETTINGS.progressColors.complete.r, MCL_SETTINGS.progressColors.complete.g, MCL_SETTINGS.progressColors.complete.b) -- blue
    end
    
    -- Ensure we have a good texture for coloring
    local textureToUse = "Interface\\TargetingFrame\\UI-StatusBar"  -- Default fallback
    
    -- Try to get the texture from settings first
    if MCL_SETTINGS and MCL_SETTINGS.statusBarTexture and MCLcore.media then
        local settingsTexture = MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture)
        if settingsTexture then
            textureToUse = settingsTexture
        end
    end
    
    -- Set the texture
    frame:SetStatusBarTexture(textureToUse)
    local texture = frame:GetStatusBarTexture()
    if texture then
        texture:SetHorizTile(false)
        texture:SetVertTile(false)
    end
    
    return frame
end

function UpdateProgressBarColor(frame)
	frame:SetStatusBarColor(0, 0.5, 0.9)
end

local function clearOverviewStats()
    for k in pairs (MCLcore.overviewStats) do
        MCLcore.overviewStats[k] = nil
    end
end

local function IsMountPinned(id)
    for k,v in pairs(MCLcore.mountFrames[1]) do
        if v.mountID == id then
            return true 
        end
    end
end

local function UpdatePin(frame)
    if not frame.pin then
        return  -- Exit early if pin doesn't exist
    end
    local pinned, pin = MCLcore.Function:CheckIfPinned("m"..tostring(frame.mountID))
    if pinned == true then
        frame.pin:SetAlpha(1)
    else
        frame.pin:SetAlpha(0)
    end
end   


function MCL_functions:UpdateCollection()
    clearOverviewStats()
    if MCLcore.MCL_MF.Bg then
        MCLcore.MCL_MF.Bg:SetVertexColor(0, 0, 0, MCL_SETTINGS.opacity)
    end
    MCLcore.total = 0
    MCLcore.collected = 0

    -- Count mounts from MCLcore.mounts
    for k, v in pairs(MCLcore.mounts) do
        local mountID = v.id
        MCLcore.total = MCLcore.total + 1
        if IsMountCollected(mountID) then
            table.insert(MCLcore.mountCheck, mountID)
            UpdateBackground(v.frame)
            MCLcore.collected = MCLcore.collected + 1
            local pin_count = table.getn(MCL_PINNED) or 0
            for i = 1, pin_count do
                if MCL_PINNED[i].mountID == "m"..v.frame.mountID then
                    table.remove(MCL_PINNED, i)
                    break
                end
            end
            UpdatePin(v.frame)
            local index = 0
            for kk, vv in pairs(MCLcore.mountFrames[1] or {}) do
                index = index + 1
                if tostring(vv.mountID) == tostring(v.frame.mountID) then
                    local f = MCLcore.mountFrames[1][index]
                    table.remove(MCLcore.mountFrames[1], index)
                    for kkk, vvv in ipairs(MCLcore.mountFrames[1]) do
                        if kkk == 1 then
                            vvv:SetParent(_G["PinnedFrame"])
                        else
                            vvv:SetParent(MCLcore.mountFrames[1][kkk-1])
                        end
                    end
                    f:Hide()
                    break
                end
            end
        else
            UpdatePin(v.frame)
        end
    end

    -- Update section stats with validation
    for k, v in pairs(MCLcore.stats) do
        local section_total = 0
        local section_collected = 0
        local section_name
        for kk, vv in pairs(v) do
            local collected = 0
            local total = 0
            if type(vv) == "table" then
                if vv["mounts"] then
                    for kkk, vvv in pairs(vv.mounts) do
                        local faction, faction_specific = IsMountFactionSpecific(vvv)
                        if faction then
                            if faction == 1 then faction = "Alliance" else faction = "Horde" end
                        end
                        if (faction_specific == false) or (faction_specific == true and faction == UnitFactionGroup("player")) then
                            local mountID
                            if string.sub(vvv, 1, 1) == "m" then
                                mountID = tonumber(string.sub(vvv, 2, -1))
                            else
                                mountID = C_MountJournal.GetMountFromItem(vvv)
                            end
                            if mountID then
                                local isCollected = IsMountCollected(mountID)
                                if isCollected == nil then
                                    C_Item.RequestLoadItemDataByID(vvv) -- Force load if item-based
                                end
                                total = total + 1
                                if isCollected then
                                    collected = collected + 1
                                end
                            end
                        end
                    end
                    if vv.pBar then
                        vv.pBar = UpdateProgressBar(vv.pBar, total, collected)
                    end
                    section_total = section_total + total
                    section_collected = section_collected + collected
                else
                    if vv.pBar then
                        vv.pBar = UpdateProgressBar(vv.pBar, section_total, section_collected)
                    end
                end
                if vv["rel"] then
                    for q, e in pairs(MCLcore.overviewFrames) do
                        if e.name == vv.rel.name and e.frame then
                            e.frame = UpdateProgressBar(e.frame, section_total, section_collected)
                            section_name = e.name
                        end
                    end
                end
            end
        end
        if section_name == MCLcore.L["Unobtainable"] then
            MCLcore.total = MCLcore.total + section_collected - section_total
        end
    end

    -- Validate and update overall progress
    if MCLcore.total < 0 then
        MCLcore.total = 0
    end
    
    -- Only update overview progress bar if it exists
    if MCLcore.overview and MCLcore.overview.pBar then
        MCLcore.overview.pBar = UpdateProgressBar(MCLcore.overview.pBar, MCLcore.total, MCLcore.collected)
    end
    
    -- Initialize pinned section if it doesn't exist yet
    if _G["PinnedFrame"] and (not MCLcore.mountFrames[1] or #MCLcore.mountFrames[1] == 0) then
        -- Initialize MCL_PINNED if it doesn't exist
        if not MCL_PINNED then
            MCL_PINNED = {}
        end
        -- Initialize mountFrames[1] if it doesn't exist
        if not MCLcore.mountFrames[1] then
            MCLcore.mountFrames[1] = {}
        end
        -- Create the pinned section content even if empty
        local overflow, mountFrame = MCLcore.Function:CreateMountsForCategory(MCL_PINNED, _G["PinnedFrame"], 30, _G["PinnedTab"], true, true)
        MCLcore.mountFrames[1] = mountFrame
    end
end


function MCL_functions:updateFromSettings(setting, val)
    for k,v in pairs(MCLcore.statusBarFrames) do
        if setting == "texture" then
            v:SetStatusBarTexture(MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture))
        elseif setting == "progressColor" then
            -- Call UpdateProgressBar with proper parameters to refresh colors
            if v.total and v.collected then
                v = UpdateProgressBar(v, v.total, v.collected)
            end
        end
    end
    if setting == "opacity" then
        MCLcore.MCL_MF.Bg:SetVertexColor(0,0,0,MCL_SETTINGS.opacity)
    elseif setting:lower() == "unobtainable" then
        for k,v in pairs(MCLcore.overviewFrames) do
            if v.name:lower() == setting:lower() then
                if val == true then
                    v.frame:GetParent():Hide()
                    v.frame.unobtainable = true
                else 
                    v.frame.unobtainable = false
                    v.frame:GetParent():Show()
                end
            end
        end
    end
end

--------------------------------------------------
-- Minimap Icon
--------------------------------------------------

function MCL_functions:test()
end


local MCL_MM = LibStub("AceAddon-3.0"):NewAddon("MCL_MM", "AceConsole-3.0")
local MCL_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("MCL!", {
type = "data source",
text = "MCL!",
icon = "Interface\\AddOns\\MCL\\mcl-logo-32",
OnTooltipShow = function(tooltip)
    tooltip:SetText("MCL")
    tooltip:AddLine(L["Mount Collection Log"], 1, 1, 1)
    tooltip:Show()
end,
OnClick = function(_, button) 
	MCLcore.Main:Toggle() 
end,
})
local icon = LibStub("LibDBIcon-1.0")

function MCL_MM:OnInitialize() -- Obviously you'll need a ## SavedVariables: BunniesDB line in your TOC, duh!
	self.db = LibStub("AceDB-3.0"):New("MCL_DB", { profile = { minimap = { hide = false, }, }, }) icon:Register("MCL!", MCL_LDB, self.db.profile.minimap)
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


function MCL_functions:updateFromDefaults(setting)
    MCLcore.Function:resetToDefault(setting)
    MCLcore.Function:updateFromSettings("opacity")
    MCLcore.Function:updateFromSettings("texture")
    MCLcore.Function:updateFromSettings("progressColor")
    MCLcore.Function:updateFromSettings("unobtainable", false)
end

function MCL_functions:AddonSettings()
    local AceConfig = LibStub("AceConfig-3.0");
    local media = LibStub("LibSharedMedia-3.0")
    MCLcore.media = media
    local options = {
        type = "group",
        name = MCLcore.L["Mount Collection Log Settings"],
        order = 1,
        args = {
            headerone = {             
                order = 1,
                name = MCLcore.L["Main Window Options"],
                type = "header",
                width = "full",
            },            
            mainWindow = {             
                order = 2,
                name = MCLcore.L["Main Window Opacity"],
                desc = MCLcore.L["Changes the opacity of the main window"],
                type = "range",
                width = "normal",
                min = 0,
                max = 1,
                softMin = 0,
                softMax = 1,
                bigStep = 0.05,
                isPercent = false,
                set = function(info, val) MCL_SETTINGS.opacity = val; MCLcore.Function:updateFromSettings("opacity"); end,
                get = function(info) return MCL_SETTINGS.opacity; end,
            },
            spacer1 = {
                order = 2.5,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "half",
            },
            defaultOpacity = {
                order = 3,
                name = MCLcore.L["Reset Opacity"],
                desc = MCLcore.L["Reset to default opacity"],
                width = "normal",
                type = "execute",
                func = function()
                    MCLcore.Function:updateFromDefaults("Opacity")
                end
            },              
            headertwo = {             
                order = 4,
                name = MCLcore.L["Progress Bar Settings"],
                type = "header",
                width = "normal",
            },             
            texture = {              
                order = 5,
                type = "select",
                name = MCLcore.L["Statusbar Texture"],
                width = "normal",
                desc = MCLcore.L["Set the statusbar texture."],
                values = media:HashTable("statusbar"),
                -- Removed dialogControl = "LSM30_Statusbar",
                set = function(info, val) MCL_SETTINGS.statusBarTexture = val; MCLcore.Function:updateFromSettings("texture"); end,
                get = function(info) return MCL_SETTINGS.statusBarTexture; end,
                style = "dropdown", -- This ensures it uses a dropdown menu for selection
            },
            spacer2 = {
                order = 5.5,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "half",
            },            
            defaultTexture = {
                order = 6,
                name = MCLcore.L["Reset Texture"],
                desc = MCLcore.L["Reset to default texture"],
                width = "normal",
                type = "execute",
                func = function()
                    MCLcore.Function:updateFromDefaults("Texture")
                end
            },
            spacer3 = {
                order = 6.5,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "full",
            },
            spacer3large = {
                order = 6.6,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "full",
            },                                  
            progressColorLow = {
                order = 7,
                type = "color",
                name = MCLcore.L["Progress Bar (<33%)"],
                width = "normal",
                desc = MCLcore.L["Set the progress bar colors to be shown when the percentage collected is below 33%"],
                set = function(info, r, g, b) MCL_SETTINGS.progressColors.low.r = r; MCL_SETTINGS.progressColors.low.g = g; MCL_SETTINGS.progressColors.low.b = b; MCLcore.Function:updateFromSettings("progressColor"); end,
                get = function(info) return MCL_SETTINGS.progressColors.low.r, MCL_SETTINGS.progressColors.low.g, MCL_SETTINGS.progressColors.low.b; end,                
            },
            spacer4 = {
                order = 7.5,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "half",
            },            
            progressColorMedium = {
                order = 8,
                type = "color",
                name = MCLcore.L["Progress Bar (<66%)"],
                width = "normal",
                desc = MCLcore.L["Set the progress bar colors to be shown when the percentage collected is below 66%"],
                set = function(info, r, g, b) MCL_SETTINGS.progressColors.medium.r = r; MCL_SETTINGS.progressColors.medium.g = g; MCL_SETTINGS.progressColors.medium.b = b; MCLcore.Function:updateFromSettings("progressColor"); end,
                get = function(info) return MCL_SETTINGS.progressColors.medium.r, MCL_SETTINGS.progressColors.medium.g, MCL_SETTINGS.progressColors.medium.b; end,                
            },
            spacer5 = {
                order = 8.5,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "half",
            },             
            progressColorHigh = {
                order = 9,
                type = "color",
                name = MCLcore.L["Progress Bar (<100%)"],
                width = "normal",
                desc = MCLcore.L["Set the progress bar colors to be shown when the percentage collected is below 100%"],
                set = function(info, r, g, b) MCL_SETTINGS.progressColors.high.r = r; MCL_SETTINGS.progressColors.high.g = g; MCL_SETTINGS.progressColors.high.b = b; MCLcore.Function:updateFromSettings("progressColor"); end,
                get = function(info) return MCL_SETTINGS.progressColors.high.r, MCL_SETTINGS.progressColors.high.g, MCL_SETTINGS.progressColors.high.b; end,                
            },
            spacer6 = {
                order = 9.5,
                cmdHidden = true,
                name = "",
                type = "description",
                width = "half",
            },             
            progressColorComplete = {
                order = 10,
                type = "color",
                name = MCLcore.L["Progress Bar (100%)"],
                width = "normal",
                desc = MCLcore.L["Set the progress bar colors to be shown when all mounts are collected"],
                set = function(info, r, g, b) MCL_SETTINGS.progressColors.complete.r = r; MCL_SETTINGS.progressColors.complete.g = g; MCL_SETTINGS.progressColors.complete.b = b; MCLcore.Function:updateFromSettings("progressColor"); end,
                get = function(info) return MCL_SETTINGS.progressColors.complete.r, MCL_SETTINGS.progressColors.complete.g, MCL_SETTINGS.progressColors.complete.b; end,                
            },
            defaultColor = {
                order = 11,
                name = MCLcore.L["Reset Colors"],
                desc = MCLcore.L["Reset to default colors"],
                width = "normal",
                type = "execute",
                func = function()
                    MCLcore.Function:updateFromDefaults("Colors")
                end
            },              
            headerthree = {             
                order = 12,
                name = MCLcore.L["Layout Settings"],
                type = "header",
                width = "full",
            },
            mountsPerRow = {
                order = 12.5,
                name = MCLcore.L["Mounts Per Row"],
                desc = MCLcore.L["Set the number of mounts to display per row in the mount grid. Requires UI reload."],
                type = "range",
                width = "normal",
                min = 6,
                max = 24,
                softMin = 6,
                softMax = 24,
                step = 1,
                bigStep = 1,
                set = function(info, val)
                    if MCL_SETTINGS.mountsPerRow ~= val then
                        -- Save the setting first
                        MCL_SETTINGS.mountsPerRow = val;
                        
                        -- Then ask if they want to reload
                        StaticPopupDialogs["MCL_MOUNTS_PER_ROW_RELOAD"] = {
                            text = MCLcore.L["Changing this setting requires a UI reload. Reload now?"],
                            button1 = MCLcore.L["YES"],
                            button2 = MCLcore.L["NO"],
                            OnAccept = function()
                                ReloadUI();
                            end,
                            OnCancel = function()
                                -- Setting is already saved, so just do nothing
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                        }
                        StaticPopup_Show("MCL_MOUNTS_PER_ROW_RELOAD")
                    end
                end,
                get = function(info) return MCL_SETTINGS.mountsPerRow; end,
            },
            headerfour = {             
                order = 13,
                name = MCLcore.L["Unobtainable Settings"],
                type = "header",
                width = "full",
            },            
            unobtainable = {             
                order = 14,
                name = MCLcore.L["Hide Unobtainable from overview"],
                desc = MCLcore.L["Hide Unobtainable mounts from the overview."],
                type = "toggle",
                width = "full",
                set = function(info, val) MCL_SETTINGS.unobtainable = val; MCLcore.Function:updateFromSettings("unobtainable", val); end,
                get = function(info) return MCL_SETTINGS.unobtainable; end,
            },
            hideCollectedMounts = {
                order = 14.5,
                name = MCLcore.L["Hide Collected Mounts"],
                desc = MCLcore.L["If enabled, collected mounts will not be shown in the list at all. Requires UI reload."],
                type = "toggle",
                width = "full",
                set = function(info, val)
                    if MCL_SETTINGS.hideCollectedMounts ~= val then
                        StaticPopupDialogs["MCL_RELOAD_CONFIRM"] = {
                            text = MCLcore.L["Changing this setting requires a UI reload. Reload now?"],
                            button1 = MCLcore.L["YES"],
                            button2 = MCLcore.L["NO"],
                            OnAccept = function()
                                MCL_SETTINGS.hideCollectedMounts = val;
                                ReloadUI();
                            end,
                            OnCancel = function()
                                -- Do nothing
                            end,
                            timeout = 0,
                            whileDead = true,
                            hideOnEscape = true,
                            preferredIndex = 3,
                        }
                        StaticPopup_Show("MCL_RELOAD_CONFIRM")
                    end
                end,
                get = function(info) return MCL_SETTINGS.hideCollectedMounts; end,
            },
            useBlizzardTheme = {
                order = 14.6,
                name = MCLcore.L["Use Blizzard Theme"],
                desc = MCLcore.L["If enabled, the addon will use Blizzard's default UI theme. Requires UI reload."],
                type = "toggle",
                width = "full",
                set = function(info, val)
                    if MCL_SETTINGS.useBlizzardTheme ~= val then
                        StaticPopupDialogs["MCL_RELOADUI"] = {
                            text = MCLcore.L["Changing this setting requires a UI reload. Reload now?"],
                            button1 = MCLcore.L["YES"],
                            button2 = MCLcore.L["NO"],
                            OnAccept = function() MCL_SETTINGS.useBlizzardTheme = val; ReloadUI(); end,
                            timeout = 0,
                            hideOnEscape = true,
                        }
                        StaticPopup_Show("MCL_RELOADUI")
                    end
                end,
                get = function(info) return MCL_SETTINGS.useBlizzardTheme; end,
            },
            minimapIconToggle = {
                order = 14.7,
                name = MCLcore.L["Show Minimap Icon"],
                desc = MCLcore.L["Toggle the display of the Minimap Icon."],
                type = "toggle",
                width = "full",
                set = function(info, val)
                    MCL_MM.db.profile.minimap.hide = not val
                    if val then
                        icon:Show("MCL!")
                    else
                        icon:Hide("MCL!")
                    end
                end,
                get = function(info)
                    return not MCL_MM.db.profile.minimap.hide
                end,
            },
            headerfive = {             
                order = 15,
                name = MCLcore.L["Reset Settings"],
                type = "header",
                width = "full",
            },             
            defaults = {
                order = 16,
                name = MCLcore.L["Reset Settings"],
                desc = MCLcore.L["Reset to default settings"],
                width = "normal",
                type = "execute",
                func = function()
                    MCLcore.Function:updateFromDefaults()
                end
            }                                                                                                       
        }
    }                                                        


    AceConfig:RegisterOptionsTable(MCLcore.addon_name, options, {});
    MCLcore.AceConfigDialog = LibStub("AceConfigDialog-3.0");
    MCLcore.AceConfigDialog:AddToBlizOptions(MCLcore.addon_name, MCLcore.addon_name, nil);
end

function MCL_functions:CalculateSectionStats()
    MCLcore.stats = {}
    
    for _, section in ipairs(MCLcore.sections or {}) do
        local sectionTotal = 0
        local sectionCollected = 0
        
        if section.mounts and section.mounts.categories then
            for categoryName, categoryData in pairs(section.mounts.categories) do
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
                    sectionTotal = sectionTotal + 1
                    local mount_Id = MCLcore.Function:GetMountID(mountId)
                    if mount_Id and IsMountCollected(mount_Id) then
                        sectionCollected = sectionCollected + 1
                    end
                end
            end
        end
        
        MCLcore.stats[section.name] = {
            total = sectionTotal,
            collected = sectionCollected
        }
    end
end

function MCL_functions:UpdateAllPinIcons(mountID)
    -- Update pin icons for mounts with the given mountID across all frames
    local mountIDString = "m" .. mountID
    local isPinned = MCLcore.Function:CheckIfPinned(mountIDString)
    
    -- Update pin icons in regular mount frames (CreateMountsForCategory)
    for k, v in pairs(MCLcore.mounts or {}) do
        if v.frame and v.frame.mountID and tostring(v.frame.mountID) == tostring(mountID) then
            if v.frame.pin then
                if isPinned then
                    v.frame.pin:SetAlpha(1)
                else
                    v.frame.pin:SetAlpha(0)
                end
            end
        end
    end
    
    -- Update pin icons in section page mount frames
    -- We need to search through all frames in the UI to find matching mount frames
    local function UpdateFrameRecursively(frame)
        if frame and frame.mountID and tostring(frame.mountID) == tostring(mountID) and frame.pin then
            if isPinned then
                frame.pin:SetAlpha(1)
            else
                frame.pin:SetAlpha(0)
            end
        end
        
        -- Check children
        if frame.GetChildren then
            for _, child in ipairs({frame:GetChildren()}) do
                UpdateFrameRecursively(child)
            end
        end
    end
    
    -- Start from the main frame and search all children
    if MCLcore.MCL_MF then
        UpdateFrameRecursively(MCLcore.MCL_MF)
    end
end
