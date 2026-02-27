-- =============================================================
-- GuideReputation.lua  –  Reputation & Renown tracker
--
-- Queries C_Reputation / C_MajorFactions APIs to show the
-- player's current standing for mounts that require reputation
-- or renown.  This data is displayed in:
--   • Zone panel tooltips
--   • Mount card tooltips (via MCL integration)
--   • Map pin tooltips
-- =============================================================

local Guide = MCL_GUIDE

Guide.Reputation = Guide.Reputation or {}
local Rep = Guide.Reputation

-- ─── Standing ID → label mapping (classic reputation) ───────
local STANDING_LABELS = {
    [1] = "Hated",
    [2] = "Hostile",
    [3] = "Unfriendly",
    [4] = "Neutral",
    [5] = "Friendly",
    [6] = "Honored",
    [7] = "Revered",
    [8] = "Exalted",
}

-- ─── Query current reputation standing ──────────────────────
function Rep:GetFactionStanding(factionId)
    if not factionId then return nil end

    -- Try C_Reputation first (11.x API)
    if C_Reputation and C_Reputation.GetFactionDataByID then
        local data = C_Reputation.GetFactionDataByID(factionId)
        if data then
            return {
                name       = data.name,
                standingId = data.reaction,
                standing   = STANDING_LABELS[data.reaction] or ("Standing " .. (data.reaction or "?")),
                current    = data.currentStanding or 0,
                max        = data.nextReactionThreshold or 0,
                earned     = data.currentReactionThreshold or 0,
            }
        end
    end

    -- Fallback to classic GetFactionInfoByID
    if GetFactionInfoByID then
        local name, _, standingId, barMin, barMax, barValue = GetFactionInfoByID(factionId)
        if name then
            return {
                name       = name,
                standingId = standingId,
                standing   = STANDING_LABELS[standingId] or ("Standing " .. (standingId or "?")),
                current    = barValue - barMin,
                max        = barMax - barMin,
                earned     = barValue,
            }
        end
    end

    return nil
end

-- ─── Query current friendship rank ───────────────────────────
function Rep:GetFriendshipRank(factionId)
    if not factionId then return nil end

    if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local info = C_GossipInfo.GetFriendshipReputation(factionId)
        if info and info.friendshipFactionID and info.friendshipFactionID > 0 then
            local ranks = C_GossipInfo.GetFriendshipReputationRanks
                          and C_GossipInfo.GetFriendshipReputationRanks(factionId)
            return {
                name          = info.name or "",
                standing      = info.standing or "",   -- current rank name
                currentLevel  = ranks and ranks.currentLevel or 0,
                maxLevel      = ranks and ranks.maxLevel or 0,
            }
        end
    end

    return nil
end

-- ─── Query current renown level ─────────────────────────────
function Rep:GetRenownLevel(factionId)
    if not factionId then return nil end

    -- C_MajorFactions API (Dragonflight+)
    if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
        local data = C_MajorFactions.GetMajorFactionData(factionId)
        if data then
            return {
                name         = data.name,
                renownLevel  = data.renownLevel or 0,
                maxRenown    = data.renownLevelThreshold or 0,
                isMaxed      = data.isMaxed or (data.renownLevel and data.renownLevel >= (data.renownLevelThreshold or 999)),
            }
        end
    end

    -- Attempt C_Reputation with isMajorFaction check
    if C_Reputation and C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(factionId) then
        if C_MajorFactions and C_MajorFactions.GetMajorFactionData then
            local data = C_MajorFactions.GetMajorFactionData(factionId)
            if data then
                return {
                    name         = data.name,
                    renownLevel  = data.renownLevel or 0,
                    maxRenown    = data.renownLevelThreshold or 0,
                    isMaxed      = data.isMaxed or false,
                }
            end
        end
    end

    return nil
end

-- ─── Standing name → standing ID for comparison ─────────────
local STANDING_IDS = {
    Hated      = 1,
    Hostile    = 2,
    Unfriendly = 3,
    Neutral    = 4,
    Friendly   = 5,
    Honored    = 6,
    Revered    = 7,
    Exalted    = 8,
}

