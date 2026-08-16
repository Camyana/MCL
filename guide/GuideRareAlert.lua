-- =============================================================
-- GuideRareAlert.lua   "That rare drops a mount you don't have"
--
-- Rares that drop mounts are worth stopping for; the rest aren't.  This
-- watches for one showing up and says so.
--
-- Two modes, chosen automatically:
--
--   STANDALONE   With no rare scanner installed, MCL sweeps the
--                minimap vignettes every few seconds (plus nameplates,
--                for rares that don't post a vignette) and announces
--                anything that drops a mount still missing from the
--                collection.
--
--   RARESCANNER  RareScanner already does the detecting, and doing it
--                twice would mean two alerts for the same rare.  So the
--                sweep switches off entirely and instead its alert
--                button gains a tag naming the mount on offer.
--
-- Either way a rare is only worth flagging if the mount is uncollected
-- and the rare hasn't already given its daily kill credit.
-- =============================================================

local _, MCLcore = ...
local L = MCLcore.L or {}
local Guide = MCL_GUIDE

Guide.RareAlert = Guide.RareAlert or {}
local Alert = Guide.RareAlert

local SCAN_INTERVAL = 3     -- seconds between minimap sweeps
local REALERT_AFTER = 300   -- don't repeat the same rare inside this
local POI_RANGE     = 12    -- map units: roughly "in this part of the zone"
local ARRIVE_YARDS  = 40    -- close enough that the arrow has done its job

-- Banner metrics.  A card with the rare's model standing on top of it,
-- feet on the upper edge - above the card, never clipping into it, so
-- the card's own layout stays intact whatever the model does.
local BANNER_W       = 230   -- a notification, not a splash screen
local MODEL_W        = 150   -- the rare, framed to the bust
local MODEL_H        = 112
local MODEL_SINK     = 0     -- the model stands on the card, never in it
local PANEL_H        = 152   -- eyebrow + rules + name + line + reward + icons
local MOUNT_ICON     = 38
local MOUNT_ICON_GAP = 10
local MOUNT_ICON_PAD = 12    -- breathing room under the icon row
local CARD_PAD       = 14    -- inner margin: the card breathes
local MAX_MOUNT_ICONS = 4
local DEFAULT_SCALE  = 1.0   -- already small; no need to shrink it
local BANNER_LIFE    = 8     -- seconds on screen before it fades

local lookup      = nil     -- lowercased rare name → mount entries
local lastAlert   = {}      -- lowercased rare name → GetTime() of last alert
local scanTicker  = nil
local trackTicker = nil     -- runs only while a waypoint is being tracked
local rsHooked    = false

-- Midnight added "secret values": some unit calls hand back a value that
-- can't be read or compared, and touching one in a conditional throws.
-- RareScanner guards every unit call this way, so we do too.
local function plain(value)
    if issecretvalue and issecretvalue(value) then return nil end
    return value
end

-- ─── What drops from what ───────────────────────────────────
-- Rare coords are the ones carrying a per-day kill credit, plus the
-- single-rare NPC drops that have no pool.
local function BuildLookup()
    lookup = {}
    if not MCL_GUIDE_DATA or not MCL_GUIDE_DATA.mounts then return end

    for spellId, rec in pairs(MCL_GUIDE_DATA.mounts) do
        if type(rec) == "table" and rec.coords then
            for _, wp in ipairs(rec.coords) do
                if wp.n and (wp.dq or rec.method == "NPC") then
                    local key = wp.n:lower()
                    lookup[key] = lookup[key] or {}
                    table.insert(lookup[key], { spellId = spellId, name = rec.name, wp = wp })
                end
            end
        end
    end
end

local function IsCollected(spellId)
    local mountID = Guide.spellToMount and Guide.spellToMount[spellId]
    if not mountID then return false end
    local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(mountID)
    return collected
end

-- Returns the mounts this rare can still give you as
-- { {name=, icon=, mountID=}, ... }, or nil if there's nothing to stop for.
-- Names in the data have to match what the game calls the rare, exactly,
-- or the alert silently never fires - which is precisely what happened
-- with "Lockjaw" against the vignette's "Lockjaw the Snapper".  So a miss
-- falls back to a prefix match: a stored name that the sighted name
-- begins with, at a word boundary.  A shortened name still works; an
-- unrelated rare still doesn't.
local function Entries(rareName)
    local key = rareName:lower()
    local hit = lookup[key]
    if hit then return hit end

    for stored, entries in pairs(lookup) do
        if #stored < #key then
            local nextChar = key:sub(#stored + 1, #stored + 1)
            if key:sub(1, #stored) == stored and (nextChar == " " or nextChar == ",") then
                return entries
            end
        end
    end
    return nil
end

function Alert:MountsFrom(rareName)
    -- The other door names come through, alongside CheckName: callers
    -- pass UnitName straight in, and that can be a secret value.
    rareName = plain(rareName)
    if type(rareName) ~= "string" or rareName == "" then return nil end
    if not lookup then BuildLookup() end

    local entries = Entries(rareName)
    if not entries then return nil end

    local out, seen
    for _, e in ipairs(entries) do
        -- Already killed today means no loot today, so nothing to stop for.
        local _, doneToday = Guide:GetWaypointState(e.wp)
        if not doneToday and not IsCollected(e.spellId) then
            local mountID = Guide.spellToMount and Guide.spellToMount[e.spellId]
            local name, icon, displayID = e.name, nil, nil
            if mountID then
                local mName, _, mIcon = C_MountJournal.GetMountInfoByID(mountID)
                name = mName or name
                icon = mIcon
                -- First return is the creature display info, which is what
                -- a model frame wants.
                displayID = C_MountJournal.GetMountInfoExtraByID(mountID)
            end
            if name then
                seen = seen or {}
                if not seen[name] then
                    seen[name] = true
                    out = out or {}
                    table.insert(out, { name = name, icon = icon, mountID = mountID, displayID = displayID })
                end
            end
        end
    end
    return out
end

-- A unit under a player's control: their pet, their minion, anything
-- charmed.  Several ways to be one, and any of them means it isn't a
-- rare standing in the world waiting to be killed.
local function IsSomeonesPet(unit)
    if not unit then return false end
    if UnitPlayerControlled and plain(UnitPlayerControlled(unit)) then return true end
    if UnitIsOtherPlayersPet and plain(UnitIsOtherPlayersPet(unit)) then return true end
    if UnitIsUnit and plain(UnitIsUnit(unit, "pet")) then return true end
    return false
end

-- Ignoring is easy to do by accident and hard to notice afterwards - the
-- alert simply never comes again - so it asks first.  Un-ignoring needs
-- no confirmation: getting an alert back is self-announcing.
StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs["MCL_IGNORE_RARE"] = {
    text = "%s",
    button1 = YES,
    button2 = NO,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,   -- keeps it clear of Blizzard's taint-prone indices
    OnAccept = function(self, data)
        if not data then return end
        local ignored, shown = Alert:ToggleIgnore(data.name)
        if ignored then
            print("|cFF1FB7EBMCL|r " .. string.format(L["No longer alerting for %s."], shown))
        end
        if data.banner and data.banner:IsShown() then
            data.banner.fadeOut:Play()
        end
    end,
}

-- ─── Ignored rares ──────────────────────────────────────────
-- Tame a rare as a hunter pet and it walks around wearing its own name
-- for the rest of its life.  The pet check below handles that one, but
-- there are other reasons to want a particular rare to stop asking -
-- one you've given up on, or one that shares a name with something you
-- pass constantly.
local function IgnoreList()
    if not MCL_GUIDE_SETTINGS then return {} end
    MCL_GUIDE_SETTINGS.rareIgnored = MCL_GUIDE_SETTINGS.rareIgnored or {}
    return MCL_GUIDE_SETTINGS.rareIgnored
end

-- The settings panel shows this list, and had no way of knowing when it
-- changed - so it only ever looked right after a reload.  Anything that
-- edits the list calls this.
local function IgnoreChanged()
    if Alert.OnIgnoreChanged then
        local ok, err = pcall(Alert.OnIgnoreChanged)
        if not ok then Alert.OnIgnoreChanged = nil end   -- stale frame; stop calling it
    end
end

function Alert:IsIgnored(rareName)
    rareName = plain(rareName)
    if type(rareName) ~= "string" then return false end
    return IgnoreList()[rareName:lower()] and true or false
end

-- Returns the new state, so callers can report it without asking again.
function Alert:ToggleIgnore(rareName)
    rareName = plain(rareName)
    if type(rareName) ~= "string" or rareName == "" then return nil end

    local list = IgnoreList()
    local key = rareName:lower()
    if list[key] then
        list[key] = nil
        IgnoreChanged()
        return false, rareName
    end
    -- Stored with its display casing so the list reads properly later.
    list[key] = rareName
    IgnoreChanged()
    return true, rareName
end

function Alert:ListIgnored()
    local out = {}
    for _, shown in pairs(IgnoreList()) do out[#out + 1] = shown end
    table.sort(out)
    return out
end

function Alert:ClearIgnored()
    local n = #self:ListIgnored()
    if MCL_GUIDE_SETTINGS then MCL_GUIDE_SETTINGS.rareIgnored = {} end
    IgnoreChanged()
    return n
end

-- Diagnostics need to tell two very different silences apart: a rare we
-- have no record of at all, versus one we know whose mounts are already
-- collected or already looted today.  Both used to print "no mount".
function Alert:Verdict(rareName)
    rareName = plain(rareName)
    if type(rareName) ~= "string" or rareName == "" then return "|cFF888888unnamed|r" end
    if not lookup then BuildLookup() end
    local mounts = self:MountsFrom(rareName)
    if mounts then return "|cFF00FF00" .. #mounts .. " mount(s)|r" end
    if Entries(rareName) then return "|cFFFFD100known - collected or killed today|r" end
    return "|cFFFF6666not in MCL data|r"
end

-- Just the names, for the places that only want text.
local function MountNames(mounts)
    local names = {}
    for _, m in ipairs(mounts) do names[#names + 1] = m.name end
    return names
end

-- ─── Sound ──────────────────────────────────────────────────
-- A rare scanner beeps for every rare it sees.  This is the "and that
-- one has a mount on it" cue, so it has to cut through that rather than
-- blend into it: short, sharp, and not a sound the game already uses
-- for something routine.  The default is the alarm clock every alert
-- addon reaches for, because it works.
Alert.SOUNDS = {
    -- MCL's own: a struck bell arpeggio rising A5-E6-A6.  Bright and
    -- over in a second, so it reads as "something good is up" next to a
    -- scanner's generic beep rather than competing with it.
    { key = "mcl",     label = "MCL Alert",    file = "Interface\\AddOns\\MCL\\mount_alert.ogg" },
    { key = "alarm",   label = "Alarm Clock",  id = SOUNDKIT and SOUNDKIT.ALARM_CLOCK_WARNING_3 or 12867 },
    { key = "ready",   label = "Ready Check",  id = SOUNDKIT and SOUNDKIT.READY_CHECK or 8960 },
    { key = "epic",    label = "Epic Loot",    id = SOUNDKIT and SOUNDKIT.UI_EPICLOOT_TOAST or 31578 },
    { key = "raid",    label = "Raid Warning", id = SOUNDKIT and SOUNDKIT.RAID_WARNING or 8959 },
    { key = "levelup", label = "Level Up",     id = SOUNDKIT and SOUNDKIT.LEVELUP or 888 },
    { key = "quest",   label = "Quest Chime",  id = SOUNDKIT and SOUNDKIT.UI_WORLDQUEST_START or 73277 },
    { key = "collected", label = "MCL Collected", file = "Interface\\AddOns\\MCL\\collected.ogg" },
}

local DEFAULT_SOUND = "mcl"

function Alert:GetSoundKey()
    return (MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareAlertSoundKey) or DEFAULT_SOUND
end

function Alert:GetSound()
    local key = self:GetSoundKey()
    for _, s in ipairs(self.SOUNDS) do
        if s.key == key then return s end
    end
    return self.SOUNDS[1]
end

function Alert:SetSound(key, audition)
    MCL_GUIDE_SETTINGS.rareAlertSoundKey = key
    if audition then self:PlayCue(true) end
    return self:GetSound()
end

-- Step to the next sound and play it, so picking one is a matter of
-- listening rather than reading a list of names.
function Alert:CycleSound()
    local key = self:GetSoundKey()
    local nextIndex = 1
    for i, s in ipairs(self.SOUNDS) do
        if s.key == key then
            nextIndex = (i % #self.SOUNDS) + 1
            break
        end
    end
    return self:SetSound(self.SOUNDS[nextIndex].key, true)
end

function Alert:PlayCue(force)
    if not force and MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareAlertSound == false then return end
    local s = self:GetSound()
    if s.file then
        PlaySoundFile(s.file, "Master")
    else
        PlaySound(s.id, "Master")
    end
end

-- ─── The banner ─────────────────────────────────────────────
-- Blizzard's raid warning is red Friz Quadrata in the middle of the
-- screen and looks nothing like the rest of MCL.  This instead reads
-- top to bottom as the rare, its name, and what it owes you:
--
--        [ rare model ]          floating, no panel
--   ================================
--        Warden of Weeds is up      the one solid element
--   ================================
--        [mount]  [mount]        centred as a group
--         name     name
--
-- Only the name carries a background; the models sit on the world.
local banner, bannerTimer
local unlocked = false   -- parked open for positioning
local tracked  = nil     -- the rare our waypoint is pointing at

-- Where to send you for a given rare, worked out fresh each time.
--
-- Everything is judged against the map you are standing on: a coord from
-- another zone's copy of the same name is worse than useless, and a live
-- vignette position is only meaningful on the map it was read from.  A
-- stored coord on your map wins, then a live position on your map, then
-- whatever we have as a last resort.
local function ResolveRareSpot(name, live)
    local currentMap = Guide:GetCurrentMapID()

    if lookup and name then
        local entries = lookup[name:lower()]
        if entries then
            for _, e in ipairs(entries) do
                if e.wp and e.wp.m == currentMap then
                    -- Prefer the live position when it agrees about the
                    -- map: same spot, but where it is rather than where
                    -- it spawns.
                    if live and live.m == currentMap then return live end
                    return e.wp
                end
            end
        end
    end

    if live and live.m == currentMap then return live end

    if lookup and name then
        local entries = lookup[name:lower()]
        if entries and entries[1] then return entries[1].wp end
    end
    return nil
end

-- Only clear a waypoint we set, and only if it's still the one in
-- place — the player may well have pointed somewhere else since.
local function ClearTrackedWaypoint()
    if not tracked then return end

    local ours = true
    if C_Map.GetUserWaypoint then
        local point = C_Map.GetUserWaypoint()
        if not point then
            ours = false
        elseif point.uiMapID ~= tracked.m then
            ours = false
        elseif point.position then
            local px, py = point.position.x * 100, point.position.y * 100
            if math.abs(px - tracked.x) > 0.5 or math.abs(py - tracked.y) > 0.5 then
                ours = false
            end
        end
    end

    if ours then C_Map.ClearUserWaypoint() end
    tracked = nil
    if trackTicker then
        trackTicker:Cancel()
        trackTicker = nil
    end
end

local function SaveBannerPosition()
    if not banner then return end
    local point, _, relPoint, x, y = banner:GetPoint()
    MCL_GUIDE_SETTINGS.rareAlertAnchor = { point = point, relPoint = relPoint, x = x, y = y }
end

local function GetBanner()
    if banner then return banner end

    local f = CreateFrame("Frame", "MCL_RareAlertBanner", UIParent, "BackdropTemplate")
    f:SetSize(BANNER_W, MODEL_H - MODEL_SINK + PANEL_H)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveBannerPosition()
    end)
    f:SetAlpha(0)
    f:Hide()

    -- ── Panel ──
    -- Starts a full model-height down: the creature occupies the space
    -- above it rather than intruding on the card.
    f.panel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    f.panel:SetPoint("TOPLEFT", f, "TOPLEFT", 0, -(MODEL_H - MODEL_SINK))
    f.panel:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    f.panel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f.panel:SetBackdropColor(0.055, 0.055, 0.070, 0.96)
    -- Muted edge, so the cyan reads as emphasis rather than outline.
    f.panel:SetBackdropBorderColor(0.20, 0.23, 0.30, 0.95)

    -- A soft drop shadow.  Against a night zone the 1px border alone is
    -- all that separates near-black panel from near-black world.
    f.shadow = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    f.shadow:SetPoint("TOPLEFT", f.panel, "TOPLEFT", -5, 5)
    f.shadow:SetPoint("BOTTOMRIGHT", f.panel, "BOTTOMRIGHT", 5, -5)
    f.shadow:SetColorTexture(0, 0, 0, 0.45)

    -- A hairline above and below the name.  The title sits in its own
    -- register that way, which is what carries the layout: everything
    -- under the rules is detail, everything in them is the headline.
    local function Rule()
        local t = f.panel:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        t:SetColorTexture(0.32, 0.38, 0.47, 0.9)
        return t
    end
    f.ruleTop, f.ruleBottom = Rule(), Rule()

    -- ── The rare, standing on the card ──
    -- No frame, no ring: the model draws on transparency, so it reads as
    -- the creature itself standing on the card rather than a portrait in
    -- a box.
    f.rareModel = CreateFrame("PlayerModel", nil, f)
    f.rareModel:SetSize(MODEL_W, MODEL_H)
    -- Anchored by its feet to the card's top edge, so every creature
    -- stands on the card instead of floating at a fixed offset.
    f.rareModel:SetPoint("BOTTOM", f.panel, "TOP", 0, -MODEL_SINK)

    -- Icon stand-in when the creature can't be modelled.
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(48, 48)
    f.icon:SetPoint("BOTTOM", f.rareModel, "BOTTOM", 0, 4)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon:Hide()

    -- ── Text block ──
    -- The name is the headline, so the category goes above it as an
    -- eyebrow.  It also gives the close control's band something to sit
    -- against instead of a bare strip.
    f.eyebrow = f.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.eyebrow:SetPoint("TOPLEFT", f.panel, "TOPLEFT", CARD_PAD, -7)
    f.eyebrow:SetText((L["Rare Sighting"] or "Rare Sighting"):upper())
    f.eyebrow:SetTextColor(0.44, 0.51, 0.62)
    local ebFile, _, ebFlags = f.eyebrow:GetFont()
    f.eyebrow:SetFont(ebFile, 10, ebFlags)

    f.ruleTop:SetPoint("TOPLEFT", f.panel, "TOPLEFT", CARD_PAD, -(CARD_PAD + 8))
    f.ruleTop:SetPoint("TOPRIGHT", f.panel, "TOPRIGHT", -CARD_PAD, -(CARD_PAD + 8))

    f.rare = f.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.rare:SetPoint("TOP", f.ruleTop, "BOTTOM", 0, -7)
    f.rare:SetWidth(BANNER_W - CARD_PAD * 2 - 4)
    f.rare:SetJustifyH("CENTER")
    f.rare:SetWordWrap(false)
    f.rare:SetTextColor(0.30, 0.72, 0.96)
    local _, rareFontSize = f.rare:GetFont()
    f.rareFontSize = rareFontSize or 16

    f.ruleBottom:SetPoint("TOPLEFT", f.rare, "BOTTOMLEFT", 0, -7)
    f.ruleBottom:SetPoint("TOPRIGHT", f.rare, "BOTTOMRIGHT", 0, -7)

    f.sub = f.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.sub:SetPoint("TOP", f.ruleBottom, "BOTTOM", 0, -8)
    f.sub:SetJustifyH("CENTER")
    -- 10pt at 66% grey on near-black was the least readable thing on a
    -- card whose whole job is to be read at a glance.
    f.sub:SetTextColor(0.80, 0.84, 0.90)
    f.sub:SetText(L["Click to target"])
    local subFile, _, subFlags = f.sub:GetFont()
    f.sub:SetFont(subFile, 12, subFlags)

    f.reward = f.panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.reward:SetPoint("TOP", f.sub, "BOTTOM", 0, -5)
    f.reward:SetJustifyH("CENTER")
    f.reward:SetTextColor(1.00, 0.82, 0.00)
    -- The reward is why you're being interrupted; at the same size as the
    -- instruction it read as a footnote to it.
    local rwFile, _, rwFlags = f.reward:GetFont()
    f.reward:SetFont(rwFile, 14, rwFlags)

    -- A dismiss control, because right-clicking to close is only
    -- discoverable if somebody tells you about it.
    f.close = CreateFrame("Button", nil, f.panel)
    f.close:SetSize(20, 20)
    f.close:SetPoint("TOPRIGHT", f.panel, "TOPRIGHT", -2, -1)
    f.close.x = f.close:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.close.x:SetPoint("CENTER")
    f.close.x:SetText("×")
    f.close.x:SetTextColor(0.62, 0.67, 0.74)
    f.close:SetScript("OnEnter", function(self) self.x:SetTextColor(1, 1, 1) end)
    f.close:SetScript("OnLeave", function(self) self.x:SetTextColor(0.62, 0.67, 0.74) end)
    f.close:SetScript("OnClick", function()
        if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
        f.fadeOut:Play()
    end)

    -- The card leaves on its own after a few seconds.  A draining rule
    -- along the bottom edge says how long is left, so it going is a thing
    -- you watched happen rather than something you missed.
    f.life = f.panel:CreateTexture(nil, "OVERLAY")
    f.life:SetPoint("BOTTOMLEFT", f.panel, "BOTTOMLEFT", 1, 1)
    f.life:SetHeight(2)
    f.life:SetColorTexture(0.30, 0.66, 0.96, 0.75)
    f.life:Hide()

    f.mountIcons = {}

    -- The whole panel is the click target, so targeting and marking work
    -- from anywhere on it rather than one narrow bar.
    -- Covers the text block only, not the icon row: the icons are their
    -- own buttons for tooltips, and a button on top of a button means
    -- clicks near them vanish instead of targeting.
    f.bar = CreateFrame("Button", "MCL_RareAlertBar", f, "SecureActionButtonTemplate")
    f.bar:SetPoint("TOPLEFT", f.panel, "TOPLEFT", 1, -1)
    f.bar:SetPoint("BOTTOMRIGHT", f.panel, "BOTTOMRIGHT",
        -1, MOUNT_ICON + MOUNT_ICON_PAD + 8)
    f.bar:RegisterForClicks("AnyUp", "AnyDown")
    f.bar:SetFrameLevel(f.panel:GetFrameLevel() + 1)

    f.close:SetFrameLevel(f.bar:GetFrameLevel() + 1)

    f.barHighlight = f.bar:CreateTexture(nil, "HIGHLIGHT")
    f.barHighlight:SetAllPoints()
    f.barHighlight:SetColorTexture(1, 1, 1, 0.05)

    -- Right-click on the card: dismiss, or with shift, stop alerting for
    -- this rare.  Shared with the parent frame's handler so the gesture
    -- works anywhere on the alert, bar or not.
    local function RightClick(banner)
        local name = banner.rareName
        if IsShiftKeyDown() and name then
            if Alert:IsIgnored(name) then
                local _, shown = Alert:ToggleIgnore(name)
                print("|cFF1FB7EBMCL|r " .. string.format(L["Alerting for %s again."], shown))
            else
                if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
                StaticPopup_Show("MCL_IGNORE_RARE",
                    string.format(L["Stop alerting for %s?"], name),
                    nil, { name = name, banner = banner })
                return
            end
        end
        if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
        banner.fadeOut:Play()
    end
    f.RightClick = RightClick

    f.bar:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            RightClick(f)
            return
        end

        local name = f.rareName
        if not name then return end

        if not plain(UnitExists("target")) and not f.warnedRange then
            f.warnedRange = true
            print("|cFF1FB7EBMCL|r " .. L["Too far away to target that rare yet - waypoint set instead."])
        end

        local wp = ResolveRareSpot(name, f.rareLive)
        if wp and wp.m and wp.x and wp.y then
            if not (C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(wp.m)) then
                C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(wp.m, wp.x / 100, wp.y / 100))
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                tracked = { npcID = f.rareNpcID, name = name, m = wp.m, x = wp.x, y = wp.y }
                Alert:WatchTracked()
            end
        end
    end)

    f.bar:RegisterForDrag("LeftButton")
    f.bar:SetScript("OnDragStart", function() f:StartMoving() end)
    f.bar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SaveBannerPosition()
    end)

    f.bar:SetScript("OnEnter", function(self)
        -- Invisible means gone.  If the banner is ever left shown at zero
        -- alpha it is still mouse-live, and answering the hover would put
        -- a tooltip over empty screen.
        if f:GetAlpha() < 0.05 then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(f.rareName or "", 1, 1, 1)
        GameTooltip:AddLine("|cFF00FF00" .. L["Click to target"] .. "|r")
        GameTooltip:AddLine("|cFF888888" .. L["Shift-right-click to ignore this rare"] .. "|r")
        GameTooltip:Show()
    end)
    f.bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

    f.unlockHint = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.unlockHint:SetPoint("TOP", f, "BOTTOM", 0, -4)
    f.unlockHint:SetText("|cFF1FB7EB" .. L["Drag to position"] .. "|r")
    f.unlockHint:Hide()

    -- Model frames ignore parent alpha, so they're hidden outright when
    -- the banner goes rather than left hanging in mid-air.
    function f:HideModels()
        if self.rareModel then
            self.rareModel:ClearModel()
            self.rareModel:Hide()
        end
        if self.icon then self.icon:Hide() end
    end

    function f:ShowChrome() end

    -- A frame hidden while the cursor is on it never receives OnLeave, so
    -- whatever tooltip it was showing stays on screen with nothing under
    -- it - which reads as the alert still being there.  Cleanup hangs off
    -- OnHide rather than the fade's OnFinished, so it runs no matter what
    -- hid the banner: the fade, the close button, Lock(), or a reload.
    f:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        -- Whatever hid us, stop taking mouse input.  A frame left shown
        -- at zero alpha is invisible but still live, and the hover it
        -- answers looks exactly like an alert that never went away.
        if self.bar then self.bar:EnableMouse(false) end
        for _, btn in ipairs(self.mountIcons or {}) do btn:EnableMouse(false) end
        if self.life then self.life:Hide() end
        self:HideModels()

        local owner = GameTooltip:GetOwner()
        if owner then
            if owner == self.bar then
                GameTooltip:Hide()
            else
                for _, btn in ipairs(self.mountIcons or {}) do
                    if owner == btn then GameTooltip:Hide(); break end
                end
            end
        end
    end)

    f.fadeIn = f:CreateAnimationGroup()
    local ai = f.fadeIn:CreateAnimation("Alpha")
    ai:SetFromAlpha(0); ai:SetToAlpha(1); ai:SetDuration(0.25)
    f.fadeIn:SetScript("OnFinished", function() f:SetAlpha(1) end)

    f.fadeOut = f:CreateAnimationGroup()
    local ao = f.fadeOut:CreateAnimation("Alpha")
    ao:SetFromAlpha(1); ao:SetToAlpha(0); ao:SetDuration(0.5)
    f.fadeOut:SetScript("OnPlay", function() f:HideModels() end)
    f.fadeOut:SetScript("OnFinished", function()
        f:SetAlpha(0)
        f:Hide()   -- OnHide does the rest
    end)

    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then self.RightClick(self) end
    end)

    local anchor = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareAlertAnchor
    if anchor and anchor.point then
        f:SetPoint(anchor.point, UIParent, anchor.relPoint or anchor.point, anchor.x or 0, anchor.y or 0)
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -190)
    end

    f:SetScale((MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareAlertScale) or DEFAULT_SCALE)

    banner = f
    return f
