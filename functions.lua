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
MCLcore.pinnedMountsChanged = false  -- Flag to track if pinned mounts have been modified


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
    local ok, faction, isFactionSpecific = pcall(GetMountInfoByIDChecked, mount_Id)

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
    if setting == "MountCardHover" or setting == nil then
        MCL_SETTINGS.enableMountCardHover = true
    end
end

if MCL_SETTINGS == nil then
    MCLcore.Function:resetToDefault()
end

-- Ensure mountsPerRow setting exists for existing users
if MCL_SETTINGS.mountsPerRow == nil then
    MCL_SETTINGS.mountsPerRow = 12
end

-- Ensure enableMountCardHover setting exists for existing users
if MCL_SETTINGS.enableMountCardHover == nil then
    MCL_SETTINGS.enableMountCardHover = true
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
                -- Allow pinning of both collected and uncollected mounts
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
                            break
                        end
                    end
                end
                
                -- Only remove if we found a valid pin index
                if pin ~= false then
                    table.remove(MCL_PINNED, pin)
                    
                    -- Set flag to indicate pinned mounts have been modified
                    MCLcore.pinnedMountsChanged = true
                    
                    -- Update all pin icons for this mount
                    MCLcore.Function:UpdateAllPinIcons(mountID)
                    
                    -- Refresh the pinned section by recreating it
                    if _G["PinnedFrame"] then
                        -- Clear existing mount frames more thoroughly
                        if MCLcore.mountFrames[1] then
                            for _, oldFrame in ipairs(MCLcore.mountFrames[1]) do
                                if oldFrame and oldFrame:GetParent() then
                                    oldFrame:Hide()
                                    oldFrame:SetParent(nil)
                                end
                            end
                        end
                        
                        -- Also clear any untracked children of PinnedFrame
                        local children = {_G["PinnedFrame"]:GetChildren()}
                        for _, child in ipairs(children) do
                            if child and child:IsObjectType("Button") and child.mountID then
                                child:Hide()
                                child:SetParent(nil)
                            end
                        end
                        
                        MCLcore.mountFrames[1] = {}
                        
                        -- Clean up invalid pinned mounts before recreating
                        MCLcore.Function:CleanupInvalidPinnedMounts()
                        
                        -- Recreate the pinned section content
                        local overflow, mountFrame = MCLcore.Function:CreateMountsForCategory(MCL_PINNED, _G["PinnedFrame"], 30, _G["PinnedTab"], true, true)
                        MCLcore.mountFrames[1] = mountFrame
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
        elseif button == 'RightButton' and not IsControlKeyDown() then
            -- Right-click to show/hide mount card
            if MCLcore and MCLcore.MountCard then
                local mountData = {
                    mountID = mountID,
                    id = mountID,
                    name = mountName,
                    category = frame.category,
                    section = frame.section
                }
                MCLcore.MountCard.Toggle(mountData, frame)
            end
        end
        if button == 'MiddleButton' then
            -- Middle click to cast mount if it's collected
            if IsMountCollected(mountID) then
                CastSpellByName(mountName);
            end
        end
    end)
end

function MCL_functions:SetMouseClickFunctionality(frame, mountID, mountName, itemLink, spellID, isSteadyFlight) -- * Mount Frames

    frame:SetScript("OnMouseDown", function(self, button)
        if IsControlKeyDown() then
            if button == 'LeftButton' then
                DressUpMount(mountID)
            elseif button == 'RightButton' then
                -- Allow pinning of both collected and uncollected mounts
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
                    
                    -- Set flag to indicate pinned mounts have been modified
                    MCLcore.pinnedMountsChanged = true
                    
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
                    
                    -- Refresh the pinned tab layout after unpinning
                    if MCL_frames and MCL_frames.RefreshLayout then
                        -- Check if we're currently viewing the Pinned tab
                        local isPinnedTabActive = false
                        if MCLcore.currentlySelectedTab and MCLcore.currentlySelectedTab.section and MCLcore.currentlySelectedTab.section.name == "Pinned" then
                            isPinnedTabActive = true
                        end
                        
                        -- Refresh the layout to update the pinned content
                        MCLcore.Frames:RefreshLayout()
                        
                        -- If we were on the Pinned tab, reselect it
                        if isPinnedTabActive and MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                            for _, tab in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                                if tab.section and tab.section.name == "Pinned" then
                                    tab:GetScript("OnClick")(tab)
                                    break
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
                    
                    -- Set flag to indicate pinned mounts have been modified
                    MCLcore.pinnedMountsChanged = true
                    
                    MCLcore.Function:CreatePinnedMount(mountID, frame.category, frame.section)
                    -- Update all pin icons for this mount
                    MCLcore.Function:UpdateAllPinIcons(mountID)

                    -- Refresh the pinned tab layout after pinning
                    C_Timer.After(0.1, function()
                        if MCL_frames and MCL_frames.SetTabs then
                            -- Check if we're currently viewing the Pinned tab
                            local isPinnedTabActive = false
                            if MCLcore.currentlySelectedTab and MCLcore.currentlySelectedTab.section and MCLcore.currentlySelectedTab.section.name == "Pinned" then
                                isPinnedTabActive = true
                            end
                            
                            -- Refresh the tabs to update the pinned content
                            MCLcore.Frames:SetTabs()
                            
                            -- If we were on the Pinned tab, reselect it
                            if isPinnedTabActive and MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                                for _, tab in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                                    if tab.section and tab.section.name == "Pinned" then
                                        tab:GetScript("OnClick")(tab)
                                        break
                                    end
                                end
                            end
                        end
                    end)

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
        elseif button == 'RightButton' and not IsControlKeyDown() then
            -- Right-click to show/hide mount card
            if MCLcore and MCLcore.MountCard then
                local mountData = {
                    mountID = mountID,
                    id = mountID,
                    name = mountName,
                    category = frame.category,
                    section = frame.section
                }
                MCLcore.MountCard.Toggle(mountData, frame)
            end
        end
        if button == 'MiddleButton' then
            -- Middle click to cast mount if it's collected
            if IsMountCollected(mountID) then
                CastSpellByName(mountName);
            end
        end
    end)
