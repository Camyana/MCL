-- =============================================================
-- GuideZonePanel.lua    Compact icon strip on the World Map
--
-- Shows mount icons for the currently viewed zone along the
-- edge of the map.  Hover any icon for full details;
-- click to place a waypoint.  A small tab toggles the strip.
--
-- Ctrl+Drag  the tab to reposition.
-- Alt+Click   the tab to cycle flyout direction (↓ ↑ → ←).
-- Shift+Click the tab to toggle child-map mount visibility.
-- =============================================================

local Guide = MCL_GUIDE

Guide.ZonePanel = Guide.ZonePanel or {}
local Panel = Guide.ZonePanel

-- Layout
local ICON_SIZE    = 34
local ICON_PAD     = 3
local STRIDE       = ICON_SIZE + ICON_PAD   -- 37px per icon
local TAB_SIZE     = 24
local COLOR_HEADER = { r = 0.12, g = 0.72, b = 0.92 }

-- Flyout direction: DOWN, UP, RIGHT, LEFT
local FLYOUT_ORDER = { "DOWN", "UP", "RIGHT", "LEFT" }
local FLYOUT_ARROWS = {
    DOWN  = { expand = "<<", collapse = ">>" },
    UP    = { expand = "<<", collapse = ">>" },
    RIGHT = { expand = "<<", collapse = ">>" },
    LEFT  = { expand = ">>", collapse = "<<" },
}

local panelExpanded = true
local scrollOffset  = 0

-- Icon pool
local iconPool    = {}
local activeIcons = {}
local mountList   = {}

-- ─── Flyout helper ──────────────────────────────────────────
local function GetFlyout()
    return MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.zonePanelFlyout or "DOWN"
end

