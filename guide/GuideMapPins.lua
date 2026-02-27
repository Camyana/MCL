-- =============================================================
-- GuideMapPins.lua  –  World map pin integration
--
-- Uses HereBeDragons-Pins or the native C_Map.SetUserWaypoint
-- API to place pins for mounts that have exact coordinates.
--
-- Also provides a data provider for the world map to show
-- small mount icons on the map itself.
-- =============================================================

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
        print("|cFF1FB7EBMCL|r Guide: No exact coordinates available for " .. (mountData.mountName or mountData.name))
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
    print("|cFF1FB7EBMCL|r Guide: Waypoint set for " .. (mountData.mountName or mountData.name) .. npcInfo
          .. " at " .. string.format("%.1f, %.1f", best.x, best.y))
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

-- ─── Pin sizing & colours by source type ────────────────────
local PIN_STYLES = {
    -- method        = { size, borderR, borderG, borderB, label, labelR, labelG, labelB }
    NPC              = { 36, 0.64, 0.21, 0.93, "Rare",   0.78, 0.43, 1.00 },
    BOSS             = { 36, 0.90, 0.49, 0.13, "Boss",   1.00, 0.65, 0.20 },
    ZONE             = { 36, 0.64, 0.21, 0.93, "Zone",   0.78, 0.43, 1.00 },
    VENDOR           = { 26, 0.85, 0.72, 0.26, "Vendor", 1.00, 0.84, 0.30 },
    QUEST            = { 30, 0.98, 0.82, 0.00, "Quest",  1.00, 0.90, 0.30 },
    FISHING          = { 28, 0.30, 0.70, 0.90, "Fish",   0.40, 0.80, 1.00 },
    USE              = { 30, 0.50, 0.80, 0.50, "Loot",   0.55, 0.90, 0.55 },
    SPECIAL          = { 30, 0.90, 0.80, 0.20, "Special",0.95, 0.85, 0.30 },
    MINING           = { 28, 0.70, 0.55, 0.35, "Mining", 0.80, 0.65, 0.40 },
    COLLECTION       = { 30, 0.40, 0.75, 0.95, "Collect",0.50, 0.85, 1.00 },
    ARCH             = { 28, 0.75, 0.60, 0.40, "Arch",   0.85, 0.70, 0.45 },
}
local DEFAULT_STYLE  = { 28, 0.50, 0.50, 0.50, "",       0.60, 0.60, 0.60 }

local MCL_GuidePinMixin = {}

function MCL_GuidePinMixin:OnLoad()
    self:SetFrameStrata("HIGH")
end

function MCL_GuidePinMixin:OnAcquired(mountData)
    self.mountData = mountData

    local style = PIN_STYLES[mountData.method] or DEFAULT_STYLE
    local scale = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.mapPinScale or 2.0
    local pinSize = math.floor(style[1] * scale + 0.5)

    -- Resize pin to match source type
    self:SetSize(pinSize, pinSize)

    -- ── Thin coloured edge border ──────────────────────────
    local bdr = math.max(2, math.floor(1.5 * scale + 0.5))
    if not self.borderTop then
        self.borderTop    = self:CreateTexture(nil, "OVERLAY")
        self.borderBottom = self:CreateTexture(nil, "OVERLAY")
        self.borderLeft   = self:CreateTexture(nil, "OVERLAY")
        self.borderRight  = self:CreateTexture(nil, "OVERLAY")
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
    self.borderLeft:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -bdr)
    self.borderLeft:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, bdr)
    self.borderLeft:SetWidth(bdr)

    self.borderRight:ClearAllPoints()
    self.borderRight:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, -bdr)
    self.borderRight:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, bdr)
    self.borderRight:SetWidth(bdr)

    local br, bg, bb = style[2], style[3], style[4]
    self.borderTop:SetVertexColor(br, bg, bb)
    self.borderBottom:SetVertexColor(br, bg, bb)
    self.borderLeft:SetVertexColor(br, bg, bb)
    self.borderRight:SetVertexColor(br, bg, bb)

    -- ── Mount icon ──────────────────────────────────────────
    if not self.icon then
        self.icon = self:CreateTexture(nil, "ARTWORK")
    end
    self.icon:ClearAllPoints()
    self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", bdr, -bdr)
    self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -bdr, bdr)

    if mountData.icon then
        self.icon:SetTexture(mountData.icon)
    else
        self.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- ── Source label badge ──────────────────────────────────
    if not self.badge then
        self.badge = self:CreateFontString(nil, "OVERLAY")
        self.badge:SetPoint("BOTTOM", self, "BOTTOM", 0, -2)
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
end

