-- =============================================================
-- GuideMapPins.lua  –  World map pin integration
--
-- Uses HereBeDragons-Pins or the native C_Map.SetUserWaypoint
-- API to place pins for mounts that have exact coordinates.
--
-- Also provides a data provider for the world map to show
-- small mount icons on the map itself.
-- =============================================================

local _, MCLcore = ...
local L = MCLcore.L or {}
local Guide = MCL_GUIDE

Guide.MapPins = Guide.MapPins or {}
local Pins = Guide.MapPins

-- Track active user waypoint created by this addon
Pins.activeWaypoint = nil    -- { mapID, x, y, spellId }
Pins.dataPins = {}           -- data-provider pin frames

-- ─── Pin a specific mount on the world map ──────────────────
function Pins:PinMount(mountData)
    if not mountData or not mountData.coords then return end

    -- Find first coord with x/y in the current zone (or any zone)
    local currentMap = Guide:GetCurrentMapID()
    local best = nil

    for _, wp in ipairs(mountData.coords) do
        if wp.x and wp.y then
            if wp.m == currentMap then
                best = wp
                break
            elseif not best then
                best = wp
            end
        end
    end

    if not best then
        -- No exact coords — just inform the user
        print("|cFF1FB7EBMCL|r " .. string.format(L["Guide: No exact coordinates available for %s"], mountData.mountName or mountData.name))
        return
    end

    -- Use the WoW native waypoint system (C_Map.SetUserWaypoint)
    local mapPoint = UiMapPoint.CreateFromCoordinates(best.m, best.x / 100, best.y / 100)
    C_Map.SetUserWaypoint(mapPoint)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    self.activeWaypoint = {
        mapID   = best.m,
        x       = best.x,
        y       = best.y,
        spellId = mountData.spellId,
        name    = mountData.mountName or mountData.name,
    }

    -- Get NPC name from the waypoint if available
    local npcInfo = best.n and (" — " .. best.n) or ""
    print("|cFF1FB7EBMCL|r " .. string.format(L["Guide: Waypoint set for %s%s at %s"], mountData.mountName or mountData.name, npcInfo, string.format("%.1f, %.1f", best.x, best.y)))
end

-- ─── Clear the active waypoint ──────────────────────────────
function Pins:ClearWaypoint()
    if self.activeWaypoint then
        C_Map.ClearUserWaypoint()
        self.activeWaypoint = nil
    end
end

-- ─── Section / Category lookup cache ─────────────────────────
-- Lazily build a table: journalMountID → { section, category }
-- by scanning MCLcore.sectionNames once.
Pins._sectionCache = nil

function Pins:GetSectionInfo(journalMountID)
    if not journalMountID then return nil, nil end

    -- Build cache on first call
    if not self._sectionCache then
        self._sectionCache = {}
        if MCLcore and MCLcore.sectionNames then
            for _, section in ipairs(MCLcore.sectionNames) do
                if section.mounts and section.mounts.categories then
                    for _, catData in pairs(section.mounts.categories) do
                        if catData.mounts then
                            for _, rawId in ipairs(catData.mounts) do
                                local resolved
                                if type(rawId) == "string" and rawId:sub(1, 1) == "m" then
                                    resolved = tonumber(rawId:sub(2))
                                elseif type(rawId) == "number" then
                                    -- Try as direct mount ID first
                                    local ok, name = pcall(C_MountJournal.GetMountInfoByID, rawId)
                                    if ok and name then
                                        resolved = rawId
                                    else
                                        -- Try item → mount
                                        local mid = C_MountJournal.GetMountFromItem(rawId)
                                        if mid and mid ~= 0 then
                                            resolved = mid
                                        elseif C_MountJournal.GetMountFromSpell then
                                            mid = C_MountJournal.GetMountFromSpell(rawId)
                                            if mid and mid ~= 0 then resolved = mid end
                                        end
                                    end
                                end
                                if resolved and not self._sectionCache[resolved] then
                                    self._sectionCache[resolved] = {
                                        section  = section.name,
                                        category = catData.name,
                                    }
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local info = self._sectionCache[journalMountID]
    if info then
        return info.section, info.category
    end
    return nil, nil
end

-- ─── World Map Data Provider ────────────────────────────────
-- This creates small pin icons on the world map for mounts
-- available in the viewed zone.

-- ─── Mini Mount Card Tooltip ─────────────────────────────────
-- A custom rich tooltip that replaces basic GameTooltip for map pins
-- Shows mount icon, name, source info, obtainment instructions, and more.

local MINI_CARD_WIDTH = 320
local miniCardFrame = nil
local miniCardLines = {}   -- reusable pool of font strings

-- Colours matching MCL house style
local COLOR_TITLE       = { 0.40, 0.78, 0.95 }  -- MCL blue
local COLOR_COLLECTED   = { 0.30, 1.00, 0.30 }
local COLOR_UNCOLLECTED = { 1.00, 0.40, 0.40 }
local COLOR_METHOD      = { 0.12, 0.72, 0.92 }
local COLOR_LABEL       = { 0.55, 0.65, 0.75 }
local COLOR_VALUE       = { 0.85, 0.85, 0.85 }
local COLOR_GOLD        = { 1.00, 0.82, 0.00 }
local COLOR_REP         = { 0.60, 0.80, 1.00 }
local COLOR_ACH         = { 1.00, 1.00, 0.40 }
local COLOR_ACH_DONE    = { 0.30, 1.00, 0.30 }
local COLOR_NOTE        = { 0.82, 0.90, 1.00 }
local COLOR_HINT        = { 0.45, 0.65, 0.45 }
local COLOR_ORIGIN      = { 0.55, 0.55, 0.55 }
local COLOR_SEPARATOR   = { 0.20, 0.40, 0.60 }
local COLOR_QUEST       = { 1.00, 0.90, 0.30 }
local COLOR_DESC        = { 0.85, 0.85, 0.30 }
local COLOR_SOURCE      = { 0.70, 0.70, 0.70 }
local COLOR_ITEM        = { 0.60, 0.80, 1.00 }
local COLOR_SECTION_HDR = { 0.50, 0.75, 0.95 }
local COLOR_BMAH        = { 0.90, 0.70, 0.30 }
local COLOR_DIFF        = { 0.90, 0.65, 0.30 }

-- ─── Note lookup (multi-strategy) ───────────────────────────
-- Notes in MCLcore.mountNotes are keyed by item ID.  We build a
-- cache mapping journal mount IDs → note strings, but also keep
-- the raw table accessible for direct item-ID or spell-ID lookup.
local pinNotesCache = nil

