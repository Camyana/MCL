local _, core = ...; -- Namespace
-------------------------------------------------------------

SLASH_MCL1 = "/mcl";

SlashCmdList["MCL"] = function(msg)
    if msg == "help" then
        print("\n|cff00CCFFMount Collection Log\nCommands:\n|cffFF0000Show:|cffFFFFFF Shows your mount collection log\n|cffFF0000Icon:|cffFFFFFF Toggles the minimap icon.\n|cffFF0000Reload:|cffFFFFFF Refreshes mount data\n|cffFF0000Help:|cffFFFFFF Shows commands")
    end
    if msg == "reload" then
        core.Config.Reload();
    end
    if msg == "show" then
        core.Config.Toggle();
    end
    if msg == "icon" then
        core.Config.MCL_MM();
    end        
    if msg == "" then
        core.Config.Toggle();
    end
 end 