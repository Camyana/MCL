-- * ------------------------------------------------------
-- *  Namespaces
-- * ------------------------------------------------------
local MCL, MCLcore = ...;
local L = MCLcore.L or {}

-- * ------------------------------------------------------
-- * Variables
-- * ------------------------------------------------------
MCLcore.Main = {};
local MCL_Load = MCLcore.Main;
local init_load = true
local load_check = 0
local region = GetCVar('portal')

-- ===================================================================
-- Item-to-Mount session cache
-- Persists for the session so that once an item resolves, the mapping
-- is never lost even if the item cache is evicted later.
-- ===================================================================
MCLcore.itemToMountCache = MCLcore.itemToMountCache or {}
MCLcore.unresolvedMounts = MCLcore.unresolvedMounts or {}  -- {itemID = true}

-- Collect every item-based ID from data.lua (excludes "m" prefix entries)
local function CollectAllItemIDs()
    local ids = {}
    for _, section in pairs(MCLcore.mountList) do
        for _, field in pairs(section) do
            if type(field) == "table" then
                for _, category in pairs(field) do
                    if type(category) == "table" and category.mounts then
                        for _, entry in ipairs(category.mounts) do
                            if type(entry) == "number" then
                                ids[entry] = true
                            elseif type(entry) == "string" and not entry:match("^m") then
                                local num = tonumber(entry)
                                if num then ids[num] = true end
                            end
                        end
                    end
                end
            end
        end
    end
    return ids
end

-- Request every item ID so the client starts caching them immediately
local allItemIDs  -- populated once on ADDON_LOADED
local function PreWarmAllItems()
    allItemIDs = CollectAllItemIDs()
    for itemID in pairs(allItemIDs) do
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

-- Try to resolve all pending items and return how many are still unresolved
local function ResolveItemCache()
    if not allItemIDs then return 0, 0 end
    local resolved, pending = 0, 0
    for itemID in pairs(allItemIDs) do
        if MCLcore.itemToMountCache[itemID] then
            resolved = resolved + 1
        else
            local mountID = C_MountJournal.GetMountFromItem(itemID)
            if mountID then
                MCLcore.itemToMountCache[itemID] = mountID
                resolved = resolved + 1
            else
                pending = pending + 1
                -- Re-request to nudge the client
                C_Item.RequestLoadItemDataByID(itemID)
            end
        end
    end
    return resolved, pending
end

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
            -- Mount journal is stable. Now also try to resolve item cache.
            local resolved, pending = ResolveItemCache()
            if pending == 0 or mountInit.attempts >= 15 then
                -- All items resolved OR we've waited long enough for the item cache
                mountInit.initialized = true
                if callback then callback(true) end
                return
            end
            -- Items still pending - keep polling a bit longer for item cache
            mountInit.stableChecks = mountInit.requiredStableChecks  -- don't reset
        end
    end

    if mountInit.attempts >= mountInit.maxAttempts then
        -- Give up waiting for perfect stability; proceed to avoid addon appearing broken.
        ResolveItemCache()  -- one last attempt
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

local function IsRegionalFiltered(id)
    if MCLcore.regionalFilter[region] ~= nil then
        for _, filteredId in pairs(MCLcore.regionalFilter[region]) do
            if filteredId == id then
                return true
            end
        end
    end
    return false
end

local function CountMounts()
    MCLcore.mountList = MCLcore.mountList or {}
    local count = 0
    for _, section in pairs(MCLcore.mountList) do
        if type(section) == "table" then
            for _, field in pairs(section) do
                if type(field) == "table" then
                    for _, category in pairs(field) do
                        if type(category.mounts) == "table" then
                            count = count + #category.mounts
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
local debugMode = false -- Set to true to enable debug mount tracking
local invalidMounts = {}
local validMounts = {}

local function InitMounts()
    load_check = 0
    totalMountCount = 0
    MCLcore.unresolvedMounts = {}
    
    -- Reset debug tracking
    if debugMode then
        invalidMounts = {}
        validMounts = {}
    end
    
    for _, section in pairs(MCLcore.mountList) do
        for _, field in pairs(section) do
            if (type(field) == "table") then
                for _, category in pairs(field) do
                    for _, mountEntry in pairs(category.mounts) do
                        if not IsRegionalFiltered(mountEntry) then
                            if not string.match(mountEntry, "^m") then
                                totalMountCount = totalMountCount + 1
                                
                                -- Check session cache first, then API
                                local mountID = MCLcore.itemToMountCache[mountEntry]
                                if not mountID then
                                    C_Item.RequestLoadItemDataByID(mountEntry)
                                    mountID = C_MountJournal.GetMountFromItem(mountEntry)
                                    if mountID then
                                        MCLcore.itemToMountCache[mountEntry] = mountID
                                    end
                                end
                                
                                -- Always count toward load_check to prevent infinite blocking,
                                -- but track unresolved items for deferred resolution.
                                load_check = load_check + 1
                                if mountID then
                                    if debugMode then
                                        table.insert(validMounts, {itemID = mountEntry, mountID = mountID, expansion = section.name, category = category.name})
                                    end
                                else
                                    MCLcore.unresolvedMounts[mountEntry] = {
                                        section = section.name,
                                        category = category.name,
                                    }
                                    if debugMode then
                                        local itemName = GetItemInfo(mountEntry) or L["Unknown Item"]
                                        table.insert(invalidMounts, {itemID = mountEntry, itemName = itemName, expansion = section.name, category = category.name})
                                    end
                                end
                            else
                                -- Handle mountID entries (strings starting with "m") - always available immediately
                                totalMountCount = totalMountCount + 1
                                load_check = load_check + 1
                                if debugMode then
                                    local mountIDNum = tonumber(string.sub(mountEntry, 2))
                                    local mountName = C_MountJournal.GetMountInfoByID(mountIDNum)
                                    if not mountName then
                                        table.insert(invalidMounts, {mountID = mountIDNum, expansion = section.name, category = category.name, type = "mountID"})
                                    else
                                        table.insert(validMounts, {mountID = mountIDNum, mountName = mountName, expansion = section.name, category = category.name, type = "mountID"})
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
        
        -- Pre-warm all item IDs immediately so the client starts caching them
        PreWarmAllItems()
        
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

