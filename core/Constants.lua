-- * ------------------------------------------------------
-- * Constants.lua
-- * Centralized color, dimension, and timing constants.
-- * Eliminates magic numbers scattered across the codebase.
-- * ------------------------------------------------------
local _, MCLcore = ...

MCLcore.C = {}
local C = MCLcore.C

-- =========================================================
-- COLORS  (RGBA tables – unpack-friendly)
-- =========================================================
-- ---------------------------------------------------------
-- The palette is an ELEVATION LADDER. In a dark UI a nearer
-- surface reads as lighter, so SURFACE_0 (the sidebar, which
-- should recede) is the darkest and every card stacked on top
-- of the body steps up from it. Getting this backwards - which
-- is what the window used to do - makes cards punch holes into
-- the window instead of floating above it.
--
-- Steps are ~0.025 apart in lightness: far enough to read as a
-- deliberate level, close enough to stay one material.
-- ---------------------------------------------------------
C.COLORS = {
    ---- Surfaces ----
    SURFACE_0           = { 0.055, 0.058, 0.070, 1 },  -- app ground / nav sidebar
    SURFACE_1           = { 0.078, 0.082, 0.098, 1 },  -- main content body
    SURFACE_2           = { 0.105, 0.110, 0.130, 1 },  -- cards, category panels
    SURFACE_3           = { 0.135, 0.142, 0.168, 1 },  -- inputs, nav buttons, toggles
    SURFACE_RAISED      = { 0.170, 0.190, 0.240, 1 },  -- hover state for SURFACE_3
    SURFACE_SEL         = { 0.150, 0.200, 0.290, 1 },  -- selected nav item

    ---- Chrome ----
    CHROME_BAR          = { 0.095, 0.100, 0.120, 1 },  -- title bar / card header bar

    ---- Borders: one hue, three weights ----
    BORDER_SUBTLE       = { 0.20, 0.21, 0.26, 1 },     -- card separation
    BORDER_DEFAULT      = { 0.27, 0.28, 0.34, 1 },     -- inputs, buttons
    BORDER_STRONG       = { 0.36, 0.38, 0.46, 1 },     -- outer window edge

    ---- Accent: one blue, four tints ----
    ACCENT              = { 0.36, 0.68, 0.92, 1 },
    ACCENT_BRIGHT       = { 0.52, 0.82, 1.00, 1 },     -- hover / selected text
    ACCENT_MUTED        = { 0.24, 0.46, 0.68, 1 },     -- fills, slider track
    ACCENT_RULE         = { 0.30, 0.60, 0.90, 0.45 },  -- the ONE 1px accent rule

    ---- Text: four steps is all a window this size needs ----
    TEXT_PRIMARY        = { 0.92, 0.94, 0.98, 1 },     -- headings, active
    TEXT_BODY           = { 0.72, 0.76, 0.84, 1 },     -- default body
    TEXT_MUTED          = { 0.50, 0.54, 0.62, 1 },     -- counts, captions
    TEXT_DISABLED       = { 0.36, 0.38, 0.44, 1 },     -- placeholder

    ---- Status: desaturated, because 15 bars share one screen ----
    STATUS_LOW          = { 0.85, 0.35, 0.35, 1 },
    STATUS_MID          = { 0.90, 0.62, 0.28, 1 },
    STATUS_HIGH         = { 0.45, 0.78, 0.42, 1 },
    STATUS_COMPLETE     = { 0.36, 0.68, 0.92, 1 },     -- = ACCENT, closes the loop
    STATUS_NEUTRAL      = { 0.42, 0.44, 0.50, 1 },
    DANGER              = { 0.78, 0.28, 0.28, 1 },     -- close button hover

    -- House-style accent blue used for titles, labels, buttons
    ACCENT_BLUE         = { 0.4,  0.78, 0.95, 1 },
    -- Softer label / subtitle color
    LABEL               = { 0.72, 0.76, 0.84, 1 },
    -- Dim label for secondary info
    LABEL_DIM           = { 0.50, 0.54, 0.62, 1 },
    -- Body text
    TEXT                = { 0.8,  0.8,  0.85, 1 },
    -- White
    WHITE               = { 1,    1,    1,    1 },

    -- Backgrounds
    DARK_BG             = { 0.055, 0.058, 0.070, 1 },
    PANEL_BG            = { 0.078, 0.082, 0.098, 0.8 },
    HEADER_BG           = { 0.095, 0.100, 0.120, 1 },
    CARD_BG             = { 0.105, 0.110, 0.130, 0.95 },

    -- Borders
    BORDER_DIM          = { 0.20, 0.21, 0.26,  0.8 },
    BORDER_MEDIUM       = { 0.27, 0.28, 0.34,  1 },
    BORDER_ACCENT       = { 0.30, 0.60, 0.90,  1 },

    -- Waypoint buttons
    WP_BG               = { 0.12, 0.12, 0.18, 0.9 },
    WP_BG_HOVER         = { 0.18, 0.18, 0.26, 1 },
    WP_BORDER           = { 0.2,  0.6,  0.9,  0.6 },
    WP_BORDER_HOVER     = { 0.3,  0.7,  1,    1 },
    WP_ICON             = { 0.2,  0.6,  0.9,  1 },
    WP_TEXT             = { 0.4,  0.78, 0.95, 1 },

    -- Quest waypoint variant (gold)
    WP_QUEST_BORDER       = { 0.9,  0.7,  0.2,  0.6 },
    WP_QUEST_BORDER_HOVER = { 1,    0.8,  0.3,  1 },
    WP_QUEST_ICON         = { 0.9,  0.7,  0.2,  1 },
    WP_QUEST_TEXT         = { 0.95, 0.82, 0.4,  1 },

    -- Flash colors (waypoint "Set!" confirmation)
    GREEN_FLASH         = { 0.3,  0.85, 0.4,  1 },

    -- Checkbox internals
    CB_BG_OFF           = { 0.078, 0.082, 0.098, 0.9 },
    CB_BG_ON            = { 0.150, 0.200, 0.290, 1 },
    CB_BORDER_OFF       = { 0.27, 0.28, 0.34, 1 },
    CB_BORDER_ON        = { 0.30, 0.60, 0.90, 1 },
    CB_BORDER_HOVER     = { 0.52, 0.82, 1.00, 0.9 },

    -- Progress bar
    PB_BG               = { 0.055, 0.058, 0.070, 0.9 },
    PB_BORDER           = { 0.20, 0.21, 0.26, 0.9 },
    PB_TEXT             = { 0.92, 0.94, 0.98, 1 },
    PB_HOVER            = { 0.52, 0.82, 1.00, 1 },
    PB_GRAY             = { 0.42, 0.44, 0.50, 1 },

    -- Slider
    SLIDER_TRACK_BG     = { 0.08, 0.08, 0.1,  1 },
    SLIDER_TRACK_BORDER = { 0.2,  0.2,  0.25, 0.6 },

    -- Pinned frame
    PINNED_BORDER       = { 0,    0.45, 0,    0.4 },

    -- Collected mount tint
    COLLECTED_TINT      = { 1,    1,    1,    1 },
}

