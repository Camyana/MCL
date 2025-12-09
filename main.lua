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

-- New mount readiness tracking (Option A implementation)
local mountInit = {
    attempts = 0,
    maxAttempts = 40,          -- up to ~40 seconds worst case
    stableChecks = 0,
    requiredStableChecks = 2,   -- need two identical consecutive snapshots
    lastCount = 0,
    lastIDsHash = nil,
    initialized = false,
}

local function HashIDs(ids)
    if not ids then return 0 end
    table.sort(ids) -- safe; GetMountIDs returns a copy
    local acc = 0
    for i=1,#ids do
        acc = (acc * 33 + ids[i]) % 2147483647
    end
    return acc
end

local function IsMountAPIPartiallyReady()
    local ids = C_MountJournal.GetMountIDs()
    if not ids or #ids == 0 then return false end
    -- Sample one mount to see if we get full info (name + spellID)
    local testId = ids[1]
    local name, spellID = C_MountJournal.GetMountInfoByID(testId)
    return (name ~= nil and spellID ~= nil)
end

local function PollMountJournalReadiness(callback)
    if mountInit.initialized then return end
    mountInit.attempts = mountInit.attempts + 1

    local ready = IsMountAPIPartiallyReady()
    local ids = C_MountJournal.GetMountIDs() or {}
    local count = #ids
    local hash = HashIDs({unpack(ids)})

    if ready then
        if count == mountInit.lastCount and hash == mountInit.lastIDsHash then
            mountInit.stableChecks = mountInit.stableChecks + 1
        else
            mountInit.stableChecks = 0
        end
        mountInit.lastCount = count
        mountInit.lastIDsHash = hash

        if mountInit.stableChecks >= mountInit.requiredStableChecks then
            mountInit.initialized = true
            if callback then callback(true) end
            return
        end
    end

    if mountInit.attempts >= mountInit.maxAttempts then
        -- Give up waiting for perfect stability; proceed to avoid addon appearing broken.
        mountInit.initialized = true
        if callback then callback(false) end
        return
    end

    C_Timer.After(1, function() PollMountJournalReadiness(callback) end)
end

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

-- Debugging variables
local debugMode = true -- Set to false to disable debugging
local invalidMounts = {}
local validMounts = {}

local function InitMounts()
    load_check = 0
    totalMountCount = 0
    
    -- Reset debug tracking
    if debugMode then
        invalidMounts = {}
        validMounts = {}
    end
    
    for b,n in pairs(MCLcore.mountList) do
        for h,j in pairs(n) do
            if (type(j) == "table") then
                for k,v in pairs(j) do
                    for kk,vv in pairs(v.mounts) do
                        if not IsRegionalFiltered(vv) then
                            if not string.match(vv, "^m") then
                                totalMountCount = totalMountCount + 1
                                C_Item.RequestLoadItemDataByID(vv)
                                local mountID = C_MountJournal.GetMountFromItem(vv)
                                
                                if mountID ~= nil then
                                    load_check = load_check + 1
                                    if debugMode then
                                        table.insert(validMounts, {itemID = vv, mountID = mountID, expansion = n.name, category = v.name})
                                    end
                                else
                                    -- Mount doesn't exist in game, but we'll count it as "loaded" to prevent infinite waiting
                                    load_check = load_check + 1
                                    if debugMode then
                                        local itemName = GetItemInfo(vv) or "Unknown Item"
                                        table.insert(invalidMounts, {itemID = vv, itemName = itemName, expansion = n.name, category = v.name})
                                    end
                                end                            
                            else
                                -- Handle mountID entries (strings starting with "m")
                                totalMountCount = totalMountCount + 1
                                load_check = load_check + 1
                                if debugMode then
                                    local mountIDNum = tonumber(string.sub(vv, 2))
                                    local mountName = C_MountJournal.GetMountInfoByID(mountIDNum)
                                    if not mountName then
                                        table.insert(invalidMounts, {mountID = mountIDNum, expansion = n.name, category = v.name, type = "mountID"})
                                    else
                                        table.insert(validMounts, {mountID = mountIDNum, mountName = mountName, expansion = n.name, category = v.name, type = "mountID"})
                                    end
                                end
                            end
                        end                                     
                    end
                end
            end
        end
    end
    
    -- Debug summary (silent tracking only)
    if debugMode then
        -- Data is collected but not printed to chat
        -- invalidMounts and validMounts tables are populated for debugging if needed
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
function MCL_Load:Init(force, showOnComplete)
    local function proceed()
        local retries = 0
        local function repeatCheck()
            if MCL_Load:PreLoad() then
                -- Initialization steps
                if MCLcore.MCL_MF == nil then
                    -- Ensure Frames module is available
                    if not MCLcore.Frames then
                        return false
                    end
                    
                    -- Ensure Frames module is properly loaded before creating main frame
                    if not MCLcore.Frames or not MCLcore.Frames.CreateMainFrame then
                        print("MCL Error: Frames module not properly loaded")
                        return false
                    end
                    
                    MCLcore.MCL_MF = MCLcore.Frames:CreateMainFrame()
                    MCLcore.MCL_MF:SetShown(false)
                    
                    -- Ensure Function module is available before calling methods
                    if MCLcore.Function and MCLcore.Function.initSections then
                        -- Data validation before initialization
                        local validationPassed = true
                        
                        -- Validate saved variables
                        if not MCL_DB or type(MCL_DB) ~= "table" then
                            print("MCL: Corrupted database detected, resetting...")
                            MCL_DB = {}
                            validationPassed = false
                        end
                        
                        if not MOUNTLIST or type(MOUNTLIST) ~= "table" then
                            print("MCL: Corrupted mount list detected, resetting...")
                            MOUNTLIST = {}
                            validationPassed = false
                        end
                        
                        if not MCL_PINNED or type(MCL_PINNED) ~= "table" then
                            print("MCL: Corrupted pinned list detected, resetting...")
                            MCL_PINNED = {}
                            validationPassed = false
                        end
                        
                        if not MCL_SETTINGS or type(MCL_SETTINGS) ~= "table" then
                            print("MCL: Corrupted settings detected, resetting...")
                            MCL_SETTINGS = {}
                            validationPassed = false
                        end
                        
                        -- Wrap initialization in protected call
                        local success, error = pcall(MCLcore.Function.initSections, MCLcore.Function)
                        if not success then
                            print("MCL Error during initialization: " .. tostring(error))
                            print("MCL: Attempting recovery...")
                            
                            -- Try to recover by resetting data and trying again
                            MCL_DB = {}
                            MOUNTLIST = {}
                            MCL_PINNED = {}
                            
                            local retrySuccess, retryError = pcall(MCLcore.Function.initSections, MCLcore.Function)
                            if not retrySuccess then
                                print("MCL Error: Recovery failed - " .. tostring(retryError))
                                return false
                            else
                                print("MCL: Recovery successful")
                            end
                        end
                    else
                        print("MCL Error: Function module or initSections not available")
                    end
                    
                    -- Clean up any invalid pinned mounts during initialization
                    if MCLcore.Function and MCLcore.Function.CleanupInvalidPinnedMounts then
                        MCLcore.Function:CleanupInvalidPinnedMounts()
                    end
                end
                
                -- Ensure Function module is available before updating collection
                if MCLcore.Function and MCLcore.Function.UpdateCollection then
                    MCLcore.Function:UpdateCollection()
                end
                
                -- If we should show the window after initialization, do so
                if showOnComplete and MCLcore.MCL_MF then
                    MCLcore.MCL_MF:Show()
                end
                
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

    -- Begin with polling readiness (only once)
    if not mountInit.initialized then
        PollMountJournalReadiness(function(stable)
            proceed()
        end)
    else
        proceed()
    end
