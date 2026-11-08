-- * ------------------------------------------------------
-- * Themes.lua
-- * Art styles. Everything that draws a colour goes through here.
-- * ------------------------------------------------------
--
-- Constants.lua always described itself as the central palette, but
-- nothing outside Widgets.lua ever read it: core/frames.lua alone had 255
-- colours written straight into the call site, 580 across the addon, in
-- 197 distinct values.  Swapping C.COLORS therefore changed nothing, which
-- is why this file exists - the palette had to become real before a second
-- art style was possible.
--
-- Two rules hold this together:
--
--   1. ApplyTheme MUTATES C.COLORS IN PLACE.  core/frames.lua caches the
--      table (`local COLORS = C.COLORS`) at load, and so does the
--      MCL_COLORS global below.  Reassigning C.COLORS would leave every one
--      of those aliases pointing at the old theme.  Wipe and refill, never
--      replace.
--
--   2. The Modern theme's values are the ones that were already in the
--      code.  Where several near-identical greys were in use for the same
--      job - 0.7/0.78/0.88 and 0.75/0.78/0.85 and 0.72/0.76/0.84 were all
--      "body text" - they collapse to one token.  Retail therefore looks
--      the same but slightly more consistent, not different.
--
-- Alpha: a token carries its usual alpha.  Where a call site needs another
-- one, MCL_SHADE("TOKEN", a) returns the token's rgb with that alpha.

local _, MCLcore = ...
local C = MCLcore.C

-- =========================================================
-- MODERN - the dark blue-grey style MCL has always had
-- =========================================================
local MODERN = {
    ---- Surfaces ----
    SURFACE_SUNKEN        = { 0.055, 0.058, 0.070, 1    },
    SURFACE_WINDOW        = { 0.078, 0.082, 0.098, 1    },
    SURFACE_PANEL         = { 0.105, 0.110, 0.130, 0.95 },
    SURFACE_RAISED        = { 0.135, 0.142, 0.168, 1    },
    SURFACE_HOVER         = { 0.170, 0.190, 0.240, 1    },
    SURFACE_SELECTED      = { 0.150, 0.200, 0.290, 1    },
    SURFACE_HEADER        = { 0.095, 0.100, 0.120, 1    },
    SURFACE_ACCENT        = { 0.100, 0.150, 0.250, 0.8  },
    SURFACE_ACCENT_STRONG = { 0.150, 0.250, 0.400, 0.9  },
    SURFACE_SUCCESS       = { 0.050, 0.150, 0.080, 0.95 },
    SURFACE_DANGER        = { 0.200, 0.050, 0.050, 0.90 },
    SURFACE_WARNING       = { 0.250, 0.150, 0.080, 0.80 },
    OVERLAY_SCRIM         = { 0,     0,     0,     0.7  },
    HIGHLIGHT_WHITE       = { 1,     1,     1,     0.08 },
    TRANSPARENT           = { 0,     0,     0,     0    },

    ---- Borders ----
    BORDER_SUBTLE         = { 0.20, 0.20, 0.25, 0.6 },
    BORDER_DEFAULT        = { 0.25, 0.25, 0.30, 0.8 },
    BORDER_STRONG         = { 0.40, 0.40, 0.45, 1   },
    BORDER_ACCENT         = { 0.30, 0.60, 0.90, 0.8 },
    BORDER_ACCENT_DIM     = { 0.20, 0.50, 0.80, 0.6 },
    BORDER_ACCENT_BRIGHT  = { 0.30, 0.70, 1.00, 1   },
    BORDER_SUCCESS        = { 0.20, 0.80, 0.30, 0.8 },
    BORDER_DANGER         = { 0.80, 0.30, 0.30, 0.8 },
    BORDER_GOLD           = { 0.80, 0.60, 0.20, 0.8 },
    BORDER_HOVER          = { 0.52, 0.82, 1.00, 1   },
    DIVIDER               = { 0.15, 0.25, 0.40, 0.9 },

    ---- Text ----
    TEXT_PRIMARY          = { 1.00, 1.00, 1.00, 1 },
    TEXT_BODY             = { 0.70, 0.78, 0.88, 1 },
    TEXT_MUTED            = { 0.50, 0.55, 0.65, 1 },
    TEXT_DISABLED         = { 0.40, 0.45, 0.50, 1 },
    TEXT_ACCENT           = { 0.40, 0.78, 0.95, 1 },
    TEXT_ACCENT_BRIGHT    = { 0.70, 0.85, 0.95, 1 },
    TEXT_SUCCESS          = { 0.30, 0.85, 0.40, 1 },
    TEXT_WARNING          = { 0.90, 0.60, 0.20, 1 },
    TEXT_DANGER           = { 0.90, 0.40, 0.40, 1 },
    TEXT_GOLD             = { 1.00, 0.82, 0.00, 1 },
    TEXT_HIGHLIGHT        = { 0.90, 0.90, 0.20, 1 },
    TEXT_INVERSE          = { 0.00, 0.00, 0.00, 1 },
    TEXT_LABEL            = { 0.55, 0.65, 0.75, 1 },   -- "Label:" in a label/value row
    TEXT_VALUE            = { 0.85, 0.85, 0.85, 1 },   -- the value after it

    ---- Icon / texture tints ----
    TINT_NONE             = { 1.00, 1.00, 1.00, 1   },
    TINT_DIM              = { 0.60, 0.60, 0.60, 0.8 },
    TINT_ACCENT           = { 0.40, 0.78, 0.95, 1   },
}

