-- =============================================================
-- MCL_Guide.lua  –  Core initialisation for the Guide addon
--
-- Responsibilities:
--   1. Wait for MCL to be ready then resolve mount data
--   2. Build lookup tables: spellId↔mountId, zone indexes
--   3. Expose MCL_GUIDE global table for sub-modules
--   4. Listen for ZONE_CHANGED_NEW_AREA to refresh zone panel
-- =============================================================

-- ─── Global addon table ──────────────────────────────────────
MCL_GUIDE = MCL_GUIDE or {}
local Guide = MCL_GUIDE

Guide.ready         = false
Guide.mountLookup   = {}    -- spellId → merged data record
Guide.zoneMounts    = {}    -- mapID   → { spellId, ... }
Guide.spellToMount  = {}    -- spellId → mountId  (WoW journal)
Guide.mountToSpell  = {}    -- mountId → spellId
Guide.collectedNames = {}   -- lowercase mount name → true (for deduping legacy mounts)

-- Settings defaults
MCL_GUIDE_SETTINGS = MCL_GUIDE_SETTINGS or {}

local DEFAULT_SETTINGS = {
    showZonePanel      = true,      -- show mount panel on world map
    showMapPins        = true,
    showRepInTooltip   = true,
    hideCollected      = true,      -- hide already-collected mounts in zone panel & map pins
    mapPinScale        = 1.0,       -- scale multiplier for map pin icons (1.0 = base size)
    showChildMapPins   = false,     -- project child-map mounts onto the parent map
    zonePanelFlyout    = "DOWN",    -- icon strip direction: DOWN, UP, RIGHT, LEFT
    zonePanelAnchor    = nil,       -- { point, x, y } saved anchor for the tab button
}

local function ApplyDefaults()
    for k, v in pairs(DEFAULT_SETTINGS) do
        if MCL_GUIDE_SETTINGS[k] == nil then
            MCL_GUIDE_SETTINGS[k] = v
        end
    end
end

-- ─── Build spell ↔ mount reverse lookup ─────────────────────
local function BuildSpellMountMap()
    local ids = C_MountJournal.GetMountIDs()
    if not ids then return end
    for _, mid in ipairs(ids) do
        local name, spellID, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mid)
        if spellID then
            Guide.mountToSpell[mid] = spellID
            -- When multiple mount IDs share the same spell, prefer the
            -- collected one so the canonical ID always reports correct status
            local existing = Guide.spellToMount[spellID]
            if not existing then
                Guide.spellToMount[spellID] = mid
            elseif isCollected then
                Guide.spellToMount[spellID] = mid
            end
            -- Track names of collected mounts so legacy duplicates
            -- (different spellID, same name) are also treated as collected
            if isCollected and name then
                Guide.collectedNames[name:lower()] = true
            end
        end
    end
end

