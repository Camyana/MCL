-- MCL Notification System
-- Shows update notifications and first-time user messages

local MCL = MCL or {}
MCL.Notifications = {}

-- Make MCL globally accessible
_G["MCL"] = MCL

-- Current version from TOC (update this when version changes)
local CURRENT_VERSION = "2.6.4"

-- Notification messages
local NOTIFICATION_MESSAGES = {
    welcome = {
        title = "Welcome to Mount Collection Log!",
        text = "Thank you for choosing MCL to enhance your mount collecting experience!\n\n" ..
               "Mount Collection Log helps you track and organize your mount collection with advanced features:\n\n" ..
               "• |cFF00FF00Detailed Collection Statistics|r - See your progress at a glance\n" ..
               "• |cFF00FF00Mount Filtering|r - Find specific mounts by expansion, type, or source\n" ..
               "• |cFF00FF00Missing Mount Finder|r - Discover which mounts you still need\n" ..
               "• |cFF00FF00Collection Comparison|r - Compare with other players\n\n" ..
               "|cFFFFD700Don't forget to check out our sister addon:|r\n" ..
               "|cFF1FB7EBPet Collection Log (PCL)|r - The ultimate battle pet tracking companion!\n\n" ..
               "Click the minimap button or use |cFFFFFFFF/mcl|r to get started!",
        icon = "Interface\\AddOns\\MCL\\mcl-logo-32"
    },
    update = {
        title = "MCL Updated to v" .. CURRENT_VERSION .. "!",
        text = "Mount Collection Log has been successfully updated!\n\n" ..
               "|cFF00FF00What's new in this version:|r\n" ..
               "• Enhanced notification system for better user experience\n" ..
               "• Improved performance and stability\n" ..
               "• Bug fixes and optimizations\n\n" ..
               "|cFFFFD700Keep your collection complete with:|r\n" ..
               "• |cFF1FB7EBMount Collection Log|r - For comprehensive mount tracking\n" ..
               "• |cFF1FB7EBPet Collection Log|r - For all your battle pet needs\n\n" ..
               "Thank you for using MCL and supporting our development!",
        icon = "Interface\\AddOns\\MCL\\mcl-logo-32"
    }
}

-- Create the notification frame
local function CreateNotificationFrame()
    -- Use the same template as the main addon window
    local frameTemplate = (MCL_SETTINGS and MCL_SETTINGS.useBlizzardTheme) and "MCLBlizzardFrameTemplate" or "MCLFrameTemplateWithInset"
    local frame = CreateFrame("Frame", "MCLNotificationFrame", UIParent, frameTemplate)
    frame:SetSize(400, 300)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    
    -- Apply the same styling as the main window
    if MCL_SETTINGS and MCL_SETTINGS.useBlizzardTheme then
        -- Hide nine-slice elements like the main frame does
        if frame.NineSlice then frame.NineSlice:Hide() end
    else
        -- Apply the same background styling as main frame
        if frame.Bg then
            local opacity = (MCL_SETTINGS and MCL_SETTINGS.opacity) or 0.95
            frame.Bg:SetVertexColor(0, 0, 0, opacity)
        end
        if frame.TitleBg then
            frame.TitleBg:SetVertexColor(0.1, 0.1, 0.1, 0.95)
        end
        -- Add border like the main frame (only if MCLcore is available)
        if MCLcore and MCLcore.Function and MCLcore.Function.CreateFullBorder then
            MCLcore.Function:CreateFullBorder(frame)
        end
    end
    
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Use the template's built-in close button (no need to create our own)
    if frame.CloseButton then
        frame.CloseButton:SetScript("OnClick", function() frame:Hide() end)
    end
    
    -- Icon
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetSize(32, 32)
    icon:SetPoint("TOPLEFT", 20, -20)
    frame.icon = icon
    
    -- Title - style it like the main window title
    local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, -5)
    if MCL_SETTINGS and MCL_SETTINGS.useBlizzardTheme then
        title:SetTextColor(1, 0.82, 0, 1)  -- Gold color like Blizzard UI
    else
        title:SetTextColor(0.12, 0.72, 0.92, 1)  -- MCL blue color
    end
    frame.title = title
    
    -- Message text
    local messageText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    messageText:SetPoint("TOPLEFT", 20, -60)
    messageText:SetPoint("TOPRIGHT", -20, -60)
    messageText:SetJustifyH("LEFT")
    messageText:SetJustifyV("TOP")
    messageText:SetWordWrap(true)
    frame.messageText = messageText
    
    -- OK Button
    local okButton = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    okButton:SetSize(100, 30)
    okButton:SetPoint("BOTTOM", 0, 20)
    okButton:SetText("OK")
    okButton:SetScript("OnClick", function() frame:Hide() end)
    
    frame:Hide()
    return frame