local function BuildPinNotesCache()
    if pinNotesCache then return end
    pinNotesCache = { byMountID = {}, byKey = {} }
    if not MCLcore or not MCLcore.mountNotes then return end
    for ref, note in pairs(MCLcore.mountNotes) do
        if not note or note == "" then -- skip blanks
        else
            -- Store the raw key for direct lookup
            local numRef = (type(ref) == "number") and ref or tonumber(ref)
            if numRef then
                pinNotesCache.byKey[numRef] = note
            end
            -- Try to resolve to a journal mount ID via item lookup
            local jid = nil
            if type(ref) == "string" and string.sub(ref, 1, 1) == "m" then
                jid = tonumber(string.sub(ref, 2))
            elseif numRef then
                -- Try item → mount (the primary keying strategy)
                local ok, mid = pcall(C_MountJournal.GetMountFromItem, numRef)
                if ok and mid and mid ~= 0 then
                    jid = mid
                end
            end
            if jid then
                pinNotesCache.byMountID[jid] = note
            end
        end
    end
end

-- Look up a note for a mount, trying multiple strategies
local function GetPinMountNote(data)
    BuildPinNotesCache()
    if not pinNotesCache then return nil end

    -- 1) By journal mount ID (fastest, most reliable)
    if data.mountID and pinNotesCache.byMountID[data.mountID] then
        return pinNotesCache.byMountID[data.mountID]
    end

    -- 2) By item ID (direct key match – notes are keyed by item ID)
    if data.itemId and pinNotesCache.byKey[data.itemId] then
        return pinNotesCache.byKey[data.itemId]
    end

    -- 3) By spell ID (some older notes may use spell ID as key)
    if data.spellId and pinNotesCache.byKey[data.spellId] then
        return pinNotesCache.byKey[data.spellId]
    end

    return nil
end

-- ─── Template tag cleaning ──────────────────────────────────
local function CleanNoteText(text)
    if not text then return nil end
    -- {{npc:id,Name}} → Name
    text = text:gsub("%{%{npc:%d+,([^}]+)%}%}", "%1")
    -- {{m:mapId,x,y}} → (x, y)
    text = text:gsub("%{%{m:(%d+),%s*([%d%.]+),%s*([%d%.]+)%}%}", function(mapId, x, y)
        -- Try to get zone name
        local mapInfo = C_Map.GetMapInfo(tonumber(mapId))
        local zoneName = mapInfo and mapInfo.name
        if zoneName then
            return zoneName .. " (" .. x .. ", " .. y .. ")"
        end
        return "(" .. x .. ", " .. y .. ")"
    end)
    -- {{m:mapId,ZoneName}} (zone-only reference, no coords)
    text = text:gsub("%{%{m:%d+,([^}]+)%}%}", "%1")
    -- {{item:id}} → [ItemName] or [Item id]
    text = text:gsub("%{%{item:(%d+)%}%}", function(id)
        local itemName = C_Item.GetItemInfo(tonumber(id))
        if itemName then return "[" .. itemName .. "]" end
        return "[Item " .. id .. "]"
    end)
    return text
end

-- ─── Gold formatting ────────────────────────────────────────
local function FormatGold(copperAmount)
    if not copperAmount or copperAmount <= 0 then return nil end
    local gold = math.floor(copperAmount / 10000)
    if gold >= 1000 then
        return string.format("%s,%03dg", math.floor(gold / 1000), gold % 1000)
    elseif gold >= 1 then
        return tostring(gold) .. "g"
    else
        return tostring(copperAmount) .. "c"
    end
end

-- ─── Frame creation ─────────────────────────────────────────
local function GetMiniCard()
    if miniCardFrame then return miniCardFrame end

    local f = CreateFrame("Frame", "MCL_MiniMountCard", UIParent, "BackdropTemplate")
    f:SetFrameStrata("TOOLTIP")
    f:SetFrameLevel(9000)
    f:SetClampedToScreen(true)
    f:EnableMouse(false)
    f:SetSize(MINI_CARD_WIDTH, 100)
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.06, 0.06, 0.09, 0.96)
    f:SetBackdropBorderColor(0.20, 0.40, 0.60, 0.80)

    -- Accent line at top
    f.accent = f:CreateTexture(nil, "OVERLAY")
    f.accent:SetHeight(1)
    f.accent:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.accent:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    f.accent:SetColorTexture(0.20, 0.60, 0.90, 0.60)

    -- Header background
    f.headerBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    f.headerBg:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -2)
    f.headerBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -2)
    f.headerBg:SetHeight(36)
    f.headerBg:SetColorTexture(0.08, 0.08, 0.12, 0.98)

    -- Mount icon
    f.mountIcon = f:CreateTexture(nil, "ARTWORK")
    f.mountIcon:SetSize(28, 28)
    f.mountIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -6)

    -- Mount name
    f.mountName = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.mountName:SetPoint("LEFT", f.mountIcon, "RIGHT", 8, 1)
    f.mountName:SetPoint("RIGHT", f, "RIGHT", -80, 0)
    f.mountName:SetJustifyH("LEFT")
    f.mountName:SetWordWrap(false)

    -- Collected badge
    f.collectedBadge = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.collectedBadge:SetPoint("RIGHT", f, "RIGHT", -8, 0)
    f.collectedBadge:SetPoint("TOP", f, "TOP", 0, -6)
    f.collectedBadge:SetJustifyH("RIGHT")

    -- Separator under header
    f.headerSep = f:CreateTexture(nil, "OVERLAY")
    f.headerSep:SetHeight(1)
    f.headerSep:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -38)
    f.headerSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -38)
    f.headerSep:SetColorTexture(COLOR_SEPARATOR[1], COLOR_SEPARATOR[2], COLOR_SEPARATOR[3], 0.50)

    f.contentStartY = -42

    -- Separator textures for reuse (up to 4)
    f.separators = {}

    miniCardFrame = f
    return f
end

-- ─── Line pool ──────────────────────────────────────────────
local function AcquireLine(card, index)
    if miniCardLines[index] then
        miniCardLines[index]:Show()
        return miniCardLines[index]
    end
    local fs = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(true)
    miniCardLines[index] = fs
    return fs
end

local function HideLinesFrom(startIdx)
    for i = startIdx, #miniCardLines do
        miniCardLines[i]:Hide()
    end
end

