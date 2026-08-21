-- * ------------------------------------------------------
-- * Anim.lua
-- * Central animation / tween manager for the MCL UI.
-- *
-- * WoW AnimationGroups can move, fade, rotate and scale a
-- * region, but they cannot animate a colour, a backdrop or a
-- * StatusBar value. Those need a tween driven from Lua, and
-- * this window can hold well over a thousand mount buttons -
-- * one OnUpdate per button would be ruinous. So every Lua
-- * tween in the addon runs off the single driver frame below
-- * and is keyed by (owner, name) so a re-triggered hover
-- * replaces its predecessor instead of fighting it.
-- *
-- * Requires: Constants.lua loaded first.
-- * ------------------------------------------------------
local _, MCLcore = ...

MCLcore.Anim = {}
local A = MCLcore.Anim

-- =========================================================
-- Settings gate
-- =========================================================
-- Animations can be turned off wholesale. When they are, every
-- helper still applies its END STATE immediately, so callers never
-- need to branch - the UI just snaps the way it always used to.
function A:IsEnabled()
    if not MCL_SETTINGS then return true end
    if MCL_SETTINGS.enableAnimations == nil then return true end
    return MCL_SETTINGS.enableAnimations and true or false
end

-- =========================================================
-- Easing
-- =========================================================
local Ease = {
    linear   = function(t) return t end,
    inQuad   = function(t) return t * t end,
    outQuad  = function(t) return 1 - (1 - t) * (1 - t) end,
    inOutQuad = function(t)
        if t < 0.5 then return 2 * t * t end
        local u = -2 * t + 2
        return 1 - (u * u) / 2
    end,
    outCubic = function(t)
        local u = 1 - t
        return 1 - u * u * u
    end,
    inOutCubic = function(t)
        if t < 0.5 then return 4 * t * t * t end
        local u = -2 * t + 2
        return 1 - (u * u * u) / 2
    end,
    -- Slight overshoot, for anything that should feel like it lands
    outBack  = function(t)
        local c1, c3 = 1.70158, 2.70158
        local u = t - 1
        return 1 + c3 * u * u * u + c1 * u * u
    end,
}
A.Ease = Ease

-- =========================================================
-- The single driver
-- =========================================================
local driver = CreateFrame("Frame", "MCL_AnimDriver")
local activeTweens = {}
local liveCount = 0

local function detach(tween)
    local owner = tween.owner
    if owner and owner.__mclTweens and owner.__mclTweens[tween.name] == tween then
        owner.__mclTweens[tween.name] = nil
    end
end

local function driverOnUpdate(_, elapsed)
    if liveCount == 0 then
        driver:SetScript("OnUpdate", nil)
        return
    end

    -- Iterate backwards so finished tweens can be swap-removed in place.
    for i = liveCount, 1, -1 do
        local tw = activeTweens[i]
        -- The loop bound is fixed at entry, so a reentrant StopAll draining
        -- the array mid-pass would otherwise leave this dereferencing nil -
        -- and liveCount below zero, which wedges the driver for good.
        if not tw then break end
        local dead = tw.cancelled

        if not dead then
            tw.elapsed = tw.elapsed + elapsed
            local t = tw.duration > 0 and (tw.elapsed / tw.duration) or 1
            if t >= 1 then t = 1 end
            local k = tw.ease(t)

            local from, to, out = tw.from, tw.to, tw.scratch
            for n = 1, tw.n do
                out[n] = from[n] + (to[n] - from[n]) * k
            end

            -- A setter that errors (usually a frame torn down mid-tween)
            -- must not take the whole driver down with it.
            local ok = pcall(tw.setter, tw.owner, out[1], out[2], out[3], out[4])
            if not ok or t >= 1 then
                dead = true
            end
        end

        if dead then
            detach(tw)
            activeTweens[i] = activeTweens[liveCount]
            activeTweens[liveCount] = nil
            liveCount = math.max(liveCount - 1, 0)
            if tw.onDone and not tw.cancelled then
                pcall(tw.onDone, tw.owner)
            end
        end
    end

    if liveCount <= 0 then
        driver:SetScript("OnUpdate", nil)
    end
end