-- Fallback progress bar colors (used when MCL_SETTINGS.progressColors is nil)
-- Deliberately desaturated: the Overview stacks fifteen of these bars on
-- one screen, and at full saturation they drown out every label near them.
C.PROGRESS_FALLBACK = {
    LOW      = { 0.85, 0.35, 0.35 },
    MEDIUM   = { 0.90, 0.62, 0.28 },
    HIGH     = { 0.45, 0.78, 0.42 },
    COMPLETE = { 0.36, 0.68, 0.92 },
}

-- Progress bar percentage thresholds
C.PROGRESS_THRESHOLDS = {
    LOW    = 33,
    MEDIUM = 66,
    HIGH   = 100,
}

-- =========================================================
-- TEXTURES
-- =========================================================
C.TEXTURES = {
    WHITE8x8       = "Interface\\Buttons\\WHITE8x8",
    STATUS_BAR     = "Interface\\TargetingFrame\\UI-StatusBar",
    TOOLTIP_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border",
    CHECKBOX       = "Interface\\Buttons\\UI-CheckBox-Check",
    PIN_ICON       = "Interface\\AddOns\\MCL\\icons\\pin",
}

-- =========================================================
-- TYPE SCALE
-- =========================================================
-- Blizzard's font objects only give us 10 / 12 / 16pt, which is a 1.2
-- ratio - far too compressed for anything to dominate. These sizes are
-- applied on top of an existing font object via C.ApplyType so the
-- window gets a real focal point.
C.TYPE = {
    DISPLAY = 20,   -- window title, page title
    HEADING = 15,   -- section headers, card headers
    SUBHEAD = 13,   -- category titles, nav labels
    BODY    = 12,   -- default
    CAPTION = 10,   -- counts, hints, placeholders
}