-- ─── Coloured info row: "Label:  Value" ────────────────────
local function AddInfoRow(card, lineIdx, yOff, label, value, labelColor, valueColor)
    local fs = AcquireLine(card, lineIdx)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", 10, yOff)
    fs:SetWidth(MINI_CARD_WIDTH - 20)
    local lHex = string.format("%02X%02X%02X", labelColor[1]*255, labelColor[2]*255, labelColor[3]*255)
    local vHex = string.format("%02X%02X%02X", valueColor[1]*255, valueColor[2]*255, valueColor[3]*255)
    fs:SetText("|cFF" .. lHex .. label .. ":|r  |cFF" .. vHex .. value .. "|r")
    local h = math.max(fs:GetStringHeight(), 12)
    return lineIdx + 1, yOff - h - 2
end

-- ─── Plain text line ────────────────────────────────────────
local function AddTextLine(card, lineIdx, yOff, text, color, indent)
    local fs = AcquireLine(card, lineIdx)
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", card, "TOPLEFT", indent or 10, yOff)
    fs:SetWidth(MINI_CARD_WIDTH - (indent or 10) - 10)
    fs:SetTextColor(color[1], color[2], color[3], 1)
    fs:SetText(text)
    local h = math.max(fs:GetStringHeight(), 12)
    return lineIdx + 1, yOff - h - 2
end

-- ─── Visual divider (thin line via a texture) ───────────────
local function AddDivider(card, yOff, sepIndex)
    if not card.separators[sepIndex] then
        local tex = card:CreateTexture(nil, "ARTWORK")
        tex:SetHeight(1)
        tex:SetColorTexture(COLOR_SEPARATOR[1], COLOR_SEPARATOR[2], COLOR_SEPARATOR[3], 0.40)
        card.separators[sepIndex] = tex
    end
    local tex = card.separators[sepIndex]
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", card, "TOPLEFT", 10, yOff - 3)
    tex:SetPoint("TOPRIGHT", card, "TOPRIGHT", -10, yOff - 3)
    tex:Show()
    return yOff - 8
end

local function HideDividersFrom(startIdx)
    for i = startIdx, #(miniCardFrame and miniCardFrame.separators or {}) do
        if miniCardFrame.separators[i] then miniCardFrame.separators[i]:Hide() end
    end
end

