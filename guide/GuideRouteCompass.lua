-- =============================================================
-- GuideRouteCompass.lua   "which way is the next stop"
--
-- The world map shows the whole loop, but you don't run a route with the
-- map open.  This puts a line on the minimap pointing at the stop you're
-- currently headed for, so the direction is available at a glance while
-- you're actually moving.
--
-- Only the direction, deliberately: the distance is already on the
-- waypoint arrow, and a second number competing with it would just be
-- noise.
-- =============================================================

local _, MCLcore = ...
local Guide = MCL_GUIDE

Guide.RouteCompass = Guide.RouteCompass or {}
local Compass = Guide.RouteCompass

local UPDATE_INTERVAL = 0.1   -- smooth enough to read while turning
local EDGE_INSET      = 9     -- keep the tip inside the minimap's rim
local INNER_GAP       = 14    -- leave the centre clear of the player blip

local frame, line, tip, ticker

-- ─── Geometry ───────────────────────────────────────────────
-- Map coordinates are normalised over the zone's bounding box, and that
-- box is not square: a step of 0.1 across is a different number of yards
-- from a step of 0.1 down.  Taking the direction straight from those
-- deltas skews the angle by the zone's aspect ratio, which is why the
-- line pointed near the waypoint rather than at it.
--
-- The fix needs the zone's scale, not its orientation.  On a north-up
-- map, map-x already runs east and map-y already runs south, so the only
-- thing wrong is that a unit of each is a different number of yards.
--
-- That scale is measured rather than assumed: two short probes across
-- the zone, compared by distance.  Distance doesn't care which world
-- axis is north, so there is no convention here to get backwards.
local mapScaleFor, mapScaleX, mapScaleY = nil, 1, 1

local function WorldPos(map, nx, ny)
    if not (C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local ok, _, world = pcall(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(nx, ny))
    if not ok or not world then return nil end
    return world:GetXY()
end

local function Separation(map, x1, y1, x2, y2)
    local ax, ay = WorldPos(map, x1, y1)
    local bx, by = WorldPos(map, x2, y2)
    if not ax or not bx then return nil end
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

local function MapScale(map)
    if mapScaleFor == map then return mapScaleX, mapScaleY end

    local across = Separation(map, 0.4, 0.5, 0.6, 0.5)   -- yards per 0.2 of map-x
    local down   = Separation(map, 0.5, 0.4, 0.5, 0.6)   -- yards per 0.2 of map-y
    if across and down and across > 0 and down > 0 then
        mapScaleX, mapScaleY = across, down
    else
        mapScaleX, mapScaleY = 1, 1
    end
    mapScaleFor = map
    return mapScaleX, mapScaleY
end

local function DirectionTo(stop)
    if not stop or not stop.m or not stop.x or not stop.y then return nil end

    local map = Guide.GetCurrentMapID and Guide:GetCurrentMapID()
    if not map or map ~= stop.m then return nil end

    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return nil end
    local px, py = pos:GetXY()
    if not px or not py then return nil end

    local tx, ty = stop.x / 100, stop.y / 100

    -- Map-x east, map-y south, each scaled into yards; the screen has
    -- north up, so the y component flips.
    local sx, sy = MapScale(map)
    local vx = (tx - px) * sx
    local vy = -(ty - py) * sy

    local len = math.sqrt(vx * vx + vy * vy)
    -- Standing on it: no direction worth drawing.
    if len < 0.0005 then return nil end
    vx, vy = vx / len, vy / len

    if GetCVar and GetCVar("rotateMinimap") == "1" then
        local facing = GetPlayerFacing()
        if facing then
            local c, s = math.cos(facing), math.sin(facing)
            vx, vy = vx * c - vy * s, vx * s + vy * c
        end
    end

    return vx, vy
end

-- ─── The line ───────────────────────────────────────────────
local function Build()
    if frame then return frame end

    frame = CreateFrame("Frame", "MCL_RouteCompass", Minimap)
    frame:SetAllPoints(Minimap)
    frame:SetFrameStrata(Minimap:GetFrameStrata())
    frame:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    frame:Hide()

    line = frame:CreateLine(nil, "OVERLAY")
    line:SetThickness(2.5)
    line:SetColorTexture(0.30, 0.72, 0.96, 0.85)

    -- A dot on the outer end, so which way the line points is not a
    -- question you have to think about.
    tip = frame:CreateTexture(nil, "OVERLAY")
    tip:SetSize(6, 6)
    tip:SetColorTexture(0.30, 0.72, 0.96, 1)

    return frame
end

local function Update()
    local Tracker = Guide.StepTracker
    if not (Tracker and Tracker.GetRoute) then Compass:Stop(); return end

    local stops, current = Tracker:GetRoute()
    local stop = stops and stops[current or 1]
    if not stop then frame:Hide(); return end

    local vx, vy = DirectionTo(stop)
    if not vx then frame:Hide(); return end

    local radius = (Minimap:GetWidth() / 2) - EDGE_INSET
    line:SetStartPoint("CENTER", frame, vx * INNER_GAP, vy * INNER_GAP)
    line:SetEndPoint("CENTER", frame, vx * radius, vy * radius)
    tip:ClearAllPoints()
    tip:SetPoint("CENTER", frame, "CENTER", vx * radius, vy * radius)
    frame:Show()
end

-- ─── Control ────────────────────────────────────────────────
function Compass:Start()
    if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.showMinimapRoute == false then
        self:Stop()
        return
    end
    Build()
    if ticker then return end
    ticker = C_Timer.NewTicker(UPDATE_INTERVAL, Update)
    Update()
end

function Compass:Stop()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    if frame then frame:Hide() end
end

-- Called whenever a route opens, closes, or moves on.  Cheap enough to
-- be the single entry point rather than having callers decide.
function Compass:Refresh()
    local Tracker = Guide.StepTracker
    local stops = Tracker and Tracker.GetRoute and Tracker:GetRoute()
    if stops and #stops > 0
        and not (MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.showMinimapRoute == false) then
        self:Start()
    else
        self:Stop()
    end
end
