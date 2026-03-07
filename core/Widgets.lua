-- * ------------------------------------------------------
-- * Widgets.lua
-- * Reusable widget factories for the MCL house-style UI.
-- * Eliminates duplicated checkbox, progress-bar, and
-- * waypoint-button creation code.
-- * Requires: Constants.lua loaded first.
-- * ------------------------------------------------------
local _, MCLcore = ...

MCLcore.Widgets = {}
local W = MCLcore.Widgets
local C = MCLcore.C
local L   -- Will be set when locales are available

-- Lazy-init the locale reference (locales.lua loads after this file)
local function GetL()
    if not L then L = MCLcore.L or {} end
    return L
end

-- =========================================================
-- Helper: Resolve the StatusBar texture from settings
-- (single source of truth for the 4-copy pattern)
-- =========================================================
function W:GetStatusBarTexture()
    local tex = C.TEXTURES.STATUS_BAR
    if MCL_SETTINGS and MCL_SETTINGS.statusBarTexture and MCLcore.media then
        local custom = MCLcore.media:Fetch("statusbar", MCL_SETTINGS.statusBarTexture)
        if custom then tex = custom end
    end
    return tex
end

-- =========================================================
-- CHECKBOX  (house-style toggle)
-- =========================================================
-- Creates a styled checkbox with label.
-- opts = {
--   parent       : Frame        (required)
--   anchorPoint  : table        { point, relTo, relPt, xOff, yOff } or nil (defaults to TOPLEFT parent)
--   x            : number       x offset from parent TOPLEFT (shorthand, ignored if anchorPoint set)
--   y            : number       y offset from parent TOPLEFT (shorthand, ignored if anchorPoint set)
--   label        : string       display text
--   labelColor   : table        RGBA (default: C.COLORS.LABEL)
--   settingKey   : string       key into MCL_SETTINGS (auto-wired OnClick)
--   defaultOn    : boolean      whether default is "checked" when key is nil (default true)
--   invertLogic  : boolean      if true, setting stores the inverse of checked state
--   onClick      : function(self, checked) -- additional callback after setting write
-- }
-- Returns: checkbox frame, label fontstring
-- =========================================================
function W:CreateCheckbox(opts)
    local parent = opts.parent
    local cb = CreateFrame("CheckButton", nil, parent)
    cb:SetSize(C.DIMS.CB_SIZE, C.DIMS.CB_SIZE)

    -- Anchoring
    if opts.anchorPoint then
        cb:SetPoint(unpack(opts.anchorPoint))
    else
        local x = opts.x or 12
        local y = opts.y or 0
        cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end

    -- Determine initial checked state
    local settingKey = opts.settingKey
    local defaultOn = opts.defaultOn
    if defaultOn == nil then defaultOn = true end
    local invertLogic = opts.invertLogic or false

    if settingKey then
        local raw = MCL_SETTINGS[settingKey]
        if raw == nil then
            cb:SetChecked(defaultOn)
        else
            cb:SetChecked(invertLogic and not raw or raw)
        end
    else
        cb:SetChecked(defaultOn)
    end

    -- Wire the click handler to write MCL_SETTINGS
    cb.originalOnClick = function(self)
        local checked = self:GetChecked()
        if settingKey then
            MCL_SETTINGS[settingKey] = invertLogic and not checked or checked
        end
        if opts.onClick then opts.onClick(self, checked) end
    end

    -- Style the checkbox (house style)
    self:StyleCheckbox(cb)

    -- Label
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("LEFT", cb, "RIGHT", C.DIMS.CB_LABEL_OFFSET, 0)
    lbl:SetText(GetL()[opts.label] or opts.label or "")
    lbl:SetTextColor(unpack(opts.labelColor or C.COLORS.LABEL))

    return cb, lbl
end