end

-- Toggle function
function MCL_Load:Toggle()
    -- Check preload status and if false, attempt initialization
    if MCLcore.dataLoaded == false then
        MCL_Load:Init(false, true) -- Initialize and show when complete
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

local function EnsureCollectionsLoaded()
    if not C_AddOns.IsAddOnLoaded("Blizzard_Collections") then
        local ok = pcall(C_AddOns.LoadAddOn, "Blizzard_Collections")
        if not ok then
            -- Retry shortly if load failed (can happen very early on some clients)
            C_Timer.After(2, EnsureCollectionsLoaded)
            return false
        end
    end
    return true
end

local function ClearMountFilters()
    if C_MountJournal.SetCollectedFilterSetting then
        -- Show both collected and not collected
        pcall(C_MountJournal.SetCollectedFilterSetting, LE_MOUNT_JOURNAL_FILTER_COLLECTED, true)
        pcall(C_MountJournal.SetCollectedFilterSetting, LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED, true)
    end
    if C_MountJournal.SetSearch then
        pcall(C_MountJournal.SetSearch, "")
    end
    if C_MountJournal.SetAllFactionFilters then
        pcall(C_MountJournal.SetAllFactionFilters, true)
    end
    if C_MountJournal.SetAllTypeFilters then
        pcall(C_MountJournal.SetAllTypeFilters, true)
    end
end

local function onevent(self, event, arg1, ...)
    if(login and ((event == "ADDON_LOADED" and MCL == arg1) or (event == "PLAYER_LOGIN"))) then
        login = nil
        f:UnregisterEvent("ADDON_LOADED")
        f:UnregisterEvent("PLAYER_LOGIN")
        
        -- Force load Blizzard_Collections early (Option A)
        EnsureCollectionsLoaded()
        ClearMountFilters()
        
        -- Ensure Function module is available before calling AddonSettings
        if MCLcore.Function and MCLcore.Function.AddonSettings then
            MCLcore.Function:AddonSettings()
        end
        
        -- Start initialization after readiness polling handled inside :Init
        MCL_Load:Init()
        
        -- Initialize search functionality
        if MCLcore.InitializeSearch then
            MCLcore.InitializeSearch()
        end
        
        -- Initialize MountCard functionality
        if MCLcore.MountCard then
            MCLcore.MountCard:CreateMountCard()
        end
    end
end

-- Listen for late mount data (item info) to trigger re-scan if needed
local itemListener = CreateFrame("Frame")
local pendingRescan
itemListener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemListener:SetScript("OnEvent", function()
    if not MCLcore.dataLoaded then return end
    if pendingRescan then return end
    pendingRescan = true
    C_Timer.After(2, function()
        pendingRescan = nil
        if MCLcore.Function and MCLcore.Function.UpdateCollection then
            MCLcore.Function:UpdateCollection()
        end
    end)
end)

-- Events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", onevent)
