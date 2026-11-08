-- * ------------------------------------------------------
-- * StylePicker.lua
-- * First-run art style choice, and the way back to it later.
-- * ------------------------------------------------------
--
-- Shown once, on the first login after installing.  It is deliberately
-- shown BEFORE the main window is built: picking a style then costs
-- nothing, because no frame has been coloured yet.  Changing it later is
-- the expensive case - every frame already carries the old theme's
-- colours in its backdrop - so that path asks for a reload instead of
-- pretending it can repaint them.

local _, MCLcore = ...
local C = MCLcore.C
local L = MCLcore.L or setmetatable({}, { __index = function(_, k) return k end })

MCLcore.StylePicker = {}
local Picker = MCLcore.StylePicker

local DIALOG_W, DIALOG_H = 460, 300
local CARD_W, CARD_H = 196, 170

-- ---------------------------------------------------------
-- A small mock of the MCL window, drawn in a theme's own
-- colours.  Describing the two styles in words is far less
-- use than showing the player the actual palette.
-- ---------------------------------------------------------
local function BuildPreview(parent, theme)
    local colors = theme.colors
    local function col(token, fallbackAlpha)
        local c = colors[token] or colors.TEXT_BODY
        return c[1], c[2], c[3], fallbackAlpha or c[4] or 1
    end

    local p = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    p:SetSize(CARD_W - 24, 86)
    p:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = MCL_PixelEdge(p),
    })
    p:SetBackdropColor(col("SURFACE_WINDOW"))
    p:SetBackdropBorderColor(col("BORDER_STRONG"))

    -- title bar
    local bar = p:CreateTexture(nil, "ARTWORK")
    bar:SetPoint("TOPLEFT", 1, -1)
    bar:SetPoint("TOPRIGHT", -1, -1)
    bar:SetHeight(16)
    bar:SetColorTexture(col("SURFACE_HEADER"))

    local title = p:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("LEFT", bar, "LEFT", 6, 0)
    title:SetText("MCL")
    title:SetTextColor(col("TEXT_ACCENT"))

    -- sidebar
    local nav = p:CreateTexture(nil, "ARTWORK")
    nav:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, 0)
    nav:SetPoint("BOTTOMLEFT", p, "BOTTOMLEFT", 1, 1)
    nav:SetWidth(44)
    nav:SetColorTexture(col("SURFACE_SUNKEN"))

    -- a selected nav row and two quiet ones
    local rows = { "SURFACE_SELECTED", "SURFACE_RAISED", "SURFACE_RAISED" }
    for i, token in ipairs(rows) do
        local r = p:CreateTexture(nil, "OVERLAY")
        r:SetPoint("TOPLEFT", nav, "TOPLEFT", 4, -4 - (i - 1) * 14)
        r:SetSize(36, 10)
        r:SetColorTexture(col(token))
    end

    -- a card with a progress bar, the thing the window is mostly made of
    local card = CreateFrame("Frame", nil, p, "BackdropTemplate")
    card:SetPoint("TOPLEFT", nav, "TOPRIGHT", 6, -4)
    card:SetPoint("BOTTOMRIGHT", p, "BOTTOMRIGHT", -6, 6)
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = MCL_PixelEdge(card),
    })
    card:SetBackdropColor(col("SURFACE_PANEL"))
    card:SetBackdropBorderColor(col("BORDER_SUBTLE"))

    local label = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", 6, -5)
    label:SetText(L["Collected"] or "Collected")
    label:SetTextColor(col("TEXT_BODY"))

    local track = card:CreateTexture(nil, "ARTWORK")
    track:SetPoint("BOTTOMLEFT", 6, 8)
    track:SetPoint("BOTTOMRIGHT", -6, 8)
    track:SetHeight(9)
    track:SetColorTexture(col("SURFACE_SUNKEN"))

    local fill = card:CreateTexture(nil, "OVERLAY")
    fill:SetPoint("TOPLEFT", track, "TOPLEFT", 0, 0)
    fill:SetPoint("BOTTOMLEFT", track, "BOTTOMLEFT", 0, 0)
    fill:SetWidth(52)
    fill:SetColorTexture(col("TEXT_SUCCESS"))

    return p
end

-- ---------------------------------------------------------
local function BuildCard(parent, themeKey, onPick)
    local theme = C.THEMES[themeKey]
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetSize(CARD_W, CARD_H)
    card:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })

    -- The dialog itself is drawn in the ACTIVE theme; each card is drawn
    -- in the theme it offers, so the two sit side by side as themselves.
    local function paint(hover)
        local active = C.COLORS
        card:SetBackdropColor(active.SURFACE_PANEL[1], active.SURFACE_PANEL[2],
                              active.SURFACE_PANEL[3], 1)
        local edge = hover and active.BORDER_ACCENT_BRIGHT or active.BORDER_DEFAULT
        card:SetBackdropBorderColor(edge[1], edge[2], edge[3], edge[4] or 1)
    end
    paint(false)

    local name = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOP", 0, -10)
    name:SetText(L[theme.name] or theme.name)

    local preview = BuildPreview(card, theme)
    preview:SetPoint("TOP", name, "BOTTOM", 0, -8)

    local desc = card:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    desc:SetPoint("TOPLEFT", preview, "BOTTOMLEFT", 0, -8)
    desc:SetPoint("TOPRIGHT", preview, "BOTTOMRIGHT", 0, -8)
    desc:SetJustifyH("CENTER")
    desc:SetJustifyV("TOP")
    desc:SetHeight(34)
    desc:SetText(L[theme.desc] or theme.desc)

    card:SetScript("OnEnter", function()
        paint(true)
        name:SetTextColor(C.COLORS.TEXT_ACCENT_BRIGHT[1], C.COLORS.TEXT_ACCENT_BRIGHT[2],
                          C.COLORS.TEXT_ACCENT_BRIGHT[3], 1)
    end)
    card:SetScript("OnLeave", function()
        paint(false)
        name:SetTextColor(C.COLORS.TEXT_PRIMARY[1], C.COLORS.TEXT_PRIMARY[2],
                          C.COLORS.TEXT_PRIMARY[3], 1)
    end)
    card:SetScript("OnClick", function() onPick(themeKey) end)

    name:SetTextColor(C.COLORS.TEXT_PRIMARY[1], C.COLORS.TEXT_PRIMARY[2],
                      C.COLORS.TEXT_PRIMARY[3], 1)
    return card