-- ─── Populate ───────────────────────────────────────────────
local function PopulateMiniCard(card, data)
    -- ── Header ──────────────────────────────────────────────
    if data.icon then
        card.mountIcon:SetTexture(data.icon)
        card.mountIcon:SetDesaturated(data.isCollected == true)
    else
        card.mountIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end
    card.mountIcon:Show()

    card.mountName:SetText(data.mountName or data.name or "Unknown")
    card.mountName:SetTextColor(COLOR_TITLE[1], COLOR_TITLE[2], COLOR_TITLE[3])

    if data.isCollected then
        card.collectedBadge:SetText("|cFF4CE04C" .. L["Collected"] .. "|r")
    else
        card.collectedBadge:SetText("|cFFFF6666" .. L["Not Collected"] .. "|r")
    end
    card.collectedBadge:Show()

    local li  = 1   -- line pool index
    local y   = card.contentStartY
    local sep = 1   -- divider index

    -- ── WoW API flavour text (description) ──────────────────
    local apiDesc, apiSource
    if data.mountID then
        local _, description, source = C_MountJournal.GetMountInfoExtraByID(data.mountID)
        apiDesc   = description and description ~= "" and description or nil
        apiSource = source and source ~= "" and source or nil
    end

    if apiDesc then
        li, y = AddTextLine(card, li, y, "\"" .. apiDesc .. "\"", COLOR_DESC, 10)
        y = y - 2
    end

    -- ── Divider after description ───────────────────────────
    if apiDesc then
        y = AddDivider(card, y, sep); sep = sep + 1
    end

    -- ── Source / Method ─────────────────────────────────────
    local methodText = Guide:GetMethodText(data.method)
    if methodText and methodText ~= "Unknown" then
        li, y = AddInfoRow(card, li, y, L["Source"], methodText, COLOR_LABEL, COLOR_METHOD)
    end

    -- Drop chance
    if data.chance then
        local chanceText = "1/" .. tostring(data.chance)
        if data.chance <= 20 then
            chanceText = chanceText .. "  " .. L["(rare!)"]
        end
        li, y = AddInfoRow(card, li, y, L["Drop Chance"], chanceText, COLOR_LABEL, COLOR_VALUE)
    end

    -- Boss
    if data.lockBossName then
        li, y = AddInfoRow(card, li, y, L["Boss"], data.lockBossName, COLOR_LABEL, COLOR_GOLD)
    end

    -- Dungeon / raid difficulty
    if data.instanceDifficulties then
        local diffText = Guide:GetDifficultyText(data.instanceDifficulties)
        if diffText then
            li, y = AddInfoRow(card, li, y, L["Difficulty"], diffText, COLOR_LABEL, COLOR_DIFF)
        end
    end

    -- NPC from coords
    if data.coords then
        for _, wp in ipairs(data.coords) do
            if wp.n then
                li, y = AddInfoRow(card, li, y, L["NPC"], wp.n, COLOR_LABEL, COLOR_VALUE)
                break
            end
        end
    end

    -- Item name
    if data.itemId then
        local itemName, itemLink = C_Item.GetItemInfo(data.itemId)
        if itemName then
            li, y = AddInfoRow(card, li, y, L["Item"], itemLink or itemName, COLOR_LABEL, COLOR_ITEM)
        end
    end

    -- Reputation
    if data.rep then
        local repInfo = data.rep
        local label = repInfo.renown and L["Renown"] or L["Reputation"]
        local text = repInfo.factionName or L["Unknown"]
        if repInfo.levelName then
            text = text .. " — " .. repInfo.levelName
        end
        local liveText = Guide.Reputation and Guide.Reputation:GetStandingText(repInfo) or nil
        if liveText then
            text = text .. "  (" .. liveText .. ")"
        end
        li, y = AddInfoRow(card, li, y, label, text, COLOR_LABEL, COLOR_REP)
    end

    -- Vendor
    if data.vendorInfo then
        local vi = data.vendorInfo
        if vi[1] and type(vi[1]) == "table" then vi = vi[1] end
        local vendorText = vi.npc or L["Vendor"]
        if vi.x and vi.y then
            vendorText = vendorText .. string.format("  (%.1f, %.1f)", vi.x, vi.y)
        end
        li, y = AddInfoRow(card, li, y, L["Vendor"], vendorText, COLOR_LABEL, { 0.80, 0.70, 1.00 })
    end

    -- Currency / Cost
    if data.spellId and MCL_GUIDE_CURRENCY_DATA then
        local costData = MCL_GUIDE_CURRENCY_DATA[data.spellId]
        if costData then
            local parts = {}
            for _, entry in ipairs(costData) do
                if entry.type == "gold" then
                    local gs = FormatGold(entry.amount)
                    if gs then table.insert(parts, gs) end
                elseif entry.type == "currency" and entry.id then
                    local info = C_CurrencyInfo.GetCurrencyInfo(entry.id)
                    if info and info.name then
                        local icon = info.iconFileID and ("|T" .. info.iconFileID .. ":14:14|t ") or ""
                        local current = info.quantity or 0
                        local needed = entry.amount
                        local progressColor = current >= needed and "4CE04C" or "FF6666"
                        local costStr = icon .. info.name .. "  |cFF" .. progressColor .. tostring(current) .. " / " .. tostring(needed) .. "|r"
                        table.insert(parts, costStr)
                    else
                        table.insert(parts, tostring(entry.amount) .. " " .. L["Currency"])
                    end
                end
            end
            if #parts > 0 then
                li, y = AddInfoRow(card, li, y, L["Cost"], table.concat(parts, ", "), COLOR_LABEL, COLOR_GOLD)
            end
        end
    end

    -- Achievement
    if data.achievementId then
        local _, achName, _, achCompleted = GetAchievementInfo(data.achievementId)
        if achName then
            local achColor = achCompleted and COLOR_ACH_DONE or COLOR_ACH
            local achStatus = achCompleted and (" " .. L["(Done)"]) or ""
            li, y = AddInfoRow(card, li, y, L["Achievement"], achName .. achStatus, COLOR_LABEL, achColor)
        end
    end

    -- Quest
    if data.questInfo then
        local qi = data.questInfo
        local questText = qi.quest or L["Quest"]
        if qi.npc then
            questText = questText .. "  " .. string.format(L["(from %s)"], qi.npc)
        end
        li, y = AddInfoRow(card, li, y, L["Quest"], questText, COLOR_LABEL, COLOR_QUEST)
    end

    -- Black Market Auction House
    if data.blackMarket then
        li, y = AddInfoRow(card, li, y, L["BMAH"], L["Available on Black Market AH"], COLOR_LABEL, COLOR_BMAH)
    end

    -- Origin (section > category)
    local sec, cat = Pins:GetSectionInfo(data.mountID)
    if sec then
        local origin = L[sec]
        if cat then origin = origin .. " > " .. L[cat] end
        li, y = AddInfoRow(card, li, y, L["Origin"], origin, COLOR_LABEL, COLOR_ORIGIN)
    end

    -- ── Notes / Instructions ────────────────────────────────
    local note = GetPinMountNote(data)
    if note then
        y = AddDivider(card, y, sep); sep = sep + 1

        li, y = AddTextLine(card, li, y, L["How to Get:"], COLOR_SECTION_HDR, 10)

        -- Clean template tags and format for display
        local cleanNote = CleanNoteText(note)
        if cleanNote then
            cleanNote = cleanNote:gsub("^\n+", "")
            cleanNote = cleanNote:gsub("\n\n+", "\n\n")
        end

        -- Truncate very long notes but allow more room than before
        local MAX_NOTE_LEN = 500
        if cleanNote and #cleanNote > MAX_NOTE_LEN then
            -- Try to truncate at a sentence boundary
            local cutPoint = cleanNote:find("%.", MAX_NOTE_LEN - 60)
            if cutPoint and cutPoint <= MAX_NOTE_LEN + 20 then
                cleanNote = cleanNote:sub(1, cutPoint) .. " ..."
            else
                cleanNote = cleanNote:sub(1, MAX_NOTE_LEN) .. "..."
            end
        end

        if cleanNote and cleanNote ~= "" then
            -- Split into paragraphs for better readability
            local paragraphs = {}
            for para in (cleanNote .. "\n"):gmatch("([^\n]+)\n") do
                local trimmed = para:match("^%s*(.-)%s*$")
                if trimmed and trimmed ~= "" then
                    table.insert(paragraphs, trimmed)
                end
            end
            if #paragraphs == 0 then
                -- No newlines, just one block of text
                li, y = AddTextLine(card, li, y, cleanNote, COLOR_NOTE, 14)
            else
                for i, para in ipairs(paragraphs) do
                    li, y = AddTextLine(card, li, y, para, COLOR_NOTE, 14)
                    if i < #paragraphs then
                        y = y - 3  -- small gap between paragraphs
                    end
                end
            end
        end
    end

    -- ── Debug IDs ───────────────────────────────────────────
    do
        local debugParts = {}
        if data.mountID then table.insert(debugParts, L["Mount"] .. ": " .. tostring(data.mountID)) end
        if data.spellId then table.insert(debugParts, L["Spell"] .. ": " .. tostring(data.spellId)) end
        if data.itemId  then table.insert(debugParts, L["Item"] .. ": " .. tostring(data.itemId))  end
        if #debugParts > 0 then
            li, y = AddTextLine(card, li, y, table.concat(debugParts, "  |  "), {0.45, 0.45, 0.45}, 10)
        end
    end

    -- ── Footer ──────────────────────────────────────────────
    y = AddDivider(card, y, sep); sep = sep + 1
    li, y = AddTextLine(card, li, y, L["Click to set waypoint | Right-click for mount card"], COLOR_HINT, 10)

    -- Clean up unused elements
    HideLinesFrom(li)
    HideDividersFrom(sep)

    -- Set dynamic height
    local totalHeight = math.abs(y) + 10
    card:SetHeight(math.max(totalHeight, 60))
end

-- ─── Show / Hide ────────────────────────────────────────────
local function ShowMiniCard(pinFrame, data)
    local card = GetMiniCard()
    PopulateMiniCard(card, data)
    card:ClearAllPoints()
    card:SetPoint("BOTTOMLEFT", pinFrame, "TOPRIGHT", 5, -5)
    card:Show()
end

local function HideMiniCard()
    if miniCardFrame then
        miniCardFrame:Hide()
    end
end