-- =========================================================
-- FOREVER - gold on near-black, after Forever's own frames
-- =========================================================
-- Forever's windows are a very dark warm brown behind an ornate gold
-- border, with gold headings, gold labels and white values.  The surfaces
-- below carry a little red and almost no blue so they sit warm against the
-- bronze edges; a neutral grey under gold trim reads as dirty.
local FOREVER = {
    ---- Surfaces ----
    SURFACE_SUNKEN        = { 0.040, 0.030, 0.020, 1    },
    SURFACE_WINDOW        = { 0.075, 0.058, 0.038, 1    },
    SURFACE_PANEL         = { 0.110, 0.085, 0.055, 0.95 },
    SURFACE_RAISED        = { 0.150, 0.115, 0.072, 1    },
    SURFACE_HOVER         = { 0.215, 0.165, 0.100, 1    },
    SURFACE_SELECTED      = { 0.280, 0.210, 0.105, 1    },
    SURFACE_HEADER        = { 0.090, 0.070, 0.045, 1    },
    SURFACE_ACCENT        = { 0.170, 0.125, 0.055, 0.8  },
    SURFACE_ACCENT_STRONG = { 0.260, 0.190, 0.080, 0.9  },
    SURFACE_SUCCESS       = { 0.060, 0.140, 0.060, 0.95 },
    SURFACE_DANGER        = { 0.220, 0.050, 0.040, 0.90 },
    SURFACE_WARNING       = { 0.280, 0.150, 0.050, 0.80 },
    OVERLAY_SCRIM         = { 0,     0,     0,     0.7  },
    HIGHLIGHT_WHITE       = { 1.000, 0.900, 0.700, 0.08 },
    TRANSPARENT           = { 0,     0,     0,     0    },

    ---- Borders: bronze trim, gold only for what is selected ----
    -- Forever uses two metals and they mean different things.  Window
    -- trim, dividers and slot edges are bronze - sampled off the character
    -- sheet at about 0.49/0.37/0.25 on the side edges and 0.59/0.45/0.30
    -- along the title bar.  Bright yellow-gold (about 0.87/0.74/0.00) is
    -- kept for the selected tab's ring.  Painting the trim in that gold
    -- makes every panel look selected, and reads yellow beside Forever's
    -- own frames.
    BORDER_SUBTLE         = { 0.300, 0.225, 0.150, 0.7 },
    BORDER_DEFAULT        = { 0.440, 0.330, 0.220, 0.9 },
    BORDER_STRONG         = { 0.560, 0.425, 0.285, 1   },
    BORDER_ACCENT         = { 0.780, 0.600, 0.300, 0.9 },
    BORDER_ACCENT_DIM     = { 0.500, 0.380, 0.250, 0.7 },
    BORDER_ACCENT_BRIGHT  = { 1.000, 0.840, 0.250, 1   },
    BORDER_SUCCESS        = { 0.300, 0.750, 0.300, 0.8 },
    BORDER_DANGER         = { 0.800, 0.250, 0.200, 0.8 },
    BORDER_GOLD           = { 1.000, 0.820, 0.000, 0.9 },
    BORDER_HOVER          = { 1.000, 0.820, 0.000, 1   },
    -- Hairlines inside a panel.  Same bronze as the trim, so a rule reads
    -- as part of the frame rather than as a darker smudge across it.
    DIVIDER               = { 0.560, 0.425, 0.285, 0.75 },

    ---- Text: gold labels, white values, as the character sheet does ----
    TEXT_PRIMARY          = { 1.000, 1.000, 1.000, 1 },
    TEXT_BODY             = { 0.920, 0.870, 0.760, 1 },
    TEXT_MUTED            = { 0.660, 0.590, 0.460, 1 },
    TEXT_DISABLED         = { 0.460, 0.410, 0.330, 1 },
    TEXT_ACCENT           = { 1.000, 0.820, 0.000, 1 },
    TEXT_ACCENT_BRIGHT    = { 1.000, 0.910, 0.550, 1 },
    TEXT_SUCCESS          = { 0.300, 0.850, 0.350, 1 },
    TEXT_WARNING          = { 1.000, 0.650, 0.150, 1 },
    TEXT_DANGER           = { 0.950, 0.400, 0.350, 1 },
    TEXT_GOLD             = { 1.000, 0.820, 0.000, 1 },
    TEXT_HIGHLIGHT        = { 1.000, 0.960, 0.400, 1 },
    TEXT_INVERSE          = { 0.000, 0.000, 0.000, 1 },
    TEXT_LABEL            = { 1.000, 0.820, 0.000, 1 },
    TEXT_VALUE            = { 1.000, 1.000, 1.000, 1 },

    ---- Icon / texture tints ----
    TINT_NONE             = { 1.000, 1.000, 1.000, 1   },
    TINT_DIM              = { 0.650, 0.580, 0.460, 0.8 },
    TINT_ACCENT           = { 1.000, 0.820, 0.000, 1   },
}