end

function MCL_functions:LinkMountItem(id, frame, pin, dragonriding)
	--Adding a tooltip for mounts
    if string.sub(id, 1, 1) == "m" then
        id = string.sub(id, 2, -1)
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(id)

        frame:HookScript("OnEnter", function()
            -- Pre-check if mount data is available before showing tooltip
            local function isSourceDataReady()
                local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(id)
                return source and source ~= ""
            end
            
            -- If source data is ready, show tooltip immediately
            if isSourceDataReady() then
                GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
                if (spellID) then
                    GameTooltip:SetSpellByID(spellID)
                    
                    local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(id)
                    GameTooltip:AddLine(source)
                    GameTooltip:Show()
                    frame:SetHyperlinksEnabled(true)
                end
            else
                -- Force load mount data and delay tooltip
                C_MountJournal.GetMountInfoByID(id) -- Ensure data is loaded
                
                C_Timer.After(0.15, function()
                    -- Only show delayed tooltip if mouse is still over the frame
                    if frame:IsMouseOver() then
                        local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(id)
                        local sourceText = source and source ~= "" and source or "Unknown"
                        
                        -- If still no Blizzard source, use MCL fallback
                        if sourceText == "Unknown" then
                            if frame.section and frame.category then
                                if frame.section ~= "Unknown" and frame.category ~= "Unknown" then
                                    sourceText = frame.section .. " - " .. frame.category
                                elseif frame.section ~= "Unknown" then
                                    sourceText = frame.section
                                elseif frame.category ~= "Unknown" then
                                    sourceText = frame.category
                                end
                            end
                        end
                        
                        GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
                        if (spellID) then
                            GameTooltip:SetSpellByID(spellID)
                            GameTooltip:AddLine(sourceText)
                            GameTooltip:Show()
                            frame:SetHyperlinksEnabled(true)
                        end
                    end
                end)
            end
            
            -- Show MountCard on hover (only if enabled in settings)
            if MCLcore and MCLcore.MountCard and MCL_SETTINGS.enableMountCardHover then
                local mountData = {
                    mountID = mountID,
                    id = mountID,
                    name = mountName,
                    category = frame.category,
                    section = frame.section
                }
                MCLcore.MountCard.ShowOnHover(mountData, frame, 0.2)  -- Reduced from 0.8 to 0.2
            end
        end)
        frame:HookScript("OnLeave", function()
            GameTooltip:Hide()
            -- Note: MountCard is now persistent, so we don't hide it on hover end
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
                -- Pre-check if dragonriding mount source data is available
                local function isDragonridingSourceReady()
                    local mountID = C_MountJournal.GetMountFromItem(id)
                    if mountID then
                        local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)
                        return source and source ~= "", mountID
                    end
                    return false, nil
                end
                
                local isReady, mountID = isDragonridingSourceReady()
                
                if isReady then
                    -- Source data is ready, show tooltip immediately
                    GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
                    if (id) then
                        GameTooltip:SetItemByID(id)
                        local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)
                        GameTooltip:AddLine(source)
                        GameTooltip:Show()
                        frame:SetHyperlinksEnabled(true)
                    end
                else
                    -- Force load data and delay tooltip
                    if mountID then
                        C_MountJournal.GetMountInfoByID(mountID) -- Ensure data is loaded
                    end
                    
                    C_Timer.After(0.15, function()
                        -- Only show delayed tooltip if mouse is still over the frame
                        if frame:IsMouseOver() then
                            local retryMountID = C_MountJournal.GetMountFromItem(id)
                            local sourceText = "Unknown"
                            
                            if retryMountID then
                                local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(retryMountID)
                                if source and source ~= "" then
                                    sourceText = source
                                end
                            end
                            
                            -- Fallback to MCL's category/section information if still no source
                            if sourceText == "Unknown" then
                                if frame.section and frame.category then
                                    if frame.section ~= "Unknown" and frame.category ~= "Unknown" then
                                        sourceText = frame.section .. " - " .. frame.category
                                    elseif frame.section ~= "Unknown" then
                                        sourceText = frame.section
                                    elseif frame.category ~= "Unknown" then
                                        sourceText = frame.category
                                    end
                                end
                            end
                            
                            -- Final fallback to the passed source parameter
                            if sourceText == "Unknown" and frame.source then
                                sourceText = frame.source
                            end
                            
                            GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT")
                            if (id) then
                                GameTooltip:SetItemByID(id)
                                GameTooltip:AddLine(sourceText)
                                GameTooltip:Show()
                                frame:SetHyperlinksEnabled(true)
                            end
                        end
                    end)
                end
                
                -- Show MountCard on hover for dragonriding mounts (only if enabled in settings)
                if MCLcore and MCLcore.MountCard and MCL_SETTINGS.enableMountCardHover then
                    local mountData = {
                        mountID = id,
                        id = id,
                        name = item or "Unknown Mount",
                        category = frame.category,
                        section = frame.section
                    }
                    MCLcore.MountCard.ShowOnHover(mountData, frame, 0.2)  -- Reduced from 0.8 to 0.2
                end
            end)
            frame:HookScript("OnLeave", function()
                GameTooltip:Hide()
                -- Note: MountCard is now persistent, so we don't hide it on hover end
            end)

        else
            local mountID = C_MountJournal.GetMountFromItem(id)
            local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mountID)
        
            -- Special handling for fallback cases (negative IDs)
            if not mountID and type(id) == "number" and id < 0 then
                local originalItemId = -id
                local itemName, itemLink = GetItemInfo(originalItemId)
                
                frame:HookScript("OnEnter", function()
                    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                    if itemLink then
                        GameTooltip:SetHyperlink(itemLink)
                        GameTooltip:AddLine("|cFFFF0000[MCL] Mount data not fully loaded|r")
                        GameTooltip:AddLine("|cFFFFFF00Try reloading UI or restarting game|r")
                        GameTooltip:Show()
                        frame:SetHyperlinksEnabled(true)
                    else
                        GameTooltip:SetText(string.format("Item ID: %d", originalItemId))
                        GameTooltip:AddLine("|cFFFF0000[MCL] Mount data not available|r")
                        GameTooltip:Show()
                    end
                end)
                frame:HookScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
                return
            end
            
            frame:HookScript("OnEnter", function()
                -- Pre-check if item-based mount source data is available
                local function isItemMountSourceReady()
                    local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)
                    return source and source ~= ""
                end
                
                if isItemMountSourceReady() then
                    -- Source data is ready, show tooltip immediately
                    GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                    if (itemLink) then
                        frame:SetHyperlinksEnabled(true)
                        GameTooltip:SetHyperlink(itemLink)
                        local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)
                        GameTooltip:AddLine(source)
                        GameTooltip:Show()
                    end
                else
                    -- Force load data and delay tooltip
                    C_MountJournal.GetMountInfoByID(mountID) -- Ensure data is loaded
                    
                    C_Timer.After(0.15, function()
                        -- Only show delayed tooltip if mouse is still over the frame
                        if frame:IsMouseOver() then
                            local _, description, source, _, mountTypeID, _, _, _, _ = C_MountJournal.GetMountInfoExtraByID(mountID)
                            local sourceText = source and source ~= "" and source or "Unknown"
                            
                            -- Fallback to MCL's category/section information if still no source
                            if sourceText == "Unknown" then
                                if frame.section and frame.category then
                                    if frame.section ~= "Unknown" and frame.category ~= "Unknown" then
                                        sourceText = frame.section .. " - " .. frame.category
                                    elseif frame.section ~= "Unknown" then
                                        sourceText = frame.section
                                    elseif frame.category ~= "Unknown" then
                                        sourceText = frame.category
                                    end
                                end
                            end
                            
                            GameTooltip:SetOwner(frame, "ANCHOR_TOP")
                            if (itemLink) then
                                frame:SetHyperlinksEnabled(true)
                                GameTooltip:SetHyperlink(itemLink)
                                GameTooltip:AddLine(sourceText)
                                GameTooltip:Show()
                            end
                        end
                    end)
                end
                
                -- Show MountCard on hover for item-based mounts (only if enabled in settings)
                if MCLcore and MCLcore.MountCard and mountID and MCL_SETTINGS.enableMountCardHover then
                    local mountData = {
                        mountID = mountID,
                        id = mountID,
                        name = mountName,
                        category = frame.category,
                        section = frame.section
                    }
                    MCLcore.MountCard.ShowOnHover(mountData, frame, 0.2)  -- Reduced from 0.8 to 0.2
                end
            end)
            frame:HookScript("OnLeave", function()
                GameTooltip:Hide()
                -- Note: MountCard is now persistent, so we don't hide it on hover end
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

function MCL_functions:CleanupInvalidPinnedMounts()
    if not MCL_PINNED then
        MCL_PINNED = {}
        return
    end
    
    local validPinnedMounts = {}
    local removedCount = 0
    
    for k, v in pairs(MCL_PINNED) do
        if v and v.mountID then
            local mountId = v.mountID
            local mount_Id = nil
            
            -- Extract numeric ID from string format (e.g., "m517" -> 517)
            if string.sub(tostring(mountId), 1, 1) == "m" then
                mount_Id = tonumber(string.sub(tostring(mountId), 2, -1))
            else
                mount_Id = tonumber(mountId)
            end
            
            -- Check if this mount ID is valid by trying to get mount info
            if mount_Id then
                local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mount_Id)
                
                if mountName and mountName ~= "" then
                    -- Mount is valid, keep it
                    table.insert(validPinnedMounts, v)
                else
                    -- Mount is invalid, remove it
                    removedCount = removedCount + 1
                end
            else
                -- Invalid format, remove it
                removedCount = removedCount + 1
            end
        else
            -- Invalid entry structure, remove it
            removedCount = removedCount + 1
        end
    end
    
    -- Replace MCL_PINNED with cleaned version
    MCL_PINNED = validPinnedMounts