-- =========================================================
-- Core tween
-- =========================================================
-- owner    : any table (usually a Frame) used to key + cancel the tween
-- name     : string, unique per owner; starting a tween cancels the old one
-- duration : seconds
-- from/to  : array of 1-4 numbers
-- setter   : function(owner, a, b, c, d)
-- ease     : easing name (default "outQuad")
-- onDone   : optional function(owner), only fired on natural completion
function A:Tween(owner, name, duration, from, to, setter, ease, onDone)
    if not owner or not setter then return end

    local n = #to
    if n == 0 then return end

    -- Cancel any tween already running under this key.
    self:Cancel(owner, name)

    if not self:IsEnabled() or not duration or duration <= 0 then
        pcall(setter, owner, to[1], to[2], to[3], to[4])
        if onDone then pcall(onDone, owner) end
        return
    end

    local tw = {
        owner    = owner,
        name     = name,
        duration = duration,
        elapsed  = 0,
        from     = from,
        to       = to,
        n        = n,
        scratch  = {},
        setter   = setter,
        ease     = Ease[ease or "outQuad"] or Ease.outQuad,
        onDone   = onDone,
    }

    owner.__mclTweens = owner.__mclTweens or {}
    owner.__mclTweens[name] = tw

    liveCount = liveCount + 1
    activeTweens[liveCount] = tw

    if liveCount == 1 then
        driver:SetScript("OnUpdate", driverOnUpdate)
    end

    return tw
end

function A:Cancel(owner, name)
    if not owner or not owner.__mclTweens then return end
    local tw = owner.__mclTweens[name]
    if tw then
        tw.cancelled = true
        owner.__mclTweens[name] = nil
    end
end

-- Cancel every tween on an owner and stop any animation group we
-- attached. Called from the frame-release path so a recycled frame
-- never resumes an animation belonging to its previous life.
local GROUP_KEYS = { "__mclPop", "__mclPulse", "__mclSweep", "__mclEnter" }

-- Tweens are keyed on whatever object they mutate, and several of ours
-- mutate a REGION rather than the frame: a button's label FontString, a
-- header icon Texture, the mount hover glow. ReleaseFrameChildren only
-- walks GetChildren(), which returns frames, so those have to be reached
-- through the frame that owns them.
local REGION_KEYS = { "text", "icon", "tex" }

local function cancelOwnerTweens(owner)
    if not (owner and owner.__mclTweens) then return end
    for name, tw in pairs(owner.__mclTweens) do
        tw.cancelled = true
        owner.__mclTweens[name] = nil
    end
end

function A:Release(owner)
    if not owner then return end

    cancelOwnerTweens(owner)
    for _, key in ipairs(REGION_KEYS) do
        cancelOwnerTweens(owner[key])
    end
    if owner.__mclFX then
        cancelOwnerTweens(owner.__mclFX.glow)
    end

    for _, key in ipairs(GROUP_KEYS) do
        local group = owner[key]
        if group and group.Stop then
            pcall(group.Stop, group)
        end
    end
end

-- Land every in-flight tween on its final value at once. Used when the
-- user switches animations off: freezing whatever is mid-flight would
-- leave half-faded widgets on screen, so each one is finished instead.
function A:StopAll()
    for i = liveCount, 1, -1 do
        local tw = activeTweens[i]
        if tw and not tw.cancelled then
            pcall(tw.setter, tw.owner, tw.to[1], tw.to[2], tw.to[3], tw.to[4])
        end
        if tw then detach(tw) end
        activeTweens[i] = nil
    end
    liveCount = 0
    driver:SetScript("OnUpdate", nil)
end

-- =========================================================
-- Colour tweens
-- =========================================================
local function setBackdropColor(f, r, g, b, a)
    f:SetBackdropColor(r, g, b, a)
end
local function setBorderColor(f, r, g, b, a)
    f:SetBackdropBorderColor(r, g, b, a)
end
local function setTextColor(f, r, g, b, a)
    f:SetTextColor(r, g, b, a)
end
local function setVertexColor(f, r, g, b, a)
    f:SetVertexColor(r, g, b, a)
end

local DEFAULT_HOVER_TIME = 0.14

local function tweenColor(owner, name, getter, setter, to, duration, ease)
    if not owner or not to then return end
    local ok, r, g, b, a = pcall(getter, owner)
    if not ok or r == nil then
        pcall(setter, owner, to[1], to[2], to[3], to[4] or 1)
        return
    end
    A:Tween(owner, name, duration or DEFAULT_HOVER_TIME,
        { r, g, b, a or 1 },
        { to[1], to[2], to[3], to[4] or 1 },
        setter, ease or "outQuad")
end

