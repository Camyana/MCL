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

-- Banner metrics.  No panel behind the whole thing: the models sit on
-- the world and only the name carries a solid bar.
local BANNER_W         = 370   -- fits three mount tiles side by side
local RARE_MODEL_W     = 180
local RARE_MODEL_H     = 108
local BAR_H            = 38
local BAR_PAD          = 18
local BAR_MIN_W        = 150
local MOUNT_MODEL      = 110
local MOUNT_GAP        = 10
local MOUNT_CAM        = 0.9   -- lower pulls the camera in, filling the tile
local MOUNT_LABEL_H    = 14
local MAX_MOUNT_MODELS = 3

local lookup      = nil     -- lowercased rare name → mount entries
local lastAlert   = {}      -- lowercased rare name → GetTime() of last alert
local scanTicker  = nil
local rsHooked    = false

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
function Alert:MountsFrom(rareName)
    if not rareName or rareName == "" then return nil end
    if not lookup then BuildLookup() end

    local entries = lookup[rareName:lower()]
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

-- Just the names, for the places that only want text.
local function MountNames(mounts)
    local names = {}
    for _, m in ipairs(mounts) do names[#names + 1] = m.name end
    return names
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

local function SaveBannerPosition()
    if not banner then return end
    local point, _, relPoint, x, y = banner:GetPoint()
    MCL_GUIDE_SETTINGS.rareAlertAnchor = { point = point, relPoint = relPoint, x = x, y = y }
end

local function GetBanner()
    if banner then return banner end

    local f = CreateFrame("Frame", "MCL_RareAlertBanner", UIParent, "BackdropTemplate")
    f:SetSize(BANNER_W, RARE_MODEL_H + BAR_H + 6 + MOUNT_MODEL + MOUNT_LABEL_H + 6)
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

    -- ── The rare, floating above the bar ────────────────────
    f.rareModel = CreateFrame("PlayerModel", nil, f)
    f.rareModel:SetSize(RARE_MODEL_W, RARE_MODEL_H)
    f.rareModel:SetPoint("TOP", f, "TOP", 0, 0)
    f.rareModel:SetPortraitZoom(0.85)

    -- Icon stand-in for when there's no model to show.
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(RARE_MODEL_H, RARE_MODEL_H)
    f.icon:SetPoint("TOP", f, "TOP", 0, 0)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.icon:Hide()

    -- ── The one solid element: the rare's name ──────────────
    -- Also the button: targeting by name has to go through a macro on a
    -- secure button, so the bar is one, with the marking and waypoint
    -- done afterwards in PostClick where normal code is allowed again.
    -- Centred and only as wide as the name needs, rather than spanning
    -- the banner: a short name shouldn't get a letterbox.
    f.bar = CreateFrame("Button", "MCL_RareAlertBar", f, "SecureActionButtonTemplate")
    f.bar:SetPoint("TOP", f, "TOP", 0, -RARE_MODEL_H)
    f.bar:SetSize(BAR_MIN_W, BAR_H)
    f.bar:RegisterForClicks("AnyUp")

    f.barBg = f.bar:CreateTexture(nil, "BACKGROUND")
    f.barBg:SetAllPoints()
    f.barBg:SetColorTexture(0.055, 0.055, 0.070, 0.94)

    f.barHighlight = f.bar:CreateTexture(nil, "HIGHLIGHT")
    f.barHighlight:SetAllPoints()
    f.barHighlight:SetColorTexture(1, 1, 1, 0.07)

    f.barTop = f.bar:CreateTexture(nil, "ARTWORK")
    f.barTop:SetPoint("TOPLEFT")
    f.barTop:SetPoint("TOPRIGHT")
    f.barTop:SetHeight(2)
    f.barTop:SetColorTexture(0.30, 0.66, 0.96, 1)

    f.barBottom = f.bar:CreateTexture(nil, "ARTWORK")
    f.barBottom:SetPoint("BOTTOMLEFT")
    f.barBottom:SetPoint("BOTTOMRIGHT")
    f.barBottom:SetHeight(1)
    f.barBottom:SetColorTexture(0.30, 0.66, 0.96, 0.35)

    -- Centred rather than stretched, so the bar can size itself to it.
    f.rare = f.bar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.rare:SetPoint("CENTER", f.bar, "CENTER", 0, 0)
    f.rare:SetJustifyH("CENTER")
    f.rare:SetWordWrap(false)
    f.rare:SetTextColor(1, 1, 1)

    -- Target via the macro, then mark and waypoint once it's ours.
    f.bar:SetScript("PostClick", function(self)
        local name = f.rareName
        if not name then return end

        if UnitExists("target") and UnitName("target") == name then
            SetRaidTarget("target", 8)   -- skull
        end

        local wp = f.rareWp
        if wp and wp.m and wp.x and wp.y then
            if not (C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(wp.m)) then
                C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(wp.m, wp.x / 100, wp.y / 100))
                C_SuperTrack.SetSuperTrackedUserWaypoint(true)
            end
        end
    end)

    -- The bar is the obvious thing to grab, so keep it draggable too.
    f.bar:RegisterForDrag("LeftButton")
    f.bar:SetScript("OnDragStart", function() f:StartMoving() end)
    f.bar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        SaveBannerPosition()
    end)

    f.bar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(f.rareName or "", 1, 1, 1)
        GameTooltip:AddLine("|cFF00FF00" .. L["Click to target and mark"] .. "|r")
        GameTooltip:Show()
    end)
    f.bar:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Only used when no mount can be modelled, so the names still show.
    f.mounts = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.mounts:SetPoint("TOP", f.bar, "BOTTOM", 0, -6)
    f.mounts:SetJustifyH("CENTER")
    f.mounts:SetWordWrap(false)
    f.mounts:SetTextColor(1.00, 0.82, 0.00)

    -- ── What's on offer, in the round ───────────────────────
    f.mountModels = {}

    f.fadeIn = f:CreateAnimationGroup()
    local ai = f.fadeIn:CreateAnimation("Alpha")
    ai:SetFromAlpha(0); ai:SetToAlpha(1); ai:SetDuration(0.25)
    f.fadeIn:SetScript("OnFinished", function() f:SetAlpha(1) end)

    f.fadeOut = f:CreateAnimationGroup()
    local ao = f.fadeOut:CreateAnimation("Alpha")
    ao:SetFromAlpha(1); ao:SetToAlpha(0); ao:SetDuration(0.5)
    f.fadeOut:SetScript("OnFinished", function() f:SetAlpha(0); f:Hide() end)

    -- Click it away if it's in the way.
    f:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            if bannerTimer then bannerTimer:Cancel(); bannerTimer = nil end
            self.fadeOut:Play()
        end
    end)

    local anchor = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareAlertAnchor
    if anchor and anchor.point then
        f:SetPoint(anchor.point, UIParent, anchor.relPoint or anchor.point, anchor.x or 0, anchor.y or 0)
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -190)
    end

    banner = f
    return f