end

function MCL_functions:CreateMountsForCategory(set, relativeFrame, frame_size, tab, skip_total, pin)
    -- Clean up invalid pinned mounts if this is for the pinned section
    if pin and set == MCL_PINNED then
        MCLcore.Function:CleanupInvalidPinnedMounts()
        -- Update the set to use the cleaned pinned mounts
        set = MCL_PINNED
    end
    
    local category = relativeFrame
    local previous_frame = relativeFrame
    local count = 0
    local first_frame
    local overflow = 0
    local mountFrames = {}
    local val
    local mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, sourceText, isSteadyFlight
    local invalidMounts = {}  -- Track invalid mounts

    for kk,vv in pairs(set) do
        local mount_Id
        local shouldProcessMount = true  -- Control flag
        
        if pin then
            val = vv.mountID
        else
            val = vv
        end

        -- Use a simpler mount ID extraction
        if pin then
            val = vv.mountID
            -- For pinned mounts, extract the numeric ID
            if string.sub(tostring(val), 1, 1) == "m" then
                mount_Id = tonumber(string.sub(tostring(val), 2, -1))
            else
                mount_Id = tonumber(val)
            end
        else
            val = vv
            mount_Id = MCLcore.Function:GetMountID(val)
        end
        
        if not mount_Id then
            -- Mount is invalid, skip it and track for debugging
            table.insert(invalidMounts, {id = val, context = "CreateMountsForCategory"})
            shouldProcessMount = false
        end

        if shouldProcessMount then
            local success = false
            
            if string.sub(tostring(val), 1, 1) == "m" then
                -- mount_Id was already extracted above, don't override it
                mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mount_Id)
                if mountName then
                    -- Get the source text from the extra info
                    local _, description, source = C_MountJournal.GetMountInfoExtraByID(mount_Id)
                    sourceText = source or "Unknown"
                    success = true
                else
                    table.insert(invalidMounts, {id = val, context = "Mount info retrieval failed"})
                    shouldProcessMount = false
                end
            else
                mount_Id = C_MountJournal.GetMountFromItem(val)
                if mount_Id then
                    mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, isSteadyFlight = C_MountJournal.GetMountInfoByID(mount_Id)
                    if mountName then
                        -- Get the source text from the extra info
                        local _, description, source = C_MountJournal.GetMountInfoExtraByID(mount_Id)
                        sourceText = source or "Unknown"
                        success = true
                    else
                        table.insert(invalidMounts, {id = val, context = "Item-based mount info retrieval failed"})
                        shouldProcessMount = false
                    end
                else
                    table.insert(invalidMounts, {id = val, context = "No mount from item"})
                    shouldProcessMount = false
                end
            end
        end

        if shouldProcessMount then
            local faction, faction_specific = IsMountFactionSpecific(val)
            if faction then
                if faction == 0 then
                    faction = "Horde"
                elseif faction == 1 then
                    faction = "Alliance"
                end
            end
            
            -- For pinned mounts, don't apply hiding filters since user specifically wants to see them
            local shouldHideCollected = false
            local factionAllowed = true
            
            if not pin then
                -- Only apply filters for non-pinned mounts
                shouldHideCollected = MCL_SETTINGS.hideCollectedMounts and IsMountCollected(mount_Id)
                factionAllowed = (faction_specific == false) or (faction_specific == true and faction == UnitFactionGroup("player"))
            end
            
            if not shouldHideCollected and factionAllowed then
                local mountsPerRow = MCL_SETTINGS.mountsPerRow or 12
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
                    frame.category = vv.category
                    frame.section = vv.section
                elseif category and category.category and category.section then
                    frame.category = category.category
                    frame.section = category.section
                else
                    frame.category = "Unknown"
                    frame.section = "Unknown"
                end

                frame.dragonRidable = isSteadyFlight

                frame:SetBackdropBorderColor(1, 0, 0, 0.03)
                frame:SetBackdropColor(0, 0, 0, MCL_SETTINGS.opacity)

                frame.tex = frame:CreateTexture()
                frame.tex:SetSize(frame_size, frame_size)
                frame.tex:SetPoint("LEFT", frame, "LEFT", 8, 0)

                if string.sub(tostring(val), 1, 1) == "m" then
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

                    -- Mount Name - Primary text (aligned to frame edge, not icon)
                    frame.mountName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                    frame.mountName:SetPoint("TOPLEFT", frame, "TOPLEFT", 46, -8)
                    frame.mountName:SetText(mountName)
                    
                    -- Section line (below pin icon on the right)
                    frame.sectionLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    frame.sectionLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -8)
                    frame.sectionLine:SetText(vv.section)

                    -- Category line (under section on the right)
                    frame.categoryLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    frame.categoryLine:SetPoint("TOPRIGHT", frame.sectionLine, "BOTTOMRIGHT", 0, -2)
                    frame.categoryLine:SetText(vv.category)
                    
                    -- Acquisition line (under mount name, full width)
                    frame.acquisitionLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    frame.acquisitionLine:SetPoint("TOPLEFT", frame.mountName, "BOTTOMLEFT", 0, -4)
                    frame.acquisitionLine:SetText(sourceText or "Unknown")
                    frame.acquisitionLine:SetJustifyH("LEFT")
                    frame.acquisitionLine:SetWordWrap(true)
                    frame.acquisitionLine:SetWidth(600)
                    
                    -- Use WoW standard tooltip border and background
                    frame:SetBackdrop({
                        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
                        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                        edgeSize = 16,
                        insets = { left = 4, right = 4, top = 4, bottom = 4 }
                    })
                    
                    -- Bottom border line for separation
                    frame.border = frame:CreateLine(nil, "BACKGROUND", nil, 0)
                    frame.border:SetThickness(1)
                    frame.border:SetColorTexture(0.5, 0.5, 0.5, 0.5)
                    frame.border:SetStartPoint("BOTTOMLEFT", 4, 4)
                    frame.border:SetEndPoint("BOTTOMRIGHT", -4, 4)
                    
                    frame:SetWidth(815)
                    frame:SetHeight(75)
                    
                    local positionRelativeTo = previous_frame
                    local isFirstFrame = (previous_frame == category)
                    
                    C_Timer.After(0, function()
                        local mountNameHeight = frame.mountName:GetStringHeight()
                        local acquisitionHeight = frame.acquisitionLine:GetStringHeight()
                        
                        local contentHeight = 8 + mountNameHeight + 4 + acquisitionHeight + 20
                        local finalHeight = math.max(contentHeight, 75)
                        frame:SetHeight(finalHeight)
                        
                        if isFirstFrame then
                            frame:SetPoint("BOTTOMLEFT", positionRelativeTo, "BOTTOMLEFT", 10, -finalHeight + 20)
                        else
                            frame:SetPoint("BOTTOMLEFT", positionRelativeTo, "BOTTOMLEFT", 0, -finalHeight - 10)
                        end
                    end)
                    
                    -- Apply collection status styling
                    if IsMountCollected(mount_Id) then
                        frame:SetBackdropBorderColor(0, 0.8, 0, 0.8)
                        frame:SetBackdropColor(0, 0.2, 0, 0.15)
                        frame.tex:SetVertexColor(1, 1, 1, 1)
                        frame.mountName:SetTextColor(0, 1, 0)
                    else
                        frame:SetBackdropBorderColor(0.8, 0.3, 0.3, 0.8)
                        frame:SetBackdropColor(0.2, 0.05, 0.05, 0.15)
                        frame.tex:SetVertexColor(0.6, 0.6, 0.6, 0.8)
                        frame.mountName:SetTextColor(0.9, 0.9, 0.9)
                    end

                    frame.pin:SetSize(20, 20)
                    frame.pin:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
                    
                    -- Add hover effects
                    frame:SetScript("OnEnter", function(self)
                        self:SetBackdropColor(1, 1, 1, 0.1)
                        if self.mountName then
                            self.mountName:SetTextColor(1, 1, 1)
                        end
                    end)
                    
                    frame:SetScript("OnLeave", function(self)
                        if IsMountCollected(mount_Id) then
                            self:SetBackdropColor(0, 0.2, 0, 0.15)
                            if self.mountName then
                                self.mountName:SetTextColor(0, 1, 0)
                            end
                        else
                            self:SetBackdropColor(0.2, 0.05, 0.05, 0.15)
                            if self.mountName then
                                self.mountName:SetTextColor(0.9, 0.9, 0.9)
                            end
                        end
                    end)

                    previous_frame = frame
                elseif count == (MCL_SETTINGS.mountsPerRow or 12) then
                    frame:SetPoint("BOTTOMLEFT", first_frame, "BOTTOMLEFT", 0, -overflow);
                    count = 0           
                elseif relativeFrame == category then
                    frame:SetPoint("BOTTOMLEFT", category, "BOTTOMLEFT", 10, -35);
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
        end  -- End of shouldProcessMount condition
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
        
        -- Clean up invalid pinned mounts before creating
        MCLcore.Function:CleanupInvalidPinnedMounts()
        
        local overflow, mountFrame = MCLcore.Function:CreateMountsForCategory(MCL_PINNED, _G["PinnedFrame"], 30, _G["PinnedTab"], true, true)
        MCLcore.mountFrames[1] = mountFrame
    else
        local relativeFrame = MCLcore.mountFrames[1][total_pinned]

        local mountName, spellID, icon, _, _, sourceType, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        
        -- Get the actual source from the game API
        local _, _, sourceText = C_MountJournal.GetMountInfoExtraByID(mount_Id)
        sourceText = sourceText or "Unknown"

        -- Create frame parented to the Pinned section, not to the previous frame
        local frame = CreateFrame("Button", nil, _G["PinnedFrame"], "BackdropTemplate");
        frame:SetWidth(frame_size);
        frame:SetHeight(frame_size);
        frame:SetBackdrop({
            -- edgeFile = [[Interface\Buttons\WHITE8x8]],
            -- edgeSize = frame_size + 2,
            bgFile = [[Interface\Buttons\WHITE8x8]],    
        })

        frame.pin = frame:CreateTexture(nil, "OVERLAY")
        frame.pin:SetWidth(16)
        frame.pin:SetHeight(16)
        frame.pin:SetTexture("Interface\\AddOns\\MCL\\icons\\pin.blp")
        frame.pin:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
        frame.pin:SetAlpha(1)

        -- Icon with horizontal padding
        frame.tex = frame:CreateTexture()
        frame.tex:SetSize(frame_size, frame_size)
        frame.tex:SetPoint("LEFT", frame, "LEFT", 8, 0)  -- 8px horizontal padding from left edge
        local mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID, _ = C_MountJournal.GetMountInfoByID(mount_Id)
        frame.tex:SetTexture(icon)

        frame.tex:SetVertexColor(0.75, 0.75, 0.75, 0.3);        

        frame.category = category
        frame.section = section

        -- Mount Name - Primary text (aligned to frame edge, not icon)
        frame.mountName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        frame.mountName:SetPoint("TOPLEFT", frame, "TOPLEFT", 46, -8)  -- Aligned to frame edge with padding
        frame.mountName:SetText(mountName)
        
        -- Section line (below pin icon on the right)
        frame.sectionLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.sectionLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -30, -8)  -- Below pin icon area
        frame.sectionLine:SetText(section)

        -- Category line (under section on the right)
        frame.categoryLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.categoryLine:SetPoint("TOPRIGHT", frame.sectionLine, "BOTTOMRIGHT", 0, -2)  -- Under section
        frame.categoryLine:SetText(category)
        
        -- Acquisition line (under mount name, full width)
        frame.acquisitionLine = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        frame.acquisitionLine:SetPoint("TOPLEFT", frame.mountName, "BOTTOMLEFT", 0, -4)
        frame.acquisitionLine:SetText(sourceText or "Unknown")  -- Removed "Acquisition:" label
        frame.acquisitionLine:SetJustifyH("LEFT")
        frame.acquisitionLine:SetWordWrap(true)  -- Allow wrapping to show full text
        frame.acquisitionLine:SetWidth(600)  -- Adjust width to not overlap with category section

        -- Use WoW standard tooltip border and background
        frame:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Bottom border line for separation
        frame.border = frame:CreateLine(nil, "BACKGROUND", nil, 0)
        frame.border:SetThickness(1)
        frame.border:SetColorTexture(0.5, 0.5, 0.5, 0.5)
        frame.border:SetStartPoint("BOTTOMLEFT", 4, 4)
        frame.border:SetEndPoint("BOTTOMRIGHT", -4, 4)
        
        frame:SetWidth(800)  -- Increased width to match pinned instruction bar
        
        -- Set a reasonable minimum height first so text can be laid out
        frame:SetHeight(75)  -- Start with minimum height
        
        -- Force text layout by getting dimensions after initial setup
        C_Timer.After(0, function()
            -- Calculate height based on actual rendered content
            local mountNameHeight = frame.mountName:GetStringHeight()
            local acquisitionHeight = frame.acquisitionLine:GetStringHeight()
            
            local contentHeight = 8 + -- Top padding to mount name
                                mountNameHeight + 4 + -- Mount name + spacing
                                acquisitionHeight + -- Acquisition text (can be multiple lines)
                                20  -- Bottom padding - increased for better spacing
            
            local finalHeight = math.max(contentHeight, 75)  -- Minimum height of 75 for better padding
            -- Set the final calculated height
            frame:SetHeight(finalHeight)
            
            -- Position the frame after height is finalized
            frame:SetPoint("BOTTOMLEFT", relativeFrame, "BOTTOMLEFT", 0, -finalHeight - 10)  -- No x-offset since this is not the first frame
        end)
        
        -- Apply collection status styling - more subtle approach
        if IsMountCollected(mount_Id) then
            -- Collected mount styling
            frame:SetBackdropBorderColor(0, 0.8, 0, 0.8)  -- Green border
            frame:SetBackdropColor(0, 0.2, 0, 0.15)       -- Subtle green background
            frame.tex:SetVertexColor(1, 1, 1, 1)          -- Full color icon
            frame.mountName:SetTextColor(0, 1, 0)         -- Green mount name
        else
            -- Uncollected mount styling
            frame:SetBackdropBorderColor(0.8, 0.3, 0.3, 0.8)  -- Red border
            frame:SetBackdropColor(0.2, 0.05, 0.05, 0.15)     -- Subtle red background
            frame.tex:SetVertexColor(0.6, 0.6, 0.6, 0.8)      -- Slightly dimmed icon
            frame.mountName:SetTextColor(0.9, 0.9, 0.9)       -- Light gray mount name
        end

        -- Enhance pin icon
        frame.pin:SetSize(20, 20)  -- Slightly larger
        frame.pin:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
        frame.pin:SetAlpha(0)

        -- Add hover effects
        frame:SetScript("OnEnter", function(self)
            self:SetBackdropColor(1, 1, 1, 0.1)  -- Subtle white highlight on hover
            if self.mountName then
                self.mountName:SetTextColor(1, 1, 1)  -- White text on hover
            end
        end)
        
        frame:SetScript("OnLeave", function(self)
            -- Restore original colors based on collection status
            if IsMountCollected(mount_Id) then
                self:SetBackdropColor(0, 0.2, 0, 0.15)
                if self.mountName then
                    self.mountName:SetTextColor(0, 1, 0)
                end
            else
                self:SetBackdropColor(0.2, 0.05, 0.05, 0.15)
                if self.mountName then
                    self.mountName:SetTextColor(0.9, 0.9, 0.9)
                end
            end
        end)

        frame.mountID = mount_Id

        MCLcore.Function:LinkMountItem("m"..tostring(mount_Id), frame, true)

        table.insert(MCLcore.mountFrames[1], frame)
  
    end