function MCL_GuidePinMixin:OnReleased()
    self.mountData = nil
end

function MCL_GuidePinMixin:OnMouseEnter()
    if not self.mountData then return end
    local data = self.mountData

    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine(data.mountName or data.name, 1, 1, 1)
    GameTooltip:AddLine(Guide:GetMethodText(data.method), 0.12, 0.72, 0.92)

    if data.chance then
        GameTooltip:AddLine("Drop chance: 1/" .. data.chance, 1, 1, 1)
    end
    if data.lockBossName then
        GameTooltip:AddLine("Boss: " .. data.lockBossName, 1, 0.82, 0)
    end

    -- NPC name from coords
    if data.coords then
        for _, wp in ipairs(data.coords) do
            if wp.n then
                GameTooltip:AddLine("NPC: " .. wp.n, 0.7, 0.7, 0.7)
                break
            end
        end
    end

    -- Reputation
    if data.rep then
        local repInfo = data.rep
        local label = repInfo.renown and "Renown" or "Reputation"
        local text = repInfo.factionName or "Unknown"
        if repInfo.levelName then
            text = text .. " — " .. repInfo.levelName
        end
        local liveText = Guide.Reputation and Guide.Reputation:GetStandingText(repInfo) or nil
        if liveText then
            text = text .. " (" .. liveText .. ")"
        end
        GameTooltip:AddLine(label .. ": " .. text, 0.6, 0.8, 1.0)
    end

    -- Vendor / Quartermaster location
    if data.vendorInfo then
        local vi = data.vendorInfo
        local vendorText = vi.npc or "Vendor"
        if vi.x and vi.y then
            vendorText = vendorText .. string.format(" (%.1f, %.1f)", vi.x, vi.y)
        end
        GameTooltip:AddLine("Vendor: " .. vendorText, 0.8, 0.7, 1.0)
    end

    -- Achievement
    if data.achievementId then
        local _, achName, _, achCompleted = GetAchievementInfo(data.achievementId)
        if achName then
            local achColor = achCompleted and "|cFF00FF00" or "|cFFFFFF00"
            local achStatus = achCompleted and " (Done)" or ""
            GameTooltip:AddLine("Achievement: " .. achColor .. achName .. achStatus .. "|r")
        end
    end

    -- Section + Category from MCL data
    local sec, cat = Pins:GetSectionInfo(data.mountID)
    if sec then
        local origin = sec
        if cat then origin = origin .. " > " .. cat end
        GameTooltip:AddLine("Origin: " .. origin, 0.6, 0.6, 0.6)
    end

    if data.isCollected then
        GameTooltip:AddLine("|cFF00FF00Collected|r")
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF00FF00Click to set waypoint|r")
    GameTooltip:Show()
end

function MCL_GuidePinMixin:OnMouseLeave()
    GameTooltip:Hide()
end

function MCL_GuidePinMixin:OnClick()
    if not self.mountData then return end
    Pins:PinMount(self.mountData)
end

-- ─── Data Provider for WorldMapFrame ────────────────────────
local dataProvider = nil
local pinPool = {}
local activePins = {}

-- Damping factor: 0 = pins stay perfectly constant regardless of
-- zoom, 1 = pins scale linearly with zoom (old behaviour).
-- 0.25 gives a subtle growth when zooming in.
local ZOOM_DAMPING = 0.25

local function ReleasePins()
    for _, pin in ipairs(activePins) do
        pin:Hide()
        pin:ClearAllPoints()
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
        pin:SetFrameStrata("HIGH")

        -- Mixin
        for k, v in pairs(MCL_GuidePinMixin) do
            pin[k] = v
        end
        pin:OnLoad()

        pin:RegisterForClicks("LeftButtonUp")
        pin:SetScript("OnEnter", pin.OnMouseEnter)
        pin:SetScript("OnLeave", pin.OnMouseLeave)
        pin:SetScript("OnClick", pin.OnClick)
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
            ReleasePins()
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
