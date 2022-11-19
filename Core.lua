local _, core = ...; -- Namespace
-------------------------------------------------------------

SLASH_MCL1 = "/mcl";

SlashCmdList["MCL"] = function(msg)
    if msg == "help" then
        print("\n|cff00CCFFMount Collection Log\nCommands:\n|cffFF0000Show:|cffFFFFFF Shows your mount collection log\n|cffFF0000Icon:|cffFFFFFF Toggles the minimap icon. Refreshes mount data\n|cffFF0000Help:|cffFFFFFF Shows commands")
    end
    if msg == "show" then
        core.Main.Toggle();
    end
    if msg == "icon" then
        core.Function.MCL_MM();
    end        
    if msg == "" then
        core.Main.Toggle();
    end
    if msg == "compare" then
        core.Function:CompareMountJournal();
    end
 end 