-- * ------------------------------------------------------
-- * MCL Compare
-- * Request another MCL user's full collection and overlay
-- * it on the main addon window for side-by-side comparison.
-- * Features a modern MCL-themed UI for the full workflow.
-- * ------------------------------------------------------
local _, MCLcore = ...

MCLcore.Compare = {}
local Compare = MCLcore.Compare

-- ============================================================
-- STYLING CONSTANTS (MCL brand palette)
-- ============================================================
local S = {
    -- Backgrounds
    mainBg          = { 0.10, 0.10, 0.18 },
    headerBg        = { 0.08, 0.08, 0.12 },
    cardBg          = { 0.06, 0.06, 0.09, 0.9 },
    rowBg           = { 0.08, 0.08, 0.12, 0.6 },
    rowHoverBg      = { 0.14, 0.14, 0.22, 1 },
    btnBg           = { 0.12, 0.12, 0.16, 0.9 },
    btnHoverBg      = { 0.18, 0.22, 0.30, 1 },
    btnCloseBg      = { 0.6, 0.1, 0.1, 1 },
    -- Borders
    mainBorder      = { 0.20, 0.20, 0.25, 0.8 },
    cardBorder      = { 0.20, 0.20, 0.25, 0.6 },
    btnBorder       = { 0.30, 0.30, 0.35, 0.8 },
    accentBorder    = { 0.30, 0.60, 0.90, 1.0 },
    btnCloseHover   = { 0.8, 0.2, 0.2, 1 },
    -- Accent
    accentLine      = { 0.20, 0.60, 0.90, 0.6 },
    -- Text
    titleText       = { 0.40, 0.78, 0.95, 1 },
    normalText      = { 0.70, 0.78, 0.88, 1 },
    hoverText       = { 0.50, 0.85, 1.00, 1 },
    mutedText       = { 0.50, 0.55, 0.65, 1 },
    btnText         = { 0.65, 0.75, 0.85, 1 },
    greenText       = { 0.30, 0.85, 0.40, 1 },
    redText         = { 0.90, 0.40, 0.40, 1 },
    -- Compare indicators
    greenDot        = { 0.10, 0.90, 0.10, 0.9 },
    redDot          = { 0.90, 0.15, 0.15, 0.9 },
    -- Shared backdrop template
    backdrop = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    },
    backdropInset = {
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 },
    },
}

-- ============================================================
-- PROTOCOL CONSTANTS
-- ============================================================
local PREFIX       = "MCL_CMP"
local MSG_SCAN     = "SCAN"
local MSG_HERE     = "HERE"
local MSG_REQDATA  = "REQD"
local MSG_CHUNK    = "CHK"
local MSG_DECLINE  = "DECL"
local CHUNK_SIZE   = 230

-- ============================================================
-- STATE
-- ============================================================
local scanResponses   = {}
local scanPending     = false
local scanTimer       = nil

local incomingChunks  = {}
local requestPending  = false
local requestTarget   = nil
local requestTimer    = nil

Compare.active        = false
Compare.targetName    = nil
Compare.collectedSet  = {}
Compare.bannerFrame   = nil
Compare.pickerFrame   = nil
Compare.consentFrame  = nil
local pendingConsent  = nil  -- { requester = "Name-Realm", channel = "PARTY" }

-- ============================================================
-- HELPERS
-- ============================================================

local function GetGroupChannel()
    if IsInRaid() then return "RAID"
    elseif IsInGroup() then return "PARTY"
    end
    return nil
end

local function GetMyFullName()
    local name, realm = UnitFullName("player")
    if not realm or realm == "" then realm = GetNormalizedRealmName() end
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

local function ShortName(fullName)
    if not fullName then return "?" end
    local myRealm = GetNormalizedRealmName()
    local n, r = fullName:match("^(.+)-(.+)$")
    if n and r and r == myRealm then return n end
    return fullName
end

--- Get class colour for a unit by name (group member lookup)
local function GetClassColorForPlayer(fullName)
    -- Try each group unit
    local prefix, count
    if IsInRaid() then prefix, count = "raid", GetNumGroupMembers()
    elseif IsInGroup() then prefix, count = "party", GetNumGroupMembers() - 1
    else return RAID_CLASS_COLORS["PRIEST"] end -- fallback white-ish

    for i = 1, count do
        local unit = prefix .. i
        local unitName, unitRealm = UnitName(unit)
        if unitName then
            local full = unitName
            if unitRealm and unitRealm ~= "" then full = unitName .. "-" .. unitRealm end
            if full == fullName or unitName == fullName then
                local _, cls = UnitClass(unit)
                if cls and RAID_CLASS_COLORS[cls] then
                    return RAID_CLASS_COLORS[cls]
                end
            end
        end
    end
    return RAID_CLASS_COLORS["PRIEST"]
end

--- Combat check: returns true if safe to proceed, prints a message if not
local function CombatGuard(action)
    if InCombatLockdown() or UnitAffectingCombat("player") then
        print("|cff00CCFF[MCL]|r Cannot " .. (action or "do that") .. " during combat.")
        return false
    end
    return true
end

-- ============================================================
-- SERIALIZE / DESERIALIZE
-- ============================================================