-- Re-size a FontString in place, keeping its font file and optionally
-- forcing an outline for the two heaviest steps.
function C.ApplyType(fontString, size, outline)
    if not fontString or not fontString.GetFont then return fontString end
    local file, _, flags = fontString:GetFont()
    if not file then return fontString end
    fontString:SetFont(file, size, outline and "OUTLINE" or flags)
    return fontString
end

-- =========================================================
-- SURFACES
-- =========================================================
-- The opacity slider used to reach exactly four backdrops, so turning
-- it down made the window vanish while every card inside stayed solid.
-- Routing surface fills through here scales them all together.
function C.Surface(token, weight)
    local c = C.COLORS[token] or C.COLORS.SURFACE_1
    local opacity = (MCL_SETTINGS and MCL_SETTINGS.opacity) or 0.94
    return c[1], c[2], c[3], (weight or 1) * opacity
end

-- =========================================================
-- DIMENSIONS
-- =========================================================
C.DIMS = {
    -- Navigation rhythm at full size. The stride is always height + gap -
    -- they used to be 32 and 28 independently, so every sidebar entry
    -- overlapped its neighbour by 4px and their 1px borders doubled up.
    -- These are the ceiling: MCL_frames:ComputeNavMetrics scales down from
    -- here when the section list is taller than the window.
    NAV_ITEM_H       = 30,
    NAV_ITEM_GAP     = 4,

    -- Shared component sizes
    CARD_HEADER_H    = 26,
    ROW_HEADER_H     = 28,
    TOGGLE_SIZE      = 16,

    -- Main frame
    MAIN_WIDTH       = 900,
    MAIN_HEIGHT      = 600,
    NAV_WIDTH        = 180,

    -- Mount card
    MOUNT_CARD_WIDTH = 400,

    -- Waypoint button
    WP_BUTTON_WIDTH  = 80,
    WP_BUTTON_HEIGHT = 16,
    WP_ICON_SIZE     = 12,

    -- Checkbox
    CB_SIZE          = 18,
    CB_CHECK_SIZE    = 14,
    CB_LABEL_OFFSET  = 8,

    -- Progress bar
    PB_HEIGHT        = 18,
    PB_WIDTH         = 150,
    PB_EDGE_SIZE     = 1,

    -- Mount grid defaults
    MOUNTS_PER_ROW_MIN     = 6,
    MOUNTS_PER_ROW_MAX     = 24,
    MOUNTS_PER_ROW_DEFAULT = 12,
    MOUNT_SPACING          = 4,

    -- Category padding
    CATEGORY_PADDING = 20,
}

-- =========================================================
-- TIMING (seconds)
-- =========================================================
C.TIMING = {
    WAYPOINT_FLASH     = 1.5,
    UI_REFRESH         = 0.1,
    UI_FAST            = 0.05,
    TOOLTIP_RETRY      = 0.15,
    TOAST_DELAY        = 0.5,
    BATCH_DELAY        = 0.02,
    COLLECTION_RETRY   = 2,
    MOUNT_POLL_INTERVAL = 1,
}

-- =========================================================
-- BACKDROP templates (reusable BackdropInfo tables)
-- =========================================================
C.BACKDROP = {
    PANEL = {
        bgFile   = C.TEXTURES.WHITE8x8,
        edgeFile = C.TEXTURES.WHITE8x8,
        edgeSize = 1,
    },
    TOOLTIP = {
        bgFile   = C.TEXTURES.WHITE8x8,
        edgeFile = C.TEXTURES.TOOLTIP_BORDER,
        edgeSize = 8,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    },
    BORDER_ONLY = {
        edgeFile = C.TEXTURES.WHITE8x8,
        edgeSize = 1,
    },
}

-- =========================================================
-- COMPARE / MESSAGING
-- =========================================================
C.COMPARE = {
    CHUNK_SIZE      = 230,
    CHUNK_DELAY     = 0.4,
    MAX_RETRIES     = 3,
    CONSENT_TIMEOUT = 30,
    PARTY_TIMEOUT   = 8,
}

-- =========================================================
-- SEARCH
-- =========================================================
C.SEARCH = {
    MAX_RESULTS = 50,
}