-- ─── Pin sizing & colours by source type ────────────────────
local PIN_STYLES = {
    -- method        = { size, borderR, borderG, borderB, label, labelR, labelG, labelB }
    NPC              = { 36, 0.64, 0.21, 0.93, L["Rare"],     0.78, 0.43, 1.00 },
    BOSS             = { 36, 0.90, 0.49, 0.13, L["Boss"],     1.00, 0.65, 0.20 },
    ZONE             = { 36, 0.64, 0.21, 0.93, L["Zone"],     0.78, 0.43, 1.00 },
    VENDOR           = { 26, 0.85, 0.72, 0.26, L["Vendor"], 1.00, 0.84, 0.30 },
    QUEST            = { 30, 0.98, 0.82, 0.00, L["Quest"],   1.00, 0.90, 0.30 },
    FISHING          = { 28, 0.30, 0.70, 0.90, L["Fish"],     0.40, 0.80, 1.00 },
    USE              = { 30, 0.50, 0.80, 0.50, L["Loot"],     0.55, 0.90, 0.55 },
    SPECIAL          = { 30, 0.90, 0.80, 0.20, L["Special"],0.95, 0.85, 0.30 },
    MINING           = { 28, 0.70, 0.55, 0.35, L["Mining"], 0.80, 0.65, 0.40 },
    COLLECTION       = { 30, 0.40, 0.75, 0.95, L["Collect"],0.50, 0.85, 1.00 },
    ARCH             = { 28, 0.75, 0.60, 0.40, L["Arch"],     0.85, 0.70, 0.45 },
    Treasure         = { 30, 0.85, 0.65, 0.13, L["Treasure"], 0.95, 0.75, 0.20 },
    Chest            = { 30, 0.85, 0.65, 0.13, L["Chest"],    0.95, 0.75, 0.20 },
    Dungeon          = { 36, 0.90, 0.49, 0.13, L["Dungeon"],  1.00, 0.65, 0.20 },
    ["Grand Hunt"]   = { 30, 0.64, 0.21, 0.93, L["Grand Hunt"], 0.78, 0.43, 1.00 },
}
local DEFAULT_STYLE  = { 28, 0.50, 0.50, 0.50, "",       0.60, 0.60, 0.60 }

-- ── Hover slide-away animation settings ─────────────────────
local SLIDE_DURATION      = 0.18   -- seconds for slide animation
local SLIDE_DISTANCE_MULT = 1.4    -- slide distance as multiple of pin size

-- ── Cluster spread settings ─────────────────────────────────
local CLUSTER_OVERLAP_MULT = 1.5   -- within N × pin-width = same cluster
local SPREAD_RADIUS_MULT   = 2.2   -- spread distance as multiple of pin width

-- Forward declarations for cluster functions (defined after mixin)
local FindClusterPins, SpreadCluster, CollapseCluster, CollapseClusterImmediate
local spreadCluster = {}           -- pins in the current spread
local spreadActive  = false
local clusterCollapseTimer = nil
local COLLAPSE_DIST_MULT   = 4.0   -- collapse when cursor is N × pin-width from centre

-- Cursor-distance collapse tracker
local clusterCenterX, clusterCenterY = 0, 0
local clusterCollapseThreshSq = 0
local distanceWatcher = CreateFrame("Frame")
distanceWatcher:Hide()
distanceWatcher:SetScript("OnUpdate", function()
    if not spreadActive then distanceWatcher:Hide() return end
    local cx, cy = GetCursorPosition()
    local uiScale = UIParent:GetEffectiveScale()
    cx, cy = cx / uiScale, cy / uiScale
    local dx = cx - clusterCenterX
    local dy = cy - clusterCenterY
    if (dx * dx + dy * dy) > clusterCollapseThreshSq then
        CollapseCluster()
    end
end)

-- Pin pool & active-pin tracking (forward-declared for cluster code)
local pinPool = {}
local activePins = {}

local MCL_GuidePinMixin = {}

function MCL_GuidePinMixin:OnLoad()
    self:SetFrameStrata("TOOLTIP")
    self:SetFrameLevel(2500)
end