local function SerializeMyCollection()
    local ids = {}
    local allMounts = C_MountJournal.GetMountIDs()
    if allMounts then
        for _, id in ipairs(allMounts) do
            local _, _, _, _, _, _, _, _, _, _, isCollected = C_MountJournal.GetMountInfoByID(id)
            if isCollected then
                ids[#ids + 1] = id
            end
        end
    end
    -- Delta-encode: sort IDs, send first value then differences.
    -- This roughly halves the payload size (deltas are 1-2 digits vs 3-5).
    table.sort(ids)
    local parts = {}
    local prev = 0
    for _, id in ipairs(ids) do
        parts[#parts + 1] = tostring(id - prev)
        prev = id
    end
    return "D" .. table.concat(parts, ",")  -- "D" prefix marks delta format
end

local function DeserializeCollection(str)
    local set = {}
    if not str or str == "" then return set end

    -- Check for delta-encoded format (starts with "D")
    if str:sub(1, 1) == "D" then
        local current = 0
        for deltaStr in str:sub(2):gmatch("([^,]+)") do
            local delta = tonumber(deltaStr)
            if delta then
                current = current + delta
                set[current] = true
            end
        end
    else
        -- Legacy comma-separated full IDs
        for idStr in str:gmatch("([^,]+)") do
            local id = tonumber(idStr)
            if id then set[id] = true end
        end
    end
    return set
end

-- ============================================================
-- CHUNKED SENDING
-- ============================================================

local function SendChunked(target, payload, channel)
    local chunks = {}
    for i = 1, #payload, CHUNK_SIZE do
        chunks[#chunks + 1] = payload:sub(i, i + CHUNK_SIZE - 1)
    end
    -- Chain sends with retry: send one chunk, verify it was accepted,
    -- retry up to 3 times with increasing delay if throttled, then
    -- wait 0.4s before sending the next chunk.
    local function SendNext(idx)
        if idx > #chunks then return end
        local msg = MSG_CHUNK .. "|" .. idx .. "|" .. #chunks .. "|" .. chunks[idx]

        local function TrySend(attempt)
            local ok = C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
            if not ok and attempt < 3 then
                -- Throttled — retry after increasing backoff
                C_Timer.After(0.5 * attempt, function() TrySend(attempt + 1) end)
            else
                -- Success (or gave up) — schedule the next chunk
                if idx < #chunks then
                    C_Timer.After(0.4, function() SendNext(idx + 1) end)
                end
            end
        end
        TrySend(1)
    end
    SendNext(1)
end

-- ============================================================
-- UI BUILDER HELPERS
-- ============================================================

--- Apply MCL header-bar pattern to a frame region
local function CreateHeader(parent, height, text)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
    header:SetHeight(height)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    header:SetBackdropColor(unpack(S.headerBg))

    -- 1px accent line
    local accent = parent:CreateTexture(nil, "OVERLAY")
    accent:SetHeight(1)
    accent:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
    accent:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
    accent:SetColorTexture(unpack(S.accentLine))

    -- Title
    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", header, "LEFT", 10, 0)
    title:SetTextColor(unpack(S.titleText))
    title:SetText(text or "")
    header.title = title

    return header
end

--- Create an MCL-style close button
local function CreateCloseButton(parent, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(22, 18)
    btn:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
    btn:SetBackdrop(S.backdropInset)
    btn:SetBackdropColor(unpack(S.btnBg))
    btn:SetBackdropBorderColor(unpack(S.btnBorder))

    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.text:SetPoint("CENTER")
    btn.text:SetText("X")
    btn.text:SetTextColor(unpack(S.btnText))

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(S.btnCloseBg))
        self:SetBackdropBorderColor(unpack(S.btnCloseHover))
        self.text:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(S.btnBg))
        self:SetBackdropBorderColor(unpack(S.btnBorder))
        self.text:SetTextColor(unpack(S.btnText))
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

--- Create an MCL-style action button
local function CreateActionButton(parent, width, text, onClick)
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(width, 26)
    btn:SetBackdrop(S.backdropInset)
    btn:SetBackdropColor(unpack(S.btnBg))
    btn:SetBackdropBorderColor(unpack(S.btnBorder))

    btn.label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btn.label:SetPoint("CENTER")
    btn.label:SetText(text)
    btn.label:SetTextColor(unpack(S.btnText))

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(S.btnHoverBg))
        self:SetBackdropBorderColor(unpack(S.accentBorder))
        self.label:SetTextColor(unpack(S.hoverText))
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(S.btnBg))
        self:SetBackdropBorderColor(unpack(S.btnBorder))
        self.label:SetTextColor(unpack(S.btnText))
    end)
    btn:SetScript("OnClick", onClick)
    return btn
end

-- ============================================================
-- CONSENT POPUP — shown on the TARGET player's screen
-- ============================================================