-- =========================================================
-- Style an existing CheckButton to house style.
-- Can be called standalone when a checkbox already exists.
-- Returns: updateVisuals function
-- =========================================================
function W:StyleCheckbox(checkbox)
    checkbox:SetNormalTexture("")
    checkbox:SetPushedTexture("")
    checkbox:SetHighlightTexture("")
    checkbox:SetCheckedTexture("")

    local bg = checkbox:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(unpack(C.COLORS.CB_BG_OFF))

    local border = CreateFrame("Frame", nil, checkbox, "BackdropTemplate")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop(C.BACKDROP.BORDER_ONLY)
    border:SetBackdropBorderColor(unpack(C.COLORS.CB_BORDER_OFF))
    checkbox.borderFrame = border

    local check = checkbox:CreateTexture(nil, "OVERLAY")
    check:SetSize(C.DIMS.CB_CHECK_SIZE, C.DIMS.CB_CHECK_SIZE)
    check:SetPoint("CENTER")
    check:SetTexture(C.TEXTURES.CHECKBOX)
    check:SetDesaturated(true)
    check:SetVertexColor(unpack(C.COLORS.ACCENT_BLUE))
    check:Hide()
    checkbox.checkMark = check

    local function updateVisuals()
        if checkbox:GetChecked() then
            bg:SetColorTexture(unpack(C.COLORS.CB_BG_ON))
            border:SetBackdropBorderColor(unpack(C.COLORS.CB_BORDER_ON))
            check:Show()
        else
            bg:SetColorTexture(unpack(C.COLORS.CB_BG_OFF))
            border:SetBackdropBorderColor(unpack(C.COLORS.CB_BORDER_OFF))
            check:Hide()
        end
    end

    checkbox:SetScript("OnClick", function(self)
        updateVisuals()
        if self.originalOnClick then self.originalOnClick(self) end
    end)
    checkbox:SetScript("OnEnter", function()
        border:SetBackdropBorderColor(unpack(C.COLORS.CB_BORDER_HOVER))
    end)
    checkbox:SetScript("OnLeave", function()
        updateVisuals()
    end)

    updateVisuals()
    return updateVisuals
end

-- =========================================================
-- PROGRESS BAR  (house-style StatusBar)
-- =========================================================
-- opts = {
--   parent           : Frame        (required)
--   width            : number       (nil = fill parent via SetAllPoints)
--   height           : number       (default C.DIMS.PB_HEIGHT)
--   anchor           : table        { point, relTo, relPt, xOff, yOff }
--   showText         : boolean      (default true)
--   registerGlobal   : boolean      insert into MCLcore.statusBarFrames (default true)
--   total            : number       initial total
--   collected        : number       initial collected
-- }
-- Returns: StatusBar frame
-- =========================================================
function W:CreateProgressBar(opts)
    local parent = opts.parent
    local pBar = CreateFrame("StatusBar", nil, parent, "BackdropTemplate")

    -- Backdrop
    pBar:SetBackdrop(C.BACKDROP.PANEL)
    pBar:SetBackdropColor(unpack(C.COLORS.PB_BG))
    pBar:SetBackdropBorderColor(unpack(C.COLORS.PB_BORDER))

    -- Texture
    local tex = self:GetStatusBarTexture()
    pBar:SetStatusBarTexture(tex)
    local barTex = pBar:GetStatusBarTexture()
    if barTex then
        barTex:SetHorizTile(false)
        barTex:SetVertTile(false)
    end

    pBar:SetMinMaxValues(0, 100)
    pBar:SetValue(0)

    -- Size / anchor
    if opts.width then
        pBar:SetWidth(opts.width)
    end
    pBar:SetHeight(opts.height or C.DIMS.PB_HEIGHT)

    if opts.anchor then
        pBar:SetPoint(unpack(opts.anchor))
    elseif not opts.width then
        -- Fill parent if no explicit width given
        pBar:SetAllPoints(parent)
    end

    -- Text overlay
    if opts.showText ~= false then
        pBar.Text = pBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        pBar.Text:SetPoint("CENTER", pBar, "CENTER", 0, 0)
        pBar.Text:SetTextColor(unpack(C.COLORS.PB_TEXT))
    end

    -- Register in the global statusBarFrames array for batch texture/color updates
    if opts.registerGlobal ~= false then
        MCLcore.statusBarFrames = MCLcore.statusBarFrames or {}
        table.insert(MCLcore.statusBarFrames, pBar)
    end

    -- Initialize values if provided
    if opts.total and opts.collected then
        self:UpdateProgressBar(pBar, opts.total, opts.collected)
    end

    return pBar
