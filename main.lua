-- * ------------------------------------------------------
-- *  Namespaces
-- * ------------------------------------------------------
local MCL, core = ...;

-- * ------------------------------------------------------
-- * Variables
-- * ------------------------------------------------------
core.Main = {};
local MCL_Load = core.Main;

-- * -------------------------------------------------
-- * Initialise Database
-- * Cycles through data.lua, checks if in game mount journal has an entry for mount. Restarts function if mount does is not loaded yet.
-- * Function is designed to check if the ingame mount journal has loaded correctly before loading our own database.
-- * -----------------------------------------------
local function InitMounts()
	local load_check = 0
	for b,n in pairs(core.mountList) do
		for h,j in pairs(n) do
            if (type(j) == "table") then
                for k,v in pairs(j) do
                    for kk,vv in pairs(v.mounts) do
                        if string.sub(vv, 1, 1) == "m" then
                            id = string.sub(vv, 2, -1)
                        else
                            id = vv
                        end
                        local try = 0
                        while(try < 5) do
                            C_MountJournal.GetMountFromItem(id)
                            try = try + 1
                        end
                    end
                end
            end
		end
	end
    return false
end


function MCL_Load:init()

    -- * -------------------------------------------------
    -- * Pre-requirements to addon loading. Must include the blizzard_collections addon and be able to load all the mounts inside of the addon. 
    
    if not IsAddOnLoaded("Blizzard_Collections") then
        LoadAddOn("Blizzard_Collections")
    end

    local init_load = true
    while (init_load) do
        init_load = InitMounts()
    end	
    -- * Addon pre-requirements met, start creating the frames
    -- * -------------------------------------------------
    return true
end

-- * -----------------------------------------------------
-- * Toggle the main window
-- * -----------------------------------------------------

function MCL_Load:Toggle()
	if not MCLFrame then
		check_if_loaded = MCL_Load.init()
        core.MCL_MF = core.Frames:CreateMainFrame()
        core.Function:initSections()
	else
		MCLFrame:SetShown(not MCLFrame:IsShown());
	end
    core.Function:UpdateCollection()
end

local f = CreateFrame("Frame")
local login = true




---------------------------------------------------
-- Loads addon once Blizzard_Collections has loaded in.
---------------------------------------------------


local function onevent(self, event, arg1, ...)
    if(login and ((event == "ADDON_LOADED" and name == arg1) or (event == "PLAYER_LOGIN"))) then
        login = nil
        f:UnregisterEvent("ADDON_LOADED")
        f:UnregisterEvent("PLAYER_LOGIN")
	    if not IsAddOnLoaded("Blizzard_Collections") then
	        LoadAddOn("Blizzard_Collections")
	    end        
        MCL_Load:init()
        -- createMCLicon()
    end
end

-- function addon:MCL_MM() self.db.profile.minimap.hide = not self.db.profile.minimap.hide if self.db.profile.minimap.hide then icon:Hide("MCL-icon") else icon:Show("MCL-icon") end end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", onevent)