end

-- ─── Position and size ───
function Alert:SetScale(scale)
    scale = math.max(0.4, math.min(scale or DEFAULT_SCALE, 2.0))
    MCL_GUIDE_SETTINGS.rareAlertScale = scale
    if banner then banner:SetScale(scale) end
    return scale
end

function Alert:GetScale()
    return (MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareAlertScale) or DEFAULT_SCALE
end

function Alert:ResetPosition()
    MCL_GUIDE_SETTINGS.rareAlertAnchor = nil
    if banner then
        banner:ClearAllPoints()
        banner:SetPoint("TOP", UIParent, "TOP", 0, -190)
    end
end

-- Unlocked, the banner stays put with a sample in it so it can be
-- dragged into place — the alerts themselves are too brief to aim.
function Alert:IsUnlocked()
    return unlocked
end

function Alert:Unlock()
    unlocked = true
    if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
    self:Preview()
    local f = GetBanner()
    f:SetAlpha(1)
    if f.unlockHint then f.unlockHint:Show() end
end

function Alert:Lock()
    unlocked = false
    local f = banner
    if not f then return end
    if f.unlockHint then f.unlockHint:Hide() end
    if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
    f:HideModels()
    f:Hide()
    f:SetAlpha(0)
end

function Alert:ToggleUnlock()
    if unlocked then self:Lock() else self:Unlock() end
    return unlocked