end

-- Function to force load mount data and handle delayed mount journal loading
function MCL_functions:ForceLoadMountData(itemId)
    -- First try to get the item info to ensure it's cached
    local itemName, itemLink = GetItemInfo(itemId)
    
    -- If item info isn't available, request it and return false to retry later
    if not itemName then
        -- This will cache the item data for future calls
        C_Item.RequestLoadItemDataByID(itemId)
        -- For persistent debugging, create a delayed retry
        C_Timer.After(0.1, function()
            local retryItemName = GetItemInfo(itemId)
            if retryItemName then
                -- Force a mount journal update if item becomes available
                C_MountJournal.GetMountFromItem(itemId)
            end
        end)
        return false, "Item data not cached yet"
    end
    
    -- Try to get mount from item
    local mountId = C_MountJournal.GetMountFromItem(itemId)
    
    if not mountId then
        -- For some old items, they might not be directly associated with mounts
        -- but still exist in the game. Try a different approach.
        return false, "No mount associated with item"
    end
    
    -- Try to get mount info
    local mountName, spellID, icon = C_MountJournal.GetMountInfoByID(mountId)
    
    if not mountName then
        -- Try to force refresh the mount journal
        C_MountJournal.ClearSearchFilters()
        C_Timer.After(0.1, function()
            local retryMountName = C_MountJournal.GetMountInfoByID(mountId)
        end)
        return false, "Mount data not available yet"
    end
    
    return true, {
        mountId = mountId,
        mountName = mountName,
        spellID = spellID,
        icon = icon,
        itemId = itemId,
        itemName = itemName
    }
