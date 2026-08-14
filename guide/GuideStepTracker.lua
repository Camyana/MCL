-- =============================================================
-- GuideStepTracker.lua   Guided window for multi-stage finds
--
-- Two modes share one window:
--
--   STEPS  Left-click a map pin whose location carries a `steps` list
--          and you get one row per step of that unlock chain.  Rows
--          tick themselves off from whatever the API exposes — an item
--          landing in your bags, a buff going up, a quest completing.
--          Conversation-only steps have no such signal, so those are
--          ticked by hand (or swept up when a later step completes,
--          since a chain is strictly ordered).
--
--   ROUTE  Shift-click any pin of a multi-location find (a treasure
--          achievement, a zone's rare pool) and you get a running order
--          through every location you still need, nearest-first from
--          where you are standing.  Only the next stop is shown — the
--          arrows skip along the route if you'd rather take a different
--          one — and it advances by itself as each is looted.
--
-- Layout follows the shape questing guides have settled on: a title
-- bar, the name of the set being run, a nav strip, banded rows that
-- carry a heading and a detail line, and a progress bar along the
-- bottom.
--
-- Drag anywhere on the window to move it; the position is saved.
-- =============================================================

local _, MCLcore = ...
local L = MCLcore.L or {}
local Guide = MCL_GUIDE

Guide.StepTracker = Guide.StepTracker or {}
local Tracker = Guide.StepTracker

-- Layout
local WIDTH          = 340   -- the default; the window is resizable
local MIN_WIDTH      = 260
local MAX_WIDTH      = 720
local PAD            = 8
local HEADER_H       = 28
local SUBTITLE_H     = 24
local NAV_H          = 24
local PROGRESS_H     = 16
local ROW_GAP        = 4
local GUTTER_W       = 20

-- Palette
local C_WINDOW_BG   = { 0.055, 0.055, 0.070, 0.96 }
local C_WINDOW_EDGE = { 0.16, 0.18, 0.24, 1.00 }
local C_HEADER_BG   = { 0.10, 0.11, 0.14, 1.00 }
local C_STRIP_BG    = { 0.085, 0.09, 0.115, 1.00 }
local C_DETAIL_BG   = { 0.10, 0.105, 0.13, 0.95 }

-- Bands stay muted; the state reads from the accent stripe down the
-- left edge, which is where the eye lands without the row shouting.
local C_BAND_CURRENT = { 0.115, 0.175, 0.245 }
local C_BAND_PENDING = { 0.135, 0.140, 0.170 }
local C_BAND_DONE    = { 0.105, 0.150, 0.115 }

local C_EDGE_CURRENT = { 0.30, 0.66, 0.96 }
local C_EDGE_PENDING = { 0.30, 0.32, 0.38 }
local C_EDGE_DONE    = { 0.30, 0.68, 0.38 }

local C_TITLE       = { 0.55, 0.80, 0.95 }
local C_HEADING     = { 1.00, 1.00, 1.00 }
local C_HEADING_DIM = { 0.62, 0.68, 0.74 }
local C_DETAIL      = { 0.66, 0.71, 0.78 }
local C_ACCENT      = { 0.40, 0.78, 0.95 }
local C_MUTED       = { 0.42, 0.47, 0.54 }

local STAR = "|A:PetJournal-FavoritesIcon:12:12|a"

-- Current run
local frame       = nil
local rows        = {}
local mode        = nil    -- "steps" | "route"

-- steps mode
local activeSteps = nil    -- the step list being tracked
local activeWp    = nil    -- the coord it came from
local activeMount = nil    -- the mount the chain belongs to
local activeName  = nil    -- where the chain starts, shown after the name
local manualDone  = {}     -- [index] = true, ticked by hand or latched
local trackedStep = nil    -- step index the waypoint currently points at

-- route mode
local routeMount  = nil    -- the mount whose locations are being routed
local routeStops  = nil    -- ordered list of remaining stops
local routeTotal  = 0      -- how many locations the set has in all
local routeIndex  = 1      -- which stop of the route is on screen
local arrived     = {}     -- stops we've already walked to this session
local routePlan   = nil    -- what the current plan was built from
local arriveTicker = nil
local routeTracked = nil   -- the coord the waypoint is currently on
local routeReturn = nil    -- mount to go back to after drilling into a chain

-- ─── Completion checks ──────────────────────────────────────
local function HasItem(step)
    if not step.item then return false end
    local count = C_Item.GetItemCount(step.item, true)
    return count >= (step.count or 1)
end

local function HasAura(step)
    if not step.aura then return false end
    local auras = type(step.aura) == "table" and step.aura or { step.aura }
    for _, spellID in ipairs(auras) do
        if C_UnitAuras.GetPlayerAuraBySpellID(spellID) then return true end
    end
    return false
end

-- Quest triggers cover the chains that run on quest completion rather
-- than on something landing in your bags — a time-gated questline being
-- the case that needs it most, since a week can pass between steps.
local function HasQuest(step)
    if not step.quest then return false end
    local quests = type(step.quest) == "table" and step.quest or { step.quest }
    for _, questID in ipairs(quests) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then return true end
    end
    return false
end

-- A step is done when its own trigger fires, when it was ticked by
-- hand, or when the whole objective is finished.
local function IsStepDone(index, step, allDone)
    if allDone then return true end
    if manualDone[index] then return true end
    return HasItem(step) or HasAura(step) or HasQuest(step)
end

-- The chain is ordered, so anything before a completed step must also
-- be done — that's what latches the consumed items (a Grisly Morsel
-- fed to the dolphin leaves your bags again) and the talk-only steps.
local function EvaluateSteps()
    if not activeSteps then return nil end

    local allDone = activeWp and select(1, Guide:GetWaypointState(activeWp)) or false

    local done = {}
    for i, step in ipairs(activeSteps) do
        done[i] = IsStepDone(i, step, allDone)
    end

    local lastDone = 0
    for i = #activeSteps, 1, -1 do
        if done[i] then lastDone = i; break end
    end
    for i = 1, lastDone do
        if not done[i] then
            done[i] = true
            manualDone[i] = true    -- latch it so it can't flicker back
        end
    end

    local current
    for i = 1, #activeSteps do
        if not done[i] then current = i; break end
    end

    return done, current, allDone