-- ─── Get formatted standing text for a repInfo record ───────
-- repInfo = { factionId, renown (bool), friendship (bool), level, levelName, ... }
function Rep:GetStandingText(repInfo)
    if not repInfo or not repInfo.factionId then return nil end

    if repInfo.friendship then
        local data = self:GetFriendshipRank(repInfo.factionId)
        if data then
            local current = data.currentLevel or 0
            local required = repInfo.level or 0
            local color
            if current >= required then
                color = "|cFF00FF00"
            else
                color = "|cFFFF4444"
            end
            local curName = data.standing or ("Rank " .. current)
            local reqName = repInfo.levelName or ("Rank " .. required)
            return color .. curName .. " (" .. current .. "/" .. required .. ") / " .. reqName .. "|r"
        end
        return "|cFFAAAAAAnot discovered|r"
    elseif repInfo.renown then
        local data = self:GetRenownLevel(repInfo.factionId)
        if data then
            local current = data.renownLevel or 0
            local required = repInfo.level or 0
            local color
            if current >= required then
                color = "|cFF00FF00"   -- green = met
            else
                color = "|cFFFF4444"   -- red = not met
            end
            return color .. "Renown " .. current .. "/" .. required .. "|r"
        end
    else
        local data = self:GetFactionStanding(repInfo.factionId)
        if data then
            local current = data.standingId or 0
            -- Resolve required standing from levelName (string) or level (number)
            local required = repInfo.level
            if not required and repInfo.levelName then
                required = STANDING_IDS[repInfo.levelName] or 8
            end
            required = required or 8
            local color
            if current >= required then
                color = "|cFF00FF00"
            else
                color = "|cFFFF4444"
            end
            local standingName = data.standing or "Unknown"
            local targetName = repInfo.levelName or STANDING_LABELS[required] or "Exalted"
            local progressText = ""
            if data.max and data.max > 0 then
                progressText = " (" .. data.current .. "/" .. data.max .. ")"
            end
            return color .. standingName .. progressText .. " / " .. targetName .. "|r"
        end
    end

    return "|cFFAAAAAAnot discovered|r"
end

-- ─── Resolve faction-specific rep entry from data ───────────
-- Rep data can be a single dict (old format) or an array of
-- dicts with optional ``faction`` field.  This picks the correct
-- entry for the current player's faction, falling back to the
-- first entry that has no faction tag (neutral).
local function resolveRepInfo(raw)
    if not raw then return nil end
    -- Old format: single dict with factionId key
    if raw.factionId then return raw end
    -- New format: array of rep dicts
    if type(raw) ~= "table" or #raw == 0 then return nil end
    if #raw == 1 then return raw[1] end

    local playerFaction = UnitFactionGroup("player")  -- "Alliance" or "Horde"
    local neutral = nil
    for _, entry in ipairs(raw) do
        if entry.faction and entry.faction == playerFaction then
            return entry
        end
        if not entry.faction or entry.faction == "" then
            neutral = neutral or entry
        end
    end
    return neutral or raw[1]
end

-- ─── Get full reputation tooltip block for a mount ──────────
-- Returns formatted multi-line string or nil
function Rep:GetTooltipBlock(spellId)
    if not MCL_GUIDE_SETTINGS.showRepInTooltip then return nil end
    if not spellId then return nil end

    -- Try the merged mountLookup first, then fall back to raw rep data
    local repInfo
    local mount = Guide.mountLookup and Guide.mountLookup[spellId]
    if mount and mount.rep then
        repInfo = resolveRepInfo(mount.rep)
    elseif MCL_GUIDE_REP_DATA and MCL_GUIDE_REP_DATA[spellId] then
        repInfo = resolveRepInfo(MCL_GUIDE_REP_DATA[spellId])
    end

    if not repInfo then return nil end

    local lines = {}

    local label = repInfo.friendship and "Friendship Required"
                or repInfo.renown and "Renown Required"
                or "Reputation Required"
    table.insert(lines, "|cFF1FB7EB" .. label .. "|r")

    local factionName = repInfo.factionName or "Unknown Faction"
    table.insert(lines, "  " .. factionName)

    if repInfo.levelName then
        table.insert(lines, "  Required: " .. repInfo.levelName)
    end

    local standing = self:GetStandingText(repInfo)
    if standing then
        table.insert(lines, "  Current: " .. standing)
    end

    if repInfo.note and repInfo.note ~= "" then
        table.insert(lines, "  |cFF888888" .. repInfo.note .. "|r")
    end

    -- Show vendor/quartermaster location
    local fid = repInfo.factionId
    local vi = nil
    if fid and MCL_GUIDE_REP_VENDORS and MCL_GUIDE_REP_VENDORS[fid] then
        vi = MCL_GUIDE_REP_VENDORS[fid]
    end
    if not vi then
        local mount = Guide.mountLookup and Guide.mountLookup[spellId]
        if mount and mount.vendorInfo then
            vi = mount.vendorInfo
        end
    end
    if vi then
        local vendorText = "  Vendor: " .. (vi.npc or "Unknown")
        if vi.x and vi.y then
            vendorText = vendorText .. string.format(" (%.1f, %.1f)", vi.x, vi.y)
        end
        table.insert(lines, "|cFFCC99FF" .. vendorText .. "|r")
    end

    return table.concat(lines, "\n")
end