local function CycleFlyout()
    local cur = GetFlyout()
    for i, d in ipairs(FLYOUT_ORDER) do
        if d == cur then
            MCL_GUIDE_SETTINGS.zonePanelFlyout = FLYOUT_ORDER[(i % #FLYOUT_ORDER) + 1]
            return MCL_GUIDE_SETTINGS.zonePanelFlyout
        end
    end
    MCL_GUIDE_SETTINGS.zonePanelFlyout = "DOWN"
    return "DOWN"
end

local function GetArrowText()
    local dir = GetFlyout()
    local t = FLYOUT_ARROWS[dir] or FLYOUT_ARROWS.DOWN
    return panelExpanded and t.expand or t.collapse
end

local function AcquireIcon(parent)
    local btn = table.remove(iconPool)
    if not btn then
        btn = CreateFrame("Button", nil, parent)
        btn:SetSize(ICON_SIZE, ICON_SIZE)

        btn.tex = btn:CreateTexture(nil, "ARTWORK")
        btn.tex:SetAllPoints()
        btn.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        -- collected check
        btn.check = btn:CreateTexture(nil, "OVERLAY")
        btn.check:SetSize(14, 14)
        btn.check:SetPoint("BOTTOMRIGHT", 2, -2)
        btn.check:SetAtlas("Tracker-Check")
        btn.check:Hide()

        -- highlight
        btn.hl = btn:CreateTexture(nil, "HIGHLIGHT")
        btn.hl:SetAllPoints()
        btn.hl:SetColorTexture(1, 1, 1, 0.25)

        btn:SetScript("OnEnter", function(self)
            if self.mountData then
                Panel:ShowIconTooltip(self)
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        btn:SetScript("OnClick", function(self)
            if not self.mountData then return end
            if IsControlKeyDown() then
                -- Ctrl+Click: preview mount with DressUpMount
                DressUpMount(self.mountData.mountID)
            else
                -- Left-click: place map pin / waypoint
                if Guide.MapPins then
                    Guide.MapPins:PinMount(self.mountData)
                end
            end
        end)
    end

    btn:SetParent(parent)
    btn:Show()
    table.insert(activeIcons, btn)
    return btn
end

local function ReleaseAllIcons()
    for i = #activeIcons, 1, -1 do
        local btn = activeIcons[i]
        btn:Hide()
        btn:ClearAllPoints()
        btn.mountData = nil
        btn.tex:SetDesaturated(false)
        btn.check:Hide()
        table.insert(iconPool, btn)
        activeIcons[i] = nil
    end
end

-- Frames
local panelFrame, tabButton

local function GetMaxVisible()
    if not panelFrame then return 1 end
    local anchor = WorldMapFrame.ScrollContainer or WorldMapFrame
    local dir = GetFlyout()
    local available
    if dir == "DOWN" or dir == "UP" then
        available = anchor:GetHeight() - TAB_SIZE - 8
    else
        available = anchor:GetWidth() - TAB_SIZE - 8
    end
    return math.max(1, math.floor(available / STRIDE))
end

local function LayoutIcons()
    ReleaseAllIcons()
    if #mountList == 0 then return end

    local maxVis = GetMaxVisible()
    local first  = scrollOffset + 1
    local last   = math.min(scrollOffset + maxVis, #mountList)
    local dir    = GetFlyout()

    local idx = 0
    for i = first, last do
        local rec = mountList[i]
        local btn = AcquireIcon(panelFrame)
        btn.mountData = rec
        btn.tex:SetTexture(rec.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
        btn.tex:SetDesaturated(rec.isCollected == true)
        btn.check:SetShown(rec.isCollected == true)

        if dir == "DOWN" then
            btn:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", 0, -(idx * STRIDE))
        elseif dir == "UP" then
            btn:SetPoint("BOTTOMLEFT", panelFrame, "BOTTOMLEFT", 0, idx * STRIDE)
        elseif dir == "RIGHT" then
            btn:SetPoint("TOPLEFT", panelFrame, "TOPLEFT", idx * STRIDE, 0)
        elseif dir == "LEFT" then
            btn:SetPoint("TOPRIGHT", panelFrame, "TOPRIGHT", -(idx * STRIDE), 0)
        end
        idx = idx + 1
    end

    local count = idx
    if dir == "DOWN" or dir == "UP" then
        panelFrame:SetSize(ICON_SIZE, math.max(ICON_SIZE, count * STRIDE - ICON_PAD))
    else
        panelFrame:SetSize(math.max(ICON_SIZE, count * STRIDE - ICON_PAD), ICON_SIZE)
    end
end

local function OnMouseWheel(_, delta)
    if #mountList == 0 then return end
    local maxVis = GetMaxVisible()
    local maxOff = math.max(0, #mountList - maxVis)
    scrollOffset = math.max(0, math.min(scrollOffset - delta, maxOff))
    LayoutIcons()
end

local function TogglePanel()
    if not panelFrame then return end
    panelExpanded = not panelExpanded
    if panelExpanded then
        panelFrame:Show()
        if tabButton then tabButton.arrow:SetText(GetArrowText()) end
        Panel:Refresh()
    else
        panelFrame:Hide()
        if tabButton then tabButton.arrow:SetText(GetArrowText()) end
    end
end

-- ─── Anchor the panel frame relative to the tab ─────────────
local function AnchorPanelToTab()
    if not panelFrame or not tabButton then return end
    panelFrame:ClearAllPoints()
    local dir = GetFlyout()
    if dir == "DOWN" then
        panelFrame:SetPoint("TOPLEFT", tabButton, "BOTTOMLEFT", 0, -4)
    elseif dir == "UP" then
        panelFrame:SetPoint("BOTTOMLEFT", tabButton, "TOPLEFT", 0, 4)
    elseif dir == "RIGHT" then
        panelFrame:SetPoint("TOPLEFT", tabButton, "TOPRIGHT", 4, 0)
    elseif dir == "LEFT" then
        panelFrame:SetPoint("TOPRIGHT", tabButton, "TOPLEFT", -4, 0)
    end
end

-- ─── Apply saved (or default) anchor to the tab button ──────
local function ApplyTabAnchor()
    if not tabButton then return end
    local anchor = WorldMapFrame.ScrollContainer or WorldMapFrame
    tabButton:ClearAllPoints()
    local saved = MCL_GUIDE_SETTINGS and MCL_GUIDE_SETTINGS.zonePanelAnchor
    if saved and saved.point and saved.x and saved.y then
        tabButton:SetPoint(saved.point, anchor, saved.point, saved.x, saved.y)
    else
        tabButton:SetPoint("TOPLEFT", anchor, "TOPLEFT", 4, -4)
    end
end

-- ─── Save tab position after drag ───────────────────────────
local function SaveTabAnchor()
    if not tabButton then return end
    local anchor = WorldMapFrame.ScrollContainer or WorldMapFrame
    -- Get tab center in anchor-relative coords
    local aL, aB, aW, aH = anchor:GetRect()
    local tL, tB, tW, tH = tabButton:GetRect()
    if not aL or not tL then return end

    -- Relative position (0-1)
    local relX = (tL - aL) / aW
    local relY = (tB - aB) / aH

    -- Choose nearest corner/edge anchor point
    local point, offX, offY
    if relX < 0.5 and relY >= 0.5 then
        -- top-left quadrant
        point = "TOPLEFT"
        offX = tL - aL
        offY = (tB + tH) - (aB + aH)
    elseif relX >= 0.5 and relY >= 0.5 then
        -- top-right quadrant
        point = "TOPRIGHT"
        offX = (tL + tW) - (aL + aW)
        offY = (tB + tH) - (aB + aH)
    elseif relX < 0.5 and relY < 0.5 then
        -- bottom-left quadrant
        point = "BOTTOMLEFT"
        offX = tL - aL
        offY = tB - aB
    else
        -- bottom-right quadrant
        point = "BOTTOMRIGHT"
        offX = (tL + tW) - (aL + aW)
        offY = tB - aB
    end

    MCL_GUIDE_SETTINGS.zonePanelAnchor = { point = point, x = offX, y = offY }
end

local function GetPanelFrame()
    if panelFrame then return panelFrame end
    if not WorldMapFrame then return nil end

    local anchor = WorldMapFrame.ScrollContainer or WorldMapFrame

    -- ── Tab button (toggle / drag handle / flyout cycle) ────
    tabButton = CreateFrame("Button", "MCL_GuideTab", WorldMapFrame, "BackdropTemplate")
    tabButton:SetSize(TAB_SIZE, TAB_SIZE)
    tabButton:SetFrameStrata("HIGH")
    tabButton:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 5) + 20)
    tabButton:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 },
    })
    tabButton:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
    tabButton:SetBackdropBorderColor(COLOR_HEADER.r, COLOR_HEADER.g, COLOR_HEADER.b, 0.8)

    tabButton.arrow = tabButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tabButton.arrow:SetPoint("CENTER")
    tabButton.arrow:SetText(GetArrowText())
    tabButton.arrow:SetTextColor(COLOR_HEADER.r, COLOR_HEADER.g, COLOR_HEADER.b)

    -- Apply saved position
    ApplyTabAnchor()

    -- ── Ctrl+Drag to reposition ─────────────────────────────
    tabButton:SetMovable(true)
    tabButton:SetClampedToScreen(true)
    tabButton:RegisterForDrag("LeftButton")

    tabButton:SetScript("OnDragStart", function(self)
        if IsControlKeyDown() then
            self:StartMoving()
            self._dragging = true
        end
    end)
    tabButton:SetScript("OnDragStop", function(self)
        if self._dragging then
            self:StopMovingOrSizing()
            self._dragging = false
            SaveTabAnchor()
            ApplyTabAnchor()   -- re-anchor with computed offsets
            AnchorPanelToTab()
        end
    end)

    -- ── Click handler: normal=toggle, alt=cycle flyout, shift=child maps ──
    tabButton:SetScript("OnClick", function(self, button)
        if IsAltKeyDown() then
            local newDir = CycleFlyout()
            self.arrow:SetText(GetArrowText())
            AnchorPanelToTab()
            Panel:Refresh()
        elseif IsShiftKeyDown() then
            MCL_GUIDE_SETTINGS.showChildMapPins = not MCL_GUIDE_SETTINGS.showChildMapPins
            Panel:Refresh()
            if Guide.MapPins then Guide.MapPins:RefreshPins() end
        else
            TogglePanel()
        end
    end)

    tabButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("MCL Guide")
        if panelFrame and panelFrame.zoneName then
            GameTooltip:AddLine(panelFrame.zoneName, 0.7, 0.7, 0.7)
        end
        if panelFrame and panelFrame.mountCount then
            GameTooltip:AddLine(panelFrame.mountCount .. " mount(s) in zone", 1, 1, 1)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFFFFFFFClick|r to " .. (panelExpanded and "collapse" or "expand"), 0.5, 0.5, 0.5)
        GameTooltip:AddLine("|cFFFFFFFFShift+Click|r to toggle child-map mounts (" .. (MCL_GUIDE_SETTINGS.showChildMapPins and "|cFF00FF00ON|r" or "|cFFFF4444OFF|r") .. ")", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("|cFFFFFFFFCtrl+Drag|r to move", 0.5, 0.5, 0.5)
        GameTooltip:AddLine("|cFFFFFFFFAlt+Click|r to change direction (" .. GetFlyout() .. ")", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    tabButton:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- ── Icon container ──────────────────────────────────────
    panelFrame = CreateFrame("Frame", "MCL_GuideZonePanel", WorldMapFrame)
    panelFrame:SetSize(ICON_SIZE, ICON_SIZE)
    panelFrame:SetFrameStrata("HIGH")
    panelFrame:SetFrameLevel((WorldMapFrame:GetFrameLevel() or 5) + 15)
    panelFrame:EnableMouse(true)
    panelFrame:EnableMouseWheel(true)
    panelFrame:SetScript("OnMouseWheel", OnMouseWheel)

    AnchorPanelToTab()

    return panelFrame
end

-- Rich tooltip: Blizzard item/mount tooltip + MCL extras
function Panel:ShowIconTooltip(btn)
    local data = btn.mountData
    if not data then return end

    GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")

    -- Try Blizzard's native tooltip: item first, then mount spell
    local usedBlizzard = false
    if data.itemId then
        GameTooltip:SetItemByID(data.itemId)
        usedBlizzard = true
    elseif data.spellId then
        GameTooltip:SetMountBySpellID(data.spellId)
        usedBlizzard = true
    end

    -- If Blizzard tooltip failed (e.g. unknown ID), fallback to plain name
    if not usedBlizzard or GameTooltip:NumLines() == 0 then
        GameTooltip:ClearLines()
        GameTooltip:AddLine(data.mountName or data.name, 1, 1, 1)
    end

    -- ── MCL source data ──
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cFF1FB7EB--- MCL Guide ---|r")

    if data.method then
        GameTooltip:AddLine("Source: " .. Guide:GetMethodText(data.method), COLOR_HEADER.r, COLOR_HEADER.g, COLOR_HEADER.b)
    end

    if data.chance then
        local txt = "1/" .. data.chance
        if data.groupSize then txt = txt .. " (group " .. data.groupSize .. ")" end
        GameTooltip:AddLine("Drop chance: " .. txt, 1, 1, 1)
    end

    if data.lockBossName then
        GameTooltip:AddLine("Boss: " .. data.lockBossName, 1, 0.82, 0)
    end

    local diff = Guide:GetDifficultyText(data.instanceDifficulties)
    if diff then
        GameTooltip:AddLine("Difficulty: " .. diff, 0.7, 0.7, 0.7)
    end

    if data.faction then
        GameTooltip:AddLine("Faction: " .. data.faction, 0.7, 0.7, 0.7)
    end
    if data.covenant then
        GameTooltip:AddLine("Covenant: " .. data.covenant, 0.7, 0.7, 0.7)
    end

    if data.rep then
        local ri = data.rep
        local label = ri.renown and "Renown" or "Reputation"
        local text = ri.factionName or "Unknown"
        if ri.levelName then text = text .. " - " .. ri.levelName end
        local live = Guide.Reputation and Guide.Reputation:GetStandingText(ri) or nil
        if live then text = text .. " |cFF888888(" .. live .. ")|r" end
        GameTooltip:AddLine(label .. ": " .. text, 0.6, 0.8, 1.0)
    end

    -- Vendor / Quartermaster location
    if data.vendorInfo then
        local vi = data.vendorInfo
        local vendorText = vi.npc or "Vendor"
        if vi.x and vi.y then
            vendorText = vendorText .. string.format(" (%.1f, %.1f)", vi.x, vi.y)
        end
        GameTooltip:AddLine("Vendor: " .. vendorText, 0.8, 0.7, 1.0)
    end

    if data.achievementId then
        local _, achName, _, achDone = GetAchievementInfo(data.achievementId)
        if achName then
            local c = achDone and "|cFF00FF00" or "|cFFFFFF00"
            local s = achDone and " (Completed)" or ""
            GameTooltip:AddLine("Achievement: " .. c .. achName .. s .. "|r", 1, 1, 1)
        end
    end

    if data.blackMarket then
        GameTooltip:AddLine("Black Market AH: |cFF00FF00Yes|r", 0.8, 0.8, 0.8)
    end

    -- Section + Category from MCL data
    if Guide.MapPins then
        local sec, cat = Guide.MapPins:GetSectionInfo(data.mountID)
        if sec then
            local origin = sec
            if cat then origin = origin .. " > " .. cat end
            GameTooltip:AddLine("Origin: " .. origin, 0.6, 0.6, 0.6)
        end
    end

    local hasCoords = false
    if data.coords then
        for _, wp in ipairs(data.coords) do
            if wp.x and wp.y then hasCoords = true; break end
        end
    end
    GameTooltip:AddLine(" ")
    if hasCoords then
        GameTooltip:AddLine("|cFF00FF00Click to set waypoint|r")
    end
    GameTooltip:AddLine("|cFF888888Ctrl+Click to preview|r")

    GameTooltip:Show()
end

-- Refresh
function Panel:Refresh()
    if not Guide.ready then return end

    local pf = GetPanelFrame()
    if not pf then return end

    scrollOffset = 0
    mountList = {}

    local mapID
    if WorldMapFrame and WorldMapFrame:IsShown() then
        mapID = WorldMapFrame:GetMapID()
    end
    if not mapID then mapID = Guide:GetCurrentMapID() end

    local zoneName = "Unknown"
    if mapID then
        local mapInfo = C_Map.GetMapInfo(mapID)
        zoneName = mapInfo and mapInfo.name or ("Map " .. mapID)

        mountList = Guide:GetMountsForZone(mapID, false)
        if #mountList == 0 and mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0 then
            mapID = mapInfo.parentMapID
            mountList = Guide:GetMountsForZone(mapID, false)
            local parentInfo = C_Map.GetMapInfo(mapID)
            if parentInfo then zoneName = zoneName .. " (" .. parentInfo.name .. ")" end
        end

        -- Flyout only shows uncollected mounts
        local filtered = {}
        for _, rec in ipairs(mountList) do
            if not (rec.isCollected == true) then
                table.insert(filtered, rec)
            end
        end
        mountList = filtered
    end

    pf.zoneName   = zoneName
    pf.mountCount = #mountList

    LayoutIcons()

    if MCL_GUIDE_SETTINGS.showZonePanel and WorldMapFrame and WorldMapFrame:IsShown() then
        if panelExpanded and #mountList > 0 then pf:Show() end
        if tabButton then tabButton:Show() end
    else
        pf:Hide()
        if tabButton then tabButton:Hide() end
    end
end

-- Map hooks
function Panel:OnMapShow()
    if MCL_GUIDE_SETTINGS.showZonePanel then
        if tabButton then tabButton:Show() end
        self:Refresh()
    end
end

function Panel:OnMapHide()
    if panelFrame then panelFrame:Hide() end
    if tabButton  then tabButton:Hide()  end
    ReleaseAllIcons()
end

local hookFrame = CreateFrame("Frame")
hookFrame:RegisterEvent("PLAYER_LOGIN")
hookFrame:SetScript("OnEvent", function()
    if not WorldMapFrame then return end

    hooksecurefunc(WorldMapFrame, "OnMapChanged", function()
        C_Timer.After(0.1, function() Panel:Refresh() end)
    end)
    WorldMapFrame:HookScript("OnShow", function()
        C_Timer.After(0.1, function() Panel:OnMapShow() end)
    end)
    WorldMapFrame:HookScript("OnHide", function()
        Panel:OnMapHide()
    end)
end)

-- Slash
SLASH_MCLGUIDE1 = "/mclguide"
SLASH_MCLGUIDE2 = "/mcg"
SlashCmdList["MCLGUIDE"] = function(msg)
    msg = (msg or ""):lower():trim()
    if msg == "hide" then
        MCL_GUIDE_SETTINGS.showZonePanel = false
        if panelFrame then panelFrame:Hide() end
        if tabButton then tabButton:Hide() end
    elseif msg == "show" then
        MCL_GUIDE_SETTINGS.showZonePanel = true
        if WorldMapFrame and WorldMapFrame:IsShown() then
            Panel:Refresh()
        else
            print("|cFF1FB7EBMCL|r Guide: Panel will show when you open the map.")
        end
    else
        MCL_GUIDE_SETTINGS.showZonePanel = not MCL_GUIDE_SETTINGS.showZonePanel
        if MCL_GUIDE_SETTINGS.showZonePanel then
            if WorldMapFrame and WorldMapFrame:IsShown() then
                Panel:Refresh()
            else
                print("|cFF1FB7EBMCL|r Guide: Panel enabled -- open your map to see it.")
            end
        else
            if panelFrame then panelFrame:Hide() end
            if tabButton then tabButton:Hide() end
            print("|cFF1FB7EBMCL|r Guide: Panel hidden.")
        end
    end
end
