local _, core = ...; -- Namespace
-------------------------------------------------------------

SLASH_MCL1 = "/mcl";

SlashCmdList["MCL"] = function(msg)
    if msg:lower() == "help" then
        print("\n|cff00CCFFMount Collection Log\nCommands:\n|cffFF0000Show:|cffFFFFFF Shows your mount collection log\n|cffFF0000Icon:|cffFFFFFF Toggles the minimap icon.\n|cffFF0000Config:|cffFFFFFF Opens the settings..\n|cffFF0000Help:|cffFFFFFF Shows commands")
    end
    if msg:lower() == "show" then
        core.Main.Toggle();
    end
    if msg:lower() == "icon" then
        core.Function.MCL_MM();
    end        
    if msg:lower() == "" then
        core.Main.Toggle();
    end
    if msg:lower() == "compare" then
        core.Function:compareLink();
    end
    if msg:lower() == "debug" then
        core.Function:GetCollectedMounts();
    end
    if msg:lower() == "conifg" or msg == "settings" then
        core.Frames:openSettings();
    end    
 end 