end

-- Enhanced GetMountID function with force loading
function MCL_functions:GetMountIDWithForceLoad(id)
    local mount_Id
    local inputType = type(id)
    local isStringWithM = (inputType == "string" and string.sub(tostring(id), 1, 1) == "m")
    local isNumber = (inputType == "number")
    
    if isStringWithM then
        mount_Id = tonumber(string.sub(tostring(id), 2, -1))
    elseif isNumber and id > 100000 then
        -- Likely an item ID (large number)
        local success, result = MCLcore.Function:ForceLoadMountData(id)
        if success then
            mount_Id = result.mountId
        else
            -- Fallback to original method
            mount_Id = C_MountJournal.GetMountFromItem(id)
        end
    elseif isNumber and id < 10000 then
        -- Could be either a mount ID or an old item ID
        -- First try as direct mount ID
        local mountName = C_MountJournal.GetMountInfoByID(id)
        if mountName then
            mount_Id = id
        else
            -- Try as item ID
            local success, result = MCLcore.Function:ForceLoadMountData(id)
            if success then
                mount_Id = result.mountId
            else
                -- Last resort - try original item lookup
                mount_Id = C_MountJournal.GetMountFromItem(id)
            end
        end
    else
        -- Default to item lookup with force loading
        local success, result = MCLcore.Function:ForceLoadMountData(id)
        if success then
            mount_Id = result.mountId
        else
            mount_Id = C_MountJournal.GetMountFromItem(id)
        end
    end
    
    return mount_Id
