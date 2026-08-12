-- =============================================================
-- GuideStepTracker.lua   Step-by-step tracker for multi-stage finds
--
-- Left-clicking a map pin whose location carries a `steps` list opens
-- this window: one row per step, click a row to waypoint it, and the
-- rows tick themselves off as you go.
--
-- Progression comes from whatever the API actually exposes — an item
-- landing in your bags, a buff going up, the treasure's own hidden
-- tracking quest completing.  Conversation-only steps have no such
-- signal, so those are ticked by hand (or swept up when a later step
-- completes, since the chain is strictly ordered).
--
-- Drag anywhere on the window to move it; the position is saved.
-- =============================================================

local _, MCLcore = ...
local L = MCLcore.L or {}
local Guide = MCL_GUIDE

Guide.StepTracker = Guide.StepTracker or {}
local Tracker = Guide.StepTracker

-- Layout
local WIDTH        = 300
local PAD          = 10
local HEADER_H     = 34
local ROW_PAD      = 6
local FOOTER_H     = 20

-- Colours
local COLOR_TITLE   = { 0.40, 0.78, 0.95 }
local COLOR_ACTIVE  = { 1.00, 1.00, 1.00 }
local COLOR_PENDING = { 0.70, 0.75, 0.80 }
local COLOR_DONE    = { 0.35, 0.70, 0.40 }
local COLOR_HINT    = { 0.45, 0.65, 0.45 }

-- Current run
local frame        = nil
local rows         = {}
local activeSteps  = nil   -- the step list being tracked
local activeWp     = nil   -- the waypoint (treasure coord) it came from
local activeName   = nil
local manualDone   = {}    -- [index] = true, ticked by hand or latched
local trackedStep  = nil   -- step index the waypoint currently points at

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
local function Evaluate()
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

-- ─── Waypointing ────────────────────────────────────────────
local function SetWaypointTo(index, step)
    if not step or not step.x or not step.y then return false end
    local mapID = step.m or (activeWp and activeWp.m)
    if not mapID then return false end
    C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, step.x / 100, step.y / 100))
    C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    trackedStep = index
    return true
end

-- ─── Rows ───────────────────────────────────────────────────
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

    row.hl = row:CreateTexture(nil, "BACKGROUND")
    row.hl:SetAllPoints()
    row.hl:SetColorTexture(0.20, 0.45, 0.65, 0.20)
    row.hl:Hide()

    row.num = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.num:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -1)
    row.num:SetWidth(18)
    row.num:SetJustifyH("LEFT")

    row.text = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 18, 0)
    row.text:SetPoint("TOPRIGHT", row, "TOPRIGHT", 0, 0)
    row.text:SetJustifyH("LEFT")
    row.text:SetWordWrap(true)

    row:SetScript("OnEnter", function(self)
        if self.step and (self.step.x or not self.done) then self.hl:Show() end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(self.step and self.step.t or "", 1, 1, 1, true)
        if self.step and self.step.x and self.step.y then
            GameTooltip:AddLine("|cFF00FF00" .. L["Click to set waypoint"] .. "|r")
        end
        GameTooltip:AddLine("|cFF888888" .. L["Right-click to tick off"] .. "|r")
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function(self)
        self.hl:Hide()
        GameTooltip:Hide()
    end)
    row:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            manualDone[self.index] = not manualDone[self.index]
            Tracker:Refresh()
            return
        end
        SetWaypointTo(self.index, self.step)
    end)

    rows[index] = row
    return row
end

-- ─── Frame ──────────────────────────────────────────────────
local function SavePosition()
    if not frame then return end
    local point, _, relPoint, x, y = frame:GetPoint()
    MCL_GUIDE_SETTINGS.stepTrackerAnchor = { point = point, relPoint = relPoint, x = x, y = y }
end