local function CreateConsentFrame()
    if Compare.consentFrame then return Compare.consentFrame end

    local f = CreateFrame("Frame", "MCLCompareConsentFrame", UIParent, "BackdropTemplate")
    f:SetSize(300, 150)
    f:SetPoint("TOP", UIParent, "TOP", 0, -120)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(250)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop(S.backdrop)
    f:SetBackdropColor(S.mainBg[1], S.mainBg[2], S.mainBg[3], 0.97)
    f:SetBackdropBorderColor(unpack(S.mainBorder))

    -- Header
    local header = CreateHeader(f, 28, "Compare Request")
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    -- MCL logo
    local logo = header:CreateTexture(nil, "OVERLAY")
    logo:SetSize(16, 16)
    logo:SetPoint("LEFT", header, "LEFT", 8, 0)
    logo:SetTexture("Interface\\AddOns\\MCL\\mcl-logo-32")
    logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    header.title:SetPoint("LEFT", logo, "RIGHT", 6, 0)

    -- Close button (acts as decline)
    CreateCloseButton(header, function() Compare:DeclineConsent() end)

    -- Body text
    f.bodyText = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.bodyText:SetPoint("TOP", f, "TOP", 0, -48)
    f.bodyText:SetWidth(260)
    f.bodyText:SetJustifyH("CENTER")
    f.bodyText:SetTextColor(unpack(S.normalText))
    f.bodyText:SetText("")

    -- Timer text
    f.timerText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.timerText:SetPoint("TOP", f.bodyText, "BOTTOM", 0, -6)
    f.timerText:SetTextColor(unpack(S.mutedText))

    -- Accept button (green accent on hover)
    local acceptBtn = CreateActionButton(f, 100, "Accept", function()
        Compare:AcceptConsent()
    end)
    acceptBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 14)
    acceptBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.12, 0.25, 0.15, 1)
        self:SetBackdropBorderColor(0.20, 0.75, 0.30, 1)
        self.label:SetTextColor(0.40, 1, 0.50, 1)
    end)
    acceptBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(S.btnBg))
        self:SetBackdropBorderColor(unpack(S.btnBorder))
        self.label:SetTextColor(unpack(S.btnText))
    end)
    f.acceptBtn = acceptBtn

    -- Decline button (red accent on hover)
    local declineBtn = CreateActionButton(f, 100, "Decline", function()
        Compare:DeclineConsent()
    end)
    declineBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 14)
    declineBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.25, 0.10, 0.10, 1)
        self:SetBackdropBorderColor(0.75, 0.20, 0.20, 1)
        self.label:SetTextColor(1, 0.50, 0.50, 1)
    end)
    declineBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(S.btnBg))
        self:SetBackdropBorderColor(unpack(S.btnBorder))
        self.label:SetTextColor(unpack(S.btnText))
    end)
    f.declineBtn = declineBtn

    f.consentTimer = nil
    Compare.consentFrame = f
    f:Hide()
    return f
end