end

-- Main GetMountID function that uses force-load logic for problematic item IDs
function MCL_functions:GetMountID(id)
    local problematicItemIds = {8563, 8595}  -- Add more IDs here as needed
    
    -- Check if this is one of the problematic item IDs that need force loading
    if type(id) == "number" then
        for _, problematicId in ipairs(problematicItemIds) do
            if id == problematicId then
                local mount_Id = MCLcore.Function:GetMountIDWithForceLoad(id)
                if mount_Id then
                    return mount_Id
                else
                    -- If force loading fails, still return the item ID
                    -- This allows the mount to be processed even if the API can't find it
                    -- Use a negative ID to indicate this is a fallback case
                    return -id
                end
            end
        end
    end
    
    -- For non-problematic IDs, use the standard logic
    local mount_Id
    local inputType = type(id)
    local isStringWithM = (inputType == "string" and string.sub(tostring(id), 1, 1) == "m")
    
    if isStringWithM then
        mount_Id = tonumber(string.sub(tostring(id), 2, -1))
    else
        mount_Id = C_MountJournal.GetMountFromItem(id)
    end
    
    return mount_Id
end

function IsMountCollected(id)
    -- Handle negative IDs (fallback cases for problematic items)
    local numericId = tonumber(id)
    if numericId and numericId < 0 then
        -- For fallback cases, we can't determine collection status from the API
        -- so we'll return false (not collected) to show them in the UI
        return false
    end
    
    -- Ensure we have a valid mount ID
    if not id or id == 0 then
        return false
    end
    
    -- Use pcall to safely get mount info
    local success, mountName, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected, mountID = pcall(C_MountJournal.GetMountInfoByID, id)
    
    if not success or not mountName then
        -- Mount data not available yet, return false but don't cache this result
        return false
    end
    
    return isCollected or false