end

-- ─── Route building ─────────────────────────────────────────
-- Map coordinates are normalised over a zone's bounding box, so x and y
-- units are only the same length when the zone happens to be square.
-- Every distance below is measured in them, which quietly biases which
-- stop counts as nearest in a zone that is much wider than it is tall.
-- One scale factor, worked out per map, makes them comparable.
local mapStretch = 1

-- Measured, not assumed: two short probes across the zone compared by
-- distance.  Distance is indifferent to which world axis is north, so
-- there is no coordinate convention here to get backwards.
local function Probe(mapID, x1, y1, x2, y2)
    local ok1, _, a = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x1, y1))
    local ok2, _, b = pcall(C_Map.GetWorldPosFromMapPos, mapID, CreateVector2D(x2, y2))
    if not (ok1 and ok2 and a and b) then return nil end
    local ax, ay = a:GetXY()
    local bx, by = b:GetXY()
    if not ax or not bx then return nil end
    local dx, dy = bx - ax, by - ay
    return math.sqrt(dx * dx + dy * dy)
end

local function SetMapStretch(mapID)
    mapStretch = 1
    if not mapID or not C_Map.GetWorldPosFromMapPos or not CreateVector2D then return end

    local across = Probe(mapID, 0.4, 0.5, 0.6, 0.5)
    local down   = Probe(mapID, 0.5, 0.4, 0.5, 0.6)
    if across and down and across > 0 and down > 0 then
        mapStretch = down / across
    end
end

local function Dist(ax, ay, bx, by)
    local dx = ax - bx
    local dy = (ay - by) * mapStretch
    return math.sqrt(dx * dx + dy * dy)
end

-- These routes are farmed repeatedly - the rares are back tomorrow - so
-- the run is a circuit, not a one-way trip.  That makes the leg from the
-- last stop back to the first a real leg, and it has to be part of what
-- gets optimised: an ordering that looks tight as an open path can leave
-- a long walk home.
--
-- Two-opt over a closed tour: reversing the run between two stops is an
-- improvement when the two edges it replaces are shorter than the two it
-- removes.  Crossings go by construction, since two legs that cross are
-- always longer than the same two uncrossed.  Indices wrap, so the
-- closing leg is considered like any other.
local function TwoOptLoop(path)
    local n = #path
    if n < 4 then return path end

    local improved, guard = true, 0
    while improved and guard < 40 do
        improved = false
        guard = guard + 1

        for i = 1, n - 1 do
            local a = path[i == 1 and n or i - 1]
            for j = i + 1, n do
                -- i == 1 and j == n reverses the whole tour, which is the
                -- same loop walked backwards; nothing to gain.
                if not (i == 1 and j == n) then
                    local b = path[j == n and 1 or j + 1]
                    local before = Dist(a.x, a.y, path[i].x, path[i].y)
                                 + Dist(path[j].x, path[j].y, b.x, b.y)
                    local after  = Dist(a.x, a.y, path[j].x, path[j].y)
                                 + Dist(path[i].x, path[i].y, b.x, b.y)

                    if after < before - 0.0001 then
                        local lo, hi = i, j
                        while lo < hi do
                            path[lo], path[hi] = path[hi], path[lo]
                            lo, hi = lo + 1, hi - 1
                        end
                        improved = true
                    end
                end
            end
        end
    end
    return path
end

-- A loop has no natural beginning, so it starts at whichever stop you are
-- closest to.  Rotating rather than re-planning keeps the circuit intact:
-- same loop, different entry point.
local function RotateToNearest(path, x, y)
    if not x or not y or #path < 2 then return path end

    local best, bestD = 1, math.huge
    for i, stop in ipairs(path) do
        local d = Dist(stop.x, stop.y, x, y)
        if d < bestD then best, bestD = i, d end
    end
    if best == 1 then return path end

    local n = #path
    local rotated = {}
    for k = 0, n - 1 do
        rotated[k + 1] = path[((best - 1 + k) % n) + 1]
    end
    for k = 1, n do path[k] = rotated[k] end
    return path
end