-- =========================================================
-- Per-theme backdrops
-- =========================================================
-- Colour alone does not make Forever's look; the ornate border does.
-- These are Blizzard's own frame textures, present in every client, so
-- nothing has to ship with the addon.
local WHITE8x8 = "Interface\\Buttons\\WHITE8x8"

local MODERN_BACKDROP = {
    WINDOW      = { bgFile = WHITE8x8, edgeFile = WHITE8x8, edgeSize = 1 },
    PANEL       = { bgFile = WHITE8x8, edgeFile = WHITE8x8, edgeSize = 1 },
    BORDER_ONLY = { edgeFile = WHITE8x8, edgeSize = 1 },
    INSET       = { left = 0, right = 0, top = 0, bottom = 0 },
}

local FOREVER_BACKDROP = {
    WINDOW = {
        bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    },
    PANEL = {
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    },
    BORDER_ONLY = {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
    },
    INSET = { left = 4, right = 4, top = 4, bottom = 4 },
}

-- =========================================================
-- Legacy names
-- =========================================================
-- Widgets.lua and about forty call sites in frames.lua were already
-- reading the palette, under the names Constants.lua used to give it -
-- SURFACE_1, CHROME_BAR, ACCENT_RULE, the WP_ waypoint set.  ApplyTheme
-- empties C.COLORS before refilling it, so any name a theme does not
-- define becomes nil and the next unpack() on it throws.  These aliases
-- are therefore not tidiness; without them the addon errors on load.
--
-- Each one points at whichever new token does that job, so both themes
-- get them right without the values being written out twice.
local LEGACY = {
    ACCENT                = "TEXT_ACCENT",
    ACCENT_BLUE           = "TEXT_ACCENT",
    ACCENT_BRIGHT         = "TEXT_ACCENT_BRIGHT",
    ACCENT_RULE           = "BORDER_ACCENT_DIM",
    BORDER_DIM            = "BORDER_SUBTLE",
    CARD_BG               = "SURFACE_PANEL",
    CB_BG_OFF             = "SURFACE_WINDOW",
    CB_BG_ON              = "SURFACE_SELECTED",
    CB_BORDER_HOVER       = "BORDER_ACCENT_BRIGHT",
    CB_BORDER_OFF         = "BORDER_DEFAULT",
    CB_BORDER_ON          = "BORDER_ACCENT",
    CHROME_BAR            = "SURFACE_HEADER",
    GREEN_FLASH           = "TEXT_SUCCESS",
    HEADER_BG             = "SURFACE_HEADER",
    LABEL                 = "TEXT_BODY",
    PB_BG                 = "SURFACE_SUNKEN",
    PB_BORDER             = "BORDER_SUBTLE",
    PB_GRAY               = "TEXT_DISABLED",
    PB_TEXT               = "TEXT_PRIMARY",
    STATUS_HIGH           = "TEXT_SUCCESS",
    STATUS_NEUTRAL        = "TEXT_DISABLED",
    SURFACE_0             = "SURFACE_SUNKEN",
    SURFACE_1             = "SURFACE_WINDOW",
    SURFACE_2             = "SURFACE_PANEL",
    SURFACE_3             = "SURFACE_RAISED",
    WP_BG                 = "SURFACE_PANEL",
    WP_BG_HOVER           = "SURFACE_HOVER",
    WP_BORDER             = "BORDER_ACCENT_DIM",
    WP_BORDER_HOVER       = "BORDER_ACCENT_BRIGHT",
    WP_ICON               = "TINT_ACCENT",
    WP_TEXT               = "TEXT_ACCENT",
    WP_QUEST_BORDER       = "BORDER_GOLD",
    WP_QUEST_BORDER_HOVER = "BORDER_ACCENT_BRIGHT",
    WP_QUEST_ICON         = "TEXT_GOLD",
    WP_QUEST_TEXT         = "TEXT_HIGHLIGHT",
}