end

-- The mounts on offer, as their own icons in a row.  Icons rather than
-- models: at this size a model is an unreadable smudge, whereas the
-- icon is the exact art the journal uses, and it can carry a real mount
-- tooltip on hover.
local function LayoutMountIcons(f, mounts)
    local shown = 0
    for _, m in ipairs(mounts) do
        if shown < MAX_MOUNT_ICONS then
            shown = shown + 1
            local btn = f.mountIcons[shown]
            if not btn then
                btn = CreateFrame("Button", nil, f.panel)
                btn:SetSize(MOUNT_ICON, MOUNT_ICON)

                -- A well rather than a bare icon: thin muted border, dark
                -- interior, art inset a pixel.  Matches the card's edge
                -- so the row reads as part of the panel.
                btn.border = btn:CreateTexture(nil, "BACKGROUND")
                btn.border:SetAllPoints()
                btn.border:SetColorTexture(0.26, 0.31, 0.40, 1)

                btn.fill = btn:CreateTexture(nil, "BORDER")
                btn.fill:SetPoint("TOPLEFT", 1, -1)
                btn.fill:SetPoint("BOTTOMRIGHT", -1, 1)
                btn.fill:SetColorTexture(0.03, 0.03, 0.05, 1)

                btn.tex = btn:CreateTexture(nil, "ARTWORK")
                btn.tex:SetPoint("TOPLEFT", 3, -3)
                btn.tex:SetPoint("BOTTOMRIGHT", -3, 3)
                btn.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

                btn.glow = btn:CreateTexture(nil, "OVERLAY")
                btn.glow:SetAllPoints()
                btn.glow:SetColorTexture(0.30, 0.66, 0.96, 0)
                btn:SetScript("OnShow", function(self) self.glow:SetAlpha(0) end)

                btn:SetScript("OnEnter", function(self)
                    if f:GetAlpha() < 0.05 then return end
                    self.glow:SetColorTexture(0.30, 0.66, 0.96, 0.35)
                    -- The count summarises; hovering says which one.
                    if self.mountName then f.reward:SetText(self.mountName) end
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    -- The real mount tooltip when the client will give
                    -- us one, the name in gold when it won't.
                    local shownTip = false
                    if self.spellID then
                        if GameTooltip.SetMountBySpellID then
                            shownTip = pcall(GameTooltip.SetMountBySpellID, GameTooltip, self.spellID)
                        end
                        if not shownTip then
                            shownTip = pcall(GameTooltip.SetSpellByID, GameTooltip, self.spellID)
                        end
                    end
                    if not shownTip then
                        GameTooltip:AddLine(self.mountName or "", 1, 0.82, 0)
                    end
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF1FB7EBMCL|r  " .. L["Not Collected"], 1, 0.4, 0.4)
                    GameTooltip:Show()
                end)
                btn:SetScript("OnLeave", function(self)
                    self.glow:SetColorTexture(0.30, 0.66, 0.96, 0)
                    if f.rewardText then f.reward:SetText(f.rewardText) end
                    GameTooltip:Hide()
                end)

                f.mountIcons[shown] = btn
            end

            btn.mountName = m.name
            btn.spellID = nil
            if m.mountID then
                local _, spellID = C_MountJournal.GetMountInfoByID(m.mountID)
                btn.spellID = spellID
            end
            btn.tex:SetTexture(m.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
            btn:Show()
        end
    end

    for i = shown + 1, #f.mountIcons do
        f.mountIcons[i]:Hide()
    end

    -- Centre the row as a group.
    local stride = MOUNT_ICON + MOUNT_ICON_GAP
    local firstX = -((shown - 1) * stride) / 2
    for i = 1, shown do
        local btn = f.mountIcons[i]
        btn:ClearAllPoints()
        btn:SetPoint("TOP", f.reward, "BOTTOM", firstX + (i - 1) * stride, -10)
    end

    return shown
end

-- The unit token for a rare that's actually in front of you, if there is
-- one.  SetUnit gives the creature exactly as it stands in the world -
-- right model, right size - where SetCreature only has an ID to work
-- from.  plain() first: unit API returns can be secret values in 12.x,
-- and a secret compared against a name is not a usable answer.
local function UnitForRare(name)
    if not name then return nil end
    for _, u in ipairs({ "target", "mouseover", "focus" }) do
        if plain(UnitExists(u)) and plain(UnitName(u)) == name then return u end
    end
    for i = 1, 40 do
        local u = "nameplate" .. i
        if plain(UnitExists(u)) and plain(UnitName(u)) == name then return u end
    end
    return nil
end

-- Showing the rare is best-effort.  SetUnit is exact but needs the rare
-- loaded nearby; SetCreature works from an ID alone but streams the model
-- in asynchronously and quietly draws nothing for some creatures.  So the
-- request is re-issued a few times before giving up, because settling
-- after a single tick is what put a mount icon where the rare should be.
local function ShowRareModel(f, npcID, unit, rareName)
    local model = f.rareModel
    unit = unit or UnitForRare(rareName)

    -- Each sighting gets a token; a stale retry from the previous rare
    -- must not draw over the current one.
    f.modelToken = (f.modelToken or 0) + 1
    local token = f.modelToken

    local function request()
        model:ClearModel()
        if unit and plain(UnitExists(unit)) and model.SetUnit then
            if pcall(model.SetUnit, model, unit) then return true end
        end
        if npcID and model.SetCreature then
            return (pcall(model.SetCreature, model, npcID))
        end
        return false
    end

    local function arrived()
        if not model.GetModelFileID then return true end
        return model:GetModelFileID() ~= nil
    end

    local framed = false
    local function frame()
        -- Once only.  Show() itself fires OnModelLoaded, and that handler
        -- calls back in here - which recursed until the C stack blew.
        if framed then return end
        framed = true
        model:SetScript("OnModelLoaded", nil)

        -- Portrait framing, pulled back to a bust.  It is the only
        -- normalised framing the client offers: full body is scaled by
        -- each creature's own bounding box, so a long-tailed wyrm ends up
        -- a speck beside a humanoid, and the in-between values put the
        -- camera inside the geometry of anything large.
        -- Each call guarded: a camera API that has moved or gone in a
        -- patch would otherwise throw before Show() ever runs, leaving a
        -- blank box and, with error display off, no clue why.
        f.modelCam = pcall(function()
            model:SetPortraitZoom(1)
            model:SetCamDistanceScale(1.6)
            model:SetRotation(0.35)
        end)
        model:SetAlpha(1)
        model:Show()
        f.icon:Hide()
        f.modelFramed = true
    end

    local function fallback()
        model:ClearModel()
        model:Hide()
        -- A rare marker, deliberately, not the mount's icon: the space
        -- above the card is the creature, and a mount icon up there says
        -- the wrong thing about what you're looking at.
        if not pcall(f.icon.SetAtlas, f.icon, "VignetteKill") then
            f.icon:SetTexture("Interface\\Icons\\Ability_Hunter_MarkedForDeath")
            f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)   -- SetAtlas clears these
        end
        f.icon:Show()
    end

    -- The model tells us when it's ready, which beats guessing.
    model:SetScript("OnModelLoaded", function()
        if f.modelToken == token and f:IsShown() then frame() end
    end)

    f.modelFramed = false
    f.modelUnit = unit
    if not request() then
        f.modelTried = false
        fallback()
        return
    end
    f.modelTried = true
    if arrived() then frame() return end

    model:Hide()
    f.icon:Hide()

    local delays = { 0.1, 0.25, 0.5, 1.0 }
    local i = 0
    local function retry()
        if f.modelToken ~= token or not f:IsShown() then return end
        if arrived() then frame() return end
        i = i + 1
        if i > #delays then fallback() return end
        request()
        C_Timer.After(delays[i], retry)
    end
    C_Timer.After(delays[1], retry)
