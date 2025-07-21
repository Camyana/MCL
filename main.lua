-- * ------------------------------------------------------
-- *  Namespaces
-- * ------------------------------------------------------
local MCL, MCLcore = ...;

-- * ------------------------------------------------------
-- * Variables
-- * ------------------------------------------------------
MCLcore.Main = {};
local MCL_Load = MCLcore.Main;
local init_load = true
local load_check = 0
local region = GetCVar('portal')


-- * -------------------------------------------------
-- * Initialise Database
-- * Cycles through data.lua, checks if in game mount journal has an entry for mount. Restarts function if mount does is not loaded yet.
-- * Function is designed to check if the ingame mount journal has loaded correctly before loading our own database.
-- * -----------------------------------------------

function IsRegionalFiltered(id)
    if MCLcore.regionalFilter[region] ~= nil then
        for k, v in pairs(MCLcore.regionalFilter[region]) do
            if v == id then
                return true
            end
        end
    end
    return false
end

function CountMounts()
    MCLcore.mountList = MCLcore.mountList or {}
    local count = 0
    for b, n in pairs(MCLcore.mountList) do
        if type(n) == "table" then
            for h, j in pairs(n) do
                if type(j) == "table" then
                    for k, v in pairs(j) do
                        -- Ensure v.mounts is a table before attempting to iterate over it
                        if type(v.mounts) == "table" then
                            for kk, vv in pairs(v.mounts) do
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
    end
    return count
end

-- Global for Addon Compartment
MCL_OnAddonCompartmentClick = function()
    MCL_Load:Toggle()
end

-- Save total mount count
local totalMountCount = CountMounts()

local function InitMounts()
    load_check = 0
    totalMountCount = 0
    for b,n in pairs(MCLcore.mountList) do
        for h,j in pairs(n) do
            if (type(j) == "table") then
                for k,v in pairs(j) do
                    for kk,vv in pairs(v.mounts) do
                        if not IsRegionalFiltered(vv) then
                            if not string.match(vv, "^m") then
                                totalMountCount = totalMountCount + 1
                                C_Item.RequestLoadItemDataByID(vv)
                                local mountName = C_MountJournal.GetMountFromItem(vv)
                                if mountName ~= nil then
                                    load_check = load_check + 1
                                end                            
                            end
                        end                                     
                    end
                end
            end
        end
    end
end


-- * -----------------------------------------------------
-- * Toggle the main window
-- * -----------------------------------------------------


MCLcore.dataLoaded = false

function MCL_Load:PreLoad()      
    if load_check >= totalMountCount then
        MCLcore.dataLoaded = true
        return true
    else   
        InitMounts()         
        return false
    end
end

-- Set a maximum number of initialization retries
local MAX_INIT_RETRIES = 3

-- Initialization function
function MCL_Load:Init(force)
    local function repeatCheck()
        local retries = 0
        if MCL_Load:PreLoad() then
            -- Initialization steps
            if MCLcore.MCL_MF == nil then
                -- Ensure Frames module is available
                if not MCLcore.Frames then
                    return false
                end
                MCLcore.MCL_MF = MCLcore.Frames:CreateMainFrame()
                MCLcore.MCL_MF:SetShown(false)
                MCLcore.Function:initSections()
            end
            MCLcore.Function:UpdateCollection()
            init_load = false -- Ensure that the initialization does not repeat unnecessarily.
        else
            retries = retries + 1
            if retries < MAX_INIT_RETRIES then
                -- Retry the initialization process after a delay
                C_Timer.After(1, repeatCheck)
            end
        end
    end

    -- Force reinitialization if specifically requested
    if force then
        load_check = 0
        MCLcore.dataLoaded = false
    end

    -- Check if we need to attempt initialization
    if not MCLcore.dataLoaded then
        init_load = true
        repeatCheck()
    end
end

-- Toggle function
function MCL_Load:Toggle()
    -- Check preload status and if false, prevent execution.
    if MCLcore.dataLoaded == false then
        MCL_Load:Init()
        return
    end 
    if MCLcore.MCL_MF == nil then
        return -- Immune to function calls before the initialization process is complete, as the frame doesn't exist yet.
    else
        MCLcore.MCL_MF:SetShown(not MCLcore.MCL_MF:IsShown()) -- The addon's frame exists and can be toggled.
    end
end

local f = CreateFrame("Frame")
local login = true



-- * -------------------------------------------------
-- * Loads addon once Blizzard_Collections has loaded in.
-- * -------------------------------------------------


local function onevent(self, event, arg1, ...)
    if(login and ((event == "ADDON_LOADED" and name == arg1) or (event == "PLAYER_LOGIN"))) then
        login = nil
        f:UnregisterEvent("ADDON_LOADED")
        f:UnregisterEvent("PLAYER_LOGIN")
	    if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
	        C_AddOns.LoadAddOn("Blizzard_Collections")
	    end
        
        -- Ensure Function module is available before calling AddonSettings
        if MCLcore.Function and MCLcore.Function.AddonSettings then
            MCLcore.Function:AddonSettings()
        end
        
        -- Initiate the addon when the required addon is loaded
        MCL_Load:Init()
        
        -- Initialize search functionality
        if MCLcore.InitializeSearch then
            MCLcore.InitializeSearch()
        end
    end
end


-- function addon:MCL_MM() self.db.profile.minimap.hide = not self.db.profile.minimap.hide if self.db.profile.minimap.hide then icon:Hide("MCL-icon") else icon:Show("MCL-icon") end end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", onevent)