-- ─── Hook into MCL mount card tooltips ──────────────────────
-- This runs after MCL_Guide is ready and injects rep info into
-- the MCL mount card system if available.
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function()
    C_Timer.After(5, function()
        -- Text-block tooltip (used in zone panel / map pin tooltips)
        MCL_GUIDE_GET_REP_TOOLTIP = function(spellId)
            return Rep:GetTooltipBlock(spellId)
        end

        -- Structured rep info (used by MountCard for clean layout)
        MCL_GUIDE_GET_REP_INFO = function(spellId)
            if not spellId then return nil end

            local repInfo
            local mount = Guide.mountLookup and Guide.mountLookup[spellId]
            if mount and mount.rep then
                repInfo = resolveRepInfo(mount.rep)
            elseif MCL_GUIDE_REP_DATA and MCL_GUIDE_REP_DATA[spellId] then
                repInfo = resolveRepInfo(MCL_GUIDE_REP_DATA[spellId])
            end
            if not repInfo then return nil end

            local result = {
                factionName  = repInfo.factionName or "Unknown Faction",
                isRenown     = repInfo.renown or false,
                isFriendship = repInfo.friendship or false,
                required     = repInfo.levelName or (repInfo.level and tostring(repInfo.level)) or "Exalted",
                note         = repInfo.note,
            }

            -- Attach vendor info if available
            local fid = repInfo.factionId
            if fid and MCL_GUIDE_REP_VENDORS and MCL_GUIDE_REP_VENDORS[fid] then
                local vi = MCL_GUIDE_REP_VENDORS[fid]
                result.vendorName = vi.npc
                result.vendorNpcId = vi.npcId
                result.vendorMapId = vi.m
                result.vendorX = vi.x
                result.vendorY = vi.y
            elseif mount and mount.vendorInfo then
                local vi = mount.vendorInfo
                result.vendorName = vi.npc
                result.vendorNpcId = vi.npcId
                result.vendorMapId = vi.m
                result.vendorX = vi.x
                result.vendorY = vi.y
            end

            if repInfo.friendship then
                local data = Rep:GetFriendshipRank(repInfo.factionId)
                if data then
                    local current = data.currentLevel or 0
                    local required = repInfo.level or 0
                    local curName = data.standing or ("Rank " .. current)
                    local reqName = repInfo.levelName or ("Rank " .. required)
                    result.currentText  = curName .. " (" .. current .. ")"
                    result.requiredText = reqName .. " (" .. required .. ")"
                    result.isMet        = current >= required
                    result.progressCur  = math.min(current, required)
                    result.progressMax  = required
                else
                    result.currentText  = "Unknown"
                    result.requiredText = repInfo.levelName or ("Rank " .. (repInfo.level or "?"))
                    result.isMet        = false
                    result.progressCur  = 0
                    result.progressMax  = repInfo.level or 1
                end
            elseif repInfo.renown then
                local data = Rep:GetRenownLevel(repInfo.factionId)
                if data then
                    local current = data.renownLevel or 0
                    local required = repInfo.level or 0
                    result.currentText  = "Renown " .. current
                    result.requiredText = "Renown " .. required
                    result.isMet        = current >= required
                    -- Progress: renown level as fraction of required
                    result.progressCur = math.min(current, required)
                    result.progressMax = required
                else
                    result.currentText  = "Unknown"
                    result.requiredText = "Renown " .. (repInfo.level or "?")
                    result.isMet        = false
                    result.progressCur  = 0
                    result.progressMax  = repInfo.level or 1
                end
            else
                local data = Rep:GetFactionStanding(repInfo.factionId)
                if data then
                    local standingName = data.standing or "Unknown"
                    local progressText = ""
                    if data.max and data.max > 0 then
                        progressText = " (" .. data.current .. "/" .. data.max .. ")"
                    end
                    result.currentText = standingName .. progressText

                    local reqId = repInfo.level
                    if not reqId and repInfo.levelName then
                        reqId = STANDING_IDS[repInfo.levelName] or 8
                    end
                    reqId = reqId or 8
                    result.requiredText = repInfo.levelName or STANDING_LABELS[reqId] or "Exalted"
                    result.isMet = (data.standingId or 0) >= reqId

                    -- Progress: standing tiers (1-8) as fraction
                    -- Each full standing tier = 1 unit; add partial within current tier
                    local curStanding = data.standingId or 1
                    local partial = 0
                    if data.max and data.max > 0 then
                        partial = data.current / data.max
                    end
                    result.progressCur = math.min(curStanding - 1 + partial, reqId - 1)
                    result.progressMax = reqId - 1  -- standing 1 (Hated) is the baseline
                else
                    result.currentText  = "Not discovered"
                    result.requiredText = repInfo.levelName or "Exalted"
                    result.isMet        = false
                    result.progressCur  = 0
                    result.progressMax  = 1
                end
            end

            return result
        end
    end)
end)