end

-- =========================================================
-- Update a progress bar's value, text, and color.
-- Replaces the old global UpdateProgressBar().
-- =========================================================
function W:UpdateProgressBar(frame, total, collected)
    if not frame then return frame end
    if total == nil and collected == nil then return frame end

    if total == 0 then
        frame:SetValue(0)
        if frame.Text then frame.Text:SetText("0/0 (0%)") end
        frame:SetStatusBarColor(unpack(C.COLORS.PB_GRAY))
        return frame
    end

    frame.collected = collected
    frame.total     = total
    local pct = (collected / total) * 100
    frame:SetValue(pct)
    frame.val = pct

    if frame.Text then
        frame.Text:SetText(collected .. "/" .. total .. " (" .. math.floor(pct) .. "%)")
    end

    -- Color based on percentage
    local colors = MCL_SETTINGS and MCL_SETTINGS.progressColors
    if not colors then
        -- Fallback colors
        if pct < C.PROGRESS_THRESHOLDS.LOW then
            frame:SetStatusBarColor(unpack(C.PROGRESS_FALLBACK.LOW))
        elseif pct < C.PROGRESS_THRESHOLDS.MEDIUM then
            frame:SetStatusBarColor(unpack(C.PROGRESS_FALLBACK.MEDIUM))
        elseif pct < C.PROGRESS_THRESHOLDS.HIGH then
            frame:SetStatusBarColor(unpack(C.PROGRESS_FALLBACK.HIGH))
        else
            frame:SetStatusBarColor(unpack(C.PROGRESS_FALLBACK.COMPLETE))
        end
    else
        if pct < C.PROGRESS_THRESHOLDS.LOW then
            frame:SetStatusBarColor(colors.low.r, colors.low.g, colors.low.b)
        elseif pct < C.PROGRESS_THRESHOLDS.MEDIUM then
            frame:SetStatusBarColor(colors.medium.r, colors.medium.g, colors.medium.b)
        elseif pct < C.PROGRESS_THRESHOLDS.HIGH then
            frame:SetStatusBarColor(colors.high.r, colors.high.g, colors.high.b)
        else
            frame:SetStatusBarColor(colors.complete.r, colors.complete.g, colors.complete.b)
        end
    end

    -- Ensure correct texture
    local tex = self:GetStatusBarTexture()
    frame:SetStatusBarTexture(tex)
    local barTex = frame:GetStatusBarTexture()
    if barTex then
        barTex:SetHorizTile(false)
        barTex:SetVertTile(false)
    end

    return frame
end