function Compare:ShowConsentPopup(requester, channel)
    -- Auto-decline silently if in combat
    if InCombatLockdown() or UnitAffectingCombat("player") then
        C_ChatInfo.SendAddonMessage(PREFIX, MSG_DECLINE, channel)
        return
    end

    pendingConsent = { requester = requester, channel = channel }

    local f = CreateConsentFrame()
    local cc = GetClassColorForPlayer(requester)
    local colorHex = string.format("|cFF%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)
    f.bodyText:SetText(colorHex .. ShortName(requester) .. "|r\nwants to compare mount collections.")

    -- 30-second auto-decline countdown
    local remaining = 30
    f.timerText:SetText("Auto-declining in " .. remaining .. "s")
    if f.consentTimer then f.consentTimer:Cancel() end
    f.consentTimer = C_Timer.NewTicker(1, function()
        remaining = remaining - 1
        if remaining <= 0 then
            Compare:DeclineConsent()
        else
            f.timerText:SetText("Auto-declining in " .. remaining .. "s")
        end
    end, 30)

    f:Show()
end

function Compare:AcceptConsent()
    if not pendingConsent then return end
    local req = pendingConsent
    pendingConsent = nil

    local f = Compare.consentFrame
    if f then
        if f.consentTimer then f.consentTimer:Cancel(); f.consentTimer = nil end
        f:Hide()
    end

    -- Send our collection data to the requester
    local channel = GetGroupChannel()
    if channel then
        SendChunked(req.requester, SerializeMyCollection(), channel)
    end
end

function Compare:DeclineConsent()
    if not pendingConsent then return end
    local req = pendingConsent
    pendingConsent = nil

    local f = Compare.consentFrame
    if f then
        if f.consentTimer then f.consentTimer:Cancel(); f.consentTimer = nil end
        f:Hide()
    end

    -- Notify the requester that we declined
    local channel = GetGroupChannel()
    if channel then
        C_ChatInfo.SendAddonMessage(PREFIX, MSG_DECLINE, channel)
    end
end

-- ============================================================
-- PICKER UI — the main compare dialog
-- ============================================================

local PICKER_W, PICKER_H = 320, 340
local HEADER_H = 30
local ROW_H    = 36

local function CreatePickerFrame()
    if Compare.pickerFrame then return Compare.pickerFrame end

    -- Main frame
    local f = CreateFrame("Frame", "MCLComparePickerFrame", UIParent, "BackdropTemplate")
    f:SetSize(PICKER_W, PICKER_H)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(200)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetBackdrop(S.backdrop)
    f:SetBackdropColor(S.mainBg[1], S.mainBg[2], S.mainBg[3], 0.97)
    f:SetBackdropBorderColor(unpack(S.mainBorder))

    -- Header bar
    local header = CreateHeader(f, HEADER_H, "Compare Collections")

    -- Make draggable from header
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    -- Close button
    CreateCloseButton(header, function() f:Hide() end)

    -- MCL logo/icon in header
    local logo = header:CreateTexture(nil, "OVERLAY")
    logo:SetSize(18, 18)
    logo:SetPoint("LEFT", header, "LEFT", 8, 0)
    logo:SetTexture("Interface\\AddOns\\MCL\\mcl-logo-32")
    logo:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    header.title:SetPoint("LEFT", logo, "RIGHT", 6, 0)

    -- Content area
    local content = CreateFrame("Frame", nil, f)
    content:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -(HEADER_H + 8))
    content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    f.content = content

    ---- STATUS / SCANNING LAYER ----
    local statusPanel = CreateFrame("Frame", nil, content)
    statusPanel:SetAllPoints(content)
    f.statusPanel = statusPanel

    -- Status icon (animated dots)
    local statusText = statusPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statusText:SetPoint("CENTER", statusPanel, "CENTER", 0, 16)
    statusText:SetTextColor(unpack(S.titleText))
    f.statusText = statusText

    local statusSub = statusPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statusSub:SetPoint("TOP", statusText, "BOTTOM", 0, -8)
    statusSub:SetTextColor(unpack(S.mutedText))
    f.statusSub = statusSub

    -- Animated spinner (dots cycling)
    local spinnerDots = { ".", "..", "...", "....", "....." }
    local spinIdx = 0
    f.spinTimer = nil

    function f:StartSpinner(mainText, subText)
        self.statusPanel:Show()
        self.playerList:Hide()
        self.statusText:SetText(mainText or "")
        self.statusSub:SetText(subText or "")
        spinIdx = 0
        if self.spinTimer then self.spinTimer:Cancel() end
        self.spinTimer = C_Timer.NewTicker(0.35, function()
            spinIdx = (spinIdx % #spinnerDots) + 1
            self.statusText:SetText((mainText or "") .. spinnerDots[spinIdx])
        end)
    end

    function f:StopSpinner()
        if self.spinTimer then self.spinTimer:Cancel(); self.spinTimer = nil end
    end

    ---- PLAYER LIST LAYER ----
    local listFrame = CreateFrame("Frame", nil, content)
    listFrame:SetAllPoints(content)
    listFrame:Hide()
    f.playerList = listFrame

    -- Subtitle
    local listHeader = listFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    listHeader:SetPoint("TOPLEFT", listFrame, "TOPLEFT", 4, 0)
    listHeader:SetTextColor(unpack(S.mutedText))
    listHeader:SetText("Select a player to compare with:")
    f.listHeader = listHeader

    -- Scroll frame for player rows
    local sf = CreateFrame("ScrollFrame", nil, listFrame, "MinimalScrollFrameTemplate")
    sf:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", -4, -8)
    sf:SetPoint("BOTTOMRIGHT", listFrame, "BOTTOMRIGHT", -6, 36)
    sf:SetClipsChildren(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local newVal = self:GetVerticalScroll() - (delta * 50)
        newVal = math.max(0, math.min(newVal, self:GetVerticalScrollRange()))
        self:SetVerticalScroll(newVal)
    end)

    -- Style scrollbar MCL-style (slim 4px)
    if sf.ScrollBar then
        sf.ScrollBar:ClearAllPoints()
        sf.ScrollBar:SetPoint("TOPLEFT", sf, "TOPRIGHT", 2, -2)
        sf.ScrollBar:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", 6, 2)
        sf.ScrollBar:SetWidth(4)
        local thumb = sf.ScrollBar:GetThumbTexture()
        if thumb then
            thumb:SetColorTexture(0.25, 0.3, 0.4, 0.7)
            thumb:SetWidth(4)
            thumb:SetHeight(40)
        end
        for _, child in pairs({sf.ScrollBar:GetChildren()}) do
            if child:IsObjectType("Button") then
                child:SetAlpha(0); child:SetSize(1, 1)
            end
        end
    end

    local scrollChild = CreateFrame("Frame", nil, sf)
    scrollChild:SetWidth(PICKER_W - 36)
    scrollChild:SetHeight(1)
    sf:SetScrollChild(scrollChild)
    f.scrollChild = scrollChild

    -- Cancel / Rescan button at the bottom
    local rescanBtn = CreateActionButton(listFrame, 120, "Rescan Group", function()
        Compare:ScanGroup()
    end)
    rescanBtn:SetPoint("BOTTOM", listFrame, "BOTTOM", 0, 0)
    f.rescanBtn = rescanBtn

    -- Storage for row frames
    f.rows = {}

    Compare.pickerFrame = f
    f:Hide()
    return f
end

--- Populate rows from scan results
local function PopulatePlayerRows(users)
    local f = Compare.pickerFrame
    if not f then return end

    -- Clear old rows
    for _, row in ipairs(f.rows) do
        row:Hide()
        row:SetParent(nil)
    end
    wipe(f.rows)

    if #users == 0 then
        f:StopSpinner()
        f.statusPanel:Show()
        f.playerList:Hide()
        f.statusText:SetText("No MCL users found")
        f.statusSub:SetText("No other group members have MCL installed.")
        return
    end

    f:StopSpinner()
    f.statusPanel:Hide()
    f.playerList:Show()

    local yOff = 0
    for i, fullName in ipairs(users) do
        local row = CreateFrame("Button", nil, f.scrollChild, "BackdropTemplate")
        row:SetSize(PICKER_W - 40, ROW_H)
        row:SetPoint("TOPLEFT", f.scrollChild, "TOPLEFT", 0, -yOff)
        row:SetBackdrop(S.backdrop)
        row:SetBackdropColor(unpack(S.rowBg))
        row:SetBackdropBorderColor(S.cardBorder[1], S.cardBorder[2], S.cardBorder[3], 0.3)

        -- Class-colored name
        local cc = GetClassColorForPlayer(fullName)
        local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("LEFT", row, "LEFT", 38, 1)
        nameText:SetTextColor(cc.r, cc.g, cc.b, 1)
        nameText:SetText(ShortName(fullName))

        -- Realm sub-text
        local _, realm = fullName:match("^(.+)-(.+)$")
        if realm then
            local realmText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            realmText:SetPoint("TOPLEFT", nameText, "BOTTOMLEFT", 0, -1)
            realmText:SetTextColor(unpack(S.mutedText))
            realmText:SetText(realm)
        end

        -- Class icon (character portrait placeholder — use class icon atlas)
        local _, cls
        local prefix, count
        if IsInRaid() then prefix, count = "raid", GetNumGroupMembers()
        elseif IsInGroup() then prefix, count = "party", GetNumGroupMembers() - 1 end
        if prefix then
            for j = 1, count do
                local unit = prefix .. j
                local uName, uRealm = UnitName(unit)
                local full = uName
                if uRealm and uRealm ~= "" then full = uName .. "-" .. uRealm end
                if full == fullName or uName == fullName then
                    _, cls = UnitClass(unit)
                    break
                end
            end
        end

        local iconBg = CreateFrame("Frame", nil, row, "BackdropTemplate")
        iconBg:SetSize(28, 28)
        iconBg:SetPoint("LEFT", row, "LEFT", 4, 0)
        iconBg:SetBackdrop(S.backdrop)
        iconBg:SetBackdropColor(0, 0, 0, 0.4)
        iconBg:SetBackdropBorderColor(cc.r, cc.g, cc.b, 0.6)

        local icon = iconBg:CreateTexture(nil, "ARTWORK")
        icon:SetSize(24, 24)
        icon:SetPoint("CENTER")
        if cls then
            local coords = CLASS_ICON_TCOORDS[cls]
            icon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
            if coords then
                icon:SetTexCoord(unpack(coords))
            end
        else
            icon:SetTexture("Interface\\AddOns\\MCL\\mcl-logo-32")
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        -- Right arrow indicator
        local arrow = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        arrow:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        arrow:SetTextColor(unpack(S.mutedText))
        arrow:SetText(">")

        -- Hover effects
        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(S.rowHoverBg))
            self:SetBackdropBorderColor(unpack(S.accentBorder))
            arrow:SetTextColor(unpack(S.hoverText))
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(unpack(S.rowBg))
            self:SetBackdropBorderColor(S.cardBorder[1], S.cardBorder[2], S.cardBorder[3], 0.3)
            arrow:SetTextColor(unpack(S.mutedText))
        end)

        -- Click handler
        row:SetScript("OnClick", function()
            Compare:RequestCollection(fullName)
        end)

        table.insert(f.rows, row)
        yOff = yOff + ROW_H + 4
    end

    -- Update scroll child height
    f.scrollChild:SetHeight(math.max(1, yOff))