end

-- Mount models under the bar, centred as a group so one mount sits in
-- the middle and two sit either side of it.
local function LayoutMountModels(f, mounts)
    local drawable = {}
    for _, m in ipairs(mounts) do
        if m.displayID and #drawable < MAX_MOUNT_MODELS then
            drawable[#drawable + 1] = m
        end
    end

    local count = #drawable
    local stride = MOUNT_MODEL + MOUNT_GAP
    local firstX = -((count - 1) * stride) / 2   -- centred on the banner

    for i, m in ipairs(drawable) do
        local tile = f.mountModels[i]
        if not tile then
            tile = CreateFrame("PlayerModel", nil, f)
            tile:SetSize(MOUNT_MODEL, MOUNT_MODEL)
            tile:SetCamDistanceScale(MOUNT_CAM)

            tile.label = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            tile.label:SetPoint("TOP", tile, "BOTTOM", 0, -2)
            tile.label:SetWidth(stride + 20)
            tile.label:SetJustifyH("CENTER")
            tile.label:SetWordWrap(false)
            tile.label:SetTextColor(1.00, 0.82, 0.00)

            f.mountModels[i] = tile
        end

        tile:ClearAllPoints()
        tile:SetPoint("TOP", f.bar, "BOTTOM", firstX + (i - 1) * stride, -6)

        pcall(tile.SetDisplayInfo, tile, m.displayID)
        tile:SetRotation(0.5)
        tile.label:SetText(m.name)
        tile:Show(); tile.label:Show()
    end

    for i = count + 1, #f.mountModels do
        local tile = f.mountModels[i]
        tile:Hide(); tile.label:Hide()
    end

    return count
end

local function ShowBanner(rareName, mounts, npcID)
    local f = GetBanner()

    -- The rare in the round if we know which creature it is, its mount's
    -- icon if not.
    local modelled = false
    if npcID and f.rareModel.SetCreature then
        modelled = pcall(f.rareModel.SetCreature, f.rareModel, npcID)
    end
    if modelled then
        f.rareModel:SetRotation(0.35)
        f.rareModel:Show()
        f.icon:Hide()
    else
        f.rareModel:ClearModel()
        f.rareModel:Hide()
        f.icon:SetTexture(mounts[1] and mounts[1].icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        f.icon:Show()
    end

    f.rare:SetText(rareName)
    -- Fit the bar to the name, within sensible bounds.
    local textW = math.ceil(f.rare:GetStringWidth())
    f.bar:SetWidth(math.max(BAR_MIN_W, math.min(textW + BAR_PAD * 2, BANNER_W)))

    -- What PostClick needs: who to target and mark, and where to point.
    f.rareName = rareName
    f.rareWp = nil
    if lookup then
        local entries = lookup[rareName:lower()]
        if entries and entries[1] then f.rareWp = entries[1].wp end
    end
    -- Secure attributes can't be touched in combat.  If the rare shows
    -- up mid-fight the bar still marks and waypoints on click (PostClick
    -- is ordinary code), it just can't do the targeting until the macro
    -- is applied on the way out of combat.
    if not InCombatLockdown() then
        f.bar:SetAttribute("type", "macro")
        f.bar:SetAttribute("macrotext", "/cleartarget\n/targetexact " .. rareName)
        f.pendingMacro = nil
    else
        f.pendingMacro = rareName
    end

    local tiles = LayoutMountModels(f, mounts)
    if tiles > 0 then
        -- The tiles are captioned, so the summary line would just repeat them.
        f.mounts:Hide()
        f:SetHeight(RARE_MODEL_H + BAR_H + 6 + MOUNT_MODEL + MOUNT_LABEL_H + 6)
    else
        f.mounts:SetText("|A:PetJournal-FavoritesIcon:12:12|a " .. table.concat(MountNames(mounts), ", "))
        f.mounts:Show()
        f:SetHeight(RARE_MODEL_H + BAR_H + 24)
    end

    if bannerTimer then bannerTimer:Cancel() end
    if f.fadeOut:IsPlaying() then f.fadeOut:Stop() end
    f:Show()
    f.fadeIn:Play()

    bannerTimer = C_Timer.NewTimer(8, function()
        bannerTimer = nil
        if f:IsShown() then f.fadeOut:Play() end
    end)
end

-- ─── Announcing ─────────────────────────────────────────────
local function Announce(rareName, mounts, npcID)
    local key = rareName:lower()
    local now = GetTime()
    if lastAlert[key] and (now - lastAlert[key]) < REALERT_AFTER then return end
    lastAlert[key] = now

    ShowBanner(rareName, mounts, npcID)

    print("|cFF1FB7EBMCL|r " .. string.format(L["%s is up - drops %s"],
        rareName, table.concat(MountNames(mounts), ", ")))
    PlaySound(SOUNDKIT.UI_WORLDQUEST_START, "Master")
end

-- ─── Standalone scanning ────────────────────────────────────
-- "Creature-0-1234-5678-9012-<npcID>-000ABC" — the sixth field is the
-- creature ID, which is what a model frame needs.
local function NpcIDFromGUID(guid)
    if not guid then return nil end
    local kind, _, _, _, _, id = strsplit("-", guid)
    if kind == "Creature" or kind == "Vehicle" then
        return tonumber(id)
    end
    return nil
end

local function CheckName(name, npcID)
    if not name then return end
    local mounts = Alert:MountsFrom(name)
    if mounts then Announce(name, mounts, npcID) end
end

local function ScanVignettes()
    if not C_VignetteInfo or not C_VignetteInfo.GetVignettes then return end
    local guids = C_VignetteInfo.GetVignettes()
    if not guids then return end
    for _, guid in ipairs(guids) do
        local info = C_VignetteInfo.GetVignetteInfo(guid)
        if info and info.name then
            CheckName(info.name, NpcIDFromGUID(info.objectGUID))
        end
    end
end

local function StartScanning()
    if scanTicker then return end
    scanTicker = C_Timer.NewTicker(SCAN_INTERVAL, ScanVignettes)
    ScanVignettes()
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
    local npcID = UnitExists("target") and NpcIDFromGUID(UnitGUID("target")) or nil
    ShowBanner(UnitExists("target") and UnitName("target") or "Coin-Eye Skully",
        { { name = "Ruby Writhe" }, { name = "Topaz Skyfang" } }, npcID)
    return false
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

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
events:RegisterEvent("VIGNETTES_UPDATED")
events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
events:SetScript("OnEvent", function(_, event, arg1)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Apply a macro that was blocked by combat.
        if banner and banner.pendingMacro then
            banner.bar:SetAttribute("type", "macro")
            banner.bar:SetAttribute("macrotext", "/cleartarget\n/targetexact " .. banner.pendingMacro)
            banner.pendingMacro = nil
        end
        return
    end

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        -- RareScanner may load after us, so settle first.
        C_Timer.After(2, function() Alert:Refresh() end)
        return
    end

    if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.rareMountAlerts == false then return end
    if Alert:UsingRareScanner() then return end

    if event == "NAME_PLATE_UNIT_ADDED" then
        -- Covers rares that never post a vignette.
        local unit = arg1
        if unit and UnitExists(unit) and not UnitIsPlayer(unit) then
            local classification = UnitClassification(unit)
            if classification == "rare" or classification == "rareelite" then
                CheckName(UnitName(unit), NpcIDFromGUID(UnitGUID(unit)))
            end
        end
        return
    end

    ScanVignettes()
end)