-- ─── Merge static guide data with live API info ──────────────
local function BuildMountLookup()
    if not MCL_GUIDE_DATA or not MCL_GUIDE_DATA.mounts then return end

    for spellId, data in pairs(MCL_GUIDE_DATA.mounts) do
        local record = {}
        -- Copy static fields
        for k, v in pairs(data) do
            record[k] = v
        end
        record.spellId = spellId
        record.mountID = Guide.spellToMount[spellId]

        -- Resolve collected state
        if record.mountID then
            local name, _, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(record.mountID)
            record.mountName  = name
            record.icon       = icon
            record.isCollected = isCollected
        end

        -- Attach reputation data if present
        if MCL_GUIDE_REP_DATA and MCL_GUIDE_REP_DATA[spellId] then
            local repRaw = MCL_GUIDE_REP_DATA[spellId]
            record.rep = type(repRaw) == "table" and repRaw[1] or repRaw
            -- Attach vendor coords from the faction vendor lookup
            local fid = record.rep.factionId
            if fid and MCL_GUIDE_REP_VENDORS and MCL_GUIDE_REP_VENDORS[fid] then
                record.vendorInfo = MCL_GUIDE_REP_VENDORS[fid]
                -- Add vendor position to coords so it shows as a map pin
                local vi = record.vendorInfo
                if vi.m and vi.x and vi.y then
                    if not record.coords then record.coords = {} end
                    -- Check if vendor coord is already present
                    local hasVendorCoord = false
                    for _, wp in ipairs(record.coords) do
                        if wp.m == vi.m and wp.n == vi.npc then
                            hasVendorCoord = true
                            break
                        end
                    end
                    if not hasVendorCoord then
                        table.insert(record.coords, { m = vi.m, x = vi.x, y = vi.y, n = vi.npc })
                    end
                end
            end
        end

        -- Attach general vendor data (from Mount DB2 SourceText)
        if not record.vendorInfo and record.mountID and MCL_GUIDE_VENDOR_DATA then
            local vdRaw = MCL_GUIDE_VENDOR_DATA[record.mountID]
            local vd = vdRaw and (type(vdRaw) == "table" and vdRaw[1] or vdRaw) or nil
            if vd then
                record.vendorInfo = vd
                -- Add vendor position to coords so it shows as a map pin
                if vd.m and vd.x and vd.y then
                    if not record.coords then record.coords = {} end
                    local hasVendorCoord = false
                    for _, wp in ipairs(record.coords) do
                        if wp.m == vd.m and wp.n == vd.npc then
                            hasVendorCoord = true
                            break
                        end
                    end
                    if not hasVendorCoord then
                        table.insert(record.coords, { m = vd.m, x = vd.x, y = vd.y, n = vd.npc })
                    end
                end
            end
        end

        -- Attach achievement data if present
        if MCL_GUIDE_ACHIEVEMENT_DATA and MCL_GUIDE_ACHIEVEMENT_DATA.bySpell then
            local achId = MCL_GUIDE_ACHIEVEMENT_DATA.bySpell[spellId]
            if achId then
                -- achId can be a single number or a table of numbers
                record.achievementId = type(achId) == "table" and achId[1] or achId
            end
        end
        -- Also try matching by itemId
        if not record.achievementId and record.itemId and MCL_GUIDE_ACHIEVEMENT_DATA and MCL_GUIDE_ACHIEVEMENT_DATA.byItem then
            local achId = MCL_GUIDE_ACHIEVEMENT_DATA.byItem[record.itemId]
            if achId then
                record.achievementId = achId
            end
        end

        Guide.mountLookup[spellId] = record

        -- ── Auto-register coords into zone index ─────────────────
        -- Ensures any mount with coordinates shows on the map even
        -- if its zone isn't listed in the static zones table.
        if record.coords then
            for _, wp in ipairs(record.coords) do
                if wp.m and wp.x and wp.y then
                    if not Guide.zoneMounts[wp.m] then
                        Guide.zoneMounts[wp.m] = {}
                    end
                    local found = false
                    for _, sid in ipairs(Guide.zoneMounts[wp.m]) do
                        if sid == spellId then found = true; break end
                    end
                    if not found then
                        table.insert(Guide.zoneMounts[wp.m], spellId)
                    end
                end
            end
        end
    end

    -- Build zone index (from static table, coords already handled above)
    if MCL_GUIDE_DATA.zones then
        for mapID, spells in pairs(MCL_GUIDE_DATA.zones) do
            if not Guide.zoneMounts[mapID] then
                Guide.zoneMounts[mapID] = {}
            end
            for _, sid in ipairs(spells) do
                local found = false
                for _, existing in ipairs(Guide.zoneMounts[mapID]) do
                    if existing == sid then found = true; break end
                end
                if not found then
                    table.insert(Guide.zoneMounts[mapID], sid)
                end
            end
        end
    end

    -- ── Register reputation/renown vendor mounts into the zone index ──
    -- Mounts that are sold by a quartermaster may not be in the drop
    -- data.  Create lightweight records for them and index them under
    -- the vendor's zone so they appear in the zone panel and on map pins.
    if MCL_GUIDE_REP_DATA and MCL_GUIDE_REP_VENDORS then
        for spellId, repRaw in pairs(MCL_GUIDE_REP_DATA) do
            local repInfo = type(repRaw) == "table" and repRaw[1] or repRaw
            local fid = repInfo.factionId
            local vendor = fid and MCL_GUIDE_REP_VENDORS[fid]
            if not vendor then
                -- No known vendor location — skip
            else
                local vendorMapID = vendor.m

                -- Ensure there is a mount record in the lookup
                if not Guide.mountLookup[spellId] then
                    -- Build a minimal record from the mount journal
                    local mountID = Guide.spellToMount[spellId]
                    if mountID then
                        local name, _, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
                        local record = {
                            spellId     = spellId,
                            mountID     = mountID,
                            mountName   = name,
                            name        = name or ("Mount " .. spellId),
                            icon        = icon,
                            isCollected = isCollected,
                            method      = "VENDOR",
                            cat         = "REP",
                            rep         = repInfo,
                            vendorInfo  = vendor,
                            coords      = {
                                { m = vendorMapID, x = vendor.x, y = vendor.y, n = vendor.npc },
                            },
                        }

                        -- Attach achievement data if present
                        if MCL_GUIDE_ACHIEVEMENT_DATA and MCL_GUIDE_ACHIEVEMENT_DATA.bySpell then
                            local achId = MCL_GUIDE_ACHIEVEMENT_DATA.bySpell[spellId]
                            if achId then
                                record.achievementId = type(achId) == "table" and achId[1] or achId
                            end
                        end

                        Guide.mountLookup[spellId] = record
                    end
                end

                -- Add to the vendor's zone index (if not already there)
                local rec = Guide.mountLookup[spellId]
                if rec and vendorMapID then
                    if not Guide.zoneMounts[vendorMapID] then
                        Guide.zoneMounts[vendorMapID] = {}
                    end
                    -- Check it isn't already listed
                    local found = false
                    for _, sid in ipairs(Guide.zoneMounts[vendorMapID]) do
                        if sid == spellId then found = true; break end
                    end
                    if not found then
                        table.insert(Guide.zoneMounts[vendorMapID], spellId)
                    end
                end
            end
        end
    end

    -- ── Attach quest data (from Quest SourceText) ────────────────────
    -- Attaches quest info to existing records and registers quest mounts.
    if MCL_GUIDE_QUEST_DATA then
        for mountID, questEntry in pairs(MCL_GUIDE_QUEST_DATA) do
            local spellId = Guide.mountToSpell[mountID]
            if spellId then
                local rec = Guide.mountLookup[spellId]
                if rec then
                    -- Attach quest info to existing record
                    rec.questInfo = questEntry
                    -- Add quest NPC position to coords for map pins
                    if questEntry.m and questEntry.x and questEntry.y then
                        if not rec.coords then rec.coords = {} end
                        local hasQuestCoord = false
                        for _, wp in ipairs(rec.coords) do
                            if wp.m == questEntry.m and wp.n == questEntry.npc then
                                hasQuestCoord = true
                                break
                            end
                        end
                        if not hasQuestCoord then
                            table.insert(rec.coords, { m = questEntry.m, x = questEntry.x, y = questEntry.y, n = questEntry.npc })
                        end
                    end
                else
                    -- Create a new record for this quest mount
                    local name, _, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(mountID)
                    if name then
                        local newRec = {
                            spellId     = spellId,
                            mountID     = mountID,
                            mountName   = name,
                            name        = name,
                            icon        = icon,
                            isCollected = isCollected,
                            method      = "QUEST",
                            cat         = "QUEST",
                            questInfo   = questEntry,
                        }
                        if questEntry.m and questEntry.x and questEntry.y then
                            newRec.coords = {
                                { m = questEntry.m, x = questEntry.x, y = questEntry.y, n = questEntry.npc },
                            }
                        end

                        -- Attach achievement data if present
                        if MCL_GUIDE_ACHIEVEMENT_DATA and MCL_GUIDE_ACHIEVEMENT_DATA.bySpell then
                            local achId = MCL_GUIDE_ACHIEVEMENT_DATA.bySpell[spellId]
                            if achId then
                                newRec.achievementId = type(achId) == "table" and achId[1] or achId
                            end
                        end

                        Guide.mountLookup[spellId] = newRec
                    end
                end

                -- Add to quest zone index
                if questEntry.m then
                    local qMapID = questEntry.m
                    if not Guide.zoneMounts[qMapID] then
                        Guide.zoneMounts[qMapID] = {}
                    end
                    local found = false
                    for _, sid in ipairs(Guide.zoneMounts[qMapID]) do
                        if sid == spellId then found = true; break end
                    end
                    if not found then
                        table.insert(Guide.zoneMounts[qMapID], spellId)
                    end
                end
            end
        end
    end

    -- ── Register general vendor mounts (from Mount DB2 SourceText) ────
    -- Mounts that are vendor-purchased but not reputation-gated.
    -- Creates records and zone index entries for mounts from MCL_GUIDE_VENDOR_DATA.
    -- Supports both old single-table format and new array-of-tables format.
    if MCL_GUIDE_VENDOR_DATA then
        for mountID, vendorRaw in pairs(MCL_GUIDE_VENDOR_DATA) do
            -- Normalize to an array of vendor entries
            local vendorList
            if vendorRaw[1] and type(vendorRaw[1]) == "table" then
                vendorList = vendorRaw  -- already an array
            elseif vendorRaw.npc then
                vendorList = { vendorRaw }  -- old single-vendor format
            else
                vendorList = {}
            end

            local spellId = Guide.mountToSpell[mountID]
            if spellId then
                -- Use the canonical journal mount ID (not the vendor-data key,
                -- which can be a legacy/duplicate ID the API reports as uncollected)
                local canonicalMountID = Guide.spellToMount[spellId] or mountID
                if not Guide.mountLookup[spellId] then
                    -- Build a minimal record using the first vendor
                    local name, _, icon, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(canonicalMountID)
                    if name then
                        local record = {
                            spellId     = spellId,
                            mountID     = canonicalMountID,
                            mountName   = name,
                            name        = name,
                            icon        = icon,
                            isCollected = isCollected,
                            method      = "VENDOR",
                            cat         = "VENDOR",
                            vendorInfo  = vendorList,
                        }
                        -- Build coords from ALL vendors that have coordinates
                        local coords = {}
                        for _, ve in ipairs(vendorList) do
                            if ve.m and ve.x and ve.y then
                                coords[#coords + 1] = { m = ve.m, x = ve.x, y = ve.y, n = ve.npc }
                            end
                        end
                        if #coords > 0 then
                            record.coords = coords
                        end

                        -- Attach achievement data if present
                        if MCL_GUIDE_ACHIEVEMENT_DATA and MCL_GUIDE_ACHIEVEMENT_DATA.bySpell then
                            local achId = MCL_GUIDE_ACHIEVEMENT_DATA.bySpell[spellId]
                            if achId then
                                record.achievementId = type(achId) == "table" and achId[1] or achId
                            end
                        end

                        Guide.mountLookup[spellId] = record
                    end
                else
                    -- Record already exists (e.g. from rep data). Merge any
                    -- vendor coords that aren't already present.
                    local rec = Guide.mountLookup[spellId]
                    for _, ve in ipairs(vendorList) do
                        if ve.m and ve.x and ve.y then
                            if not rec.coords then rec.coords = {} end
                            local hasCoord = false
                            for _, wp in ipairs(rec.coords) do
                                if wp.m == ve.m and wp.n == ve.npc then
                                    hasCoord = true
                                    break
                                end
                            end
                            if not hasCoord then
                                table.insert(rec.coords, { m = ve.m, x = ve.x, y = ve.y, n = ve.npc })
                            end
                        end
                    end
                end
            end

            -- Add to each vendor's zone index
            if spellId and Guide.mountLookup[spellId] then
                for _, ve in ipairs(vendorList) do
                    local vendorMapID = ve.m
                    if vendorMapID then
                        if not Guide.zoneMounts[vendorMapID] then
                            Guide.zoneMounts[vendorMapID] = {}
                        end
                        local found = false
                        for _, sid in ipairs(Guide.zoneMounts[vendorMapID]) do
                            if sid == spellId then found = true; break end
                        end
                        if not found then
                            table.insert(Guide.zoneMounts[vendorMapID], spellId)
                        end
                    end
                end
            end
        end
    end
end

-- ─── Get mounts available in a specific zone ────────────────
-- ─── Collect all descendant (child) map IDs ─────────────────
function Guide:GetAllChildMapIDs(mapID, maxDepth)
    maxDepth = maxDepth or 5
    local children = {}
    local seen = {}
    local function recurse(mid, depth)
        if depth > maxDepth then return end
        local info = C_Map.GetMapChildrenInfo(mid)
        if not info then return end
        for _, child in ipairs(info) do
            if not seen[child.mapID] then
                seen[child.mapID] = true
                table.insert(children, child.mapID)
                recurse(child.mapID, depth + 1)
            end
        end
    end
    recurse(mapID, 1)
    return children
end

function Guide:GetMountsForZone(mapID, includeChildren)
    if not mapID then return {} end

    -- Decide which zone IDs to pull mounts from
    local mapIDs = { mapID }
    if includeChildren then
        for _, childID in ipairs(self:GetAllChildMapIDs(mapID)) do
            table.insert(mapIDs, childID)
        end
    end

    local seen = {}
    local results = {}
    local n = 0
    for _, mid in ipairs(mapIDs) do
        local spells = self.zoneMounts[mid]
        if spells then
            for _, spellId in ipairs(spells) do
                if not seen[spellId] then
                    seen[spellId] = true
                    local rec = self.mountLookup[spellId]
                    if rec and type(rec) == "table" then
                        -- Refresh collected status live from the journal
                        -- Use the canonical mount ID (spellToMount) to avoid legacy
                        -- mount IDs that report incorrect collected status
                        local checkID = Guide.spellToMount[spellId] or rec.mountID
                        if checkID then
                            if IsMountCollected then
                                rec.isCollected = IsMountCollected(checkID)
                            else
                                local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(checkID)
                                rec.isCollected = collected
                            end
                        end
                        -- Also treat as collected if another mount with the
                        -- same name is collected (handles legacy duplicate IDs)
                        if not rec.isCollected then
                            local mName = rec.mountName or rec.name
                            if mName and Guide.collectedNames[mName:lower()] then
                                rec.isCollected = true
                            end
                        end
                        if rec.isCollected == true then
                            -- skip collected mounts from map pins & zone panel
                        else
                            n = n + 1
                            results[n] = rec
                        end
                    end
                end
            end
        end
    end
    -- Trim any trailing nils (safety)
    for i = #results, n + 1, -1 do
        results[i] = nil
    end
    -- Sort: uncollected first, then by name
    if n > 1 then
        table.sort(results, function(a, b)
            if not a or not b then return false end
            local aCol = (a.isCollected == true)
            local bCol = (b.isCollected == true)
            if aCol ~= bCol then
                return not aCol
            end
            return (a.mountName or a.name or "") < (b.mountName or b.name or "")
        end)
    end
    return results
end

-- ─── Get current player zone mapID ───────────────────────────
function Guide:GetCurrentMapID()
    return C_Map.GetBestMapForUnit("player")
end

-- ─── Method text helpers ─────────────────────────────────────
local METHOD_LABELS = {
    NPC        = "Rare / NPC Drop",
    BOSS       = "Boss Drop",
    ZONE       = "Zone Drop",
    USE        = "Container / Use",
    FISHING    = "Fishing",
    ARCH       = "Archaeology",
    SPECIAL    = "Special",
    MINING     = "Mining",
    COLLECTION = "Collection",
    VENDOR     = "Vendor",
    QUEST      = "Quest",
}

function Guide:GetMethodText(method)
    return METHOD_LABELS[method] or method or "Unknown"
end

-- ─── Difficulty labels ───────────────────────────────────────
local DIFF_LABELS = {
    [2]  = "Heroic",
    [14] = "Normal",
    [15] = "Heroic",
    [16] = "Mythic",
    [17] = "LFR",
    [23] = "Mythic+",
    [24] = "Timewalking",
    [33] = "TW Raid",
}

function Guide:GetDifficultyText(difficulties)
    if not difficulties or #difficulties == 0 then return nil end
    local parts = {}
    for _, d in ipairs(difficulties) do
        table.insert(parts, DIFF_LABELS[d] or tostring(d))
    end
    return table.concat(parts, ", ")
end

-- ─── Initialisation ──────────────────────────────────────────
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        ApplyDefaults()
        -- Delay to allow MCL and mount journal to initialise
        C_Timer.After(4, function()
            BuildSpellMountMap()
            BuildMountLookup()
            Guide.ready = true

            local mountCount = 0
            for _ in pairs(Guide.mountLookup) do mountCount = mountCount + 1 end
            local zoneCount = 0
            for _ in pairs(Guide.zoneMounts) do zoneCount = zoneCount + 1 end

            -- Map pins and zone panel will self-refresh when map opens
            if Guide.MapPins and Guide.MapPins.RefreshPins then
                Guide.MapPins:RefreshPins()
            end
        end)

    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" then
        if not Guide.ready then return end
        -- Refresh map pins on zone change (panel refreshes via map hooks)
        C_Timer.After(0.5, function()
            if Guide.MapPins and Guide.MapPins.RefreshPins then
                Guide.MapPins:RefreshPins()
            end
        end)
    end
end)
