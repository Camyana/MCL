-- * ------------------------------------------------------
-- * MCL Party Check
-- * Scans party/raid for other MCL users and reports
-- * each player's collected mount totals.
-- * ------------------------------------------------------
local _, MCLcore = ...

MCLcore.PartyCheck = {}
local PartyCheck = MCLcore.PartyCheck

-- Addon message prefix (max 16 chars)
local PREFIX = "MCL_PARTY"

-- Protocol message types
local MSG_REQUEST  = "REQ"   -- "Please send me your mount counts"
local MSG_RESPONSE = "RSP"   -- "Here are my counts: collected|total"

-- State
local pendingRequest   = false
local requestTimeout   = 8        -- seconds to wait for replies
local responses        = {}       -- { [playerName] = { collected, total } }
local timerHandle      = nil

-- --------------------------------------------------------
-- Helpers
-- --------------------------------------------------------

-- Return "PARTY" or "RAID" depending on the current group, or nil
local function GetGroupChannel()
    if IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    end
    return nil
end

-- Get the player's "Name-Realm" identifier (same format the API delivers)
local function GetMyFullName()
    local name, realm = UnitFullName("player")
    if not realm or realm == "" then
        realm = GetNormalizedRealmName()
    end
    if realm and realm ~= "" then
        return name .. "-" .. realm
    end
    return name
end

-- Strip realm from "Name-Realm" for display when on the same realm
local function ShortName(fullName)
    if not fullName then return "?" end
    local myRealm = GetNormalizedRealmName()
    local name, realm = fullName:match("^(.+)-(.+)$")
    if name and realm and realm == myRealm then
        return name
    end
    return fullName
end

-- Build the local player's mount stats from MCLcore
local function GetMyMountCounts()
    -- 1) Prefer the pre-computed totals set by UpdateCollection()
    local collected = MCLcore.collected or 0
    local total     = MCLcore.total or 0
    if total > 0 then
        return collected, total
    end

    -- 2) Sum per-section stats if they've been calculated
    if MCLcore.stats then
        for _, sectionData in pairs(MCLcore.stats) do
            if type(sectionData) == "table" then
                if sectionData.collected and sectionData.total then
                    collected = collected + sectionData.collected
                    total     = total + sectionData.total
                end
            end
        end
        if total > 0 then
            return collected, total
        end
    end

    -- 3) Compute directly from mountList data (always available from data.lua)
    if MCLcore.mountList then
        local region = GetCVar("portal")
        for _, section in pairs(MCLcore.mountList) do
            if type(section) == "table" then
                local categories = section.categories or section
                for fieldKey, field in pairs(categories) do
                    if type(field) == "table" and field.mounts then
                        for _, mountEntry in pairs(field.mounts) do
                            -- Resolve to a mount journal ID
                            local mountID
                            local entryStr = tostring(mountEntry)
                            if entryStr:sub(1, 1) == "m" then
                                mountID = tonumber(entryStr:sub(2))
                            else
                                mountID = C_MountJournal.GetMountFromItem(mountEntry)
                            end
                            if mountID then
                                total = total + 1
                                if IsMountCollected(mountID) then
                                    collected = collected + 1
                                end
                            end
                        end
                    end
                end
            end
        end
        if total > 0 then
            return collected, total
        end
    end

    -- 4) Last resort: use the raw WoW mount journal API
    local mountIDs = C_MountJournal.GetMountIDs()
    if mountIDs then
        total = #mountIDs
        collected = 0
        for _, id in ipairs(mountIDs) do
            local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
            if isCollected then
                collected = collected + 1
            end
        end
    end

    return collected, total
end

-- --------------------------------------------------------
-- Display results
-- --------------------------------------------------------

local function PrintHeader()
    print("|cff00CCFF[MCL]|r |cFFFFFFFFMount Collection – Party Check|r")
end

local function PrintResults()
    PrintHeader()

    if not next(responses) then
        print("|cff00CCFF[MCL]|r No other MCL users responded.")
        return
    end

    -- Sort by collected (descending)
    local sorted = {}
    for name, data in pairs(responses) do
        table.insert(sorted, { name = name, collected = data.collected, total = data.total })
    end
    table.sort(sorted, function(a, b) return a.collected > b.collected end)

    for i, entry in ipairs(sorted) do
        local pct = 0
        if entry.total > 0 then
            pct = math.floor((entry.collected / entry.total) * 100)
        end
        -- Colour the percentage: green ≥75, yellow ≥40, red otherwise
        local colour
        if pct >= 75 then
            colour = "|cFF00FF00"
        elseif pct >= 40 then
            colour = "|cFFFFFF00"
        else
            colour = "|cFFFF4444"
        end
        print(string.format("  |cFFFFFFFF%d.|r %s – %s%d/%d (%d%%)|r",
            i, ShortName(entry.name), colour, entry.collected, entry.total, pct))
    end
end

-- --------------------------------------------------------
-- Sending
-- --------------------------------------------------------

--- Send a request to the group asking for mount counts
function PartyCheck:SendRequest()
    local channel = GetGroupChannel()
    if not channel then
        print("|cff00CCFF[MCL]|r You are not in a party or raid.")
        return
    end

    -- Reset state
    pendingRequest = true
    responses = {}

    -- Include our own data immediately
    local myCollected, myTotal = GetMyMountCounts()
    responses[GetMyFullName()] = { collected = myCollected, total = myTotal }

    -- Ask the group
    C_ChatInfo.SendAddonMessage(PREFIX, MSG_REQUEST, channel)

    print("|cff00CCFF[MCL]|r Scanning group for MCL users...")

    -- After the timeout, show results
    if timerHandle then
        timerHandle:Cancel()
    end
    timerHandle = C_Timer.NewTimer(requestTimeout, function()
        pendingRequest = false
        PrintResults()
        timerHandle = nil
    end)
end

-- --------------------------------------------------------
-- Receiving
-- --------------------------------------------------------

local function OnAddonMessage(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end

    if message == MSG_REQUEST then
        -- Someone is asking for our mount counts – reply
        local channel = GetGroupChannel()
        if not channel then return end
        local collected, total = GetMyMountCounts()
        local payload = MSG_RESPONSE .. "|" .. collected .. "|" .. total
        C_ChatInfo.SendAddonMessage(PREFIX, payload, channel)

    elseif message:sub(1, #MSG_RESPONSE) == MSG_RESPONSE and pendingRequest then
        -- Parse "RSP|collected|total"
        local _, colStr, totStr = strsplit("|", message)
        local collected = tonumber(colStr) or 0
        local total     = tonumber(totStr) or 0
        responses[sender] = { collected = collected, total = total }
    end
end

-- --------------------------------------------------------
-- Event frame – register prefix & handler
-- --------------------------------------------------------

local eventFrame = CreateFrame("Frame")
C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    end
end)