-- =========================================================
-- WAYPOINT BUTTON  (house-style, TomTom + Blizzard fallback)
-- =========================================================
-- Creates a compact "Waypoint" button that sets a TomTom or
-- Blizzard user waypoint when clicked, with flash feedback.
--
-- opts = {
--   parent   : Frame        (required)
--   mapID    : number       (required)
--   x        : number       coordinate 0-100 scale (required)
--   y        : number       coordinate 0-100 scale (required)
--   title    : string       waypoint name (default "Mount")
--   anchor   : table        { point, relTo, relPt, xOff, yOff }
--   style    : string       "blue" (default) or "quest" (gold)
--   width    : number       button width (default auto-size or 80)
--   showIcon : boolean      show pin icon (default true)
-- }
-- Returns: Button frame
-- =========================================================
function W:CreateWaypointButton(opts)
    local parent = opts.parent
    local mapID  = opts.mapID
    local wx     = opts.x
    local wy     = opts.y
    local title  = opts.title or "Mount"
    local style  = opts.style or "blue"

    -- Determine color scheme
    local borderColor, borderHover, iconColor, textColor, textFlash
    if style == "quest" then
        borderColor = C.COLORS.WP_QUEST_BORDER
        borderHover = C.COLORS.WP_QUEST_BORDER_HOVER
        iconColor   = C.COLORS.WP_QUEST_ICON
        textColor   = C.COLORS.WP_QUEST_TEXT
        textFlash   = C.COLORS.GREEN_FLASH
    else
        borderColor = C.COLORS.WP_BORDER
        borderHover = C.COLORS.WP_BORDER_HOVER
        iconColor   = C.COLORS.WP_ICON
        textColor   = C.COLORS.WP_TEXT
        textFlash   = C.COLORS.GREEN_FLASH
    end

    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(opts.width or C.DIMS.WP_BUTTON_WIDTH, C.DIMS.WP_BUTTON_HEIGHT)
    btn:SetBackdrop(C.BACKDROP.PANEL)
    btn:SetBackdropColor(unpack(C.COLORS.WP_BG))
    btn:SetBackdropBorderColor(unpack(borderColor))

    -- Anchor
    if opts.anchor then
        btn:SetPoint(unpack(opts.anchor))
    end

    -- Pin icon
    if opts.showIcon ~= false then
        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(C.DIMS.WP_ICON_SIZE, C.DIMS.WP_ICON_SIZE)
        icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
        icon:SetTexture(C.TEXTURES.PIN_ICON)
        icon:SetVertexColor(unpack(iconColor))
        btn.icon = icon
    end

    -- Label
    local wpText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if btn.icon then
        wpText:SetPoint("LEFT", btn.icon, "RIGHT", 3, 0)
    else
        wpText:SetPoint("CENTER")
    end
    wpText:SetText(GetL()["Waypoint"] or "Waypoint")
    wpText:SetTextColor(unpack(textColor))
    btn.label = wpText

    -- Hover effects
    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(unpack(borderHover))
        self:SetBackdropColor(unpack(C.COLORS.WP_BG_HOVER))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(unpack(borderColor))
        self:SetBackdropColor(unpack(C.COLORS.WP_BG))
    end)

    -- Click: set waypoint
    btn:SetScript("OnClick", function()
        local normX = wx / 100
        local normY = wy / 100
        if TomTom and TomTom.AddWaypoint then
            TomTom:AddWaypoint(mapID, normX, normY, {
                title      = title,
                persistent = false,
                minimap    = true,
                world      = true,
            })
        else
            local vector = CreateVector2D(normX, normY)
            C_Map.SetUserWaypoint(UiMapPoint.CreateFromVector2D(mapID, vector))
            C_SuperTrack.SetSuperTrackedUserWaypoint(true)
        end
        OpenWorldMap(mapID)
        -- Flash confirmation
        wpText:SetTextColor(unpack(textFlash))
        wpText:SetText("Set!")
        C_Timer.After(C.TIMING.WAYPOINT_FLASH, function()
            if wpText then
                wpText:SetTextColor(unpack(textColor))
                wpText:SetText(GetL()["Waypoint"] or "Waypoint")
            end
        end)
    end)

    return btn
end

-- =========================================================
-- SETTINGS CARD  (house-style container with header)
-- =========================================================
-- opts = {
--   parent   : Frame         (required)
--   title    : string        header text
--   yOffset  : number        vertical offset from parent TOPLEFT
--   height   : number        card height
--   width    : number        nil = fill parent width with 15px margin
-- }
-- Returns: card Frame
-- =========================================================
function W:CreateSettingsCard(opts)
    local parent = opts.parent
    local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    card:SetHeight(opts.height or 120)
    card:SetBackdrop(C.BACKDROP.PANEL)
    card:SetBackdropColor(unpack(C.COLORS.CARD_BG))
    card:SetBackdropBorderColor(unpack(C.COLORS.BORDER_DIM))

    if opts.width then
        card:SetWidth(opts.width)
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, opts.yOffset or 0)
    else
        card:SetPoint("TOPLEFT", parent, "TOPLEFT", 15, opts.yOffset or 0)
        card:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -15, opts.yOffset or 0)
    end

    -- Header bar
    local header = card:CreateTexture(nil, "ARTWORK")
    header:SetColorTexture(unpack(C.COLORS.HEADER_BG))
    header:SetHeight(24)
    header:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    header:SetPoint("TOPRIGHT", card, "TOPRIGHT", -1, -1)

    local titleText = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("LEFT", header, "LEFT", 10, 0)
    titleText:SetText(GetL()[opts.title] or opts.title or "")
    titleText:SetTextColor(unpack(C.COLORS.ACCENT_BLUE))
    card.titleText = titleText

    return card
end