-- Nearest-neighbour to lay a circuit down, two-opt to pull the crossings
-- out of it, then rotate it to start nearest you.  Re-planned every time
-- the window refreshes, so walking it out of order costs nothing.
local function BuildRoute(mountData)
    local pool, total = {}, 0
    for _, wp in ipairs(mountData.coords or {}) do
        if wp.x and wp.y then
            total = total + 1
            -- Looted treasures are gone for good; a rare killed today is
            -- back tomorrow but is no use on this run either, so both
            -- drop off the route.
            local spent, doneToday = Guide:GetWaypointState(wp)
            if not spent and not doneToday then
                pool[#pool + 1] = {
                    wp       = wp,
                    m        = wp.m,
                    x        = wp.x,
                    y        = wp.y,
                    name     = wp.n or (mountData.mountName or mountData.name or "?"),
                    hasSteps = wp.steps and #wp.steps > 0,
                }
            end
        end
    end
    if #pool == 0 then return {}, total end

    -- Group by map so a set that spills onto a second map stays in
    -- sensible blocks; whichever map you're standing on comes first.
    local currentMap = Guide:GetCurrentMapID()
    local byMap, order = {}, {}
    for _, s in ipairs(pool) do
        local m = s.m or 0
        if not byMap[m] then byMap[m] = {}; order[#order + 1] = m end
        byMap[m][#byMap[m] + 1] = s
    end
    table.sort(order, function(a, b)
        if a == currentMap then return true end
        if b == currentMap then return false end
        return a < b
    end)

    local px, py
    if currentMap and byMap[currentMap] then
        local pos = C_Map.GetPlayerMapPosition(currentMap, "player")
        if pos then px, py = pos.x * 100, pos.y * 100 end
    end

    local route = {}
    for _, m in ipairs(order) do
        local stops = byMap[m]
        local cx, cy = px, py
        if not cx then
            -- No player anchor on this map: start from the westernmost
            -- stop so the order is at least stable between openings.
            local best = stops[1]
            for _, s in ipairs(stops) do
                if s.x < best.x then best = s end
            end
            cx, cy = best.x, best.y
        end

        -- Where this map's leg begins, kept for the improvement pass.
        local startX, startY = cx, cy
        SetMapStretch(m)

        local leg = {}
        while #stops > 0 do
            local bi, bd = 1, math.huge
            for i, s in ipairs(stops) do
                local d = Dist(s.x, s.y, cx, cy)
                if d < bd then bi, bd = i, d end
            end
            local pick = table.remove(stops, bi)
            leg[#leg + 1] = pick
            cx, cy = pick.x, pick.y
        end

        TwoOptLoop(leg)
        RotateToNearest(leg, startX, startY)
        for _, stop in ipairs(leg) do route[#route + 1] = stop end

        px, py = nil, nil   -- only the first map gets the player anchor
    end

    return route, total
end

-- ─── Waypointing ────────────────────────────────────────────
local function SetWaypoint(mapID, x, y)
    if not mapID or not x or not y then return false end

    -- Instance and some special maps refuse user waypoints outright.
    if C_Map.CanSetUserWaypointOnMap and not C_Map.CanSetUserWaypointOnMap(mapID) then
        return false
    end

    local point = UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100)
    C_Map.SetUserWaypoint(point)
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)

    -- The world map's own click handling can land after ours and drop a
    -- waypoint wherever the cursor happened to be, silently replacing
    -- the one we just set.  Re-assert on the next frame so ours wins.
    C_Timer.After(0, function()
        C_Map.SetUserWaypoint(point)
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end)
    return true
end

local function SetWaypointToStep(index, step)
    if not step or not step.x or not step.y then return false end
    if SetWaypoint(step.m or (activeWp and activeWp.m), step.x, step.y) then
        trackedStep = index
        return true
    end
    return false
end

local function SetWaypointToStop(stop)
    if not stop then return false end
    return SetWaypoint(stop.m, stop.x, stop.y)
end

-- ─── Arrival ────────────────────────────────────────────────
-- Reaching a stop is the other way a route moves on.  Looting one
-- already drops it from the plan, but a rare you walked to and found
-- absent leaves you standing on a waypoint that will never clear itself.
local ARRIVE_YARDS = 40

-- Yards when the client will give them - GetDistance measures to the
-- super-tracked point, which is ours - and map units when it won't.
-- Map units are zone-relative rather than absolute, so that threshold
-- has to be loose enough for a big zone.
local function AtStop(stop)
    if not stop then return false end

    local dist = C_Navigation and C_Navigation.GetDistance and C_Navigation.GetDistance()
    if type(dist) == "number" and dist > 0 then
        return dist <= ARRIVE_YARDS
    end

    local map = Guide.GetCurrentMapID and Guide:GetCurrentMapID()
    if not map or map ~= stop.m then return false end
    local pos = C_Map.GetPlayerMapPosition and C_Map.GetPlayerMapPosition(map, "player")
    if not pos then return false end
    local px, py = pos:GetXY()
    if not px or not py then return false end
    return math.abs(px * 100 - stop.x) <= 1.0 and math.abs(py * 100 - stop.y) <= 1.0
end

-- The first stop at or after `from` that hasn't been walked to yet.
-- Returns nil when they've all been visited, which leaves the window on
-- the last one rather than snapping somewhere arbitrary.
local function NextUnvisited(from)
    for i = from, #(routeStops or {}) do
        local stop = routeStops[i]
        if stop and not arrived[stop.wp] then return i end
    end
    return nil
end

-- ─── Rows ───────────────────────────────────────────────────
-- A row is a coloured heading band with a bullet, and a detail line on
-- a slightly lighter panel beneath it.
local function ReleaseRows()
    for _, row in ipairs(rows) do
        row:Hide()
    end
end

local function AcquireRow(index)
    if rows[index] then
        rows[index]:Show()
        return rows[index]
    end

    local row = CreateFrame("Button", nil, frame)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    row.band = row:CreateTexture(nil, "BACKGROUND")
    row.band:SetPoint("TOPLEFT")
    row.band:SetPoint("TOPRIGHT")

    row.detailBg = row:CreateTexture(nil, "BACKGROUND")
    row.detailBg:SetPoint("TOPLEFT", row.band, "BOTTOMLEFT")
    row.detailBg:SetPoint("BOTTOMRIGHT")
    row.detailBg:SetColorTexture(unpack(C_DETAIL_BG))

    row.hl = row:CreateTexture(nil, "ARTWORK")
    row.hl:SetAllPoints()
    row.hl:SetColorTexture(1, 1, 1, 0.06)
    row.hl:Hide()

    -- Accent stripe down the left edge carries the row's state.
    row.accent = row:CreateTexture(nil, "ARTWORK")
    row.accent:SetPoint("TOPLEFT")
    row.accent:SetPoint("BOTTOMLEFT")
    row.accent:SetWidth(3)

    -- Fixed gutter: the step number, or a tick once it's done.  Keeping
    -- it out of the heading means wrapped lines align under the text
    -- rather than under the number.
    row.gutter = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.gutter:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -5)
    row.gutter:SetWidth(GUTTER_W - 4)
    row.gutter:SetJustifyH("RIGHT")

    row.heading = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.heading:SetPoint("TOPLEFT", row, "TOPLEFT", 8 + GUTTER_W, -5)
    row.heading:SetPoint("TOPRIGHT", row, "TOPRIGHT", -7, -5)
    row.heading:SetJustifyH("LEFT")
    row.heading:SetWordWrap(true)

    row.detail = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.detail:SetPoint("TOPLEFT", row.band, "BOTTOMLEFT", 8 + GUTTER_W, -3)
    row.detail:SetPoint("TOPRIGHT", row.band, "BOTTOMRIGHT", -7, -3)
    row.detail:SetJustifyH("LEFT")
    row.detail:SetWordWrap(true)
    row.detail:SetTextColor(unpack(C_DETAIL))

    row:SetScript("OnEnter", function(self)
        self.hl:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.kind == "route" then
            GameTooltip:AddLine(self.stop and self.stop.name or "", 1, 1, 1, true)
            GameTooltip:AddLine("|cFF00FF00" .. L["Click to set waypoint"] .. "|r")
            if self.stop and self.stop.hasSteps then
                GameTooltip:AddLine("|cFF888888" .. L["Right-click for this treasure's steps"] .. "|r")
            end
        else
            GameTooltip:AddLine(self.step and self.step.t or "", 1, 1, 1, true)
            if self.step and self.step.x and self.step.y then
                GameTooltip:AddLine("|cFF00FF00" .. L["Click to set waypoint"] .. "|r")
            end
            GameTooltip:AddLine("|cFF888888" .. L["Right-click to tick off"] .. "|r")
        end
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hl:Hide()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self, button)
        if self.kind == "route" then
            if button == "RightButton" then
                if self.stop and self.stop.hasSteps then
                    -- Drill into that treasure's chain, remembering the
                    -- route so the header can offer a way back.
                    local back = routeMount
                    Tracker:Show(routeMount, self.stop.wp)
                    routeReturn = back
                    Tracker:Refresh()
                end
                return
            end
            SetWaypointToStop(self.stop)
            return
        end
        if button == "RightButton" then
            manualDone[self.index] = not manualDone[self.index]
            Tracker:Refresh()
            return
        end
        SetWaypointToStep(self.index, self.step)
    end)

    rows[index] = row
    return row