end

-- ============================================================
-- PHASE 1 — SCAN GROUP
-- ============================================================

function Compare:ScanGroup()
    if not CombatGuard("compare") then return end
    local channel = GetGroupChannel()
    if not channel then
        print("|cff00CCFF[MCL]|r You are not in a party or raid.")
        return
    end

    local f = CreatePickerFrame()
    f:Show()
    f:StartSpinner("Scanning", "Looking for MCL users in your group")

    scanPending   = true
    scanResponses = {}
    C_ChatInfo.SendAddonMessage(PREFIX, MSG_SCAN, channel)

    if scanTimer then scanTimer:Cancel() end
    scanTimer = C_Timer.NewTimer(4, function()
        scanPending = false
        scanTimer = nil

        -- Collect results excluding self
        local myName = GetMyFullName()
        local users = {}
        for name in pairs(scanResponses) do
            if name ~= myName then
                users[#users + 1] = name
            end
        end
        table.sort(users)
        Compare._lastScanUsers = users
        PopulatePlayerRows(users)
    end)
end

-- ============================================================
-- PHASE 2 — SHOW PICKER (also callable via /mcl compare)
-- ============================================================

function Compare:ShowUserPicker()
    Compare:ScanGroup()
end

-- ============================================================
-- PHASE 3 — REQUEST COLLECTION
-- ============================================================

function Compare:RequestCollection(nameOrIndex)
    if not CombatGuard("compare") then return end
    local target

    -- Resolve target
    local idx = tonumber(nameOrIndex)
    if idx and Compare._lastScanUsers and Compare._lastScanUsers[idx] then
        target = Compare._lastScanUsers[idx]
    else
        if Compare._lastScanUsers then
            local search = tostring(nameOrIndex):lower()
            for _, fullName in ipairs(Compare._lastScanUsers) do
                if fullName:lower() == search or ShortName(fullName):lower() == search then
                    target = fullName
                    break
                end
            end
        end
        if not target then target = tostring(nameOrIndex) end
    end

    local channel = GetGroupChannel()
    if not channel then
        print("|cff00CCFF[MCL]|r You are not in a party or raid.")
        return
    end

    requestPending = true
    requestTarget  = target
    incomingChunks[target] = { chunks = {}, expected = 0 }

    -- Show loading state in picker
    local f = Compare.pickerFrame
    if f and f:IsShown() then
        f:StartSpinner("Requesting", "Waiting for " .. ShortName(target) .. " to respond")
    end

    C_ChatInfo.SendAddonMessage(PREFIX, MSG_REQDATA .. "|" .. target, channel)

    -- Timeout that resets every time we receive a chunk (see OnAddonMessage).
    -- Only fires if no data arrives for 12 seconds straight.
    local function StartOrResetTimeout()
        if requestTimer then requestTimer:Cancel() end
        requestTimer = C_Timer.NewTimer(12, function()
            if requestPending then
                requestPending = false
                if f and f:IsShown() then
                    f:StopSpinner()
                    f.statusPanel:Show()
                    f.playerList:Hide()
                    f.statusText:SetText("No Response")
                    f.statusText:SetTextColor(unpack(S.redText))
                    f.statusSub:SetText(ShortName(target) .. " did not respond.\nThey may not have the compare feature.")
                    C_Timer.After(3, function()
                        if f.statusText then f.statusText:SetTextColor(unpack(S.titleText)) end
                    end)
                end
            end
            requestTimer = nil
        end)
    end
    Compare._resetTimeout = StartOrResetTimeout
    StartOrResetTimeout()
end

-- ============================================================
-- PHASE 4 — ACTIVATE / DEACTIVATE
-- ============================================================

function Compare:Activate(playerName, collectionSet)
    Compare.active       = true
    Compare.targetName   = playerName
    Compare.collectedSet = collectionSet

    -- Count
    local count = 0
    for _ in pairs(collectionSet) do count = count + 1 end

    -- Show success in picker briefly, then close
    local f = Compare.pickerFrame
    if f and f:IsShown() then
        f:StopSpinner()
        f.statusPanel:Show()
        f.playerList:Hide()
        f.statusText:SetText("Connected!")
        f.statusText:SetTextColor(unpack(S.greenText))
        f.statusSub:SetText("Received " .. count .. " mounts from " .. ShortName(playerName))
        C_Timer.After(1.5, function()
            if f and f:IsShown() then f:Hide() end
            if f.statusText then f.statusText:SetTextColor(unpack(S.titleText)) end
        end)
    end

    Compare:ApplyOverlay()
    Compare:ShowBanner()
end

function Compare:Deactivate()
    Compare.active       = false
    Compare.targetName   = nil
    Compare.collectedSet = {}
    Compare:RemoveOverlay()
    Compare:HideBanner()
    if Compare.pickerFrame and Compare.pickerFrame:IsShown() then
        Compare.pickerFrame:Hide()
    end
end

-- ============================================================
-- MOUNT FRAME OVERLAY — indicators on each mount icon
-- ============================================================

local function ResolveMountJournalID(mountId)
    if not mountId then return nil end
    local str = tostring(mountId)
    if str:sub(1,1) == "m" then
        return tonumber(str:sub(2))
    else
        return C_MountJournal.GetMountFromItem(mountId)
    end
end

local function SetCompareIndicator(mountFrame, theyHaveIt)
    if not mountFrame then return end
    if not mountFrame.compareIndicator then
        -- Dark outline border for a clean MCL-themed look
        local border = mountFrame:CreateTexture(nil, "OVERLAY", nil, 6)
        border:SetSize(14, 14)
        border:SetPoint("BOTTOMLEFT", mountFrame, "BOTTOMLEFT", 1, 1)
        border:SetColorTexture(0, 0, 0, 0.9)
        mountFrame.compareBorder = border

        -- Colored fill centered inside the border
        local indicator = mountFrame:CreateTexture(nil, "OVERLAY", nil, 7)
        indicator:SetSize(10, 10)
        indicator:SetPoint("CENTER", border, "CENTER")
        indicator:SetTexture("Interface\\Buttons\\WHITE8x8")
        mountFrame.compareIndicator = indicator
    end

    mountFrame.compareBorder:Show()
    local dot = mountFrame.compareIndicator
    dot:Show()
    if theyHaveIt then
        dot:SetColorTexture(0.15, 0.85, 0.25, 1)
    else
        dot:SetColorTexture(0.85, 0.18, 0.18, 1)
    end
end

local function ClearCompareIndicator(mountFrame)
    if mountFrame then
        if mountFrame.compareIndicator then mountFrame.compareIndicator:Hide() end
        if mountFrame.compareBorder then mountFrame.compareBorder:Hide() end
    end
end

function Compare:ApplyOverlay()
    if not Compare.active then return end

    -- Path B: MCLcore.mounts (TableMounts populated)
    if MCLcore.mounts then
        for _, entry in pairs(MCLcore.mounts) do
            if entry.id and entry.frame then
                SetCompareIndicator(entry.frame, Compare.collectedSet[entry.id] or false)
            end
        end
    end

    -- Path A: walk frame tree from scroll children
    if MCLcore.MCL_MF and MCLcore.MCL_MF.ScrollFrame then
        local sc = MCLcore.MCL_MF.ScrollFrame:GetScrollChild()
        if sc then Compare:WalkFrameTree(sc) end
    end
    if MCL_mainFrame and MCL_mainFrame.ScrollChild then
        Compare:WalkFrameTree(MCL_mainFrame.ScrollChild)
    end
end

function Compare:WalkFrameTree(parent)
    if not parent then return end
    for i = 1, parent:GetNumChildren() do
        local child = select(i, parent:GetChildren())
        if child then
            if child.mountID then
                local jid = ResolveMountJournalID(child.mountID)
                if jid then
                    SetCompareIndicator(child, Compare.collectedSet[jid] or false)
                end
                for j = 1, child:GetNumChildren() do
                    local inner = select(j, child:GetChildren())
                    if inner and inner.mountID then
                        local iid = ResolveMountJournalID(inner.mountID)
                        if iid then
                            SetCompareIndicator(inner, Compare.collectedSet[iid] or false)
                        end
                    end
                end
            else
                Compare:WalkFrameTree(child)
            end
        end
    end
end

function Compare:RemoveOverlay()
    if MCLcore.mounts then
        for _, entry in pairs(MCLcore.mounts) do
            if entry.frame then ClearCompareIndicator(entry.frame) end
        end
    end
    if MCL_mainFrame and MCL_mainFrame.ScrollChild then
        Compare:ClearFrameTree(MCL_mainFrame.ScrollChild)
    end
    if MCLcore.MCL_MF and MCLcore.MCL_MF.ScrollFrame then
        local sc = MCLcore.MCL_MF.ScrollFrame:GetScrollChild()
        if sc then Compare:ClearFrameTree(sc) end
    end
end

function Compare:ClearFrameTree(parent)
    if not parent then return end
    for i = 1, parent:GetNumChildren() do
        local child = select(i, parent:GetChildren())
        if child then
            ClearCompareIndicator(child)
            if child:GetNumChildren() > 0 then
                Compare:ClearFrameTree(child)
            end
        end
    end
end

-- ============================================================
-- BANNER — docked to the MCL main window header
-- ============================================================

function Compare:ShowBanner()
    if not MCLcore.MCL_MF then return end

    if not Compare.bannerFrame then
        local banner = CreateFrame("Frame", nil, MCLcore.MCL_MF, "BackdropTemplate")
        banner:SetHeight(28)
        banner:SetPoint("TOPLEFT", MCLcore.MCL_MF, "TOPLEFT", 0, -30) -- below main header
        banner:SetPoint("TOPRIGHT", MCLcore.MCL_MF, "TOPRIGHT", 0, -30)
        banner:SetFrameLevel(MCLcore.MCL_MF:GetFrameLevel() + 50)
        banner:SetBackdrop(S.backdrop)
        banner:SetBackdropColor(0.06, 0.12, 0.22, 0.97)
        banner:SetBackdropBorderColor(unpack(S.accentBorder))

        -- 1px accent line at bottom
        local accent = banner:CreateTexture(nil, "OVERLAY")
        accent:SetHeight(1)
        accent:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT")
        accent:SetPoint("BOTTOMRIGHT", banner, "BOTTOMRIGHT")
        accent:SetColorTexture(unpack(S.accentLine))

        -- Main text (center)
        banner.text = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        banner.text:SetPoint("CENTER", banner, "CENTER", 0, 0)

        -- MCL-style close button
        local closeBtn = CreateFrame("Button", nil, banner, "BackdropTemplate")
        closeBtn:SetSize(22, 18)
        closeBtn:SetPoint("RIGHT", banner, "RIGHT", -6, 0)
        closeBtn:SetBackdrop(S.backdropInset)
        closeBtn:SetBackdropColor(unpack(S.btnBg))
        closeBtn:SetBackdropBorderColor(unpack(S.btnBorder))

        closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        closeBtn.text:SetPoint("CENTER")
        closeBtn.text:SetText("X")
        closeBtn.text:SetTextColor(unpack(S.btnText))

        closeBtn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(unpack(S.btnCloseBg))
            self:SetBackdropBorderColor(unpack(S.btnCloseHover))
            self.text:SetTextColor(1, 1, 1, 1)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Exit comparison mode")
            GameTooltip:Show()
        end)
        closeBtn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(unpack(S.btnBg))
            self:SetBackdropBorderColor(unpack(S.btnBorder))
            self.text:SetTextColor(unpack(S.btnText))
            GameTooltip:Hide()
        end)
        closeBtn:SetScript("OnClick", function() Compare:Deactivate() end)

        -- Legend: red dot = Missing, green dot = Has
        local legendAnchor = banner.text

        local greenDot = banner:CreateTexture(nil, "OVERLAY")
        greenDot:SetSize(8, 8)
        greenDot:SetPoint("LEFT", legendAnchor, "RIGHT", 14, 0)
        greenDot:SetColorTexture(unpack(S.greenDot))

        local greenLabel = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        greenLabel:SetPoint("LEFT", greenDot, "RIGHT", 3, 0)
        greenLabel:SetText("Has")
        greenLabel:SetTextColor(0.7, 1, 0.7, 1)

        local redDot = banner:CreateTexture(nil, "OVERLAY")
        redDot:SetSize(8, 8)
        redDot:SetPoint("LEFT", greenLabel, "RIGHT", 10, 0)
        redDot:SetColorTexture(unpack(S.redDot))

        local redLabel = banner:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        redLabel:SetPoint("LEFT", redDot, "RIGHT", 3, 0)
        redLabel:SetText("Missing")
        redLabel:SetTextColor(1, 0.7, 0.7, 1)

        Compare.bannerFrame = banner
    end

    local cc = GetClassColorForPlayer(Compare.targetName)
    local colorCode = string.format("|cFF%02x%02x%02x", cc.r * 255, cc.g * 255, cc.b * 255)

    Compare.bannerFrame.text:SetText(
        "|cFF" .. "66C7F2" .. "Comparing with  " .. colorCode .. ShortName(Compare.targetName) .. "|r"
    )
    Compare.bannerFrame:Show()