end

-- Show notification
function MCL.Notifications:ShowNotification(messageType)
    local message = NOTIFICATION_MESSAGES[messageType]
    if not message then return end
    
    if not self.notificationFrame then
        self.notificationFrame = CreateNotificationFrame()
    end
    
    local frame = self.notificationFrame
    frame.icon:SetTexture(message.icon)
    frame.title:SetText(message.title)
    frame.messageText:SetText(message.text)
    
    -- Adjust frame height based on text
    local textHeight = frame.messageText:GetStringHeight()
    frame:SetHeight(math.max(300, textHeight + 120))
    
    frame:Show()
end

-- Check if we should show a notification
function MCL.Notifications:CheckAndShowNotification()
    -- Initialize settings if they don't exist
    if not MCL_SETTINGS then
        MCL_SETTINGS = {}
    end
    
    if not MCL_SETTINGS.notifications then
        MCL_SETTINGS.notifications = {}
    end
    
    local lastVersion = MCL_SETTINGS.notifications.lastVersion
    local hasSeenWelcome = MCL_SETTINGS.notifications.hasSeenWelcome
    
    -- First time user
    if not hasSeenWelcome then
        C_Timer.After(1, function() -- Delay to let UI load
            self:ShowNotification("welcome")
        end)
        MCL_SETTINGS.notifications.hasSeenWelcome = true
        MCL_SETTINGS.notifications.lastVersion = CURRENT_VERSION
        return
    end
    
    -- Version update
    if lastVersion and lastVersion ~= CURRENT_VERSION then
        C_Timer.After(1, function() -- Delay to let UI load
            self:ShowNotification("update")
        end)
        MCL_SETTINGS.notifications.lastVersion = CURRENT_VERSION
        return
    end
    
    -- Set version if it's missing but user has seen welcome
    if not lastVersion then
        MCL_SETTINGS.notifications.lastVersion = CURRENT_VERSION
    end
end

-- Reset notification status (for testing or admin purposes)
function MCL.Notifications:ResetNotificationStatus()
    if not MCL_SETTINGS then
        MCL_SETTINGS = {}
    end
    
    MCL_SETTINGS.notifications = {
        hasSeenWelcome = false,
        lastVersion = nil
    }
    
    print("|cFF1FB7EBMCL:|r Notification status has been reset. You will see the welcome message next time you open MCL.")
end

-- Force show a specific notification (for testing)
function MCL.Notifications:ForceShowNotification(messageType)
    messageType = messageType or "welcome"
    if NOTIFICATION_MESSAGES[messageType] then
        self:ShowNotification(messageType)
        print("|cFF1FB7EBMCL:|r Showing " .. messageType .. " notification.")
    else
        print("|cFF1FB7EBMCL:|r Invalid notification type. Use 'welcome' or 'update'.")
    end
end

-- Manual trigger for testing the automatic check
function MCL.Notifications:TriggerCheck()
    self:CheckAndShowNotification()
end

-- Initialize the notification system
local function InitializeNotifications()
    -- Simple approach: Monitor the main frame directly
    local function SetupMainFrameHook()
        -- Find the main frame (it might be MCL_mainFrame or MCLFrame)
        local mainFrame = MCLcore and MCLcore.MCL_MF
        if not mainFrame then
            mainFrame = _G["MCLFrame"] or _G["MCL_mainFrame"]
        end
        
        if mainFrame then
            -- Hook the OnShow script
            local originalOnShow = mainFrame:GetScript("OnShow")
            mainFrame:SetScript("OnShow", function(self)
                if originalOnShow then
                    originalOnShow(self)
                end
                -- Check for notifications when main frame shows
                C_Timer.After(0.5, function()
                    MCL.Notifications:CheckAndShowNotification()
                end)
            end)
            return true
        end
        return false
    end
    
    -- Try to set up the hook immediately
    if not SetupMainFrameHook() then
        -- If main frame doesn't exist yet, keep trying
        local attempts = 0
        local function TryAgain()
            attempts = attempts + 1
            if SetupMainFrameHook() then
                return -- Success
            elseif attempts < 10 then -- Try for up to 10 seconds
                C_Timer.After(1, TryAgain)
            end
        end
        TryAgain()
    end
end

-- Event handler for addon loaded
local notificationEventFrame = CreateFrame("Frame")
notificationEventFrame:RegisterEvent("ADDON_LOADED")
notificationEventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "MCL" then
        -- Ensure MCL is globally accessible immediately
        _G["MCL"] = MCL
        
        -- Also make it accessible through MCLcore if it exists
        if MCLcore then
            MCLcore.Notifications = MCL.Notifications
        end
        
        -- Initialize after a short delay to ensure all components are loaded
        C_Timer.After(2, function()
            InitializeNotifications()
        end)
    end
end)