function MCL_GuidePinMixin:OnAcquired(mountData)
    self.mountData = mountData

    -- ── Visual container (slides on hover) ─────────────────
    -- Created as a Button so it can receive clicks during cluster spread.
    if not self.visual then
        self.visual = CreateFrame("Button", nil, self)
        self.visual:EnableMouse(false)
        self.visual:RegisterForClicks("LeftButtonUp", "RightButtonDown")
    end
    self:SetScript("OnUpdate", nil)
    self._slidOut = false
    self._inCluster = false
    self:EnableMouse(true)                -- ensure restored after any prior spread
    self.visual:EnableMouse(false)
    self.visual:SetScript("OnEnter", nil)
    self.visual:SetScript("OnLeave", nil)
    self.visual:SetScript("OnClick", nil)

    local style = PIN_STYLES[mountData.method] or DEFAULT_STYLE
    local scale = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.mapPinScale or 2.0
    local pinSize = math.floor(style[1] * scale + 0.5)

    -- Resize pin to match source type
    self:SetSize(pinSize, pinSize)
    self.visual:SetSize(pinSize, pinSize)
    self.visual:ClearAllPoints()
    self.visual:SetPoint("CENTER")

    -- ── Thin coloured edge border ──────────────────────────
    local bdr = math.max(2, math.floor(1.5 * scale + 0.5))
    if not self.borderTop then
        self.borderTop    = self.visual:CreateTexture(nil, "OVERLAY")
        self.borderBottom = self.visual:CreateTexture(nil, "OVERLAY")
        self.borderLeft   = self.visual:CreateTexture(nil, "OVERLAY")
        self.borderRight  = self.visual:CreateTexture(nil, "OVERLAY")
        self.borderTop:SetColorTexture(1, 1, 1, 1)
        self.borderBottom:SetColorTexture(1, 1, 1, 1)
        self.borderLeft:SetColorTexture(1, 1, 1, 1)
        self.borderRight:SetColorTexture(1, 1, 1, 1)
    end
    self.borderTop:ClearAllPoints()
    self.borderTop:SetPoint("TOPLEFT")
    self.borderTop:SetPoint("TOPRIGHT")
    self.borderTop:SetHeight(bdr)

    self.borderBottom:ClearAllPoints()
    self.borderBottom:SetPoint("BOTTOMLEFT")
    self.borderBottom:SetPoint("BOTTOMRIGHT")
    self.borderBottom:SetHeight(bdr)

    self.borderLeft:ClearAllPoints()
    self.borderLeft:SetPoint("TOPLEFT", self.visual, "TOPLEFT", 0, -bdr)
    self.borderLeft:SetPoint("BOTTOMLEFT", self.visual, "BOTTOMLEFT", 0, bdr)
    self.borderLeft:SetWidth(bdr)

    self.borderRight:ClearAllPoints()
    self.borderRight:SetPoint("TOPRIGHT", self.visual, "TOPRIGHT", 0, -bdr)
    self.borderRight:SetPoint("BOTTOMRIGHT", self.visual, "BOTTOMRIGHT", 0, bdr)
    self.borderRight:SetWidth(bdr)

    local br, bg, bb = style[2], style[3], style[4]
    self.borderTop:SetVertexColor(br, bg, bb)
    self.borderBottom:SetVertexColor(br, bg, bb)
    self.borderLeft:SetVertexColor(br, bg, bb)
    self.borderRight:SetVertexColor(br, bg, bb)

    -- ── Mount icon ──────────────────────────────────────────
    if not self.icon then
        self.icon = self.visual:CreateTexture(nil, "ARTWORK")
    end
    self.icon:ClearAllPoints()
    self.icon:SetPoint("TOPLEFT", self.visual, "TOPLEFT", bdr, -bdr)
    self.icon:SetPoint("BOTTOMRIGHT", self.visual, "BOTTOMRIGHT", -bdr, bdr)

    if mountData.icon then
        self.icon:SetTexture(mountData.icon)
    else
        self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- ── Source label badge ──────────────────────────────────
    if not self.badge then
        self.badge = self.visual:CreateFontString(nil, "OVERLAY")
        self.badge:SetPoint("BOTTOM", self.visual, "BOTTOM", 0, -2)
    end
    local badgeFontSize = math.max(9, math.floor(9 * scale + 0.5))
    self.badge:SetFont(STANDARD_TEXT_FONT, badgeFontSize, "OUTLINE")
    local label = style[5]
    if label and label ~= "" then
        self.badge:SetText(label)
        self.badge:SetTextColor(style[6], style[7], style[8], 1)
        self.badge:Show()
    else
        self.badge:SetText("")
        self.badge:Hide()
    end

    -- ── Desaturate if collected ─────────────────────────────
    if mountData.isCollected then
        self.icon:SetDesaturated(true)
        self.icon:SetAlpha(0.5)
        self.borderTop:SetAlpha(0.4)
        self.borderBottom:SetAlpha(0.4)
        self.borderLeft:SetAlpha(0.4)
        self.borderRight:SetAlpha(0.4)
        if self.badge then self.badge:SetAlpha(0.5) end
    else
        self.icon:SetDesaturated(false)
        self.icon:SetAlpha(1.0)
        self.borderTop:SetAlpha(1.0)
        self.borderBottom:SetAlpha(1.0)
        self.borderLeft:SetAlpha(1.0)
        self.borderRight:SetAlpha(1.0)
        if self.badge then self.badge:SetAlpha(1.0) end
    end

    -- ── Hover reference dot (stays when pin slides away) ───
    local dotSize = math.max(6, math.floor(6 * scale + 0.5))
    if not self.dot then
        self.dot = self:CreateTexture(nil, "ARTWORK")
        self.dot:SetPoint("CENTER")
    end
    self.dot:SetSize(dotSize, dotSize)
    self.dot:SetColorTexture(br, bg, bb, 0.9)
    self.dot:Hide()
end

function MCL_GuidePinMixin:OnReleased()
    self.mountData = nil
    self:SetScript("OnUpdate", nil)
    self._slidOut = false
    self._inCluster = false
    self:EnableMouse(true)
    if self.visual then
        self.visual:EnableMouse(false)
        self.visual:SetScript("OnEnter", nil)
        self.visual:SetScript("OnLeave", nil)
        self.visual:SetScript("OnClick", nil)
        self.visual:ClearAllPoints()
        self.visual:SetPoint("CENTER")
    end
    if self.dot then self.dot:Hide() end
end

-- ── Single-pin handlers (non-cluster) ───────────────────────
function MCL_GuidePinMixin:OnMouseEnter()
    if not self.mountData then return end

    -- Cancel any pending cluster collapse
    if clusterCollapseTimer then
        clusterCollapseTimer:Cancel()
        clusterCollapseTimer = nil
    end

    -- Collapse any previous cluster instantly
    if spreadActive then
        CollapseClusterImmediate()
    end

    -- Detect overlapping pins
    local cluster = FindClusterPins(self)

    if #cluster <= 1 then
        -- Isolated pin: slide left (tooltip appears on the right)
        self:SlideVisual(-1, 0, self:GetWidth() * SLIDE_DISTANCE_MULT)
        ShowMiniCard(self, self.mountData)
    else
        -- Multi-pin cluster: radial spread with interactive visuals
        SpreadCluster(cluster, self)
    end
end

function MCL_GuidePinMixin:OnMouseLeave()
    HideMiniCard()

    if not self._inCluster then
        self:SlideVisualBack()
    end
    -- Cluster stays open: collapse is handled by hovering a
    -- different mount pin, or by map change / close.
end

-- ── Visual slide animation ──────────────────────────────────
function MCL_GuidePinMixin:SlideVisual(dx, dy, dist)
    if self._slidOut then return end
    self._slidOut = true
    self._slideDist = dist
    self._slideDX = dx
    self._slideDY = dy

    if self.dot then self.dot:Show() end

    local elapsed = 0
    local vis = self.visual
    self:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / SLIDE_DURATION, 1)
        t = 1 - (1 - t) * (1 - t)  -- ease-out quadratic

        local offset = dist * t
        vis:ClearAllPoints()
        vis:SetPoint("CENTER", self, "CENTER", dx * offset, dy * offset)

        if t >= 1 then self:SetScript("OnUpdate", nil) end
    end)
end

function MCL_GuidePinMixin:SlideVisualBack()
    if not self._slidOut then return end
    self._slidOut = false

    local startDist = self._slideDist or 0
    local dx = self._slideDX or -1
    local dy = self._slideDY or 0

    if startDist == 0 then
        if self.dot then self.dot:Hide() end
        return
    end

    local elapsed = 0
    local vis = self.visual
    self:SetScript("OnUpdate", function(_, dt)
        elapsed = elapsed + dt
        local t = math.min(elapsed / SLIDE_DURATION, 1)
        t = t * t  -- ease-in quadratic

        local offset = startDist * (1 - t)
        vis:ClearAllPoints()
        vis:SetPoint("CENTER", self, "CENTER", dx * offset, dy * offset)

        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            vis:ClearAllPoints()
            vis:SetPoint("CENTER")
            if self.dot then self.dot:Hide() end
        end
    end)