end

-- ---------------------------------------------------------
-- needsReload: a later change from the settings panel cannot repaint
-- frames that already exist, so it offers a reload instead of claiming
-- the switch has happened.
-- ---------------------------------------------------------
function Picker:Show(needsReload)
    if self.frame and self.frame:IsShown() then return end

    local f = self.frame
    if not f then
        f = CreateFrame("Frame", "MCL_StylePicker", UIParent, "BackdropTemplate")
        f:SetSize(DIALOG_W, DIALOG_H)
        f:SetPoint("CENTER")
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)
        self.frame = f
    end

    f:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 2,
    })
    f:SetBackdropColor(C.COLORS.SURFACE_WINDOW[1], C.COLORS.SURFACE_WINDOW[2],
                       C.COLORS.SURFACE_WINDOW[3], 1)
    f:SetBackdropBorderColor(C.COLORS.BORDER_STRONG[1], C.COLORS.BORDER_STRONG[2],
                             C.COLORS.BORDER_STRONG[3], 1)

    if not f.title then
        f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        f.title:SetPoint("TOP", 0, -16)
        f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        f.subtitle:SetPoint("TOP", f.title, "BOTTOM", 0, -6)
    end
    f.title:SetText(L["Choose a style"] or "Choose a style")
    f.title:SetTextColor(C.COLORS.TEXT_ACCENT[1], C.COLORS.TEXT_ACCENT[2],
                         C.COLORS.TEXT_ACCENT[3], 1)
    f.subtitle:SetText(L["Style subtitle"] or
        "You can change this later in MCL's settings.")
    f.subtitle:SetTextColor(C.COLORS.TEXT_MUTED[1], C.COLORS.TEXT_MUTED[2],
                            C.COLORS.TEXT_MUTED[3], 1)

    local function pick(key)
        MCL_SETTINGS = MCL_SETTINGS or {}
        local previous = MCL_SETTINGS.artStyle
        MCL_SETTINGS.artStyle = key
        MCL_SETTINGS.artStyleChosen = true
        C.ApplyTheme(key)
        f:Hide()
        if needsReload and previous and previous ~= key then
            -- Frames already built still hold the old colours.
            Picker:EnsureReloadPrompt()
            StaticPopup_Show("MCL_STYLE_RELOAD")
        end
    end

    if not f.cards then
        f.cards = {}
        local n = #C.THEME_ORDER
        local totalW = n * CARD_W + (n - 1) * 16
        for i, key in ipairs(C.THEME_ORDER) do
            local card = BuildCard(f, key, pick)
            card:SetPoint("TOPLEFT", f, "TOPLEFT",
                (DIALOG_W - totalW) / 2 + (i - 1) * (CARD_W + 16), -72)
            f.cards[i] = card
        end
    else
        -- Reopened from settings: the click handler closes over `pick`,
        -- which closes over this call's `needsReload`, so rebind it.
        for i, card in ipairs(f.cards) do
            local key = C.THEME_ORDER[i]
            card:SetScript("OnClick", function() pick(key) end)
        end
    end

    f:Show()
end

-- Shown once per install.
function Picker:MaybePromptOnLogin()
    if MCL_SETTINGS and MCL_SETTINGS.artStyleChosen then return end
    -- A beat after login so it does not fight the loading screen.
    if C_Timer and C_Timer.After then
        C_Timer.After(1.5, function() Picker:Show(false) end)
    else
        Picker:Show(false)
    end
end

-- The reload prompt is registered on demand, not at file load.  Writing
-- into Blizzard's StaticPopupDialogs is ordinary addon practice, but it
-- is still a write into a Blizzard global at load time, and only a
-- player who changes style after the fact ever needs it - never the
-- login path this file otherwise exists for.
local reloadPromptRegistered = false

function Picker:EnsureReloadPrompt()
    if reloadPromptRegistered then return end
    reloadPromptRegistered = true
    StaticPopupDialogs = StaticPopupDialogs or {}
    StaticPopupDialogs["MCL_STYLE_RELOAD"] = {
        text = L["Style reload prompt"] or
            "MCL's art style has changed. Reload the interface to apply it everywhere?",
        button1 = L["Reload"] or "Reload",
        button2 = L["Later"] or "Later",
        OnAccept = function() ReloadUI() end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
end
