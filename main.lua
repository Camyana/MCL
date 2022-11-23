-- * ------------------------------------------------------
-- *  Namespaces
-- * ------------------------------------------------------
local MCL, core = ...;

-- * ------------------------------------------------------
-- * Variables
-- * ------------------------------------------------------
core.Main = {};
local MCL_Load = core.Main;
local init_load = true
local load_check = 0

-- * -------------------------------------------------
-- * Initialise Database
-- * Cycles through data.lua, checks if in game mount journal has an entry for mount. Restarts function if mount does is not loaded yet.
-- * Function is designed to check if the ingame mount journal has loaded correctly before loading our own database.
-- * -----------------------------------------------

local function InitMounts()
	load_check = 0
	for b,n in pairs(core.mountList) do
		for h,j in pairs(n) do
			if (type(j) == "table") then
				for k,v in pairs(j) do
                    for kk,vv in pairs(v.mounts) do
                        if string.sub(vv, 1, 1) == "m" then
                        else
                            load_check = load_check + 1
                            local a = vv
                            mountName = C_MountJournal.GetMountFromItem(vv)
                        end
                        if mountName ~= nil then
                            load_check = load_check + 1                   
                        end                        
                    end                    
				end
			end
		end
	end
end


-- * -----------------------------------------------------
-- * Toggle the main window
-- * -----------------------------------------------------

function MCL_Load:PreLoad()      
    if load_check > 1000 then
        return true
    else
        print("MCL - Initialising, try again")        
        InitMounts()         
        return false
    end
end

function MCL_Load:Toggle()
    if MCL_Load:PreLoad() == false then
        return
    end
    if core.MCL_MF == nil then
        core.MCL_MF = core.Frames:CreateMainFrame()            
        core.Function:initSections()               
    else
        core.MCL_MF:SetShown(not core.MCL_MF:IsShown());
    end
    core.Function:UpdateCollection()
end

local f = CreateFrame("Frame")
local login = true



-- * -------------------------------------------------
-- * Loads addon once Blizzard_Collections has loaded in.
-- * -------------------------------------------------


local function onevent(self, event, arg1, ...)
    if(login and ((event == "ADDON_LOADED" and name == arg1) or (event == "PLAYER_LOGIN"))) then
        login = nil
        f:UnregisterEvent("ADDON_LOADED")
        f:UnregisterEvent("PLAYER_LOGIN")
	    if not IsAddOnLoaded("Blizzard_Collections") then
	        LoadAddOn("Blizzard_Collections")
	    end
        core.Function:AddonSettings()
    end
end


-- function addon:MCL_MM() self.db.profile.minimap.hide = not self.db.profile.minimap.hide if self.db.profile.minimap.hide then icon:Hide("MCL-icon") else icon:Show("MCL-icon") end end
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", onevent)