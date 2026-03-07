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
C.COLORS = {
    -- House-style accent blue used for titles, labels, buttons
    ACCENT_BLUE         = { 0.4,  0.78, 0.95, 1 },
    -- Softer label / subtitle color
    LABEL               = { 0.7,  0.78, 0.88, 1 },
    -- Dim label for secondary info
    LABEL_DIM           = { 0.5,  0.55, 0.65, 1 },
    -- Body text
    TEXT                = { 0.8,  0.8,  0.85, 1 },
    -- White
    WHITE               = { 1,    1,    1,    1 },

    -- Backgrounds
    DARK_BG             = { 0.06, 0.06, 0.09, 1 },
    PANEL_BG            = { 0.08, 0.08, 0.1,  0.8 },
    HEADER_BG           = { 0.08, 0.08, 0.12, 1 },
    CARD_BG             = { 0.09, 0.09, 0.12, 0.95 },

    -- Borders
    BORDER_DIM          = { 0.25, 0.25, 0.3,  0.8 },
    BORDER_MEDIUM       = { 0.25, 0.25, 0.3,  1 },
    BORDER_ACCENT       = { 0.3,  0.6,  0.9,  1 },

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
    CB_BG_OFF           = { 0.08, 0.08, 0.1,  0.8 },
    CB_BG_ON            = { 0.15, 0.25, 0.4,  0.9 },
    CB_BORDER_OFF       = { 0.25, 0.25, 0.3,  1 },
    CB_BORDER_ON        = { 0.3,  0.6,  0.9,  1 },
    CB_BORDER_HOVER     = { 0.3,  0.6,  0.9,  0.8 },

    -- Progress bar
    PB_BG               = { 0.08, 0.08, 0.1,  0.8 },
    PB_BORDER           = { 0.25, 0.25, 0.3,  0.8 },
    PB_TEXT             = { 0.85, 0.9,  0.95, 1 },
    PB_HOVER            = { 0.8,  0.5,  0.9,  1 },
    PB_GRAY             = { 0.5,  0.5,  0.5,  1 },

    -- Slider
    SLIDER_TRACK_BG     = { 0.08, 0.08, 0.1,  1 },
    SLIDER_TRACK_BORDER = { 0.2,  0.2,  0.25, 0.6 },

    -- Pinned frame
    PINNED_BORDER       = { 0,    0.45, 0,    0.4 },

    -- Collected mount tint
    COLLECTED_TINT      = { 1,    1,    1,    1 },
}

-- Fallback progress bar colors (used when MCL_SETTINGS.progressColors is nil)
C.PROGRESS_FALLBACK = {
    LOW      = { 1,    0,    0    },  -- red
    MEDIUM   = { 1,    0.65, 0    },  -- orange
    HIGH     = { 0,    1,    0    },  -- green
    COMPLETE = { 0,    0.5,  1    },  -- blue
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
-- DIMENSIONS
-- =========================================================
C.DIMS = {
    -- Main frame
    MAIN_WIDTH       = 800,
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
    PB_HEIGHT        = 15,
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