local function withLegacy(colors)
    for old, new in pairs(LEGACY) do
        if colors[old] == nil then colors[old] = colors[new] end
    end
    return colors
end

withLegacy(MODERN)
withLegacy(FOREVER)

-- =========================================================
-- Registry
-- =========================================================
C.THEMES = {
    modern = {
        key      = "modern",
        name     = "Modern",
        desc     = "MCL's own dark style. Flat panels, thin borders, blue accents.",
        colors   = MODERN,
        backdrop = MODERN_BACKDROP,
    },
    forever = {
        key      = "forever",
        name     = "Forever",
        desc     = "Gold on dark wood, cut to match Forever's own window frames.",
        colors   = FOREVER,
        backdrop = FOREVER_BACKDROP,
    },
}

-- Order the picker offers them in.
C.THEME_ORDER = { "modern", "forever" }

-- The style a fresh install starts on, per client.  A Forever player who
-- never opens the picker should still get the matching style, and a retail
-- player should not be handed gold frames they did not ask for.
function C.DefaultThemeKey()
    if C.IsForever and C.IsForever() then return "forever" end
    return "modern"
end

function C.ActiveThemeKey()
    local key = MCL_SETTINGS and MCL_SETTINGS.artStyle
    if key and C.THEMES[key] then return key end
    return C.DefaultThemeKey()
end

function C.ActiveTheme()
    return C.THEMES[C.ActiveThemeKey()] or C.THEMES.modern
end

-- =========================================================
-- Apply
-- =========================================================
-- In place, for the reason at the top of this file.
local function refill(dest, src)
    for k in pairs(dest) do dest[k] = nil end
    for k, v in pairs(src) do
        if type(v) == "table" then
            local copy = {}
            for i = 1, #v do copy[i] = v[i] end
            for kk, vv in pairs(v) do
                if type(kk) ~= "number" then copy[kk] = vv end
            end
            dest[k] = copy
        else
            dest[k] = v
        end
    end
end

function C.ApplyTheme(key)
    local theme = C.THEMES[key] or C.ActiveTheme()
    C.COLORS = C.COLORS or {}
    refill(C.COLORS, theme.colors)

    C.BACKDROP = C.BACKDROP or {}
    refill(C.BACKDROP, theme.backdrop)
    -- Widgets.lua and others still ask for these two by their old names.
    C.BACKDROP.TOOLTIP = {
        bgFile   = WHITE8x8,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    }

    C.activeTheme = theme.key
    MCL_COLORS = C.COLORS
    return theme
end

-- =========================================================
-- Globals
-- =========================================================
-- Eight of the files that draw colours never receive the addon namespace
-- at all - the guide files are built on globals - so the palette is
-- reachable as a global rather than each file growing a different alias.
-- MCL_COLORS is the same table C.COLORS points at, so it follows a theme
-- change without being reassigned anywhere.
MCL_COLORS = C.COLORS

-- Token's rgb with a different alpha, for the call sites that fade
-- something in or out.
function MCL_SHADE(token, alpha)
    local c = MCL_COLORS[token] or MCL_COLORS.TEXT_BODY
    return c[1], c[2], c[3], alpha
end

-- Token as an inline "|cFFrrggbb" escape, for text built by concatenation
-- (tooltip lines, labelled rows) where SetTextColor cannot reach.
function MCL_HEX(token)
    local c = MCL_COLORS[token] or MCL_COLORS.TEXT_BODY
    return string.format("|cFF%02X%02X%02X",
        math.floor(c[1] * 255 + 0.5),
        math.floor(c[2] * 255 + 0.5),
        math.floor(c[3] * 255 + 0.5))
end

-- Resolve at load so anything built before the settings table exists still
-- gets a complete palette; main.lua applies the saved choice on
-- ADDON_LOADED, before any frame is created.
C.ApplyTheme(C.DefaultThemeKey())