-- ===================================================================
-- Deferred mount resolver
-- After the UI is built, keep resolving unresolved item-based mounts
-- in the background. When newly resolved mounts are detected, trigger
-- a full section rebuild so the user sees all mounts.
-- ===================================================================
local deferredResolver = CreateFrame("Frame")
local deferredTicks = 0
local MAX_DEFERRED_TICKS = 40   -- retry for up to ~120 seconds (40 ticks * 3s)
local deferredRunning = false

local function RunDeferredResolver()
    if deferredRunning then return end
    deferredRunning = true
    deferredTicks = 0
    
    local function tick()
        deferredTicks = deferredTicks + 1
        if not MCLcore.dataLoaded then
            -- UI not built yet, keep waiting
            if deferredTicks < MAX_DEFERRED_TICKS then
                C_Timer.After(3, tick)
            end
            return
        end
        
        -- Try to resolve any remaining unresolved mounts
        local newlyResolved = 0
        if MCLcore.unresolvedMounts then
            for itemID, info in pairs(MCLcore.unresolvedMounts) do
                local mountID = MCLcore.itemToMountCache[itemID]
                if not mountID then
                    mountID = C_MountJournal.GetMountFromItem(itemID)
                    if mountID then
                        MCLcore.itemToMountCache[itemID] = mountID
                    else
                        -- Re-request to nudge the client
                        C_Item.RequestLoadItemDataByID(itemID)
                    end
                end
                if mountID then
                    MCLcore.unresolvedMounts[itemID] = nil
                    newlyResolved = newlyResolved + 1
                end
            end
        end
        
        if newlyResolved > 0 then
            -- Mounts were newly resolved! Rebuild sections to add the missing frames.
            if MCLcore.Function and MCLcore.Function.initSections and MCLcore.MCL_MF then
                local currentTabName = nil
                if MCLcore.currentlySelectedTab and MCLcore.currentlySelectedTab.section then
                    currentTabName = MCLcore.currentlySelectedTab.section.name
                end
                
                -- Rebuild sections (this re-creates all mount frames)
                pcall(MCLcore.Function.initSections, MCLcore.Function)
                
                -- Update collection counts
                if MCLcore.Function.UpdateCollection then
                    pcall(MCLcore.Function.UpdateCollection, MCLcore.Function)
                end
                
                -- Try to re-select the tab the user was on
                if currentTabName and MCLcore.MCL_MF_Nav and MCLcore.MCL_MF_Nav.tabs then
                    for _, tab in ipairs(MCLcore.MCL_MF_Nav.tabs) do
                        if tab.section and tab.section.name == currentTabName then
                            pcall(tab.GetScript, tab, "OnClick")
                            if tab:GetScript("OnClick") then
                                pcall(tab:GetScript("OnClick"), tab)
                            end
                            break
                        end
                    end
                end
            end
        elseif MCLcore.Function and MCLcore.Function.UpdateCollection then
            -- Even without new frames, update collection counts
            -- (item data may have loaded, improving count accuracy)
            pcall(MCLcore.Function.UpdateCollection, MCLcore.Function)
        end
        
        -- Check if there are still unresolved mounts
        local stillPending = 0
        if MCLcore.unresolvedMounts then
            for _ in pairs(MCLcore.unresolvedMounts) do
                stillPending = stillPending + 1
            end
        end
        
        -- Continue if there are still pending mounts and haven't exceeded max ticks
        if stillPending > 0 and deferredTicks < MAX_DEFERRED_TICKS then
            C_Timer.After(3, tick)
        else
            deferredRunning = false
        end
    end
    
    -- Start the first tick after a delay to let the UI finish building
    C_Timer.After(5, tick)
end

-- Listen for late mount data (item info) to populate session cache
local itemListener = CreateFrame("Frame")
itemListener:RegisterEvent("GET_ITEM_INFO_RECEIVED")
itemListener:SetScript("OnEvent", function(_, _, itemID)
    -- Opportunistically populate the cache when any item loads
    if itemID and not MCLcore.itemToMountCache[itemID] then
        local mountID = C_MountJournal.GetMountFromItem(itemID)
        if mountID then
            MCLcore.itemToMountCache[itemID] = mountID
        end
    end
    
    -- Start the deferred resolver if it's not already running
    if MCLcore.unresolvedMounts and not deferredRunning then
        local hasUnresolved = false
        for _ in pairs(MCLcore.unresolvedMounts) do
            hasUnresolved = true
            break
        end
        if hasUnresolved then
            RunDeferredResolver()
        end
    end
end)

-- Events
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", onevent)

-- Start the deferred resolver on Init completion (belt-and-suspenders approach)
hooksecurefunc(MCL_Load, "Init", function()
    C_Timer.After(8, function()
        if MCLcore.dataLoaded then
            RunDeferredResolver()
        end
    end)
end)