end

-- ── Cluster detection & interactive radial spread ───────────

FindClusterPins = function(hoveredPin)
    local hx, hy = hoveredPin._canvasX, hoveredPin._canvasY
    if not hx then return { hoveredPin } end
    local comp = hoveredPin:GetScale()
    if comp <= 0 then comp = 1 end
    local threshold = hoveredPin:GetWidth() * comp * CLUSTER_OVERLAP_MULT
    local threshSq  = threshold * threshold
    local cluster = {}
    for _, pin in ipairs(activePins) do
        if pin:IsShown() and pin._canvasX then
            local ddx = pin._canvasX - hx
            local ddy = pin._canvasY - hy
            if (ddx * ddx + ddy * ddy) <= threshSq then
                cluster[#cluster + 1] = pin
            end
        end
    end
    return cluster
end

SpreadCluster = function(cluster, triggerPin)
    spreadActive = true
    wipe(spreadCluster)

    local n = #cluster
    local refPin  = cluster[1]
    local dist    = refPin:GetWidth() * SPREAD_RADIUS_MULT

    -- Record screen-space cluster centre for distance collapse
    local cScale = refPin:GetEffectiveScale()
    local cX, cY = refPin:GetCenter()
    if cX and cY then
        clusterCenterX = cX * cScale
        clusterCenterY = cY * cScale
        local uiScale = UIParent:GetEffectiveScale()
        clusterCenterX = clusterCenterX / uiScale
        clusterCenterY = clusterCenterY / uiScale
        local threshold = refPin:GetWidth() * cScale / uiScale * COLLAPSE_DIST_MULT
        clusterCollapseThreshSq = threshold * threshold
    end
    distanceWatcher:Show()

    -- ── Spread each pin ──────────────────────────────────────
    for i, pin in ipairs(cluster) do
        pin._inCluster = true
        spreadCluster[#spreadCluster + 1] = pin

        -- Disable the button's mouse so stacked buttons don't fight
        pin:EnableMouse(false)

        -- Enable the visual as an interactive element
        pin.visual:EnableMouse(true)
        pin.visual:SetFrameLevel(pin:GetFrameLevel() + 1)

        -- Per-pin closures for visual hover / click
        pin.visual:SetScript("OnEnter", function()
            if clusterCollapseTimer then
                clusterCollapseTimer:Cancel()
                clusterCollapseTimer = nil
            end
            ShowMiniCard(pin.visual, pin.mountData)
        end)
        pin.visual:SetScript("OnLeave", function()
            HideMiniCard()
        end)
        pin.visual:SetScript("OnClick", function(_, button)
            pin:OnClick(button)
        end)

        -- 180° arc to the left (π/2 → 3π/2), evenly spaced
        local angle = (math.pi / 2) + (math.pi * (i - 1)) / math.max(n - 1, 1)
        local dx = math.cos(angle)
        local dy = math.sin(angle)
        pin:SlideVisual(dx, dy, dist)
    end

    -- Show tooltip for the pin that triggered the spread
    if triggerPin and triggerPin.visual and triggerPin.mountData then
        ShowMiniCard(triggerPin.visual, triggerPin.mountData)
    end
end

CollapseCluster = function()
    spreadActive = false
    distanceWatcher:Hide()
    for _, pin in ipairs(spreadCluster) do
        pin._inCluster = false
        pin:EnableMouse(true)
        pin.visual:EnableMouse(false)
        pin.visual:SetScript("OnEnter", nil)
        pin.visual:SetScript("OnLeave", nil)
        pin.visual:SetScript("OnClick", nil)
        pin:SlideVisualBack()
    end
    wipe(spreadCluster)
end

CollapseClusterImmediate = function()
    spreadActive = false
    distanceWatcher:Hide()
    if clusterCollapseTimer then
        clusterCollapseTimer:Cancel()
        clusterCollapseTimer = nil
    end
    for _, pin in ipairs(spreadCluster) do
        pin._inCluster = false
        pin._slidOut = false
        pin:SetScript("OnUpdate", nil)
        pin:EnableMouse(true)
        pin.visual:EnableMouse(false)
        pin.visual:SetScript("OnEnter", nil)
        pin.visual:SetScript("OnLeave", nil)
        pin.visual:SetScript("OnClick", nil)
        if pin.visual then
            pin.visual:ClearAllPoints()
            pin.visual:SetPoint("CENTER")
        end
        if pin.dot then pin.dot:Hide() end
    end
    wipe(spreadCluster)
end

function MCL_GuidePinMixin:OnClick(button)
    if not self.mountData then return end
    if button == "RightButton" then
        HideMiniCard()
        -- Open mount card in the Legend Tab panel
        if Guide.MapPanel and Guide.MapPanel.ShowMountCard then
            Guide.MapPanel:ShowMountCard(self.mountData)
        elseif MCLcore and MCLcore.MountCard and MCLcore.MountCard.Show then
            local mountID = self.mountData.mountID
            if mountID then
                local card = MCLcore.MountCard.Show({
                    mountID = mountID,
                    id      = mountID,
                }, WorldMapFrame)
                if card then
                    card:ClearAllPoints()
                    card:SetPoint("TOPLEFT", WorldMapFrame, "TOPRIGHT", 4, 0)
                    card:SetFrameStrata("FULLSCREEN_DIALOG")
                    card:SetFrameLevel(500)
                end
            end
        end
    else
        Pins:PinMount(self.mountData)
    end
end

-- ─── Data Provider for WorldMapFrame ────────────────────────
local dataProvider = nil

-- Damping factor: 0 = pins stay perfectly constant regardless of
-- zoom, 1 = pins scale linearly with zoom (old behaviour).
-- 0.25 gives a subtle growth when zooming in.
local ZOOM_DAMPING = 0.25

local function ReleasePins()
    HideMiniCard()
    -- Clear cluster state first
    if spreadActive then
        CollapseClusterImmediate()
    end
    for _, pin in ipairs(activePins) do
        pin:Hide()
        pin:ClearAllPoints()
        pin:SetScript("OnUpdate", nil)
        pin._slidOut = false
        pin._inCluster = false
        pin:EnableMouse(true)
        if pin.visual then
            pin.visual:EnableMouse(false)
            pin.visual:SetScript("OnEnter", nil)
            pin.visual:SetScript("OnLeave", nil)
            pin.visual:SetScript("OnClick", nil)
            pin.visual:ClearAllPoints()
            pin.visual:SetPoint("CENTER")
        end
        if pin.dot then pin.dot:Hide() end
        pin.mountData = nil
        pin:SetScale(1)
        table.insert(pinPool, pin)
    end
    wipe(activePins)
end

local function AcquirePin(canvas)
    local pin = table.remove(pinPool)
    if not pin then
        pin = CreateFrame("Button", nil, canvas)
        pin:SetFrameStrata("TOOLTIP")
        pin:SetFrameLevel(2500)

        -- Mixin
        for k, v in pairs(MCL_GuidePinMixin) do
            pin[k] = v
        end
        pin:OnLoad()

        pin:RegisterForClicks("LeftButtonUp", "RightButtonDown")
        pin:SetScript("OnEnter", pin.OnMouseEnter)
        pin:SetScript("OnLeave", pin.OnMouseLeave)
        pin:SetScript("OnClick", pin.OnClick)

        -- Prevent mouse events from propagating to underlying map elements
        if pin.SetPropagateMouseMotion then
            pin:SetPropagateMouseMotion(false)
        end
        if pin.SetPropagateMouseClicks then
            pin:SetPropagateMouseClicks(false)
        end
    end
    pin:Show()
    table.insert(activePins, pin)
    return pin
end

-- ─── Compute the scale compensation for the current zoom ────
-- Returns a factor to apply via pin:SetScale() so that the pin
-- maintains a near-constant screen size.  With ZOOM_DAMPING the
-- pin grows *slightly* as you zoom in.
--
-- Formula: 1 / canvasScale^(1 - ZOOM_DAMPING)
--   damping=0   → 1/canvasScale      (perfectly constant)
--   damping=0.25→ 1/canvasScale^0.75 (subtle growth)
--   damping=1   → 1                  (old behaviour, scales 1:1)
local function GetPinScaleCompensation(canvas)
    local canvasScale = canvas and canvas:GetScale() or 1
    if canvasScale <= 0 then canvasScale = 1 end
    local exponent = 1 - ZOOM_DAMPING
    return 1 / (canvasScale ^ exponent)
end

-- ─── Re-apply scale to all visible pins (called on zoom) ────
local function UpdatePinScales()
    if #activePins == 0 then return end
    local canvas = activePins[1]:GetParent()
    local comp = GetPinScaleCompensation(canvas)
    for _, pin in ipairs(activePins) do
        pin:SetScale(comp)
        -- Reposition: SetScale changes how offsets are interpreted,
        -- so divide stored canvas-space coords by the scale factor
        pin:ClearAllPoints()
        pin:SetPoint("CENTER", canvas, "TOPLEFT",
            pin._canvasX / comp, pin._canvasY / comp)
    end
end

-- ─── Place a single pin on the canvas ───────────────────────
local function PlacePin(canvas, rec, fx, fy, canvasWidth, canvasHeight, scaleComp)
    local pin = AcquirePin(canvas)
    pin:OnAcquired(rec)

    -- Counteract canvas zoom so pins stay consistent
    pin:SetScale(scaleComp)

    -- Store unscaled canvas-space position for zoom updates
    local px = fx * canvasWidth
    local py = -fy * canvasHeight
    pin._canvasX = px
    pin._canvasY = py

    -- SetScale makes offsets act in scaled space,
    -- so divide by comp to keep world position correct
    pin:SetPoint("CENTER", canvas, "TOPLEFT",
        px / scaleComp, py / scaleComp)
end

-- ─── Refresh pins on the world map ──────────────────────────
function Pins:RefreshPins()
    if not Guide.ready then return end
    if not WorldMapFrame or not WorldMapFrame:IsShown() then return end

    ReleasePins()

    if not MCL_GUIDE_SETTINGS.showMapPins then return end

    local mapID = WorldMapFrame:GetMapID()
    if not mapID then return end

    local canvas = WorldMapFrame:GetCanvas()
    if not canvas then return end

    local canvasWidth  = canvas:GetWidth()
    local canvasHeight = canvas:GetHeight()
    local scaleComp = GetPinScaleCompensation(canvas)

    local showChildren = MCL_GUIDE_SETTINGS.showChildMapPins

    -- Build a set of geographic child map IDs for coord projection.
    -- Coords on child maps can be projected onto the parent map.
    local childMapSet = {}
    for _, childID in ipairs(Guide:GetAllChildMapIDs(mapID)) do
        childMapSet[childID] = true
    end

    -- Direct mounts for the current map
    local mounts = Guide:GetMountsForZone(mapID, showChildren)
    for _, rec in ipairs(mounts) do
        if rec.coords then
            for _, wp in ipairs(rec.coords) do
                if wp.x and wp.y then
                    if wp.m == mapID then
                        -- Pin on this exact map
                        PlacePin(canvas, rec, wp.x / 100, wp.y / 100,
                                 canvasWidth, canvasHeight, scaleComp)
                    elseif childMapSet[wp.m] then
                        -- Project child-map coord onto the parent via C_Map
                        local continentID, worldPos = C_Map.GetWorldPosFromMapPos(wp.m,
                            CreateVector2D(wp.x / 100, wp.y / 100))
                        if continentID and worldPos then
                            local _, vec = C_Map.GetMapPosFromWorldPos(continentID, worldPos, mapID)
                            if vec then
                                local fx, fy = vec:GetXY()
                                if fx >= 0 and fx <= 1 and fy >= 0 and fy <= 1 then
                                    PlacePin(canvas, rec, fx, fy,
                                             canvasWidth, canvasHeight, scaleComp)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ─── Hook into WorldMapFrame ────────────────────────────────
local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function()
    -- Hook map open/close and map ID changes
    if WorldMapFrame then
        hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
            C_Timer.After(0.1, function()
                Pins:RefreshPins()
            end)
        end)

        WorldMapFrame:HookScript("OnShow", function()
            C_Timer.After(0.1, function()
                Pins:RefreshPins()
            end)
        end)

        WorldMapFrame:HookScript("OnHide", function()
            HideMiniCard()
            ReleasePins()
            -- Also hide the full mount card if it was opened from a map pin
            if MCLcore and MCLcore.MountCard and MCLcore.MountCard.Hide then
                MCLcore.MountCard.Hide()
            end
        end)

        -- Track canvas zoom changes to keep pin sizes consistent
        local canvas = WorldMapFrame:GetCanvas()
        if canvas then
            hooksecurefunc(canvas, "SetScale", function()
                UpdatePinScales()
            end)
        end
    end
end)
