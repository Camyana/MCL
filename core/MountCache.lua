-- * ------------------------------------------------------
-- * MountCache.lua
-- * Caches mount journal API results to avoid repeated
-- * lookups of GetMountFromItem / GetMountInfoByID.
-- * Invalidated on NEW_MOUNT_ADDED so collected status
-- * stays fresh.
-- * ------------------------------------------------------
local _, MCLcore = ...

MCLcore.MountCache = {}
local Cache = MCLcore.MountCache

-- Private cache tables
local itemToMount = {}   -- itemID -> mountJournalID
local mountInfo   = {}   -- mountJournalID -> { name, spellID, icon, isCollected, isFactionSpecific, faction }
local spellToMount = {}  -- spellID -> mountJournalID

local cacheHits  = 0
local cacheMisses = 0

-- =========================================================
-- Item ID  ->  Mount Journal ID
-- =========================================================
function Cache:GetMountFromItem(itemID)
    if itemID == nil then return nil end

    local cached = itemToMount[itemID]
    if cached ~= nil then
        -- We store false for "no result" to distinguish from "never looked up"
        cacheHits = cacheHits + 1
        return cached ~= false and cached or nil
    end

    cacheMisses = cacheMisses + 1
    local mountID = C_MountJournal.GetMountFromItem(itemID)
    itemToMount[itemID] = mountID or false
    return mountID
end

-- =========================================================
-- Spell ID  ->  Mount Journal ID
-- =========================================================
function Cache:GetMountFromSpell(spellID)
    if spellID == nil then return nil end
    if not C_MountJournal.GetMountFromSpell then return nil end

    local cached = spellToMount[spellID]
    if cached ~= nil then
        cacheHits = cacheHits + 1
        return cached ~= false and cached or nil
    end

    cacheMisses = cacheMisses + 1
    local mountID = C_MountJournal.GetMountFromSpell(spellID)
    spellToMount[spellID] = mountID or false
    return mountID
end

-- =========================================================
-- Mount Journal ID  ->  full info table
-- Returns: name, spellID, icon, isCollected, isFactionSpecific, faction, mountID
-- =========================================================
function Cache:GetMountInfo(journalID)
    if journalID == nil or journalID == 0 then return nil end

    local cached = mountInfo[journalID]
    if cached then
        cacheHits = cacheHits + 1
        return cached.name, cached.spellID, cached.icon, cached.isCollected,
               cached.isFactionSpecific, cached.faction, journalID
    end

    cacheMisses = cacheMisses + 1
    local ok, name, spellID, icon, _, _, _, _, isFactionSpecific, faction, _, isCollected =
        pcall(C_MountJournal.GetMountInfoByID, journalID)

    if not ok or not name then return nil end

    mountInfo[journalID] = {
        name              = name,
        spellID           = spellID,
        icon              = icon,
        isCollected       = isCollected or false,
        isFactionSpecific = isFactionSpecific,
        faction           = faction,
    }

    return name, spellID, icon, isCollected, isFactionSpecific, faction, journalID
end

-- =========================================================
-- Check collected status (cached)
-- =========================================================
function Cache:IsMountCollected(journalID)
    if journalID == nil or journalID == 0 then return false end

    -- Handle negative/fallback IDs
    local numID = tonumber(journalID)
    if numID and numID < 0 then return false end

    local cached = mountInfo[journalID]
    if cached then
        cacheHits = cacheHits + 1
        return cached.isCollected
    end

    -- Populate cache via full lookup
    local name, _, _, isCollected = self:GetMountInfo(journalID)
    if not name then return false end
    return isCollected
end

-- =========================================================
-- Invalidation
-- Called on NEW_MOUNT_ADDED to refresh collected flags.
-- Full wipe is cheap because we only store primitives.
-- =========================================================
function Cache:InvalidateCollected()
    -- Only clear collected flags, preserve name/spellID/icon
    for id, info in pairs(mountInfo) do
        local ok, _, _, _, _, _, _, _, _, _, _, isCollected =
            pcall(C_MountJournal.GetMountInfoByID, id)
        if ok then
            info.isCollected = isCollected or false
        end
    end
end

function Cache:InvalidateAll()
    wipe(itemToMount)
    wipe(mountInfo)
    wipe(spellToMount)
    cacheHits  = 0
    cacheMisses = 0
end

-- =========================================================
-- Debug / Stats
-- =========================================================
function Cache:GetStats()
    local infoCount = 0
    for _ in pairs(mountInfo) do infoCount = infoCount + 1 end
    local itemCount = 0
    for _ in pairs(itemToMount) do itemCount = itemCount + 1 end
    return {
        mountInfoEntries = infoCount,
        itemToMountEntries = itemCount,
        cacheHits  = cacheHits,
        cacheMisses = cacheMisses,
    }
end

-- =========================================================
-- Event hookup  (auto-invalidate on mount changes)
-- =========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("NEW_MOUNT_ADDED")
eventFrame:RegisterEvent("MOUNT_JOURNAL_SEARCH_UPDATED")
eventFrame:SetScript("OnEvent", function(_, event)
    if event == "NEW_MOUNT_ADDED" then
        Cache:InvalidateCollected()
    end
    -- MOUNT_JOURNAL_SEARCH_UPDATED can fire during filter changes;
    -- we don't need to invalidate here since we bypass search filters.
end)