local function GetFrame()
    if frame then return frame end

    local f = CreateFrame("Frame", "MCL_GuideStepTracker", UIParent, "BackdropTemplate")
    f:SetFrameStrata("HIGH")
    f:SetSize(WIDTH, 120)
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
    f:SetBackdropColor(0.06, 0.06, 0.09, 0.94)
    f:SetBackdropBorderColor(0.20, 0.40, 0.60, 0.80)

    f.headerBg = f:CreateTexture(nil, "BACKGROUND")
    f.headerBg:SetPoint("TOPLEFT", 1, -1)
    f.headerBg:SetPoint("TOPRIGHT", -1, -1)
    f.headerBg:SetHeight(HEADER_H - 2)
    f.headerBg:SetColorTexture(0.08, 0.08, 0.12, 0.98)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", PAD, -9)
    f.title:SetPoint("TOPRIGHT", -28, -9)
    f.title:SetJustifyH("LEFT")
    f.title:SetWordWrap(false)
    f.title:SetTextColor(unpack(COLOR_TITLE))

    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetSize(24, 24)
    f.close:SetPoint("TOPRIGHT", -2, -2)
    f.close:SetScript("OnClick", function() Tracker:Hide() end)

    f.footer = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.footer:SetPoint("BOTTOMLEFT", PAD, 6)
    f.footer:SetPoint("BOTTOMRIGHT", -PAD, 6)
    f.footer:SetJustifyH("LEFT")
    f.footer:SetTextColor(unpack(COLOR_HINT))

    local anchor = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.stepTrackerAnchor
    if anchor and anchor.point then
        f:SetPoint(anchor.point, UIParent, anchor.relPoint or anchor.point, anchor.x or 0, anchor.y or 0)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 300, 0)
    end

    frame = f
    return f
end

-- ─── Public API ─────────────────────────────────────────────
function Tracker:Refresh()
    if not frame or not frame:IsShown() or not activeSteps then return end

    local done, current, allDone = Evaluate()
    if not done then return end

    ReleaseRows()

    local y = -(HEADER_H + ROW_PAD)
    for i, step in ipairs(activeSteps) do
        local row = AcquireRow(i)
        row.index = i
        row.step  = step
        row.done  = done[i]

        local numText, color
        if done[i] then
            numText = "|cFF59B36A" .. i .. ".|r"
            color = COLOR_DONE
        elseif i == current then
            numText = "|cFFF2BF33" .. i .. ".|r"
            color = COLOR_ACTIVE
        else
            numText = "|cFF8A939C" .. i .. ".|r"
            color = COLOR_PENDING
        end

        row.num:SetText(numText)

        local label = step.t or ""
        if step.n and step.x and step.y then
            label = label .. string.format("  |cFF6E7A85(%.1f, %.1f)|r", step.x, step.y)
        end
        if done[i] then
            label = "|cFF59B36A" .. label:gsub("|cFF%x%x%x%x%x%x", ""):gsub("|r", "") .. "|r"
        end
        row.text:SetText(label)
        row.text:SetTextColor(unpack(color))

        local h = math.max(row.text:GetStringHeight(), 12) + 4
        row:SetHeight(h)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
        row:Show()

        y = y - h - 2
    end

    -- Auto-advance the waypoint as steps complete, but only while it is
    -- still pointing at a step we set — if you clicked a different row,
    -- that choice stands.
    if current and trackedStep and trackedStep ~= current then
        local prev = activeSteps[trackedStep]
        if not prev or done[trackedStep] then
            SetWaypointTo(current, activeSteps[current])
        end
    end

    if allDone then
        frame.footer:SetText("|cFF59B36A" .. L["Complete!"] .. "|r")
    else
        frame.footer:SetText(L["Click a step to waypoint it."])
    end

    frame:SetHeight(math.abs(y) + FOOTER_H + ROW_PAD)
end

-- Open the tracker for a treasure coord that carries a step list.
function Tracker:Show(mountData, waypoint)
    if not waypoint or not waypoint.steps or #waypoint.steps == 0 then return false end

    local f = GetFrame()

    -- Switching objective resets the hand-ticked flags
    if activeWp ~= waypoint then
        wipe(manualDone)
        trackedStep = nil
    end

    activeSteps = waypoint.steps
    activeWp    = waypoint
    activeName  = waypoint.n or (mountData and (mountData.mountName or mountData.name)) or ""

    f.title:SetText(activeName)
    f:Show()
    self:Refresh()

    -- Point the way at the first outstanding step straight away
    local _, current = Evaluate()
    if current then SetWaypointTo(current, activeSteps[current]) end

    return true
end

function Tracker:Hide()
    if frame then frame:Hide() end
    activeSteps = nil
    activeWp    = nil
    trackedStep = nil
    wipe(manualDone)
end

function Tracker:IsShown()
    return frame and frame:IsShown()
end

-- ─── Auto-progression ───────────────────────────────────────
-- Re-evaluate on the events that can move a step along.  Bag and aura
-- updates are noisy, so the refresh is cheap and guarded on the window
-- actually being open.
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