end

-- Lay a row out and return the height it consumed.
local function LayoutRow(row, yOff, state, number, heading, detail)
    local band, edge, headColor, gutColor
    if state == "done" then
        band, edge, headColor, gutColor = C_BAND_DONE, C_EDGE_DONE, C_HEADING_DIM, C_EDGE_DONE
    elseif state == "current" then
        band, edge, headColor, gutColor = C_BAND_CURRENT, C_EDGE_CURRENT, C_HEADING, C_EDGE_CURRENT
    else
        band, edge, headColor, gutColor = C_BAND_PENDING, C_EDGE_PENDING, C_HEADING_DIM, C_MUTED
    end

    row.band:SetColorTexture(band[1], band[2], band[3], 1)
    row.accent:SetColorTexture(edge[1], edge[2], edge[3], 1)

    -- A finished row swaps its number for a tick.
    row.gutter:SetText(state == "done" and "|A:common-icon-checkmark:10:10|a" or (number .. "."))
    row.gutter:SetTextColor(unpack(gutColor))

    row.heading:SetText(heading or "")
    row.heading:SetTextColor(unpack(headColor))
    local headH = math.max(row.heading:GetStringHeight(), 11) + 8
    row.band:SetHeight(headH)

    local total = headH
    if detail and detail ~= "" then
        row.detail:SetText(detail)
        row.detail:Show()
        row.detailBg:Show()
        total = total + math.max(row.detail:GetStringHeight(), 10) + 7
    else
        row.detail:SetText("")
        row.detail:Hide()
        row.detailBg:Hide()
    end

    row:SetHeight(total)
    row:ClearAllPoints()
    -- Anchored to both edges rather than given a width, so a row is
    -- whatever the window currently is.
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, yOff)
    row:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, yOff)
    row:Show()
    return total
end

-- ─── Frame ──────────────────────────────────────────────────
local function SavePosition()
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    MCL_GUIDE_SETTINGS.stepTrackerAnchor = { point = point, relPoint = relPoint, x = x, y = y }
end

local function MakeStripButton(parent, text, width)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 20, NAV_H - 6)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.label:SetAllPoints()
    b.label:SetText(text)
    b.label:SetTextColor(unpack(C_ACCENT))
    b:SetScript("OnEnter", function(s) s.label:SetTextColor(1, 1, 1) end)
    b:SetScript("OnLeave", function(s) s.label:SetTextColor(unpack(C_ACCENT)) end)
    return b
end

