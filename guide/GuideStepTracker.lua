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
local WIDTH          = 340
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
-- Greedy nearest-neighbour over the locations still outstanding.  It is
-- not the optimal tour, but for a scattered treasure set it is within a
-- hop or two of one and it re-plans every time you open it, so walking
-- it out of order costs nothing.
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
        while #stops > 0 do
            local bi, bd = 1, math.huge
            for i, s in ipairs(stops) do
                local dx, dy = s.x - cx, s.y - cy
                local d = dx * dx + dy * dy
                if d < bd then bi, bd = i, d end
            end
            local pick = table.remove(stops, bi)
            route[#route + 1] = pick
            cx, cy = pick.x, pick.y
        end
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
    row:SetWidth(WIDTH - PAD * 2)
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
    row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, yOff)
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
    f:SetSize(WIDTH, 160)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
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
        if routeIndex > 1 then routeIndex = routeIndex - 1; Tracker:Refresh() end
    end)

    f.next = MakeStripButton(f, ">", 22)
    f.next:SetPoint("LEFT", f.prev, "RIGHT", 2, 0)
    f.next:SetScript("OnClick", function()
        if routeIndex < #(routeStops or {}) then routeIndex = routeIndex + 1; Tracker:Refresh() end
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

-- A route shows one stop at a time: the whole point is "go here next",
-- and a dozen rows of places you aren't going yet is just noise.  Use
-- the arrows to skip ahead if you'd rather take a different one.
local function RefreshRoute()
    -- Re-plan from what is still outstanding; looted stops fall out.
    routeStops, routeTotal = BuildRoute(routeMount)

    ReleaseRows()
    local f = frame
    f.back:Hide()

    local remaining = #routeStops

    -- If the stop we were pointing at has gone (you looted it), snap
    -- back to the head of the freshly planned route.
    if routeTracked then
        local stillThere = false
        for _, s in ipairs(routeStops) do
            if s.wp == routeTracked then stillThere = true; break end
        end
        if not stillThere then routeIndex = 1 end
    end
    routeIndex = math.max(1, math.min(routeIndex, math.max(remaining, 1)))

    SetSubtitle(routeMount)
    ShowNavStrip(remaining > 1)
    if remaining > 1 then
        f.position:SetText(string.format("%d / %d", routeIndex, remaining))
    end
    f.status:SetText(remaining == 0
        and ("|cFF59B36A" .. L["Complete!"] .. "|r")
        or string.format(L["%d to go"], remaining))

    local y = ContentTop(remaining > 1)
    local stop = routeStops[routeIndex]
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
function Tracker:Refresh()
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
function Tracker:ShowRoute(mountData)
    if not mountData or not mountData.coords or #mountData.coords < 2 then return false end

    local f = GetFrame()

    mode        = "route"
    routeMount  = mountData
    routeStops  = nil
    routeIndex  = 1
    routeTracked = nil
    routeReturn = nil

    f:Show()
    RefreshRoute()
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
    routeReturn = nil
    wipe(manualDone)
end

function Tracker:IsShown()
    return frame and frame:IsShown()
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