end

function UpdateBackground(frame)
    local pinned, pin = MCLcore.Function:CheckIfPinned("m"..tostring(frame.mountID))
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
            -- Note: No longer automatically removing collected mounts from pinned list
            -- as users should be able to pin collected mounts for favorites/tracking
            UpdatePin(v.frame)
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
            mountCardHoverToggle = {
                order = 14.8,
                name = MCLcore.L["Enable Mount Card on Hover"],
                desc = MCLcore.L["If enabled, the mount card will automatically appear when hovering over mounts."],
                type = "toggle",
                width = "full",
                set = function(info, val)
                    MCL_SETTINGS.enableMountCardHover = val
                end,
                get = function(info)
                    return MCL_SETTINGS.enableMountCardHover
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
                    local mount_Id = MCLcore.Function:GetMountID(mountId)
                    if mount_Id then
                        -- Apply the same faction filtering as the display logic
                        local faction, faction_specific = MCLcore.Function.IsMountFactionSpecific(mountId)
                        local playerFaction = UnitFactionGroup("player")
                        local allowed = false
                        if faction_specific == false then
                            allowed = true
                        elseif faction_specific == true then
                            if faction == 0 then faction = "Horde" elseif faction == 1 then faction = "Alliance" end
                            allowed = (faction == playerFaction)
                        end
                        
                        -- Only count mounts that pass faction restrictions
                        if allowed then
                            sectionTotal = sectionTotal + 1
                            if IsMountCollected(mount_Id) then
                                sectionCollected = sectionCollected + 1
                            end
                        end
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

-- Function to update pin icons for a specific mount across all frames
function MCL_functions:UpdateAllPinIcons(mountID)
    local isPinned = MCLcore.Function:CheckIfPinned("m"..mountID)
    
    -- Update pin icons in all mount frames
    for k, v in pairs(MCLcore.mounts) do
        if v.frame and v.frame.pin and tostring(v.id) == tostring(mountID) then
            if isPinned then
                v.frame.pin:SetAlpha(1)
            else
                v.frame.pin:SetAlpha(0)
            end
        end
    end
    
    -- Also update pin icons in pinned section frames
    if MCLcore.mountFrames[1] then
        for k, v in pairs(MCLcore.mountFrames[1]) do
            if v.pin and tostring(v.mountID) == tostring(mountID) then
                if isPinned then
                    v.pin:SetAlpha(1)
                else
                    v.pin:SetAlpha(0)
                end
            end
        end
    end
end

function MCL_functions:UpdatePinnedMountStyling(mountID)
    -- Update styling for a specific pinned mount when its collection status changes
    if not MCLcore.mountFrames[1] then
        return
    end
    
    for k, frame in pairs(MCLcore.mountFrames[1]) do
        if frame.mountID and tostring(frame.mountID) == tostring(mountID) then
            if IsMountCollected(mountID) then
                -- Collected mount styling
                frame:SetBackdropBorderColor(0, 0.8, 0, 0.8)  -- Green border
                frame:SetBackdropColor(0, 0.2, 0, 0.15)       -- Subtle green background
                frame.tex:SetVertexColor(1, 1, 1, 1)          -- Full color icon
                if frame.mountName then
                    frame.mountName:SetTextColor(0, 1, 0)     -- Green mount name
                end
            else
                -- Uncollected mount styling
                frame:SetBackdropBorderColor(0.8, 0.3, 0.3, 0.8)  -- Red border
                frame:SetBackdropColor(0.2, 0.05, 0.05, 0.15)     -- Subtle red background
                frame.tex:SetVertexColor(0.6, 0.6, 0.6, 0.8)      -- Slightly dimmed icon
                if frame.mountName then
                    frame.mountName:SetTextColor(0.9, 0.9, 0.9)   -- Light gray mount name
                end
            end
            break
        end
    end
end

-- Function to check if we need to refresh layout after pinned mount changes
function MCL_functions:CheckAndRefreshAfterPinnedChanges(newSectionName)
    -- If we're switching away from the Pinned section and pinned mounts were modified
    if MCLcore.pinnedMountsChanged and newSectionName ~= "Pinned" then
        MCLcore.pinnedMountsChanged = false  -- Reset the flag
        
        -- Use a small delay to ensure the new section is fully loaded before refreshing
        C_Timer.After(0.1, function()
            if MCL_frames and MCL_frames.RefreshLayout then
                MCL_frames:RefreshLayout()
            elseif MCLcore.Frames and MCLcore.Frames.RefreshLayout then
                MCLcore.Frames:RefreshLayout()
            end
        end)
    end
end

-- Add this debugging function to functions.lua
function MCL_functions:DebugMountLoading(id, context)
    local mount_Id = nil
    local mountName = nil
    local errorInfo = {}
    
    -- Store original ID for reference
    errorInfo.originalId = id
    errorInfo.context = context or "Unknown"
    
    if string.sub(tostring(id), 1, 1) == "m" then
        mount_Id = tonumber(string.sub(tostring(id), 2, -1))
        errorInfo.type = "Mount ID"
        errorInfo.processedId = mount_Id
        
        if mount_Id then
            local success, mountName, spellID, icon = pcall(C_MountJournal.GetMountInfoByID, mount_Id)
            if success and mountName then
                errorInfo.status = "Valid"
            else
                errorInfo.status = "Invalid Mount ID"
                errorInfo.error = "Mount ID not found in journal"
            end
        else
            errorInfo.status = "Invalid Format"
            errorInfo.error = "Could not extract mount ID from string"
        end
    else
        errorInfo.type = "Item ID"
        errorInfo.processedId = id
        
        -- First check if item exists
        local itemName = GetItemInfo(id)
        if not itemName then
            -- Try to force load the item
            C_Item.RequestLoadItemDataByID(id)
            C_Timer.After(0.5, function()
                local retryItemName = GetItemInfo(id)
                if not retryItemName then
                    print(string.format("|cffFF0000[MCL Debug]|r Item ID %s does not exist in game", tostring(id)))
                end
            end)
            errorInfo.status = "Item Not Found"
            errorInfo.error = "Item does not exist or not cached"
        else
            -- Item exists, check if it has an associated mount
            mount_Id = C_MountJournal.GetMountFromItem(id)
            if mount_Id then
                local success, mountName, spellID, icon = pcall(C_MountJournal.GetMountInfoByID, mount_Id)
                if success and mountName then
                    errorInfo.status = "Valid"
                    errorInfo.mountId = mount_Id
                else
                    errorInfo.status = "Invalid Mount Association"
                    errorInfo.error = "Item exists but associated mount ID is invalid"
                    errorInfo.mountId = mount_Id
                end
            else
                errorInfo.status = "No Mount Association"
                errorInfo.error = "Item exists but has no associated mount"
            end
        end
    end
    
    -- Log the result
    if errorInfo.status ~= "Valid" then
        print(string.format("|cffFF0000[MCL Debug]|r %s: %s (Original: %s, Type: %s, Context: %s)", 
            errorInfo.status, 
            errorInfo.error or "Unknown error", 
            tostring(errorInfo.originalId), 
            errorInfo.type, 
            errorInfo.context))
        return false, errorInfo
    end
    
    return true, {originalId = id, mountId = mount_Id, mountName = mountName}
end

-- Enhanced GetMountID function with better error handling
function MCL_functions:GetMountIDSafe(id, context)
    local success, isValid, data = pcall(function()
        return MCLcore.Function:DebugMountLoading(id, context)
    end)
    
    if not success then
        print(string.format("|cffFF0000[MCL Debug]|r Critical error processing mount %s: %s", tostring(id), tostring(isValid)))
        return nil
    end
    
    if isValid and data and data.mountId then
        return data.mountId
    else
        -- Return nil for invalid mounts instead of breaking
        return nil
    end
end