end

function Compare:HideBanner()
    if Compare.bannerFrame then
        Compare.bannerFrame:Hide()
    end
end

-- ============================================================
-- INCOMING MESSAGE HANDLER
-- ============================================================

local function OnAddonMessage(prefix, message, distribution, sender)
    if prefix ~= PREFIX then return end

    if message == MSG_SCAN then
        local channel = GetGroupChannel()
        if channel then
            C_ChatInfo.SendAddonMessage(PREFIX, MSG_HERE, channel)
        end
        return
    end

    if message == MSG_HERE and scanPending then
        scanResponses[sender] = true
        return
    end

    if message:sub(1, #MSG_REQDATA) == MSG_REQDATA then
        local _, target = strsplit("|", message)
        if target and (target == GetMyFullName() or target == UnitName("player")) then
            local channel = GetGroupChannel()
            if channel then
                Compare:ShowConsentPopup(sender, channel)
            end
        end
        return
    end

    if message == MSG_DECLINE then
        -- The target player declined our compare request
        local matchesTarget = false
        if requestTarget then
            if sender == requestTarget then
                matchesTarget = true
            elseif ShortName(sender) == ShortName(requestTarget) then
                matchesTarget = true
            end
        end
        if requestPending and matchesTarget then
            requestPending = false
            Compare._resetTimeout = nil
            if requestTimer then requestTimer:Cancel(); requestTimer = nil end

            local f = Compare.pickerFrame
            if f and f:IsShown() then
                f:StopSpinner()
                f.statusPanel:Show()
                f.playerList:Hide()
                f.statusText:SetText("Declined")
                f.statusText:SetTextColor(unpack(S.redText))
                f.statusSub:SetText(ShortName(sender) .. " declined the compare request.")
                C_Timer.After(3, function()
                    if f.statusText then f.statusText:SetTextColor(unpack(S.titleText)) end
                    PopulatePlayerRows(Compare._lastScanUsers or {})
                end)
            end
        end
        return
    end

    if message:sub(1, #MSG_CHUNK) == MSG_CHUNK then
        -- Only process chunks if WE made a request. This prevents the
        -- target player from activating compare mode on their own screen
        -- when they hear their own outgoing chunks on the group channel.
        if not requestPending then return end

        local _, seqStr, totalStr, data = strsplit("|", message, 4)
        local seq   = tonumber(seqStr) or 0
        local total = tonumber(totalStr) or 0

        -- Match chunks to the right entry: sender name from CHAT_MSG_ADDON
        -- may differ from requestTarget (e.g. realm suffix). Try both keys.
        local key = sender
        if requestTarget and not incomingChunks[sender] and incomingChunks[requestTarget] then
            key = requestTarget
        end

        if not incomingChunks[key] then
            incomingChunks[key] = { chunks = {}, expected = total }
        end
        local entry = incomingChunks[key]
        entry.expected = total
        entry.chunks[seq] = data

        -- Reset the "no response" timeout — data is still flowing
        if Compare._resetTimeout then Compare._resetTimeout() end

        -- Progress update in picker
        local f = Compare.pickerFrame
        if f and f:IsShown() and f.statusSub then
            local received = 0
            for ii = 1, total do
                if entry.chunks[ii] then received = received + 1 end
            end
            f.statusSub:SetText(
                "Receiving data from " .. ShortName(sender) ..
                "  (" .. received .. "/" .. total .. " chunks)"
            )
        end

        local complete = true
        for i = 1, total do
            if not entry.chunks[i] then complete = false; break end
        end

        if complete then
            local parts = {}
            for i = 1, total do parts[#parts + 1] = entry.chunks[i] end
            local collectionSet = DeserializeCollection(table.concat(parts))

            requestPending = false
            Compare._resetTimeout = nil
            if requestTimer then requestTimer:Cancel(); requestTimer = nil end
            incomingChunks[key] = nil

            Compare:Activate(sender, collectionSet)
        end
        return
    end
end

-- ============================================================
-- HOOKS — re-apply overlay when the UI refreshes
-- ============================================================

local originalUpdateCollection
local function HookUpdateCollection()
    if MCLcore.Function and MCLcore.Function.UpdateCollection and not originalUpdateCollection then
        originalUpdateCollection = MCLcore.Function.UpdateCollection
        MCLcore.Function.UpdateCollection = function(self, ...)
            originalUpdateCollection(self, ...)
            if Compare.active then
                C_Timer.After(0.1, function() Compare:ApplyOverlay() end)
            end
        end
    end
end

local originalSetTabs
local function HookSetTabs()
    if MCLcore.Frames and MCLcore.Frames.SetTabs and not originalSetTabs then
        originalSetTabs = MCLcore.Frames.SetTabs
        MCLcore.Frames.SetTabs = function(self, ...)
            local r1, r2 = originalSetTabs(self, ...)
            if Compare.active then
                C_Timer.After(0.2, function() Compare:ApplyOverlay() end)
            end
            return r1, r2
        end
    end
end

-- ============================================================
-- EVENT FRAME
-- ============================================================

local eventFrame = CreateFrame("Frame")
C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
eventFrame:RegisterEvent("CHAT_MSG_ADDON")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        OnAddonMessage(...)
    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            HookUpdateCollection()
            HookSetTabs()
        end)
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Combat started: dismiss open UI and cancel in-flight operations
        if Compare.pickerFrame and Compare.pickerFrame:IsShown() then
            Compare.pickerFrame:StopSpinner()
            Compare.pickerFrame:Hide()
        end
        if pendingConsent then
            Compare:DeclineConsent()
        end
        if Compare.active then
            Compare:Deactivate()
        end
        if scanPending then
            scanPending = false
            if scanTimer then scanTimer:Cancel(); scanTimer = nil end
        end
        if requestPending then
            requestPending = false
            Compare._resetTimeout = nil
            if requestTimer then requestTimer:Cancel(); requestTimer = nil end
        end
    end
end)