local function GetFrame()
    if frame then return frame end

    local f = CreateFrame("Frame", "MCL_GuideStepTracker", UIParent, "BackdropTemplate")
    -- Above the world map: at HIGH the map's scroll container was taking
    -- the clicks meant for our rows.
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(700)
    f:SetToplevel(true)
    f:SetSize((MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.guideWindowWidth) or WIDTH, 160)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:SetResizable(true)
    -- Height is computed from the content, so only the width is really
    -- up for grabs; the height bounds are just wide enough not to fight
    -- whatever the layout works out.
    if f.SetResizeBounds then
        f:SetResizeBounds(MIN_WIDTH, 80, MAX_WIDTH, 2000)
    end
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    f:Hide()

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(unpack(C_WINDOW_BG))
    f:SetBackdropBorderColor(unpack(C_WINDOW_EDGE))

    -- ── Width grip ──────────────────────────────────────────
    -- On the right edge rather than the usual bottom-right corner,
    -- because a corner grip promises height resizing that isn't on
    -- offer: the window sizes itself to its content vertically.
    f.grip = CreateFrame("Button", nil, f)
    f.grip:SetPoint("RIGHT", f, "RIGHT", -1, 0)
    f.grip:SetSize(8, 44)
    f.grip:EnableMouse(true)

    f.gripMark = f.grip:CreateTexture(nil, "OVERLAY")
    f.gripMark:SetPoint("CENTER")
    f.gripMark:SetSize(2, 26)
    f.gripMark:SetColorTexture(0.42, 0.48, 0.58, 0.75)

    f.grip:SetScript("OnEnter", function(self)
        self:GetParent().gripMark:SetColorTexture(0.30, 0.72, 0.96, 1)
    end)
    f.grip:SetScript("OnLeave", function(self)
        if not self.sizing then
            self:GetParent().gripMark:SetColorTexture(0.42, 0.48, 0.58, 0.75)
        end
    end)
    -- Drag scripts rather than mouse down/up: OnMouseUp only fires if the
    -- button is released over the grip, so a quick drag that ends off the
    -- edge would leave the window stuck sizing.
    f.grip:RegisterForDrag("LeftButton")
    f.grip:SetScript("OnDragStart", function(self)
        self.sizing = true
        self:GetParent():StartSizing("RIGHT")
    end)
    f.grip:SetScript("OnDragStop", function(self)
        self.sizing = nil
        local parent = self:GetParent()
        parent:StopMovingOrSizing()
        MCL_GUIDE_SETTINGS.guideWindowWidth = math.floor(parent:GetWidth() + 0.5)
        parent.gripMark:SetColorTexture(0.42, 0.48, 0.58, 0.75)
        -- Rows follow the width on their own, but a heading that now
        -- wraps onto fewer lines needs the heights worked out again.
        Tracker:Refresh()
    end)

    -- ── Title bar ───────────────────────────────────────────
    f.headerBg = f:CreateTexture(nil, "BACKGROUND")
    f.headerBg:SetPoint("TOPLEFT", 1, -1)
    f.headerBg:SetPoint("TOPRIGHT", -1, -1)
    f.headerBg:SetHeight(HEADER_H)
    f.headerBg:SetColorTexture(unpack(C_HEADER_BG))

    f.brand = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.brand:SetPoint("TOP", f, "TOP", 0, -8)
    f.brand:SetText("M C L   G U I D E")
    f.brand:SetTextColor(unpack(C_TITLE))

    -- Flat close, rather than the Blizzard gold-and-red one, which sits
    -- badly against a dark panel.
    f.close = MakeStripButton(f, "\195\151", 20)   -- multiplication sign
    f.close:SetPoint("TOPRIGHT", -6, -5)
    f.close.label:SetTextColor(unpack(C_MUTED))
    f.close:SetScript("OnEnter", function(s) s.label:SetTextColor(1, 0.45, 0.45) end)
    f.close:SetScript("OnLeave", function(s) s.label:SetTextColor(unpack(C_MUTED)) end)
    f.close:SetScript("OnClick", function() Tracker:Hide() end)

    -- Back to the route, shown only after drilling into a chain
    f.back = MakeStripButton(f, "<", 22)
    f.back:SetPoint("TOPLEFT", 5, -4)
    f.back:SetScript("OnClick", function()
        if routeReturn then Tracker:ShowRoute(routeReturn) end
    end)
    f.back:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(L["Route"], 1, 1, 1)
        GameTooltip:Show()
    end)
    f.back:SetScript("OnLeave", function() GameTooltip:Hide() end)
    f.back:Hide()

    -- ── Subtitle strip: what is being run ───────────────────
    f.subBg = f:CreateTexture(nil, "BACKGROUND")
    f.subBg:SetPoint("TOPLEFT", 1, -(HEADER_H + 1))
    f.subBg:SetPoint("TOPRIGHT", -1, -(HEADER_H + 1))
    f.subBg:SetHeight(SUBTITLE_H)
    f.subBg:SetColorTexture(unpack(C_STRIP_BG))

    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetSize(16, 16)
    f.icon:SetPoint("LEFT", f.subBg, "LEFT", PAD, 0)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Status sits at the right of the same strip, so it stays visible
    -- whether or not the nav strip below is in play.
    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.status:SetPoint("RIGHT", f.subBg, "RIGHT", -PAD, 0)
    f.status:SetJustifyH("RIGHT")
    f.status:SetTextColor(unpack(C_MUTED))

    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.subtitle:SetPoint("LEFT", f.icon, "RIGHT", 6, 0)
    f.subtitle:SetPoint("RIGHT", f.status, "LEFT", -8, 0)
    f.subtitle:SetJustifyH("LEFT")
    f.subtitle:SetWordWrap(false)
    f.subtitle:SetTextColor(1, 1, 1)

    -- ── Nav strip: paging + position ────────────────────────
    f.navBg = f:CreateTexture(nil, "BACKGROUND")
    f.navBg:SetPoint("TOPLEFT", 1, -(HEADER_H + SUBTITLE_H + 1))
    f.navBg:SetPoint("TOPRIGHT", -1, -(HEADER_H + SUBTITLE_H + 1))
    f.navBg:SetHeight(NAV_H)
    f.navBg:SetColorTexture(0.07, 0.075, 0.095, 1)

    -- Step back and forward through the route one stop at a time, for
    -- when you want to skip the nearest one and take the next instead.
    f.prev = MakeStripButton(f, "<", 22)
    f.prev:SetPoint("LEFT", f.navBg, "LEFT", PAD, 0)
    f.prev:SetScript("OnClick", function()
        if routeIndex > 1 then routeIndex = routeIndex - 1; Tracker:Refresh(); RedrawMap() end
    end)

    f.next = MakeStripButton(f, ">", 22)
    f.next:SetPoint("LEFT", f.prev, "RIGHT", 2, 0)
    f.next:SetScript("OnClick", function()
        if routeIndex < #(routeStops or {}) then routeIndex = routeIndex + 1; Tracker:Refresh(); RedrawMap() end
    end)

    f.position = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.position:SetPoint("LEFT", f.next, "RIGHT", 8, 0)
    f.position:SetJustifyH("LEFT")
    f.position:SetTextColor(unpack(C_MUTED))

    -- ── Progress bar ────────────────────────────────────────
    f.progress = CreateFrame("StatusBar", nil, f)
    f.progress:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    f.progress:GetStatusBarTexture():SetHorizTile(false)
    f.progress:SetStatusBarColor(0.25, 0.62, 0.32, 1)
    f.progress:SetHeight(PROGRESS_H)
    f.progress:SetPoint("BOTTOMLEFT", PAD, PAD - 2)
    f.progress:SetPoint("BOTTOMRIGHT", -PAD, PAD - 2)
    f.progress:SetMinMaxValues(0, 1)
    f.progress:SetValue(0)

    f.progressBg = f.progress:CreateTexture(nil, "BACKGROUND")
    f.progressBg:SetAllPoints()
    f.progressBg:SetColorTexture(0.14, 0.15, 0.18, 1)

    f.progressText = f.progress:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.progressText:SetPoint("CENTER")
    f.progressText:SetTextColor(0.88, 0.92, 0.96)

    local anchor = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.stepTrackerAnchor
    if anchor and anchor.point then
        f:SetPoint(anchor.point, UIParent, anchor.relPoint or anchor.point, anchor.x or 0, anchor.y or 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    end

    f:SetScale((MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.guideWindowScale) or 1.0)

    frame = f
    return f
end

-- ─── Position and size ──────────────────────────────────────
function Tracker:SetScale(scale)
    scale = math.max(0.5, math.min(scale or 1.0, 2.0))
    MCL_GUIDE_SETTINGS.guideWindowScale = scale
    if frame then frame:SetScale(scale) end
    return scale
end

function Tracker:GetScale()
    return (MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.guideWindowScale) or 1.0
end

function Tracker:ResetPosition()
    MCL_GUIDE_SETTINGS.stepTrackerAnchor = nil
    MCL_GUIDE_SETTINGS.guideWindowWidth = nil
    if frame then frame:SetWidth(WIDTH) end
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    end
end

-- The nav strip only exists when there is paging to do, so the rows
-- move up to fill the space when it isn't needed.
local function ShowNavStrip(show)
    local f = frame
    f.navBg:SetShown(show)
    f.prev:SetShown(show)
    f.next:SetShown(show)
    f.position:SetShown(show)
end

local function ContentTop(navShown)
    return -(HEADER_H + SUBTITLE_H + (navShown and NAV_H or 0) + ROW_GAP + 2)
end

-- Subtitle strip: the mount being guided, with where you are in it
-- trailing behind in a dimmer tone.
local function SetSubtitle(mountData, suffix)
    local f = frame
    local icon = mountData and mountData.icon
    f.icon:SetShown(icon ~= nil)
    if icon then f.icon:SetTexture(icon) end
    f.subtitle:ClearAllPoints()
    f.subtitle:SetPoint("LEFT", icon and f.icon or f.subBg, icon and "RIGHT" or "LEFT", icon and 6 or PAD, 0)
    f.subtitle:SetPoint("RIGHT", f.status, "LEFT", -8, 0)

    local name = mountData and (mountData.mountName or mountData.name) or ""
    if suffix and suffix ~= "" and suffix ~= name then
        name = name .. "  |cFF6E7A85" .. suffix .. "|r"
    end
    f.subtitle:SetText(name)
end

local function SetProgress(done, total)
    local f = frame
    if total and total > 0 then
        f.progress:SetMinMaxValues(0, total)
        f.progress:SetValue(done)
        f.progressText:SetText(string.format("%d / %d", done, total))
        if done >= total then
            f.progress:SetStatusBarColor(0.30, 0.72, 0.38, 1)
        else
            f.progress:SetStatusBarColor(0.22, 0.52, 0.72, 1)
        end
        f.progress:Show()
    else
        f.progress:Hide()
    end
end

-- ─── Rendering ──────────────────────────────────────────────
local function RefreshSteps()
    local done, current, allDone = EvaluateSteps()
    if not done then return end

    ReleaseRows()
    local f = frame
    f.back:SetShown(routeReturn ~= nil)
    ShowNavStrip(false)

    SetSubtitle(activeMount, activeName)

    local doneCount = 0
    for _, d in ipairs(done) do
        if d then doneCount = doneCount + 1 end
    end
    f.status:SetText(allDone and ("|cFF59B36A" .. L["Complete!"] .. "|r") or "")

    local y = ContentTop(false)
    local lastDetail
    for i, step in ipairs(activeSteps) do
        local row = AcquireRow(i)
        row.kind, row.index, row.step, row.stop = "steps", i, step, nil

        local state = done[i] and "done" or (i == current and "current" or "pending")

        -- Consecutive steps at the same place don't need the location
        -- repeated under every one of them.
        local detail
        if step.n and step.x and step.y then
            detail = string.format("%s  (%.1f, %.1f)", step.n, step.x, step.y)
        elseif step.x and step.y then
            detail = string.format("(%.1f, %.1f)", step.x, step.y)
        end
        if detail and detail == lastDetail then
            detail = nil
        elseif detail then
            lastDetail = detail
        end

        y = y - LayoutRow(row, y, state, i, step.t or "", detail) - ROW_GAP
    end

    -- Auto-advance the waypoint as steps complete, but only while it is
    -- still pointing at a step we set — if you clicked a different row,
    -- that choice stands.
    if current and trackedStep and trackedStep ~= current and done[trackedStep] then
        SetWaypointToStep(current, activeSteps[current])
    end

    SetProgress(doneCount, #activeSteps)
    f:SetHeight(math.abs(y) + PROGRESS_H + PAD * 2)
end

-- What is still outstanding, as a comparable string.  Re-planning is only
-- honest when this changes; anything else is the same set of places.
local function OutstandingKey(mountData)
    local keys = {}
    for _, wp in ipairs(mountData.coords or {}) do
        if wp.x and wp.y then
            local spent, doneToday = Guide:GetWaypointState(wp)
            if not spent and not doneToday then
                keys[#keys + 1] = string.format("%d:%.1f:%.1f", wp.m or 0, wp.x, wp.y)
            end
        end
    end
    table.sort(keys)
    return table.concat(keys, "|")
end

-- ─── Finishing empty-handed ─────────────────────────────────
-- Walking the whole loop and getting nothing is the normal outcome, and
-- the window going quiet at "0 to go" doesn't say so.  Worth naming, and
-- worth saying when it's worth coming back.
local announcedDry = {}

local function MountCollected(mountData)
    local mountID = mountData and (mountData.mountID
        or (mountData.spellId and Guide.spellToMount and Guide.spellToMount[mountData.spellId]))
    if not mountID then return false end
    local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(mountID)
    return collected and true or false
end

-- Daily reset, formatted by the game so it reads right in every locale.
local function TimeToReset()
    local secs
    if C_DateAndTime and C_DateAndTime.GetSecondsUntilDailyReset then
        local ok, value = pcall(C_DateAndTime.GetSecondsUntilDailyReset)
        if ok then secs = value end
    end
    if (not secs or secs <= 0) and GetQuestResetTime then
        local ok, value = pcall(GetQuestResetTime)
        if ok then secs = value end
    end
    if not secs or secs <= 0 then return nil end
    return SecondsToTime(secs, true), secs
end

-- Once per mount per session: the route refreshes constantly, and a line
-- of chat on every refresh would be worse than no line at all.
local function AnnounceDry(mountData, pretty)
    local key = mountData and (mountData.spellId or mountData.name)
    if not key or announcedDry[key] then return end
    announcedDry[key] = true

    local name = (mountData.mountName or mountData.name or "?")
    if pretty then
        print(("|cFF1FB7EBMCL|r " .. L["No %s today - every rare is done. Next chance in %s."])
            :format(name, pretty))
    else
        print(("|cFF1FB7EBMCL|r " .. L["No %s today - every rare is done."]):format(name))
    end
end

-- A route shows one stop at a time: the whole point is "go here next",
-- and a dozen rows of places you aren't going yet is just noise.  Use
-- the arrows to skip ahead if you'd rather take a different one.
local function RefreshRoute()
    -- Plan once and then walk it.  Re-planning on every refresh looked
    -- reasonable until you started moving: the loop is anchored to where
    -- you're standing, so every few steps produced a different order and
    -- the window appeared to shuffle itself while the line on the map
    -- redrew underneath you.  A plan only changes when the set of places
    -- left to visit does.
    local key = OutstandingKey(routeMount)
    if key ~= routePlan or not routeStops then
        local wasOn = routeStops and routeStops[routeIndex] and routeStops[routeIndex].wp
        routeStops, routeTotal = BuildRoute(routeMount)
        routePlan = key

        -- Keep pointing at the same place if it survived the re-plan, so
        -- collecting one stop doesn't move the goalposts on the rest.
        routeIndex = 1
        if wasOn then
            for i, stop in ipairs(routeStops) do
                if stop.wp == wasOn then routeIndex = i; break end
            end
        end
    end

    ReleaseRows()
    local f = frame
    f.back:Hide()

    local remaining = #routeStops
    routeIndex = math.max(1, math.min(routeIndex, math.max(remaining, 1)))

    -- Don't sit on somewhere already walked to; the route moves on.
    if remaining > 0 and routeStops[routeIndex]
        and arrived[routeStops[routeIndex].wp] then
        routeIndex = NextUnvisited(routeIndex) or NextUnvisited(1) or routeIndex
    end

    SetSubtitle(routeMount)
    ShowNavStrip(remaining > 1)
    if remaining > 1 then
        f.position:SetText(string.format("%d / %d", routeIndex, remaining))
    end
    local gotIt = remaining == 0 and MountCollected(routeMount)
    local resetIn = (remaining == 0 and not gotIt) and TimeToReset() or nil

    if remaining > 0 then
        f.status:SetText(string.format(L["%d to go"], remaining))
    elseif gotIt then
        f.status:SetText("|cFF59B36A" .. L["Complete!"] .. "|r")
    else
        f.status:SetText("|cFFFFD100" .. L["No mount today"] .. "|r")
    end

    local y = ContentTop(remaining > 1)
    local stop = routeStops[routeIndex]

    -- Finished the loop without the mount: say so, and say when it is
    -- worth coming back, rather than leaving an empty window.
    if remaining == 0 and not gotIt then
        local row = AcquireRow(1)
        row.kind, row.index, row.step, row.stop = nil, nil, nil, nil
        y = y - LayoutRow(row, y, "done", 1, L["No mount today"],
                          resetIn and string.format(L["Try again in %s"], resetIn)
                                  or L["Try again after the daily reset"]) - ROW_GAP
        AnnounceDry(routeMount, resetIn)
    end

    if stop then
        local row = AcquireRow(1)
        row.kind, row.index, row.step, row.stop = "route", routeIndex, nil, stop

        local heading = stop.name
        if stop.hasSteps then heading = heading .. "  " .. STAR end

        y = y - LayoutRow(row, y, "current", routeIndex, heading,
                          string.format("(%.1f, %.1f)", stop.x, stop.y)) - ROW_GAP

        if routeTracked ~= stop.wp then
            SetWaypointToStop(stop)
            routeTracked = stop.wp
        end
    else
        routeTracked = nil
    end

    SetProgress(routeTotal - remaining, routeTotal)
    f:SetHeight(math.abs(y) + PROGRESS_H + PAD * 2)
end

-- ─── Public API ─────────────────────────────────────────────
-- A re-plan can reorder every leg, so the map has to follow.  Refresh is
-- driven by bag and aura events, which arrive in bursts, so the redraw is
-- deferred and coalesced rather than run once per event.
local mapRedrawPending = false
local function RedrawMapSoon()
    if mapRedrawPending then return end
    if not (Guide.MapPins and Guide.MapPins.RefreshRoutePath) then return end
    mapRedrawPending = true
    C_Timer.After(0, function()
        mapRedrawPending = false
        if mode == "route" then Guide.MapPins:RefreshRoutePath() end
    end)
end

function Tracker:Refresh()
    if mode == "route" then RedrawMapSoon() end
    if Guide.RouteCompass and Guide.RouteCompass.Refresh then
        Guide.RouteCompass:Refresh()
    end
    if not frame or not frame:IsShown() then return end
    if mode == "route" then
        RefreshRoute()
    elseif activeSteps then
        RefreshSteps()
    end
end

-- Open the chain for a location that carries a step list.
function Tracker:Show(mountData, waypoint)
    if not waypoint or not waypoint.steps or #waypoint.steps == 0 then return false end

    local f = GetFrame()

    -- Switching objective resets the hand-ticked flags
    if activeWp ~= waypoint then
        wipe(manualDone)
        trackedStep = nil
    end

    mode        = "steps"
    activeSteps = waypoint.steps
    activeWp    = waypoint
    activeMount = mountData
    activeName  = waypoint.n or ""
    routeReturn = nil

    f:Show()
    RefreshSteps()

    -- Point the way at the first outstanding step straight away
    local _, current = EvaluateSteps()
    if current then SetWaypointToStep(current, activeSteps[current]) end

    return true
end

-- Open a running order through every location of a multi-location find.
-- Only runs while a route is on screen, and stops itself the moment one
-- isn't.  A second between checks is well inside walking pace.
local function StartArriveWatch()
    if arriveTicker then return end
    arriveTicker = C_Timer.NewTicker(1, function()
        if not (frame and frame:IsShown() and mode == "route") then
            if arriveTicker then arriveTicker:Cancel(); arriveTicker = nil end
            return
        end
        if MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.routeAutoAdvance == false then return end

        local stop = routeStops and routeStops[routeIndex]
        if not stop or not AtStop(stop) then return end

        -- Walked to.  Remember it so a re-plan doesn't drop us back on
        -- it, and move to the next place we haven't been.
        arrived[stop.wp] = true
        local nextIndex = NextUnvisited(routeIndex + 1) or NextUnvisited(1)
        if nextIndex and nextIndex ~= routeIndex then
            routeIndex = nextIndex
            Tracker:Refresh()
        end
    end)
end

function Tracker:ShowRoute(mountData)
    if not mountData or not mountData.coords or #mountData.coords < 2 then return false end

    local f = GetFrame()

    mode        = "route"
    routeMount  = mountData
    routeStops  = nil
    routePlan   = nil
    routeIndex  = 1
    routeTracked = nil
    routeReturn = nil

    wipe(arrived)
    wipe(announcedDry)

    f:Show()
    RefreshRoute()
    StartArriveWatch()
    RedrawMap()
    return true
end

function Tracker:Hide()
    if frame then frame:Hide() end
    mode        = nil
    activeSteps = nil
    activeWp    = nil
    activeMount = nil
    activeName  = nil
    trackedStep = nil
    routeMount  = nil
    routeStops  = nil
    routePlan   = nil
    routeReturn = nil
    wipe(manualDone)
    wipe(arrived)
    if arriveTicker then
        arriveTicker:Cancel()
        arriveTicker = nil
    end
    RedrawMap()
end

function Tracker:IsShown()
    return frame and frame:IsShown()
end

-- Opening or closing a route changes what the map should be drawing, and
-- the map won't know unless it is told.
local function RedrawMap()
    if Guide.MapPins and Guide.MapPins.RefreshRoutePath then
        Guide.MapPins:RefreshRoutePath()
    end
    -- The minimap line follows the same stop the window is pointing at.
    if Guide.RouteCompass and Guide.RouteCompass.Refresh then
        Guide.RouteCompass:Refresh()
    end
end

-- The world map draws the planned route, so it has to be able to see it.
-- Returns nil unless a route is actually on screen.
-- What the window thinks it is doing, for diagnostics.
function Tracker:DebugState()
    return mode, (frame and frame:IsShown()) and true or false,
           routeStops and #routeStops or 0, routeIndex
end

function Tracker:GetRoute()
    if mode ~= "route" or not (frame and frame:IsShown()) then return nil end
    return routeStops, routeIndex, arrived
end

-- ─── Auto-progression ───────────────────────────────────────
-- Re-evaluate on the events that can move a step or a route along.  Bag
-- and aura updates are noisy, so the refresh is cheap and guarded on the
-- window actually being open.
local events = CreateFrame("Frame")
events:RegisterEvent("BAG_UPDATE_DELAYED")
events:RegisterEvent("UNIT_AURA")
events:RegisterEvent("QUEST_TURNED_IN")
events:RegisterEvent("QUEST_LOG_UPDATE")
events:SetScript("OnEvent", function(_, event, unit)
    if event == "UNIT_AURA" and unit ~= "player" then return end
    if not (frame and frame:IsShown()) then return end
    Tracker:Refresh()
end)