function A:BackdropColor(frame, to, duration, ease)
    if not (frame and frame.GetBackdropColor) then return end
    tweenColor(frame, "bg", frame.GetBackdropColor, setBackdropColor, to, duration, ease)
end

function A:BorderColor(frame, to, duration, ease)
    if not (frame and frame.GetBackdropBorderColor) then return end
    tweenColor(frame, "border", frame.GetBackdropBorderColor, setBorderColor, to, duration, ease)
end

function A:TextColor(fontString, to, duration, ease)
    if not (fontString and fontString.GetTextColor) then return end
    tweenColor(fontString, "text", fontString.GetTextColor, setTextColor, to, duration, ease)
end

function A:VertexColor(texture, to, duration, ease)
    if not (texture and texture.GetVertexColor) then return end
    tweenColor(texture, "vertex", texture.GetVertexColor, setVertexColor, to, duration, ease)
end

-- =========================================================
-- GlideTo - the workhorse for hover states
-- =========================================================
-- Moves a whole widget colour set toward a target in one call, so an
-- OnEnter/OnLeave pair reads as two lines instead of six snaps.
--
-- spec = {
--   bg     = {r,g,b,a},   -- backdrop colour
--   border = {r,g,b,a},   -- backdrop border colour
--   text   = {r,g,b,a},   -- applies to frame.text
--   icon   = {r,g,b,a},   -- applies to frame.icon (a Texture)
--   alpha  = number,      -- frame alpha
-- }
function A:GlideTo(frame, spec, duration, ease)
    if not (frame and spec) then return end
    local d = duration or DEFAULT_HOVER_TIME
    if spec.bg     then self:BackdropColor(frame, spec.bg, d, ease) end
    if spec.border then self:BorderColor(frame, spec.border, d, ease) end
    if spec.text   then self:TextColor(frame.text, spec.text, d, ease) end
    if spec.icon   then self:VertexColor(frame.icon, spec.icon, d, ease) end
    if spec.alpha then
        self:Tween(frame, "alpha", d, { frame:GetAlpha() }, { spec.alpha },
            function(f, v) f:SetAlpha(v) end, ease or "outQuad")
    end
end

-- =========================================================
-- AnimationGroup helpers (engine-side, effectively free)
-- =========================================================
local function ensureGroup(frame, key)
    local group = frame[key]
    if group then
        group:Stop()
        return group, false
    end
    group = frame:CreateAnimationGroup()
    frame[key] = group
    return group, true
end

-- Fade a frame in, optionally with a small scale-up.
-- ---------------------------------------------------------
-- A note on what is NOT here.
--
-- There is deliberately no whole-window fade helper. Alpha and scale are
-- not comparable in cost on a large frame: scale invalidates the layout of
-- the entire subtree every step, and alpha is propagated by WoW to every
-- descendant, which is the reason SetIgnoreParentAlpha exists at all.
--
-- The MCL window owns roughly four thousand frames, because SetTabs builds
-- every tab's content up front and hides all but one. Animating either
-- property on that root froze the game on open and close. Everything in
-- this file is therefore scoped to a small subtree: one button, one status
-- bar, one tab's content.
-- ---------------------------------------------------------

-- Fade a frame in while it travels a short distance to its anchor.
--
-- A bare Translation animates AWAY from the anchor and snaps back when the
-- group ends, which is the opposite of an entrance. The fix is two steps:
-- an instant zero-duration hop to the offset position, then a timed ride
-- back to zero. When the group finishes and clears its transform, the
-- frame is already home, so nothing snaps.
--
-- Only for a bounded subtree - one tab's content, not the whole window.
function A:EnterFrom(frame, dx, dy, duration)
    if not frame then return end
    duration = duration or 0.16

    if not self:IsEnabled() then
        frame:SetAlpha(1)
        return
    end

    local group = frame.__mclEnter
    if not group then
        group = frame:CreateAnimationGroup()
        group.fade = group:CreateAnimation("Alpha")
        group.fade:SetOrder(1)
        group.fade:SetFromAlpha(0)
        group.fade:SetToAlpha(1)
        group.fade:SetSmoothing("OUT")
        group.hop = group:CreateAnimation("Translation")
        group.hop:SetOrder(1)
        group.hop:SetDuration(0)
        group.ride = group:CreateAnimation("Translation")
        group.ride:SetOrder(2)
        group.ride:SetSmoothing("OUT")
        local function settle() frame:SetAlpha(1) end
        group:SetScript("OnFinished", settle)
        group:SetScript("OnStop", settle)
        frame.__mclEnter = group
    else
        group:Stop()
    end

    group.fade:SetDuration(duration)
    group.hop:SetOffset(dx or 0, dy or 0)
    group.ride:SetOffset(-(dx or 0), -(dy or 0))
    group.ride:SetDuration(duration)

    frame:SetAlpha(0)
    group:Play()