end

-- Rare names run long, and a headline that truncates to "KARI'ZAH THE
-- FORGO..." has failed at the one job it has.  Shrink to fit instead: a
-- smaller headline still reads, an ellipsis doesn't.
local function FitTitle(f)
    local file, _, flags = f.rare:GetFont()
    local maxW = BANNER_W - CARD_PAD * 2 - 4
    local size = f.rareFontSize or 16
    f.rare:SetFont(file, size, flags)
    while size > 10 and f.rare:GetStringWidth() > maxW do
        size = size - 1
        f.rare:SetFont(file, size, flags)
    end
end

local function ShowBanner(rareName, mounts, npcID, unit, livePos)
    local f = GetBanner()

    f:ShowChrome()
    ShowRareModel(f, npcID, unit, rareName)

    f.rare:SetText(rareName and rareName:upper() or "")
    FitTitle(f)

    -- The reward line is the reason you're being interrupted, so it gets
    -- its own line in gold rather than being inferred from the icons.
    local names = MountNames(mounts)
    if #names == 1 then
        f.rewardText = names[1]
    else
        f.rewardText = string.format(L["%d mounts available"], #names)
    end
    f.reward:SetText(f.rewardText)

    f.rareName = rareName
    f.rareNpcID = npcID
    f.rareLive = livePos
    f.warnedRange = nil   -- a new sighting deserves a fresh warning

    if not InCombatLockdown() then
        -- type1/macrotext1 rather than type/macrotext: the bar is
        -- registered for every button so it can catch right-clicks, and
        -- without this the targeting macro would fire on those too.
        f.bar:SetAttribute("type1", "macro")
        -- Targeting only.  SetRaidTarget is protected: run from a
        -- macro it still raises ADDON_ACTION_FORBIDDEN, so the skull
        -- was never going to land and the attempt only spammed the
        -- error log.
        f.bar:SetAttribute("macrotext1", "/targetexact " .. rareName)
        f.pendingMacro = nil
    else
        f.pendingMacro = rareName
    end

    local icons = LayoutMountIcons(f, mounts)
    f:SetHeight(MODEL_H - MODEL_SINK + PANEL_H
        + (icons > 0 and 0 or -(MOUNT_ICON + MOUNT_ICON_PAD)))

    if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
    if f.fadeOut:IsPlaying() then f.fadeOut:Stop() end

    -- Showing puts the mouse back; OnHide takes it away.
    f.bar:EnableMouse(true)
    for _, btn in ipairs(f.mountIcons or {}) do btn:EnableMouse(true) end
    f:Show()

    if unlocked then
        f:SetAlpha(1)
        f.life:Hide()
        f:SetScript("OnUpdate", nil)
        return
    end

    f.fadeIn:Play()

    local inner = BANNER_W - 2
    local expires = GetTime() + BANNER_LIFE
    f.life:SetWidth(inner)
    f.life:Show()
    f:SetScript("OnUpdate", function(self)
        local left = expires - GetTime()
        if left <= 0 then
            self.life:Hide()
            self:SetScript("OnUpdate", nil)
            return
        end
        self.life:SetWidth(inner * (left / BANNER_LIFE))
    end)

    bannerTimer = C_Timer.NewTimer(BANNER_LIFE, function()
        bannerTimer = nil
        if f:IsShown() then f.fadeOut:Play() end
    end)
end

-- ─── Announcing ─────────────────────────────────────────────
local function Announce(rareName, mounts, npcID, livePos)
    local key = rareName:lower()
    local now = GetTime()
    if lastAlert[key] and (now - lastAlert[key]) < REALERT_AFTER then
        -- Silence here looks identical to a detection failure, which is
        -- exactly the confusion watch mode exists to clear up.
        if Alert.watching then
            print(("|cFF1FB7EBMCL|r [held] %s - alerted %.0fs ago, quiet for another %.0fs")
                :format(rareName, now - lastAlert[key], REALERT_AFTER - (now - lastAlert[key])))
        end
        return
    end
    lastAlert[key] = now

    ShowBanner(rareName, mounts, npcID, nil, livePos)

    print("|cFF1FB7EBMCL|r " .. string.format(L["%s is up - drops %s"],
        rareName, table.concat(MountNames(mounts), ", ")))
    Alert:PlayCue()
end

-- ─── Standalone scanning ────────────────────────────────────
-- "Creature-0-1234-5678-9012-<npcID>-000ABC" — the sixth field is the
-- creature ID, which is what a model frame needs.
local function NpcIDFromGUID(guid)
    -- UnitGUID hands back a secret string in 12.x, and strsplit on one
    -- throws rather than returning nothing.  Fired from nameplate and
    -- target events, that is thousands of errors a session.  No GUID we
    -- can read means no npcID; the model falls back to the icon and
    -- everything else carries on off the name.
    guid = plain(guid)
    if type(guid) ~= "string" then return nil end

    local ok, kind, _, _, _, _, id = pcall(strsplit, "-", guid)
    if not ok then return nil end
    if kind == "Creature" or kind == "Vehicle" then
        return tonumber(id)
    end
    return nil
end

-- `unit` is set when the sighting came from a nameplate, a mouseover or
-- the target — the cases where we can act on it directly rather than
-- waiting for a click.
local function CheckName(name, npcID, unit, livePos)
    -- UnitName is a secret value for some units in 12.x, and every use
    -- below is a string operation that would throw on one.  This is the
    -- single door every detection path comes through, so the guard lives
    -- here rather than at each of the four call sites.
    name = plain(name)
    if type(name) ~= "string" or name == "" then return end
    -- A corpse is not an opportunity.  Anything already dead is skipped
    -- outright, whether we found it on a nameplate or under the cursor.
    if unit and plain(UnitIsDead(unit)) then return end

    -- Somebody's pet is not a rare, even when it used to be one.  A tamed
    -- rare keeps its name, so without this a hunter who tamed Oro'ohna
    -- gets told she's up every time her nameplate comes back.
    if unit and IsSomeonesPet(unit) then return end

    if Alert:IsIgnored(name) then return end

    local mounts = Alert:MountsFrom(name)
    if not mounts then return end

    Announce(name, mounts, npcID, livePos)
end

-- Watch mode: report everything the sweep sees, matched or not, so a
-- late alert can be pinned on the right thing - either the source never
-- carried the rare, or it did and the name didn't match.
local watchSeen = {}

local function Watch(source, name, matched)
    if not Alert.watching or not name then return end
    local key = source .. "|" .. name
    if watchSeen[key] then return end
    watchSeen[key] = true
    print(("|cFF1FB7EBMCL|r [%s] %s%s"):format(source, name,
        matched and " |cFF00FF00<- mount rare|r" or ""))
end

function Alert:ToggleWatch()
    self.watching = not self.watching
    wipe(watchSeen)
    print("|cFF1FB7EBMCL|r rare watch: " .. (self.watching
        and "ON - every vignette and POI the sweep sees will be listed once"
        or "OFF"))
    return self.watching
end

local function ScanVignettes()
    if not C_VignetteInfo or not C_VignetteInfo.GetVignettes then return end
    local guids = C_VignetteInfo.GetVignettes()
    if not guids then return end
    for _, guid in ipairs(guids) do
        local info = C_VignetteInfo.GetVignetteInfo(guid)
        if info and info.name then
            Watch("vignette", info.name, Alert:MountsFrom(info.name) ~= nil)

            -- The vignette knows where it is right now, which beats a
            -- stored spawn point for anything that patrols.
            local livePos
            local mapID = Guide:GetCurrentMapID()
            if mapID and C_VignetteInfo.GetVignettePosition then
                local vec = C_VignetteInfo.GetVignettePosition(guid, mapID)
                if vec then
                    local vx, vy = vec:GetXY()
                    if vx and vy then
                        livePos = { m = mapID, x = vx * 100, y = vy * 100 }
                    end
                end
            end
            CheckName(info.name, NpcIDFromGUID(info.objectGUID), nil, livePos)
        end
    end
end

-- Every nameplate currently up, not just ones that raised an event.
-- Events can be missed - the plate may already have existed when the
-- zone loaded, or when the alerts were switched on - and this is the
-- pass that puts a skull on a rare you simply walked up to.
local function ScanNameplates()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = plate and plate.namePlateUnitToken
        if unit and plain(UnitExists(unit)) and not plain(UnitIsPlayer(unit))
            and not plain(UnitIsDead(unit)) then
            CheckName(UnitName(unit), NpcIDFromGUID(UnitGUID(unit)), unit)
        end
    end
end

-- Not every rare posts a vignette - Hisstara doesn't, even standing next
-- to it - but many are area POIs on the zone map, which is what puts
-- them on the minimap.  This is the source that gives warning at range.
local function ScanAreaPOIs()
    if not C_AreaPoiInfo or not C_AreaPoiInfo.GetAreaPOIForMap then return end
    local mapID = Guide:GetCurrentMapID()
    if not mapID then return end

    local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
    if not pois then return end

    -- POIs cover the whole map, and on a continent-sized one that means
    -- rares in zones you aren't in.  Being told about something a flight
    -- away is worse than not being told: check it's actually near you.
    local me = C_Map.GetPlayerMapPosition(mapID, "player")
    local px, py = me and me.x, me and me.y

    for _, poiID in ipairs(pois) do
        local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
        if info and info.name then
            local near = true
            if px and info.position then
                local ix, iy = info.position.x, info.position.y
                if ix and iy then
                    local dx, dy = (ix - px) * 100, (iy - py) * 100
                    near = (dx * dx + dy * dy) <= (POI_RANGE * POI_RANGE)
                end
            end
            if near then
                Watch("areapoi", info.name, Alert:MountsFrom(info.name) ~= nil)
                CheckName(info.name)
            end
        end
    end
end

-- Death, without the combat log.  Registering for it is protected now,
-- so instead: a rare whose daily credit has landed is one we just
-- killed, and a corpse on a nameplate is one someone else did.  Both
-- mean the waypoint is clutter and the alert should stay quiet.
local function NoticeDeaths()
    if tracked and tracked.name and not Alert:MountsFrom(tracked.name) then
        ClearTrackedWaypoint()
        if banner and banner:IsShown() and not unlocked then
            if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
            banner.fadeOut:Play()
        end
    end

    if not C_NamePlate or not C_NamePlate.GetNamePlates then return end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = plate and plate.namePlateUnitToken
        if unit and plain(UnitExists(unit)) and plain(UnitIsDead(unit)) then
            local name = plain(UnitName(unit))
            if name and lookup and lookup[name:lower()] then
                lastAlert[name:lower()] = GetTime()   -- hush until it respawns
            end
            -- Somebody else's kill still ends the trip.  The daily credit
            -- never lands in that case, so the corpse is the only signal.
            if name and tracked and tracked.name
                and name:lower() == tracked.name:lower() then
                ClearTrackedWaypoint()
            end
        end
    end
end

-- Arriving is as good a reason to drop the waypoint as killing it: the
-- rare is in front of you and the arrow is pointing at your feet.
local function NoticeArrival()
    if not tracked then return end
    if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareClearWaypoint == false then return end

    -- The navigation distance is in yards and accounts for the route, so
    -- it's the honest answer when the arrow is tracking our waypoint.
    local dist = C_Navigation and C_Navigation.GetDistance and C_Navigation.GetDistance()
    if type(dist) == "number" and dist > 0 then
        if dist <= ARRIVE_YARDS then ClearTrackedWaypoint() end
        return
    end

    -- Without it, fall back to map coordinates.  Those are zone-relative
    -- rather than yards, so the threshold has to be loose enough to work
    -- in a large zone and is correspondingly generous in a small one.
    local map = Guide.GetCurrentMapID and Guide:GetCurrentMapID()
    if not map or map ~= tracked.m then return end
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return end
    local px, py = pos:GetXY()
    if not px or not py then return end
    if math.abs(px * 100 - tracked.x) <= 1.0
        and math.abs(py * 100 - tracked.y) <= 1.0 then
        ClearTrackedWaypoint()
    end
end

-- Watching costs a distance check a second, and only while a waypoint of
-- ours is actually in place.  It can't ride on the sweep: with a rare
-- scanner installed the sweep doesn't run at all.
function Alert:WatchTracked()
    if trackTicker then return end
    trackTicker = C_Timer.NewTicker(1, function()
        if not tracked then
            if trackTicker then trackTicker:Cancel(); trackTicker = nil end
            return
        end
        NoticeArrival()
    end)
end

local function Sweep()
    ScanVignettes()
    ScanAreaPOIs()
    NoticeDeaths()
    NoticeArrival()
    ScanNameplates()
    -- The target counts too: you may have clicked it before we ever saw it.
    if plain(UnitExists("target")) and not plain(UnitIsPlayer("target"))
        and not plain(UnitIsDead("target")) then
        CheckName(UnitName("target"), NpcIDFromGUID(UnitGUID("target")), "target")
    end
end

local function StartScanning()
    if scanTicker then return end
    scanTicker = C_Timer.NewTicker(SCAN_INTERVAL, Sweep)
    Sweep()
end

local function StopScanning()
    if scanTicker then
        scanTicker:Cancel()
        scanTicker = nil
    end
end

-- ─── RareScanner integration ────────────────────────────────
-- Their button already tells you a rare is up; all it's missing is
-- whether it's one you actually need.  Tag it when it is.
local function HookRareScanner()
    if rsHooked then return false end

    local btn = _G["RARESCANNER_BUTTON"]
    if not btn or type(btn.ShowButton) ~= "function" then return false end

    -- Their layout has the model above the button and the loot bar
    -- directly below, so a floating tag would land on one or the other.
    -- The description line inside the button is free real estate, and
    -- ShowButton has already set it by the time this hook runs.
    hooksecurefunc(btn, "ShowButton", function(self)
        if not self.Description_text then return end
        if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareMountAlerts == false then return end

        local mounts = Alert:MountsFrom(self.name)
        if not mounts then return end

        -- RareScanner beeps for every rare it finds; this is the extra
        -- cue that says this one is actually worth breaking off for.
        Alert:PlayCue()

        -- Atlas markup rather than a unicode star: the description uses
        -- GameFontWhiteTiny, which has no glyph for one and renders a box.
        local base = self.Description_text:GetText() or ""
        self.Description_text:SetText(base .. "  |A:PetJournal-FavoritesIcon:12:12|a|cFFFFD100" .. L["Mount"] .. "|r")

        -- The names go on the tooltip rather than the button, where a
        -- long mount name would overflow a 200px line.
        if not self.mclTooltipHooked then
            self.mclTooltipHooked = true
            self:HookScript("OnEnter", function(s)
                local list = Alert:MountsFrom(s.name)
                if list and GameTooltip:IsShown() then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("|cFF1FB7EBMCL|r  " .. L["Mount"] .. ": " .. table.concat(MountNames(list), ", "), 1, 0.82, 0)
                    GameTooltip:Show()
                end
            end)
        end
    end)

    rsHooked = true
    return true
end

-- ─── Wiring ─────────────────────────────────────────────────
-- Preview the banner without waiting for a rare to actually show up.
-- Uses a real rare you still need if there is one, so what you see is
-- what you'll get.
function Alert:Preview()
    if not lookup then BuildLookup() end
    for rareName in pairs(lookup) do
        local mounts = self:MountsFrom(rareName)
        if mounts then
            -- lookup keys are lowercased; take the display name off the coord
            local entry = lookup[rareName][1]
            ShowBanner(entry.wp.n or rareName, mounts)
            return true
        end
    end
    -- Nothing outstanding: preview with whatever the player is looking
    -- at, so the model frame still has something to draw.
    local haveTarget = plain(UnitExists("target"))
    local npcID = haveTarget and NpcIDFromGUID(UnitGUID("target")) or nil
    ShowBanner((haveTarget and plain(UnitName("target"))) or "Coin-Eye Skully",
        { { name = "Ruby Writhe" }, { name = "Topaz Skyfang" } }, npcID)
    return false
end

-- Detection is the part that can't be tested from outside the game, so
-- this reports exactly what the sweep can see right now.
function Alert:Debug()
    if not lookup then BuildLookup() end

    local count = 0
    for _ in pairs(lookup) do count = count + 1 end

    print("|cFF1FB7EBMCL|r rare alerts:")
    print(("  mode: %s"):format(self:UsingRareScanner() and "RareScanner (our sweep is off)" or "standalone"))
    print(("  enabled: %s   sweep running: %s"):format(
        tostring(MCL_GUIDE_SETTINGS.rareMountAlerts ~= false), tostring(scanTicker ~= nil)))
    print(("  rares known: %d"):format(count))

    local guids = C_VignetteInfo and C_VignetteInfo.GetVignettes and C_VignetteInfo.GetVignettes()
    if not guids or #guids == 0 then
        print("  minimap vignettes: none in range")
    else
        print(("  minimap vignettes: %d"):format(#guids))
        for _, guid in ipairs(guids) do
            local info = C_VignetteInfo.GetVignetteInfo(guid)
            if info then
                print(("    %s - %s"):format(info.name or "?", self:Verdict(info.name)))
            end
        end
    end

    -- Area POIs: what puts a rare on the minimap when it has no vignette.
    local mapID = Guide:GetCurrentMapID()
    local pois = mapID and C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap
        and C_AreaPoiInfo.GetAreaPOIForMap(mapID)
    if not pois or #pois == 0 then
        print("  area POIs: none on this map")
    else
        print(("  area POIs: %d"):format(#pois))
        for _, poiID in ipairs(pois) do
            local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
            if info and info.name then
                print(("    %s - %s"):format(info.name, self:Verdict(info.name)))
            end
        end
    end

    if plain(UnitExists("target")) then
        local targetName = plain(UnitName("target")) or "<secret>"
        local mounts = self:MountsFrom(targetName)
        print(("  target: %s - %s"):format(targetName,
            mounts and ("|cFF00FF00" .. #mounts .. " mount(s)|r") or "|cFF888888no match|r"))

        if banner then
            print(("  banner: shown=%s alpha=%.2f mouse=%s fading=%s"):format(
                tostring(banner:IsShown()), banner:GetAlpha(),
                tostring(banner:IsMouseEnabled()),
                tostring(banner.fadeOut and banner.fadeOut:IsPlaying())))
            if banner.bar then
                print(("  bar:    shown=%s mouse=%s over=%s"):format(
                    tostring(banner.bar:IsShown()),
                    tostring(banner.bar:IsMouseEnabled()),
                    tostring(banner.bar:IsMouseOver())))
            end
            print(("  timer:  %s   unlocked=%s"):format(
                tostring(bannerTimer ~= nil), tostring(unlocked)))
        end
        if banner and banner.rareModel then
            local m = banner.rareModel
            print(("  model: unit=%s tried=%s framed=%s cam=%s shown=%s file=%s"):format(
                tostring(banner.modelUnit), tostring(banner.modelTried),
                tostring(banner.modelFramed), tostring(banner.modelCam),
                tostring(m:IsShown()),
                tostring(m.GetModelFileID and m:GetModelFileID())))
            print(("         size=%dx%d alpha=%.2f npcID=%s"):format(
                m:GetWidth(), m:GetHeight(), m:GetAlpha(),
                tostring(banner.rareNpcID)))
        end
        if banner and banner.bar then
            local mt = banner.bar:GetAttribute("macrotext1")
            print(("  alert macro: %s"):format(mt and "armed" or "|cFFFF6666not set|r"))
            if mt then
                print(("    %s"):format((mt:gsub("\n", " | "))))
            end
        else
            print("  alert macro: banner has never been shown")
        end
    else
        print("  target: none - target the rare and run this again")
    end
end

function Alert:UsingRareScanner()
    return C_AddOns and C_AddOns.IsAddOnLoaded and C_AddOns.IsAddOnLoaded("RareScanner") or false
end

function Alert:Refresh()
    lookup = nil    -- rebuilt lazily; collected state is read live

    if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareMountAlerts == false then
        StopScanning()
        return
    end

    if self:UsingRareScanner() then
        -- Let RareScanner do the finding, and don't double up on alerts.
        StopScanning()
        HookRareScanner()
    else
        StartScanning()
    end
end

-- Registered one at a time and guarded: Midnight has made some events
-- protected (COMBAT_LOG_EVENT_UNFILTERED among them), and a blocked
-- call throws out of the main chunk - taking every registration after
-- it with it, which silently disables the whole module.
local events = CreateFrame("Frame")

local function Listen(event)
    local ok = pcall(events.RegisterEvent, events, event)
    if not ok then
        print(("|cFF1FB7EBMCL|r rare alerts: the game won't allow listening for %s"):format(event))
    end
    return ok
end

Listen("PLAYER_REGEN_ENABLED")
Listen("PLAYER_LOGIN")
Listen("PLAYER_ENTERING_WORLD")
Listen("VIGNETTE_MINIMAP_UPDATED")
Listen("VIGNETTES_UPDATED")
Listen("NAME_PLATE_UNIT_ADDED")
Listen("UPDATE_MOUSEOVER_UNIT")
Listen("PLAYER_TARGET_CHANGED")
Listen("CHAT_MSG_MONSTER_YELL")
Listen("CHAT_MSG_MONSTER_EMOTE")
Listen("NAME_PLATE_UNIT_REMOVED")
events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Apply a macro that was blocked by combat.
        if banner and banner.pendingMacro then
            banner.bar:SetAttribute("type1", "macro")
            banner.bar:SetAttribute("macrotext1",
                "/targetexact " .. banner.pendingMacro)
            banner.pendingMacro = nil
        end
        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- RareScanner may load after us, so settle first.
        C_Timer.After(2, function() Alert:Refresh() end)
        return
    end

    if event == "NAME_PLATE_UNIT_REMOVED" then
        return
    end

    if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareMountAlerts == false then return end
    if Alert:UsingRareScanner() then return end

    -- Plenty of rares announce themselves on spawn, which beats every
    -- other source for warning: the yell carries further than the
    -- minimap and lands the moment they appear.  arg2 is the speaker.
    if event == "CHAT_MSG_MONSTER_YELL" or event == "CHAT_MSG_MONSTER_EMOTE" then
        CheckName(arg2)
        return
    end

    -- Unit-based paths: a nameplate appearing, something moused over, or
    -- something targeted.  No classification test — the name being in the
    -- rare table is a stronger check than UnitClassification, which not
    -- every rare reports the way you'd expect.
    if event == "NAME_PLATE_UNIT_ADDED" or event == "UPDATE_MOUSEOVER_UNIT"
       or event == "PLAYER_TARGET_CHANGED" then
        local unit = arg1
        if event == "UPDATE_MOUSEOVER_UNIT" then unit = "mouseover" end
        if event == "PLAYER_TARGET_CHANGED" then unit = "target" end
        if unit and plain(UnitExists(unit)) and not plain(UnitIsPlayer(unit))
           and not plain(UnitIsDead(unit)) then
            CheckName(UnitName(unit), NpcIDFromGUID(UnitGUID(unit)), unit)
        end
        return
    end

    Sweep()
end)
