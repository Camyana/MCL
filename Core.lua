local _, MCLCore = ...;
local MCL_Load = MCLCore.Main;

-- Namespace
-------------------------------------------------------------

SLASH_MCL1 = "/mcl";

SlashCmdList["MCL"] = function(msg)
    if msg:lower() == "help" then
        print("\n|cff00CCFFMount Collection Log\nCommands:\n|cffFF0000Show:|cffFFFFFF Shows your mount collection log\n|cffFF0000Icon:|cffFFFFFF Toggles the minimap icon.\n|cffFF0000Config:|cffFFFFFF Opens the settings..\n|cffFF0000Help:|cffFFFFFF Shows commands")
    end
    if msg:lower() == "show" then
        MCLCore.Main.Toggle();
    end
    if msg:lower() == "icon" then
        MCLCore.Function.MCL_MM();
    end        
    if msg:lower() == "" then
        MCLCore.Main.Toggle();
    end
    if msg:lower() == "debug" then
        MCLCore.Function:GetCollectedMounts();
    end
    if msg:lower() == "conifg" or msg == "settings" then
        MCLCore.Frames:openSettings();
    end
    if msg:lower() == "refresh" then
        if MCL_Load and type(MCL_Load.Init) == "function" then
            MCL_Load:Init(true)  -- True to force re-initialization.
        end
    end  
 end