end

-- Staggered entrance for grid items. startDelay is engine-side, so a
-- thousand of these cost nothing per frame.
function A:PopIn(frame, delay, duration)
    if not frame then return end
    if not self:IsEnabled() then
        frame:SetAlpha(1)
        return
    end
    duration = duration or 0.22

    local group, fresh = ensureGroup(frame, "__mclPop")
    if fresh then
        group.a = group:CreateAnimation("Alpha")
        group.a:SetOrder(1)
        group.a:SetFromAlpha(0)
        group.a:SetToAlpha(1)
        group.a:SetSmoothing("OUT")
        group:SetScript("OnFinished", function() frame:SetAlpha(1) end)
        group:SetScript("OnStop", function() frame:SetAlpha(1) end)
    end

    group.a:SetDuration(duration)
    group.a:SetStartDelay(delay or 0)

    frame:SetAlpha(0)
    group:Play()
end

-- =========================================================
-- StatusBar value tween
-- =========================================================
-- SetValue snaps. Easing it out over half a second turns "the number
-- changed" into "you made progress", which is the whole point of a
-- collection log.
local function setBarValue(bar, v)
    bar:SetValue(v)
end

-- Is a bar allowed to animate right now?
-- SetTabs and RefreshLayout push a new value into every bar in the window -
-- roughly a hundred of them - so without this gate a rebuild turns the
-- Overview into a slot machine. Only a visible bar, in an open window,
-- outside a bulk rebuild, gets to travel.
function A:CanAnimateBar(bar)
    if not self:IsEnabled() then return false end
    if MCLcore.rebuilding then return false end
    if not (bar and bar.IsVisible and bar:IsVisible()) then return false end
    local window = MCLcore.MCL_MF
    if not (window and window:IsShown()) then return false end
    return true
end

function A:BarTo(bar, value, duration, onDone)
    if not bar then return end
    local current = bar:GetValue() or 0
    if not self:CanAnimateBar(bar) or math.abs(current - value) < 0.01 then
        self:Cancel(bar, "barvalue")
        bar:SetValue(value)
        if onDone then onDone(bar) end
        return
    end
    self:Tween(bar, "barvalue", duration or 0.45, { current }, { value },
        setBarValue, "outCubic", onDone)
end

-- One-shot sheen that sweeps across a bar. Created lazily so bars that
-- never animate never pay for it.
function A:BarSweep(bar, duration)
    if not bar or not self:IsEnabled() then return end

    if not bar.__mclSheen then
        local sheen = bar:CreateTexture(nil, "OVERLAY")
        sheen:SetTexture("Interface\\Buttons\\WHITE8x8")
        sheen:SetBlendMode("ADD")
        sheen:SetVertexColor(1, 1, 1, 0.20)
        sheen:SetWidth(26)
        sheen:Hide()
        bar.__mclSheen = sheen

        local group = sheen:CreateAnimationGroup()
        local move = group:CreateAnimation("Translation")
        move:SetOrder(1)
        move:SetSmoothing("IN_OUT")
        local fade = group:CreateAnimation("Alpha")
        fade:SetOrder(1)
        fade:SetFromAlpha(0)
        fade:SetToAlpha(1)
        group:SetScript("OnPlay", function() sheen:Show() end)
        group:SetScript("OnFinished", function() sheen:Hide() end)
        group:SetScript("OnStop", function() sheen:Hide() end)
        bar.__mclSweep = group
        bar.__mclSweepMove = move
        bar.__mclSweepFade = fade
    end

    local width = bar:GetWidth() or 0
    if width <= 0 then return end

    duration = duration or 0.55
    local sheen = bar.__mclSheen
    sheen:ClearAllPoints()
    sheen:SetPoint("TOP", bar, "TOP", 0, 0)
    sheen:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
    sheen:SetPoint("LEFT", bar, "LEFT", -30, 0)

    bar.__mclSweepMove:SetDuration(duration)
    bar.__mclSweepMove:SetOffset(width + 60, 0)
    bar.__mclSweepFade:SetDuration(duration)

    bar.__mclSweep:Stop()
    bar.__mclSweep:Play()
end
