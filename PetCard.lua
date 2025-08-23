local PCL, PCLcore = ...;

-- Ensure the Frames module exists
PCLcore.Frames = PCLcore.Frames or {};
PCLcore.PetCard = {};

local PetCard = PCLcore.PetCard;
local PCL_functions = PCLcore.Functions or {};

-- Constants
local PET_CARD_WIDTH = 400;  -- Increased from 350 to 380 for better space utilization
local PET_CARD_HEIGHT = 600; -- Keep height for content display

-- Global frame reference
local PAPetCard = nil

-- Pet type mappings for display
local PET_TYPE_SUFFIX = {
    [1] = "Humanoid", [2] = "Dragonkin", [3] = "Flying", [4] = "Undead", [5] = "Critter",
    [6] = "Magic", [7] = "Elemental", [8] = "Beast", [9] = "Aquatic", [10] = "Mechanical"
}

-- Hover delay system to prevent tooltip flickering when moving between pets
local hoverTimer = nil
local currentHoveredPet = nil
local currentAnchorFrame = nil

-- PetCollector compatibility interface
PCLcore.PetCard.Display = PCLcore.PetCard.Display or {}

--[[
  Family Details - Returns family name, icon key, and RGB colors
]]
local function getFamilyDetails(family)
    if family == 1 then
        return "Humanoid", "humanoid", 8 / 256, 138 / 256, 222 / 256
    elseif family == 2 then
        return "Dragonkin", "dragon", 34 / 256, 165 / 256, 24 / 256
    elseif family == 3 then
        return "Flying", "flying", 214 / 256, 199 / 256, 74 / 256
    elseif family == 4 then
        return "Undead", "undead", 164 / 256, 109 / 256, 115 / 256
    elseif family == 5 then
        return "Critter", "critter", 140 / 256, 101 / 256, 74 / 256
    elseif family == 6 then
        return "Magical", "magical", 156 / 256, 105 / 256, 255 / 256
    elseif family == 7 then
        return "Elemental", "elemental", 247 / 256, 105 / 256, 0 / 256
    elseif family == 8 then
        return "Beast", "beast", 193 / 256, 36 / 256, 33 / 256
    elseif family == 9 then
        return "Aquatic", "water", 8 / 256, 170 / 256, 181 / 256
    elseif family == 10 then
        return "Mechanical", "mechanical", 132 / 256, 125 / 256, 115 / 256
    end
    return "Unknown", "beast", 1, 1, 1
end

--[[
  Detect breed ID from pet stats (simplified version)
]]
local function DetectPetBreed(speciesID, health, power, speed, level, rarity)
    -- Quality multipliers (exact values from BattlePetBreedID)
    local qualityMultipliers = {
        [1] = 0.5, [2] = 0.550000011920929, [3] = 0.600000023841858, 
        [4] = 0.649999976158142, [5] = 0.699999988079071, [6] = 0.75
    }
    
    -- Breed stats modifiers (exact values from BattlePetBreedID)
    local breedStatsModifiers = {
        [3] = {0.5, 0.5, 0.5},   -- B/B
        [4] = {0, 2, 0},         -- P/P
        [5] = {0, 0, 2},         -- S/S
        [6] = {2, 0, 0},         -- H/H
        [7] = {0.9, 0.9, 0},     -- H/P
        [8] = {0, 0.9, 0.9},     -- P/S
        [9] = {0.9, 0, 0.9},     -- H/S
        [10] = {0.4, 0.9, 0.4},  -- P/B
        [11] = {0.4, 0.4, 0.9},  -- S/B
        [12] = {0.9, 0.4, 0.4}   -- H/B
    }
    
    -- Local function to get breed letters from breed ID
    local function GetBreedLetters(breedID)
        local breedLetters = {
            [3] = "B/B",   -- Balanced
            [4] = "P/P",   -- Power
            [5] = "S/S",   -- Speed
            [6] = "H/H",   -- Health
            [7] = "H/P",   -- Health/Power
            [8] = "P/S",   -- Power/Speed
            [9] = "H/S",   -- Health/Speed
            [10] = "P/B",  -- Power/Balanced
            [11] = "S/B",  -- Speed/Balanced
            [12] = "H/B"   -- Health/Balanced
        }
        return breedLetters[breedID] or "?/?"
    end
    
    -- If we don't have complete stats, return first available breed
    if not health or not power or not speed or not level or not rarity then
        if PCLcore.breedData and PCLcore.breedData.species and PCLcore.breedData.species[speciesID] then
            local availableBreeds = PCLcore.breedData.species[speciesID].breeds
            if availableBreeds and #availableBreeds > 0 then
                local firstBreed = availableBreeds[1]
                return firstBreed, GetBreedLetters(firstBreed)
            end
        end
        return 3, "B/B"  -- Fallback only if no breed data
    end
    
    -- Get available breeds for this species
    if not PCLcore.breedData or not PCLcore.breedData.species or not PCLcore.breedData.species[speciesID] then
        return 3, "B/B"  -- Default if no breed data
    end
    
    local availableBreeds = PCLcore.breedData.species[speciesID].breeds
    if not availableBreeds or #availableBreeds == 0 then
        return 3, "B/B"
    end
    
    -- Get base stats for this species (rough estimation)
    local baseHealth, basePower, baseSpeed = 10, 8, 9  -- Default fallback
    
    -- Try to reverse-engineer base stats from the pet's actual stats
    -- This is a simplified approach - for a more accurate one, we'd need the full BattlePetBreedID algorithm
    local qualityMult = qualityMultipliers[rarity] or qualityMultipliers[3]
    local nQL = qualityMult * 2 * level
    
    -- For level 25 rare pets, try to match against expected breed patterns
    if level == 25 and rarity == 3 then
        -- Test each available breed to see which one matches closest
        local bestBreed = availableBreeds[1]  -- Default to first available breed
        local bestLetters = GetBreedLetters(bestBreed)
        local smallestDiff = math.huge
        
        for _, breedID in ipairs(availableBreeds) do
            local breedMods = breedStatsModifiers[breedID]
            if breedMods then
                -- Calculate expected stats for this breed
                local expectedHealth = math.floor(((baseHealth + breedMods[1]) * nQL * 5 + 100) + 0.5)
                local expectedPower = math.floor(((basePower + breedMods[2]) * nQL) + 0.5)
                local expectedSpeed = math.floor(((baseSpeed + breedMods[3]) * nQL) + 0.5)
                
                -- Calculate difference from actual stats
                local diff = math.abs(health - expectedHealth) + math.abs(power - expectedPower) + math.abs(speed - expectedSpeed)
                
                if diff < smallestDiff then
                    smallestDiff = diff
                    bestBreed = breedID
                    bestLetters = GetBreedLetters(breedID)
                end
            end
        end
        
        return bestBreed, bestLetters
    end
    
    -- For other cases, use scoring system to find best match among available breeds
    local totalStats = health + power + speed
    local healthRatio = health / totalStats
    local powerRatio = power / totalStats
    local speedRatio = speed / totalStats
    
    -- Look for stat distribution patterns in available breeds only
    local bestMatch = availableBreeds[1]  -- Default to first available
    local bestLetters = GetBreedLetters(bestMatch)
    local bestScore = 0
    
    for _, breedID in ipairs(availableBreeds) do
        local letters = GetBreedLetters(breedID)
        local score = 0
        
        -- Calculate match score based on stat emphasis
        if letters == "P/P" and powerRatio > 0.4 then
            score = powerRatio * 100
        elseif letters == "S/S" and speedRatio > 0.4 then
            score = speedRatio * 100
        elseif letters == "H/H" and healthRatio > 0.5 then
            score = healthRatio * 100
        elseif letters == "H/P" and healthRatio > 0.35 and powerRatio > 0.3 then
            score = (healthRatio + powerRatio) * 50
        elseif letters == "P/S" and powerRatio > 0.3 and speedRatio > 0.3 then
            score = (powerRatio + speedRatio) * 50
        elseif letters == "H/S" and healthRatio > 0.35 and speedRatio > 0.3 then
            score = (healthRatio + speedRatio) * 50
        elseif letters == "P/B" then
            score = powerRatio * 60  -- Medium power bias
        elseif letters == "S/B" then
            score = speedRatio * 60  -- Medium speed bias
        elseif letters == "H/B" then
            score = healthRatio * 60  -- Medium health bias
        elseif letters == "B/B" then
            score = 30  -- Balanced gets moderate score
        end
        
        if score > bestScore then
            bestScore = score
            bestMatch = breedID
            bestLetters = letters
        end
    end
    
    return bestMatch, bestLetters
end

--[[
  Update ability display with proper tooltip
]]
local function UpdateAbility(texture, abilityID, petType)
    if not abilityID then
        texture:Hide()
        return
    end
    
    local _, icon = C_PetJournal.GetPetAbilityInfo(abilityID)
    if icon then
        texture:Show()
        texture:SetTexture(icon)
        
        texture:SetScript("OnEnter", function(self)
            -- Try to use the proper WoW pet battle tooltip first
            if SharedPetBattleAbilityTooltip_SetAbility and PetBattlePrimaryAbilityTooltip then
                local abilityInfo = C_PetJournal.GetPetAbilityInfo(abilityID)
                if abilityInfo then
                    local success = pcall(function()
                        PetBattlePrimaryAbilityTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        SharedPetBattleAbilityTooltip_SetAbility(PetBattlePrimaryAbilityTooltip, abilityInfo)
                        PetBattlePrimaryAbilityTooltip:Show()
                    end)
                    if success then
                        return
                    end
                end
            end
            
            -- Fallback to custom tooltip
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local name, icon, petType, noStrongWeakHints = C_PetJournal.GetPetAbilityInfo(abilityID)
            if name then
                GameTooltip:SetText(name, 1, 1, 1, 1, true)
                if petType then
                    local familyName = getFamilyDetails(petType)
                    GameTooltip:AddLine("Type: " .. familyName, 0.9, 0.9, 0.9)
                end
                GameTooltip:AddLine("Ability ID: " .. abilityID, 0.6, 0.6, 0.6)
            end
            GameTooltip:Show()
        end)
        
        texture:SetScript("OnLeave", function()
            if PetBattlePrimaryAbilityTooltip then
                pcall(function() PetBattlePrimaryAbilityTooltip:Hide() end)
            end
            GameTooltip:Hide()
        end)
    else
        texture:Hide()
    end
end

-- Breed ID to stat allocation mapping (based on WoW pet breed system)
local breedData = {
    [3] = {health = 5, power = 5, speed = 5, letters = "B/B"}, -- Balanced
    [4] = {health = 9, power = 0, speed = 9, letters = "H/S"}, -- Health/Speed 
    [5] = {health = 0, power = 20, speed = 0, letters = "P/P"}, -- Pure Power
    [6] = {health = 20, power = 0, speed = 0, letters = "H/H"}, -- Pure Health
    [7] = {health = 9, power = 9, speed = 0, letters = "H/P"}, -- Health/Power
    [8] = {health = 0, power = 9, speed = 9, letters = "P/S"}, -- Power/Speed
    [9] = {health = 4, power = 9, speed = 4, letters = "H/S"}, -- Health/Speed (variant)
    [10] = {health = 4, power = 4, speed = 9, letters = "P/B"}, -- Power/Balance
    [11] = {health = 4, power = 4, speed = 9, letters = "S/B"}, -- Speed/Balance
    [12] = {health = 9, power = 4, speed = 4, letters = "H/B"}, -- Health/Balance
    [13] = {health = 5, power = 5, speed = 5, letters = "B/B"}, -- Balanced (variant)
    [14] = {health = 0, power = 0, speed = 20, letters = "S/S"}, -- Pure Speed
    [15] = {health = 0, power = 0, speed = 20, letters = "S/S"}, -- Pure Speed (variant)
    [16] = {health = 20, power = 0, speed = 0, letters = "H/H"}, -- Pure Health (variant)
    [17] = {health = 9, power = 0, speed = 9, letters = "H/P"}, -- Health/Power (variant)
    [18] = {health = 0, power = 9, speed = 9, letters = "P/S"}, -- Power/Speed (variant)
    [19] = {health = 4, power = 9, speed = 4, letters = "H/S"}, -- Health/Speed (variant)
    [20] = {health = 4, power = 4, speed = 9, letters = "P/B"}, -- Power/Balance (variant)
    [21] = {health = 4, power = 4, speed = 9, letters = "S/B"}, -- Speed/Balance (variant)
    [22] = {health = 9, power = 4, speed = 4, letters = "H/B"}, -- Health/Balance (variant)
}

-- Quality multipliers (exact values from BattlePetBreedID)
local qualityMultipliers = {
    [1] = 0.5,
    [2] = 0.550000011920929,
    [3] = 0.600000023841858, 
    [4] = 0.649999976158142,
    [5] = 0.699999988079071,
    [6] = 0.75
}

-- Breed stats modifiers (exact values from BattlePetBreedID)
local breedStatsModifiers = {
    [3] = {0.5, 0.5, 0.5},   -- B/B
    [4] = {0, 2, 0},         -- P/P
    [5] = {0, 0, 2},         -- S/S
    [6] = {2, 0, 0},         -- H/H
    [7] = {0.9, 0.9, 0},     -- H/P
    [8] = {0, 0.9, 0.9},     -- P/S
    [9] = {0.9, 0, 0.9},     -- H/S
    [10] = {0.4, 0.9, 0.4},  -- P/B
    [11] = {0.4, 0.4, 0.9},  -- S/B
    [12] = {0.9, 0.4, 0.4}   -- H/B
}

--[[
  Calculate breed stats for a pet using BattlePetBreedID algorithm
]]
local function CalculateBreedStats(baseHealth, basePower, baseSpeed, breedID, level, quality)
    level = level or 25
    quality = quality or 3
    
    local breedMods = breedStatsModifiers[breedID]
    if not breedMods then
        return nil -- Unknown breed
    end
    
    local qualityMult = qualityMultipliers[quality] or qualityMultipliers[3]
    local nQL = qualityMult * 2 * level
    
    -- Use exact BattlePetBreedID formulas
    local health = math.floor(((baseHealth + breedMods[1]) * nQL * 5 + 100) + 0.5)
    local power = math.floor(((basePower + breedMods[2]) * nQL) + 0.5)
    local speed = math.floor(((baseSpeed + breedMods[3]) * nQL) + 0.5)
    
    return {
        health = health,
        power = power,
        speed = speed,
        letters = breedData[breedID] and breedData[breedID].letters or "?/?"
    }
end

--[[
  Get collection status for a pet species with breed information
]]
local function GetPetCollectionInfo(speciesID)
    local collectedCount = 0
    local collectedPets = {}
    local maxQuality = 0
    
    for i = 1, C_PetJournal.GetNumPets() do
        local petID, speciesIDCheck, owned, customName, level, favorite, isRevoked = C_PetJournal.GetPetInfoByIndex(i)
        if speciesIDCheck == speciesID and owned then
            collectedCount = collectedCount + 1
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
            if rarity and rarity > maxQuality then
                maxQuality = rarity
            end
            
            -- Use the DetectPetBreed function which respects available breeds
            local breedID, breedLetters = DetectPetBreed(speciesID, health, power, speed, level, rarity)
            
            table.insert(collectedPets, {
                petID = petID,
                level = level or 1,
                rarity = rarity or 1,
                health = health or 0,
                power = power or 0,
                speed = speed or 0,
                breedID = breedID,
                breedLetters = breedLetters,
                customName = customName or nil
            })
        end
    end
    
    -- Sort by quality (rarity) descending, then by level descending
    table.sort(collectedPets, function(a, b)
        if a.rarity ~= b.rarity then
            return a.rarity > b.rarity
        end
        return a.level > b.level
    end)
    
    return collectedCount, collectedPets, maxQuality
end

--[[
  Get available breeds for a pet species with realistic WoW data
]]
--[[
  Get available breeds for a pet species using comprehensive breed data
]]
local function GetPetBreeds(speciesID)
    -- Check if we have breed data loaded and available for this species
    if not PCLcore.breedData or not PCLcore.breedData.species or not PCLcore.breedData.species[speciesID] then
        return {} -- No breed data available
    end
    
    -- Get the available breeds from our comprehensive data
    local availableBreedIDs = PCLcore.breedData.species[speciesID].breeds
    if not availableBreedIDs or #availableBreedIDs == 0 then
        return {} -- No breeds available for this species
    end
    
    -- Get base stats for this species (try to get from actual collected pets first)
    local baseHealth, basePower, baseSpeed = 10, 8, 9 -- Default fallback values
    local foundRealStats = false
    
    -- Look for collected pets of this species to get real base stats
    for i = 1, C_PetJournal.GetNumPets() do
        local petID, speciesIDCheck, owned, customName, level, favorite, isRevoked = C_PetJournal.GetPetInfoByIndex(i)
        if speciesIDCheck == speciesID and owned then
            local health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
            if health and power and speed and level and level > 1 then
                -- Reverse calculate base stats using BattlePetBreedID method
                local qualityMult = qualityMultipliers[rarity] or qualityMultipliers[3]
                local nQL = qualityMult * 2 * level
                baseHealth = ((health - 100) / (nQL * 5)) - 0.5
                basePower = (power / nQL) - 0.5
                baseSpeed = (speed / nQL) - 0.5
                foundRealStats = true
                break
            end
        end
    end
    
    -- If no real stats found, use species-specific defaults based on common pet types
    if not foundRealStats then
        -- These are based on common WoW pet stat patterns
        local speciesName = C_PetJournal.GetPetInfoBySpeciesID(speciesID)
        if speciesName then
            if string.find(string.lower(speciesName), "moth") or string.find(string.lower(speciesName), "flying") then
                baseHealth, basePower, baseSpeed = 8, 7, 12  -- Flying pets tend to be fast
            elseif string.find(string.lower(speciesName), "beast") or string.find(string.lower(speciesName), "wolf") then
                baseHealth, basePower, baseSpeed = 10, 10, 8   -- Balanced stats
            else
                baseHealth, basePower, baseSpeed = 9, 8, 9     -- Default balanced
            end
        end
    end
    
    -- Build breeds list using only the available breeds for this species
    local breeds = {}
    for _, breedID in ipairs(availableBreedIDs) do
        local breedName = PCLcore.GetBreedName(breedID)
        local stats = CalculateBreedStats(baseHealth, basePower, baseSpeed, breedID, 25, 3)
        if stats and breedName then
            table.insert(breeds, {
                breedID = breedID,
                breedCode = breedName,
                health = stats.health,
                power = stats.power,
                speed = stats.speed
            })
        end
    end
    
    -- Sort by total stats descending (most powerful first)
    table.sort(breeds, function(a, b)
        local totalA = a.health + a.power + a.speed
        local totalB = b.health + b.power + b.speed
        return totalA > totalB
    end)
    
    return breeds
end

--[[
  Update ability display with proper tooltip
]]
local function UpdateAbility(texture, abilityID, petType)
    if not abilityID then
        texture:Hide()
        return
    end
    
    local _, icon = C_PetJournal.GetPetAbilityInfo(abilityID)
    if icon then
        texture:Show()
        texture:SetTexture(icon)
        
        -- Add border to ability icons
        if not texture.border then
            texture.border = texture:GetParent():CreateTexture(nil, "OVERLAY")
            texture.border:SetPoint("CENTER", texture, "CENTER")
            texture.border:SetSize(texture:GetSize())
            texture.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            texture.border:SetVertexColor(0.5, 0.5, 0.5, 0.8)
        end
        
        texture:SetScript("OnEnter", function(self)
            -- Try to use the proper WoW pet battle tooltip first
            if SharedPetBattleAbilityTooltip_SetAbility and PetBattlePrimaryAbilityTooltip and PetBattlePrimaryAbilityTooltip.SetOwner then
                local abilityInfo = C_PetJournal.GetPetAbilityInfo(abilityID)
                if abilityInfo then
                    local success = pcall(function()
                        PetBattlePrimaryAbilityTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        SharedPetBattleAbilityTooltip_SetAbility(PetBattlePrimaryAbilityTooltip, abilityInfo)
                        PetBattlePrimaryAbilityTooltip:Show()
                    end)
                    if success then
                        return
                    end
                end
            end
            
            -- Fallback to custom tooltip with detailed ability info
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local name, icon, petType, noStrongWeakHints = C_PetJournal.GetPetAbilityInfo(abilityID)
            if name then
                GameTooltip:SetText(name, 1, 1, 1, 1, true)
                if petType then
                    local familyName = getFamilyDetails(petType)
                    GameTooltip:AddLine("Type: " .. familyName, 0.9, 0.9, 0.9)
                end
                GameTooltip:AddLine("Ability ID: " .. abilityID, 0.6, 0.6, 0.6)
            else
                GameTooltip:SetText("Pet Ability", 1, 1, 1)
                GameTooltip:AddLine("Ability ID: " .. abilityID, 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        
        texture:SetScript("OnLeave", function()
            if PetBattlePrimaryAbilityTooltip and PetBattlePrimaryAbilityTooltip.Hide then
                pcall(function()
                    PetBattlePrimaryAbilityTooltip:Hide()
                end)
            end
            GameTooltip:Hide()
        end)
    else
        texture:Hide()
    end
end

--[[
  Create section header with your navigation frame styling
]]
local function CreateSectionHeader(parent, text, yOffset, currentOpacity)
    local header = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    header:SetSize(PET_CARD_WIDTH - 40, 25)
    header:SetPoint("TOP", parent, "TOP", 0, yOffset)
    
    -- Use current opacity if provided, otherwise fallback
    local opacity = currentOpacity or (PCL_SETTINGS and PCL_SETTINGS.opacity) or 0.95
    
    -- Use your navigation frame styling
    if PCL_SETTINGS and PCL_SETTINGS.useBlizzardTheme then
        header:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", 
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
            edgeSize = 8,
            insets = {left = 2, right = 2, top = 2, bottom = 2}
        })
        header:SetBackdropColor(0.05, 0.05, 0.2, opacity)
        header:SetBackdropBorderColor(0.6, 0.6, 0.8, 0.8)
    else
        header:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            edgeSize = 4
        })
        header:SetBackdropColor(0.1, 0.1, 0.1, opacity)  -- Use current opacity setting
        header:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    end
    
    local headerText = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    headerText:SetPoint("LEFT", header, "LEFT", 8, 0)
    if PCL_SETTINGS and PCL_SETTINGS.useBlizzardTheme then
        headerText:SetTextColor(1, 0.82, 0, 1)  -- Gold color like Blizzard UI
    else
        headerText:SetTextColor(0.3, 0.7, 0.9, 1)  -- Your PCL blue color
    end
    headerText:SetText(text)
    
    return header
end

-- Mixed implementation cleanup - removed incomplete functions

--[[
  Get PetCard dimensions that match main window height
]]
local function GetPetCardDimensions()
    local cardWidth = PET_CARD_WIDTH
    local cardHeight = PET_CARD_HEIGHT
    
    -- Get main window height if available
    if PCL_frames and PCL_frames.GetCurrentFrameDimensions then
        local _, mainHeight = PCL_frames:GetCurrentFrameDimensions()
        if mainHeight and mainHeight > 0 then
            cardHeight = mainHeight
            if PCLcore and PCLcore.Debug then
                print(string.format("[PCL Debug] GetPetCardDimensions: Using main window height: %d", mainHeight))
            end
        else
            if PCLcore and PCLcore.Debug then
                print("[PCL Debug] GetPetCardDimensions: No valid main height, using default")
            end
        end
    else
        if PCLcore and PCLcore.Debug then
            print("[PCL Debug] GetPetCardDimensions: PCL_frames.GetCurrentFrameDimensions not available")
        end
    end
    
    return cardWidth, cardHeight
end

--[[
  Resize PetCard to match main frame dimensions
]]
function PetCard:ResizePetCard()
    if not PCL_PetCard then
        return
    end
    
    -- Get new dimensions (fixed width, dynamic height)
    local cardWidth, cardHeight = GetPetCardDimensions()
    
    -- Debug output to help diagnose sizing issues
    if PCLcore and PCLcore.Debug then
        print(string.format("[PCL Debug] PetCard Resize: cardWidth=%d, cardHeight=%d", cardWidth or 0, cardHeight or 0))
        if PCL_mainFrame then
            local mainWidth, mainHeight = PCL_mainFrame:GetSize()
            print(string.format("[PCL Debug] MainFrame Size: width=%d, height=%d", mainWidth or 0, mainHeight or 0))
        end
    end
    
    -- Resize the main card frame
    PCL_PetCard:SetSize(cardWidth, cardHeight)
    
    -- Resize child frames with fixed width
    if PCL_PetCard.titleFrame then
        PCL_PetCard.titleFrame:SetSize(cardWidth - 20, 40)
    end
    
    if PCL_PetCard.scrollChild then
        PCL_PetCard.scrollChild:SetSize(cardWidth - 20, cardHeight - 80)
    end
end

--[[
  Create the main PetCard frame using PCL styling
]]
function PetCard:CreatePetCard()
    if PCL_PetCard then
        return PCL_PetCard  -- Already exists
    end
    
    -- Get dynamic dimensions
    local cardWidth, cardHeight = GetPetCardDimensions()
    
    -- Create main frame with PCL styling
    local f = CreateFrame("Frame", "PCL_PetCard", UIParent, "BackdropTemplate")
    f:SetSize(cardWidth, cardHeight)  -- Use dynamic dimensions
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetMovable(false)  -- Disable moving since it's anchored
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:Hide()  -- Start hidden
    
    -- Apply PCL theming
    local currentOpacity = (PCL_SETTINGS and PCL_SETTINGS.opacity) or 0.95
    if PCL_SETTINGS and PCL_SETTINGS.useBlizzardTheme then
        f:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark", 
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
            edgeSize = 16,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        f:SetBackdropColor(0.05, 0.05, 0.15, currentOpacity)
        f:SetBackdropBorderColor(0.4, 0.4, 0.6, 1)
    else
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8", 
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", 
            edgeSize = 8
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, currentOpacity)
        f:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    end
    
    -- Tabs removed - simplified layout
    
    -- Title bar
    f.titleFrame = CreateFrame("Frame", nil, f)
    f.titleFrame:SetSize(cardWidth - 20, 40)
    f.titleFrame:SetPoint("TOP", f, "TOP", 0, -10)
    f.titleFrame:EnableMouse(false)  -- Disable dragging since frame is anchored
    
    -- Title text
    f.title = f.titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("LEFT", f.titleFrame, "LEFT", 10, 0)
    f.title:SetText("Pet Information")
    if PCL_SETTINGS and PCL_SETTINGS.useBlizzardTheme then
        f.title:SetTextColor(1, 0.82, 0, 1)
    else
        f.title:SetTextColor(0.3, 0.7, 0.9, 1)
    end
    
    
    -- Scroll frame for content (positioned below title frame)
    f.scrollFrame = CreateFrame("ScrollFrame", nil, f)
    f.scrollFrame:SetPoint("TOPLEFT", f.titleFrame, "BOTTOMLEFT", 0, -10)  -- Below title frame
    f.scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -10, 10)
    
    -- Scroll child
    f.scrollChild = CreateFrame("Frame", nil, f.scrollFrame)
    f.scrollChild:SetSize(cardWidth - 20, cardHeight - 80)  -- Use dynamic dimensions
    f.scrollFrame:SetScrollChild(f.scrollChild)
    
    -- Initialize properties
    f.isPinned = false
    f.currentSpeciesID = nil
    f.currentAnchorFrame = nil
    
    -- Store global reference
    PCL_PetCard = f
    return f
end

--[[
  Create pet card content directly in the main window
]]
function PetCard:CreatePetCardContent(parentFrame, petData)
    if not parentFrame or not petData then
        -- Missing parentFrame or petData
        return
    end
    
    
    -- Clear existing content in the parent frame
    local children = {parentFrame:GetChildren()}
    for _, child in ipairs(children) do
        if child then
            child:Hide()
            if child.SetParent then
                child:SetParent(nil)
            end
        end
    end
    
    -- Get pet data from WoW API
    local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(petData.speciesID)
    local abilities = C_PetJournal.GetPetAbilityList(petData.speciesID)
    
    
    -- Get pet collection info
    local collectedCount, collectedPets, maxQuality = GetPetCollectionInfo(petData.speciesID)
    
    local yOffset = -20
    local contentHeight = 40
    local contentWidth = parentFrame:GetWidth() - 60 -- Leave margins
    
    -- Pet Card Title
    local titleFrame = CreateFrame("Frame", nil, parentFrame)
    titleFrame:SetSize(contentWidth, 40)
    titleFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 30, yOffset)
    
    local title = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("LEFT", titleFrame, "LEFT", 0, 0)
    title:SetText(speciesName or "Unknown Pet")
    title:SetTextColor(1, 0.82, 0, 1) -- Yellow title
    
    yOffset = yOffset - 50
    contentHeight = contentHeight + 50
    
    -- Main content area: Full-width model frame
    local mainContentFrame = CreateFrame("Frame", nil, parentFrame)
    mainContentFrame:SetSize(contentWidth, 125)
    mainContentFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 30, yOffset)
    
    -- Full-width model area
    local modelFrame = CreateFrame("Frame", nil, mainContentFrame, "BackdropTemplate")
    modelFrame:SetSize(contentWidth, 125)
    modelFrame:SetPoint("TOPLEFT", mainContentFrame, "TOPLEFT", 0, 0)
    
    -- Style the model frame
    modelFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 4,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    modelFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    modelFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    -- Create the 3D model in the model frame
    local petModel = CreateFrame("PlayerModel", nil, modelFrame)
    petModel:SetSize(contentWidth - 50, 190)
    petModel:SetPoint("CENTER", modelFrame, "CENTER", 0, 0)
    
    -- Enable mouse interaction
    petModel:EnableMouse(true)
    petModel:SetScript("OnMouseWheel", function(self, delta)
        -- Use SetCamDistanceScale for PlayerModel frames
        local currentScale = self.cameraScale or 1.8
        currentScale = currentScale - (delta * 0.2)  -- Adjust zoom sensitivity
        currentScale = math.max(0.5, math.min(5.0, currentScale))  -- Reasonable zoom range
        self:SetCamDistanceScale(currentScale)
        self.cameraScale = currentScale  -- Store current scale
    end)
    
    -- Set up the 3D model with fallback
    if modelVariations and modelVariations.variations and #modelVariations.variations > 0 then
        -- Model variations available - will be handled by tab system below
    else
        -- No variations - set up default model
        if companionID and companionID > 0 then
            local success = pcall(function()
                petModel:SetCreature(companionID)
            end)
            
            if success then
                petModel:Show()
                C_Timer.After(0.1, function()
                    if petModel then
                        petModel:SetCamDistanceScale(1.8)
                        petModel:SetRotation(0.3)
                        if petModel.RefreshCamera then
                            petModel:RefreshCamera()
                        end
                    end
                end)
            else
                petModel:Hide()
            end
        end
    end
    
    -- Fallback icon if 3D model doesn't work
    local fallbackIcon = mainContentFrame.modelFrame.fallbackIcon
    if not fallbackIcon then
        fallbackIcon = mainContentFrame.modelFrame:CreateTexture(nil, "ARTWORK")
        mainContentFrame.modelFrame.fallbackIcon = fallbackIcon
        fallbackIcon:SetSize(128, 128)
        fallbackIcon:SetPoint("CENTER", mainContentFrame.modelFrame, "CENTER", 20, 0)  -- Offset for tabs
    end
    
    if not companionID or companionID <= 0 then
        if speciesIcon then
            fallbackIcon:SetTexture(speciesIcon)
            fallbackIcon:Show()
        end
        petModel:Hide()
    else
        fallbackIcon:Hide()
    end
    
    yOffset = yOffset - 140
    contentHeight = contentHeight + 140
    
    -- Description section
    if tooltipDescription then
        local descFrame = CreateFrame("Frame", nil, parentFrame)
        descFrame:SetSize(contentWidth, 30)
        descFrame:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 30, yOffset)
        
        local descText = descFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descText:SetPoint("TOPLEFT", descFrame, "TOPLEFT", 0, 0)
        descText:SetPoint("TOPRIGHT", descFrame, "TOPRIGHT", 0, 0)
        descText:SetJustifyH("CENTER")
        descText:SetWordWrap(true)
        descText:SetText(tooltipDescription)
        descText:SetTextColor(1, 0.82, 0, 1)
        
        local descHeight = descText:GetStringHeight()
        descFrame:SetHeight(descHeight + 10)
        yOffset = yOffset - (descHeight + 20)
        contentHeight = contentHeight + descHeight + 20
    end
    
    -- Set the parent frame's height to fit all content
    parentFrame:SetHeight(contentHeight + 40)
end

--[[
  Update window with pet data - Main content update function
]]
function PetCard:UpdateWindow(petData)
    if not PCL_PetCard or not petData then 
        -- Missing PetCard or petData
        return 
    end
    
    
    -- Get the current opacity setting fresh each time
    local currentOpacity = 0.95  -- default fallback
    if PCL_SETTINGS and PCL_SETTINGS.opacity then
        currentOpacity = PCL_SETTINGS.opacity
    end
    
    -- For backdrop color, we need to use a much lower opacity to match the main frame's visual appearance
    local backdropOpacity = math.min(1.0, currentOpacity * 1.2)  -- More opaque to match main frame appearance, clamped to 1.0
    
    -- Update main frame opacity if it exists using navigation frame styling
    if PCL_PetCard.SetBackdropColor then
        if PCL_SETTINGS and PCL_SETTINGS.useBlizzardTheme then
            PCL_PetCard:SetBackdropColor(0.05, 0.05, 0.15, 0.95)  -- Dark blue tint with higher opacity
        else
            PCL_PetCard:SetBackdropColor(0.08, 0.08, 0.08, 0.95)  -- Same as nav frame
        end
    end
    
    -- Get pet data from WoW API
    local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable, creatureDisplayID = C_PetJournal.GetPetInfoBySpeciesID(petData.speciesID)
    local abilities = C_PetJournal.GetPetAbilityList(petData.speciesID)
    
    
    -- Get pet collection info
    local collectedCount, collectedPets, maxQuality = GetPetCollectionInfo(petData.speciesID)
    
    -- Update title
    PCL_PetCard.title:SetText(speciesName or "Unknown Pet")
    
    -- Clear and rebuild content - properly destroy all child frames
    if PCL_PetCard.scrollChild then
        -- Get all children and completely remove them
        local children = {PCL_PetCard.scrollChild:GetChildren()}
        for _, child in ipairs(children) do
            if child then
                -- Hide child first
                if child.Hide then
                    child:Hide()
                end
                
                -- Clear all child's own children recursively
                local subChildren = {child:GetChildren()}
                for _, subChild in ipairs(subChildren) do
                    if subChild and subChild.Hide then
                        subChild:Hide()
                    end
                    if subChild and subChild.SetParent then
                        subChild:SetParent(nil)
                    end
                end
                
                -- Clear all regions (textures/fontstrings) on the child
                local childRegions = {child:GetRegions()}
                for _, region in ipairs(childRegions) do
                    if region and region.Hide then
                        region:Hide()
                    end
                    if region and region.SetParent then
                        region:SetParent(nil)
                    end
                end
                
                -- Finally remove the child itself
                if child.SetParent then
                    child:SetParent(nil)
                end
            end
        end
        
        -- Also clear font strings and textures that are direct children of scrollChild
        local regions = {PCL_PetCard.scrollChild:GetRegions()}
        for _, region in ipairs(regions) do
            if region and region.Hide then
                region:Hide()
            end
            if region and region.SetParent then
                region:SetParent(nil)
            end
        end
        
        -- Clear ALL stored references so they get recreated fresh
        PCL_PetCard.scrollChild.mainContent = nil
        PCL_PetCard.scrollChild.modelFrame = nil
        PCL_PetCard.scrollChild.infoFrame = nil
        PCL_PetCard.scrollChild.petModel = nil
        PCL_PetCard.scrollChild.fallbackIcon = nil
        PCL_PetCard.scrollChild.petNameLabel = nil
        PCL_PetCard.scrollChild.familyIconTex = nil
        PCL_PetCard.scrollChild.familyText = nil
        PCL_PetCard.scrollChild.collectionText = nil
        PCL_PetCard.scrollChild.tradeableText = nil
        PCL_PetCard.scrollChild.petTabContainer = nil
        PCL_PetCard.scrollChild.sourceLabel = nil
        PCL_PetCard.scrollChild.descText = nil
        PCL_PetCard.scrollChild.descFrame = nil
        PCL_PetCard.scrollChild.bannerFrame = nil
        PCL_PetCard.scrollChild.mainFrame = nil
        -- Clear section headers
        PCL_PetCard.scrollChild.abilitiesHeader = nil
        PCL_PetCard.scrollChild.petsHeader = nil
        PCL_PetCard.scrollChild.sourceHeader = nil
        PCL_PetCard.scrollChild.descHeader = nil
        -- Clear ability frames
        for i = 1, 10 do
            PCL_PetCard.scrollChild["abilityFrame" .. i] = nil
        end
    end
    
    local yOffset = -5  -- Moved closer to title (was -20)
    local contentHeight = 20
    
    -- Main content area: Full-width model frame like in reference
    local mainContentFrame = PCL_PetCard.scrollChild.mainContent or CreateFrame("Frame", nil, PCL_PetCard.scrollChild)
    PCL_PetCard.scrollChild.mainContent = mainContentFrame
    mainContentFrame:SetSize(PET_CARD_WIDTH - 20, 180)  -- Increased height from 125 to 180
    mainContentFrame:SetPoint("TOPLEFT", PCL_PetCard.scrollChild, "TOPLEFT", 10, yOffset)  -- Reduced left margin from 20 to 10
    
    -- Full-width model area (like in reference image)
    local modelFrame = mainContentFrame.modelFrame or CreateFrame("Frame", nil, mainContentFrame, "BackdropTemplate")
    mainContentFrame.modelFrame = modelFrame
    modelFrame:SetSize(PET_CARD_WIDTH - 20, 180)  -- Increased height from 125 to 180
    modelFrame:SetPoint("TOPLEFT", mainContentFrame, "TOPLEFT", 0, 0)
    
    -- Style the model frame
    modelFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 4,
        insets = {left = 3, right = 3, top = 3, bottom = 3}
    })
    modelFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    modelFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
    
    -- Create the 3D model in the model frame
    local petModel = mainContentFrame.modelFrame.petModel
    
    if not petModel then
        -- Use PlayerModel for 3D display
        petModel = CreateFrame("PlayerModel", nil, mainContentFrame.modelFrame)
        mainContentFrame.modelFrame.petModel = petModel
        petModel:SetSize(PET_CARD_WIDTH - 90, 175)  -- Reduced width to make room for tabs
        petModel:SetPoint("CENTER", mainContentFrame.modelFrame, "CENTER", 20, 0)  -- Offset right for tabs
        
        -- Enable mouse interaction for camera controls
        petModel:EnableMouse(true)
        petModel:SetScript("OnMouseWheel", function(self, delta)
            -- Use SetCamDistanceScale for PlayerModel frames
            local currentScale = self.cameraScale or 1.8
            currentScale = currentScale - (delta * 0.2)  -- Adjust zoom sensitivity
            currentScale = math.max(0.5, math.min(5.0, currentScale))  -- Reasonable zoom range
            self:SetCamDistanceScale(currentScale)
            self.cameraScale = currentScale  -- Store current scale
        end)
        
        -- Enable dragging to rotate
        petModel:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self.isRotating = true
                self.startX = GetCursorPosition()
            end
        end)
        
        petModel:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                self.isRotating = false
            end
        end)
        
        petModel:SetScript("OnUpdate", function(self)
            if self.isRotating then
                local currentX = GetCursorPosition()
                if self.startX then
                    local deltaX = (currentX - self.startX) * 0.01
                    local currentRotation = self.currentRotation or 0.3
                    currentRotation = currentRotation + deltaX
                    self:SetRotation(currentRotation)
                    self.currentRotation = currentRotation
                    self.startX = currentX
                end
            end
        end)
    end
    
    -- Create model variation tabs system
    local modelVariationsFrame = mainContentFrame.modelFrame.modelVariationsFrame
    if not modelVariationsFrame then
        modelVariationsFrame = CreateFrame("Frame", nil, mainContentFrame.modelFrame)
        mainContentFrame.modelFrame.modelVariationsFrame = modelVariationsFrame
        modelVariationsFrame:SetSize(40, 175)  -- Narrow tab area
        modelVariationsFrame:SetPoint("LEFT", mainContentFrame.modelFrame, "LEFT", 5, 0)
    end
    
    -- Get model variations for this pet
    local modelVariations = nil
    if PCLcore.PetModelVariations and PCLcore.PetModelVariations[petData.speciesID] then
        modelVariations = PCLcore.PetModelVariations[petData.speciesID]
    end
    
    -- Clear existing tabs
    if modelVariationsFrame.tabs then
        for _, tab in ipairs(modelVariationsFrame.tabs) do
            tab:Hide()
            tab:SetParent(nil)
        end
    end
    modelVariationsFrame.tabs = {}
    
    -- Function to update the model display
    local function UpdateModelDisplay(displayID, isOwned)
        if not petModel then 
            return 
        end
        
        local modelShown = false
        
        if displayID then
            -- Try method 1: Set display info directly
            local success = pcall(function()
                petModel:SetDisplayInfo(tonumber(displayID))
                modelShown = true
            end)
            
            if not success and companionID and companionID > 0 then
                -- Try method 2: Set creature and override display
                success = pcall(function()
                    petModel:SetCreature(companionID)
                    -- Some models might need the display ID set after creature
                    petModel:SetDisplayInfo(tonumber(displayID))
                    modelShown = true
                end)
            end
            
            if not success and companionID and companionID > 0 then
                -- Fallback: Just use the base creature model
                success = pcall(function()
                    petModel:SetCreature(companionID)
                    modelShown = true
                end)
            end
        elseif companionID and companionID > 0 then
            -- No specific display ID, use creature ID
            local success = pcall(function()
                petModel:SetCreature(companionID)
                modelShown = true
            end)
        end
        
        if modelShown then
            petModel:Show()
            -- Apply camera settings after a brief delay
            C_Timer.After(0.1, function()
                if petModel then
                    petModel:SetCamDistanceScale(1.8)
                    petModel:SetRotation(0.3)
                    petModel.currentRotation = 0.3
                    if petModel.RefreshCamera then
                        petModel:RefreshCamera()
                    end
                end
            end)
            
            -- Update visual feedback based on ownership
            if petModel and petModel.SetDesaturated then
                if isOwned then
                    petModel:SetDesaturated(false)
                    petModel:SetAlpha(1.0)
                else
                    petModel:SetDesaturated(true)
                    petModel:SetAlpha(0.6)
                end
            elseif petModel then
                -- Fallback: only set alpha if SetDesaturated is not available
                if isOwned then
                    petModel:SetAlpha(1.0)
                else
                    petModel:SetAlpha(0.6)
                end
            end
            
            -- Hide fallback icon
            if fallbackIcon then
                fallbackIcon:Hide()
            end
        else
            -- Model failed to load, show fallback icon
            if petModel then
                petModel:Hide()
            end
            if fallbackIcon and speciesIcon then
                fallbackIcon:SetTexture(speciesIcon)
                fallbackIcon:Show()
                if fallbackIcon.SetDesaturated then
                    if not isOwned then
                        fallbackIcon:SetDesaturated(true)
                        fallbackIcon:SetAlpha(0.6)
                    else
                        fallbackIcon:SetDesaturated(false)
                        fallbackIcon:SetAlpha(1.0)
                    end
                else
                    -- Fallback: only set alpha if SetDesaturated is not available
                    if not isOwned then
                        fallbackIcon:SetAlpha(0.6)
                    else
                        fallbackIcon:SetAlpha(1.0)
                    end
                end
            elseif fallbackIcon then
                -- Ensure fallback icon is hidden if no speciesIcon
                fallbackIcon:Hide()
            end
        end
    end
    
    -- Function to check if player owns this specific display variant
    local function PlayerOwnsDisplayVariant(displayID)
        if not displayID then return false end
        
        -- If player doesn't have any of this species, they can't own any variants
        if collectedCount == 0 then
            return false
        end
        
        -- Check probability and return ownership based on collection count
        local variations = modelVariations and modelVariations.variations
        if variations then
            for _, variation in ipairs(variations) do
                if variation.displays then
                    for _, display in ipairs(variation.displays) do
                        if display.id == displayID then
                            -- For high-probability variants (>= 80%), assume owned if pet is collected
                            if display.probability >= 80 then
                                return true
                            end
                            
                            -- For medium-probability variants (20-79%), show as potentially owned based on collection count
                            if display.probability >= 20 and display.probability < 80 then
                                local result = collectedCount >= 2
                                return result
                            end
                            
                            -- For rare variants (<20%), be more generous
                            if display.probability < 20 and display.probability > 0 then
                                local result
                                if display.probability < 5 then
                                    -- For very rare variants, show the most common one as owned if we have any pets
                                    -- Find the highest probability among all variants for this pet
                                    local maxProbability = 0
                                    if PCLcore.PetModelVariations[petData.speciesID] and PCLcore.PetModelVariations[petData.speciesID].variations then
                                        for _, variation in ipairs(PCLcore.PetModelVariations[petData.speciesID].variations) do
                                            if variation.displays then
                                                for _, varDisplay in ipairs(variation.displays) do
                                                    if varDisplay.probability > maxProbability then
                                                        maxProbability = varDisplay.probability
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    
                                    -- If this is the most common variant and we have any pets, show as owned
                                    if display.probability == maxProbability and collectedCount >= 1 then
                                        result = true
                                    else
                                        result = collectedCount >= 2
                                    end
                                else
                                    result = collectedCount >= 1
                                end
                                return result
                            end
                        end
                    end
                end
            end
        end
        
        -- Fallback: If we have collected pets but no variants detected, 
        -- assume ownership of at least the most common variant
        if collectedCount > 0 and variations then
            local highestProb = 0
            local mostCommonDisplayID = nil
            for _, variation in ipairs(variations) do
                if variation.displays then
                    for _, display in ipairs(variation.displays) do
                        if display.probability > highestProb then
                            highestProb = display.probability
                            mostCommonDisplayID = display.id
                        end
                    end
                end
            end
            
            if mostCommonDisplayID == displayID then
                return true
            end
        end
        
        return false
    end
    
    if modelVariations and modelVariations.variations and #modelVariations.variations > 0 then
        -- Count total display variants across all variations
        local totalDisplays = 0
        for varIndex, variation in ipairs(modelVariations.variations) do
            if variation.displays then
                totalDisplays = totalDisplays + #variation.displays
            end
        end
        
        -- Only show tabs if there are multiple display variants
        if totalDisplays > 1 then
            -- Calculate total probability for percentage normalization
            local totalProbability = 0
            for varIndex, variation in ipairs(modelVariations.variations) do
                if variation.displays then
                    for dispIndex, display in ipairs(variation.displays) do
                        totalProbability = totalProbability + (display.probability or 1)
                    end
                end
            end
            
            -- Create tabs for each model variation
            local tabIndex = 1
            local selectedTab = 1
        
        for varIndex, variation in ipairs(modelVariations.variations) do
            if variation.displays then
                for dispIndex, display in ipairs(variation.displays) do
                    if tabIndex <= 6 then  -- Limit to 6 tabs to fit in the space
                        local tab = CreateFrame("Button", nil, modelVariationsFrame, "BackdropTemplate")
                        tab:SetSize(32, 25)
                        tab:SetPoint("TOPLEFT", modelVariationsFrame, "TOPLEFT", 2, -(tabIndex - 1) * 28)
                        
                        -- Tab styling
                        tab:SetBackdrop({
                            bgFile = "Interface\\Buttons\\WHITE8x8",
                            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                            edgeSize = 2,
                            insets = {left = 2, right = 2, top = 2, bottom = 2}
                        })
                        
                        -- Check if player owns this variant
                        local isOwned = PlayerOwnsDisplayVariant(display.id)
                        
                        if isOwned then
                            tab:SetBackdropColor(0.2, 0.6, 0.2, 0.8)  -- Green for owned
                            tab:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)
                        else
                            tab:SetBackdropColor(0.3, 0.3, 0.3, 0.8)  -- Gray for not owned
                            tab:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                        end
                        
                        -- Tab number and ownership indicator
                        local tabText = tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                        tabText:SetPoint("CENTER", tab, "CENTER", 0, 0)
                        tabText:SetText(tostring(tabIndex))
                        if isOwned then
                            tabText:SetTextColor(1, 1, 1, 1)  -- White for owned
                        else
                            tabText:SetTextColor(0.6, 0.6, 0.6, 1)  -- Gray for not owned
                        end
                        
                        -- Add checkmark for owned variants
                        if isOwned then
                            local checkmark = tab:CreateTexture(nil, "OVERLAY")
                            checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                            checkmark:SetSize(8, 8)
                            checkmark:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -2, 2)
                            tab.checkmark = checkmark
                        end
                        
                        -- Store display info
                        tab.displayID = display.id
                        tab.isOwned = isOwned
                        tab.probability = display.probability
                        tab.totalProbability = totalProbability
                        tab.tabIndex = tabIndex
                        
                        -- Tab click handler
                        tab:SetScript("OnClick", function(self)
                            -- Update all tabs to unselected state
                            for _, otherTab in ipairs(modelVariationsFrame.tabs) do
                                if otherTab.isOwned then
                                    otherTab:SetBackdropColor(0.2, 0.6, 0.2, 0.8)
                                    otherTab:SetBackdropBorderColor(0.4, 0.8, 0.4, 1)
                                else
                                    otherTab:SetBackdropColor(0.3, 0.3, 0.3, 0.8)
                                    otherTab:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
                                end
                            end
                            
                            -- Set this tab as selected
                            if self.isOwned then
                                self:SetBackdropColor(0.1, 0.8, 0.1, 1.0)  -- Brighter green for selected owned
                                self:SetBackdropBorderColor(0.6, 1.0, 0.6, 1)
                            else
                                self:SetBackdropColor(0.5, 0.5, 0.5, 1.0)  -- Brighter gray for selected not owned
                                self:SetBackdropBorderColor(0.7, 0.7, 0.7, 1)
                            end
                            
                            selectedTab = self.tabIndex
                            UpdateModelDisplay(self.displayID, self.isOwned)
                        end)
                        
                        -- Tooltip for tab
                        tab:SetScript("OnEnter", function(self)
                            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                            GameTooltip:SetText("Model Variant " .. self.tabIndex, 1, 1, 1, 1, true)
                            GameTooltip:AddLine("Display ID: " .. self.displayID, 0.8, 0.8, 0.8)
                            
                            -- Show probability info
                            if self.probability and self.probability > 0 then
                                -- Calculate normalized percentage
                                local percentage = 0
                                if self.totalProbability and self.totalProbability > 0 then
                                    percentage = (self.probability / self.totalProbability) * 100
                                end
                                
                                if percentage >= 80 then
                                    GameTooltip:AddLine(string.format("Very Common (%.0f%%)", percentage), 0.2, 1, 0.2)
                                elseif percentage >= 20 then
                                    GameTooltip:AddLine(string.format("Common (%.1f%%)", percentage), 0.9, 0.9, 0.5)
                                else
                                    GameTooltip:AddLine(string.format("Rare (%.1f%%)", percentage), 1, 0.5, 0.2)
                                end
                            end
                            
                            -- Ownership status
                            if self.isOwned then
                                GameTooltip:AddLine("You likely own this variant", 0.2, 1, 0.2)
                            else
                                GameTooltip:AddLine("You likely don't own this variant", 1, 0.4, 0.4)
                            end
                            
                            GameTooltip:AddLine("Click to preview", 0.6, 0.6, 1)
                            GameTooltip:Show()
                        end)
                        
                        tab:SetScript("OnLeave", function(self)
                            GameTooltip:Hide()
                        end)
                        
                        table.insert(modelVariationsFrame.tabs, tab)
                        tabIndex = tabIndex + 1
                    end
                end
            end
        end
        
        -- Select first owned variant, or first variant if none owned
        local firstOwnedTab = nil
        local firstTab = modelVariationsFrame.tabs[1]
        
        for _, tab in ipairs(modelVariationsFrame.tabs) do
            if tab.isOwned and not firstOwnedTab then
                firstOwnedTab = tab
                break
            end
        end
        
        local defaultTab = firstOwnedTab or firstTab
        if defaultTab then
            defaultTab:GetScript("OnClick")(defaultTab)
        end
        
        -- Show variation count and ownership summary
        local variationLabel = modelVariationsFrame.variationLabel
        if not variationLabel then
            variationLabel = modelVariationsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            modelVariationsFrame.variationLabel = variationLabel
            variationLabel:SetPoint("BOTTOM", modelVariationsFrame, "BOTTOM", 0, 5)
        end
        
        -- Count owned variants
        local ownedCount = 0
        for _, tab in ipairs(modelVariationsFrame.tabs) do
            if tab.isOwned then
                ownedCount = ownedCount + 1
            end
        end
        
        local totalCount = #modelVariationsFrame.tabs
        variationLabel:SetText(string.format("%d/%d variants", ownedCount, totalCount))
        
        -- Color based on completion
        if ownedCount == totalCount then
            variationLabel:SetTextColor(0.2, 1, 0.2, 1)  -- Green - complete
        elseif ownedCount > 0 then
            variationLabel:SetTextColor(1, 1, 0.5, 1)  -- Yellow - partial
        else
            variationLabel:SetTextColor(1, 0.4, 0.4, 1)  -- Red - none
        end
        
        else
            -- Only one variant, don't show tabs - just use default display
            UpdateModelDisplay(creatureDisplayID, true)
        end
        
    else
        -- No model variations - use default display
        UpdateModelDisplay(creatureDisplayID, true)
    end
    
    -- Add fullscreen button to model frame
    local fullscreenButton = mainContentFrame.modelFrame.fullscreenButton
    if not fullscreenButton then
        fullscreenButton = CreateFrame("Button", nil, mainContentFrame.modelFrame, "BackdropTemplate")
        mainContentFrame.modelFrame.fullscreenButton = fullscreenButton
        fullscreenButton:SetSize(28, 28)  -- Made even larger
        fullscreenButton:SetPoint("TOPRIGHT", mainContentFrame.modelFrame, "TOPRIGHT", -5, -5)  -- Adjusted for larger frame
        fullscreenButton:SetFrameLevel(mainContentFrame.modelFrame:GetFrameLevel() + 10)  -- Ensure it's on top
        
        -- Very visible background
        fullscreenButton:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 2,
        })
        fullscreenButton:SetBackdropColor(0.2, 0.2, 0.2, 0.9)  -- More opaque dark background
        fullscreenButton:SetBackdropBorderColor(0.8, 0.8, 0.8, 1)  -- Bright border
        
        -- Very visible expand icon using a simple texture
        local fullscreenIcon = fullscreenButton:CreateTexture(nil, "ARTWORK")
        fullscreenIcon:SetSize(20, 20)
        fullscreenIcon:SetPoint("CENTER", fullscreenButton, "CENTER", 0, 0)
        fullscreenIcon:SetTexture("Interface\\Buttons\\Arrow-Up-Up")
        fullscreenIcon:SetVertexColor(1, 1, 1, 1)
        
        -- Very obvious hover effects
        fullscreenButton:SetScript("OnEnter", function(self)
            self:SetBackdropColor(1, 0.82, 0, 0.9)  -- Bright yellow on hover
            fullscreenIcon:SetVertexColor(0, 0, 0, 1)  -- Black icon on yellow background
            
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText("Click for Fullscreen Pet View", 1, 1, 1)
            GameTooltip:Show()
        end)
        
        fullscreenButton:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.2, 0.2, 0.2, 0.9)  -- Back to dark
            fullscreenIcon:SetVertexColor(1, 1, 1, 1)  -- Back to white
            GameTooltip:Hide()
        end)
        
        -- Make sure button is always visible and clickable
        fullscreenButton:Show()
        fullscreenButton:EnableMouse(true)
        
        -- Fullscreen button created and positioned
    end
    
    -- Always update the click handler with current petData
    fullscreenButton:SetScript("OnClick", function(self)
        PCLcore.PetCard:ShowFullscreen(petData)
    end)
    
    -- Set up the 3D model
    if petModel and companionID and companionID > 0 then
        local success = pcall(function()
            petModel:SetCreature(companionID)
        end)
        
        if success then
            petModel:Show()
            C_Timer.After(0.1, function()
                if petModel then
                    petModel:SetCamDistanceScale(1.8)
                    petModel:SetRotation(0.3)
                    if petModel.RefreshCamera then
                        petModel:RefreshCamera()
                    end
                end
            end)
        else
            petModel:Hide()
        end
    end
    
    -- Fallback icon if 3D model doesn't work
    local fallbackIcon = mainContentFrame.modelFrame.fallbackIcon
    if not fallbackIcon then
        fallbackIcon = mainContentFrame.modelFrame:CreateTexture(nil, "ARTWORK")
        mainContentFrame.modelFrame.fallbackIcon = fallbackIcon
        fallbackIcon:SetSize(128, 128)
        fallbackIcon:SetPoint("CENTER", mainContentFrame.modelFrame, "CENTER", 0, 0)
    end
    
    if not petModel or not companionID or companionID <= 0 then
        if speciesIcon then
            fallbackIcon:SetTexture(speciesIcon)
            fallbackIcon:Show()
        end
        if petModel then petModel:Hide() end
    else
        fallbackIcon:Hide()
    end
    
    yOffset = yOffset - 185  -- Account for larger main content frame (was -130)
    contentHeight = contentHeight + 175  -- Account for increased height (was +120)
    
    -- Description section (directly under model - like in the reference image)
    if tooltipDescription then
        local descFrame = PCL_PetCard.scrollChild.descFrame or CreateFrame("Frame", nil, PCL_PetCard.scrollChild)
        PCL_PetCard.scrollChild.descFrame = descFrame
        descFrame:SetSize(PET_CARD_WIDTH - 20, 30)  -- Will adjust height based on content
        descFrame:SetPoint("TOPLEFT", PCL_PetCard.scrollChild, "TOPLEFT", 0, yOffset)  -- Position right after model
        
        local descText = descFrame.text or descFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        descFrame.text = descText
        descText:SetPoint("TOPLEFT", descFrame, "TOPLEFT", 0, 0)
        descText:SetPoint("TOPRIGHT", descFrame, "TOPRIGHT", 0, 0)
        descText:SetJustifyH("CENTER")
        descText:SetWordWrap(true)
        descText:SetText(tooltipDescription)
        descText:SetTextColor(1, 0.82, 0, 1)  -- Yellow like in reference image
        
        local descHeight = descText:GetStringHeight()
        descFrame:SetHeight(descHeight + 10)
        yOffset = yOffset - (descHeight + 20)  -- Adjust yOffset for next elements
        contentHeight = contentHeight + descHeight + 20
    end
    
    -- Banner section with family icon and "Possible Breeds" title
    local bannerFrame = PCL_PetCard.scrollChild.bannerFrame or CreateFrame("Frame", nil, PCL_PetCard.scrollChild, "BackdropTemplate")
    PCL_PetCard.scrollChild.bannerFrame = bannerFrame
    bannerFrame:SetSize(PET_CARD_WIDTH - 20, 35)  -- Increased height to accommodate larger icon, reduced padding
    bannerFrame:SetPoint("TOPLEFT", PCL_PetCard.scrollChild, "TOPLEFT", 10, yOffset)  -- Reduced left margin
    
    -- Style banner with subtle background
    bannerFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 1
    })
    bannerFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.5)
    bannerFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    
    -- Family icon and name (left side) - Enhanced with larger icon and colored text
    local familyIcon = bannerFrame.familyIcon or bannerFrame:CreateTexture(nil, "ARTWORK")
    bannerFrame.familyIcon = familyIcon
    familyIcon:SetSize(28, 28)  -- Slightly smaller, better proportion
    familyIcon:SetPoint("LEFT", bannerFrame, "LEFT", 5, 0)
    
    -- Use the correct pet type icon path (based on PetCollector reference)
    local familyName, iconKey, r, g, b = getFamilyDetails(petType or 8)
    local iconTexture = "Interface\\Icons\\Pet_Type_" .. (iconKey or "beast")
    familyIcon:SetTexture(iconTexture)
    familyIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)  -- Crop borders for cleaner look
    
    local familyText = bannerFrame.familyText or bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bannerFrame.familyText = familyText
    familyText:SetPoint("LEFT", familyIcon, "RIGHT", 10, 0)
    familyText:SetText(PET_TYPE_SUFFIX[petType] or "Unknown")
    
    -- Set pet type colored text using the family details (already retrieved above)
    familyText:SetTextColor(r, g, b, 1)  -- Use the pet family color
    
    -- "Possible Breeds" title with collection status (right side)
    local breedsTitle = bannerFrame.breedsTitle or bannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bannerFrame.breedsTitle = breedsTitle
    breedsTitle:SetPoint("RIGHT", bannerFrame, "RIGHT", -90, 0)
    
    -- Enhance title with breed collection information
    local breedsTitleText = "Possible Breeds"
    if collectionComparison and collectionComparison.isCollected then
        local ownedCount = #collectionComparison.ownedBreeds
        local totalCount = collectionComparison.totalAvailableBreeds
        if totalCount > 1 then  -- Only show breed count if there are multiple breeds
            breedsTitleText = string.format("Breeds (%d/%d)", ownedCount, totalCount)
            
            -- Color the title based on completion status
            if ownedCount >= totalCount then
                breedsTitle:SetTextColor(0, 1, 0, 1)  -- Green - complete
            elseif ownedCount > 0 then
                breedsTitle:SetTextColor(1, 1, 0, 1)  -- Yellow - partial
            else
                breedsTitle:SetTextColor(1, 0.4, 0.4, 1)  -- Light red - none collected
            end
        else
            breedsTitle:SetTextColor(0.8, 0.8, 0.8, 1)  -- Gray - single breed species
        end
    else
        breedsTitle:SetTextColor(0.5, 0.5, 0.5, 1)  -- Gray - not collected
    end
    
    breedsTitle:SetText(breedsTitleText)
    
    yOffset = yOffset - 40  -- Increased from 35 to account for larger banner
    contentHeight = contentHeight + 40
    
    -- Main content area - Compacted layout for narrower window
    local mainFrame = PCL_PetCard.scrollChild.mainFrame or CreateFrame("Frame", nil, PCL_PetCard.scrollChild)
    PCL_PetCard.scrollChild.mainFrame = mainFrame
    mainFrame:SetSize(PET_CARD_WIDTH - 20, 300)  -- Reduced padding, will adjust height based on content
    mainFrame:SetPoint("TOPLEFT", PCL_PetCard.scrollChild, "TOPLEFT", 10, yOffset)  -- Reduced left margin
    
    -- Column 1 (Left side) - 40% width (more compact)
    local leftColumn = mainFrame.leftColumn or CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    mainFrame.leftColumn = leftColumn
    local leftWidth = (PET_CARD_WIDTH - 30) * 0.40  -- Adjusted for new padding (was 60, now 30)
    leftColumn:SetSize(leftWidth, 300)
    leftColumn:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 0, 0)
    
    -- Column 2 (Right side) - 55% width with 5% gap (more space for breeds)
    local rightColumn = mainFrame.rightColumn or CreateFrame("Frame", nil, mainFrame, "BackdropTemplate")
    mainFrame.rightColumn = rightColumn
    local rightWidth = (PET_CARD_WIDTH - 30) * 0.55  -- Adjusted for new padding (was 60, now 30)
    rightColumn:SetSize(rightWidth, 300)
    rightColumn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 0, 0)
    
    -- LEFT COLUMN CONTENT
    
    -- Collected Header (Column 1)
    local collectedHeader = leftColumn.collectedHeader or leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftColumn.collectedHeader = collectedHeader
    collectedHeader:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, -10)
    if collectedCount and collectedCount > 0 then
        collectedHeader:SetText(string.format("Collected %d/3", collectedCount))
        collectedHeader:SetTextColor(1, 0.82, 0, 1)  -- Yellow
    else
        collectedHeader:SetText("Collected 0/3")
        collectedHeader:SetTextColor(0.6, 0.6, 0.6, 1)  -- Gray
    end
    
    -- Pet Collection List (Column 1) - With bordered frames
    local leftYOffset = -35
    if collectedCount and collectedCount > 0 then
        for i = 1, math.min(3, collectedCount) do
            local pet = collectedPets and collectedPets[i]
            if pet then
                local petFrame = leftColumn["petEntry" .. i] or CreateFrame("Frame", nil, leftColumn, "BackdropTemplate")
                leftColumn["petEntry" .. i] = petFrame
                petFrame:SetSize(leftWidth - 10, 22)  -- Slightly taller for border
                petFrame:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
                
                -- Add border styling to collected pet frames
                petFrame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8x8",
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 1,
                    insets = {left = 2, right = 2, top = 2, bottom = 2}
                })
                petFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.3)  -- Subtle dark background
                
                -- Color border based on pet quality
                local qualityColors = {
                    [1] = {0.6, 0.6, 0.6, 0.8}, -- Poor (gray)
                    [2] = {1, 1, 1, 0.8},       -- Common (white) 
                    [3] = {0.12, 1, 0, 0.8},    -- Uncommon (green)
                    [4] = {0, 0.44, 0.87, 0.8}, -- Rare (blue)
                    [5] = {0.64, 0.21, 0.93, 0.8}, -- Epic (purple)
                    [6] = {1, 0.5, 0, 0.8}      -- Legendary (orange)
                }
                local borderColor = qualityColors[pet.rarity] or qualityColors[1]
                petFrame:SetBackdropBorderColor(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
                
                local petText = petFrame.text or petFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                petFrame.text = petText
                petText:SetPoint("LEFT", petFrame, "LEFT", 4, 0)  -- Slight padding for border
                
                -- Format: "25 H/H" (level and breed)
                local qualityTextColors = {"", "|cff9d9d9d", "|cffffffff", "|cff1eff00", "|cff0070dd", "|cffa335ee", "|cffff8000"}
                local qualityColor = qualityTextColors[pet.rarity] or ""
                petText:SetText(string.format("%s%d %s|r", qualityColor, pet.level or 1, pet.breedLetters or "B/B"))
                
                leftYOffset = leftYOffset - 24  -- Account for slightly taller frames
            end
        end
    else
        -- Show "Not collected" message
        local notCollectedFrame = leftColumn.notCollectedFrame or CreateFrame("Frame", nil, leftColumn)
        leftColumn.notCollectedFrame = notCollectedFrame
        notCollectedFrame:SetSize(leftWidth - 10, 20)
        notCollectedFrame:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
        
        local notCollectedText = notCollectedFrame.text or notCollectedFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        notCollectedFrame.text = notCollectedText
        notCollectedText:SetPoint("LEFT", notCollectedFrame, "LEFT", 0, 0)
        notCollectedText:SetText("Not collected")
        notCollectedText:SetTextColor(0.6, 0.6, 0.6, 1)
        
        leftYOffset = leftYOffset - 22
    end
    
    -- Tradeable Section (Column 1) - Combined header and icon on single line
    leftYOffset = leftYOffset - 20  -- Add some spacing
    local tradeableFrame = leftColumn.tradeableFrame or CreateFrame("Frame", nil, leftColumn)
    leftColumn.tradeableFrame = tradeableFrame
    tradeableFrame:SetSize(leftWidth - 10, 25)
    tradeableFrame:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
    
    -- Tradeable text
    local tradeableHeader = tradeableFrame.header or tradeableFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tradeableFrame.header = tradeableHeader
    tradeableHeader:SetPoint("LEFT", tradeableFrame, "LEFT", 0, 0)
    tradeableHeader:SetText("Tradeable")
    tradeableHeader:SetTextColor(1, 1, 1, 1)
    
    -- Tradeable icon on same line
    local tradeableIcon = tradeableFrame.icon or tradeableFrame:CreateTexture(nil, "ARTWORK")
    tradeableFrame.icon = tradeableIcon
    tradeableIcon:SetSize(16, 16)
    tradeableIcon:SetPoint("LEFT", tradeableHeader, "RIGHT", 8, 0)  -- Position next to text
    if isTradeable then
        tradeableIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")  -- Green checkmark
    else
        tradeableIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")  -- Red X
    end
    
    -- Abilities Section (Column 1)
    leftYOffset = leftYOffset - 35  -- Reduced spacing since tradeable is now single line
    local abilitiesHeader = leftColumn.abilitiesHeader or leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    leftColumn.abilitiesHeader = abilitiesHeader
    abilitiesHeader:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, leftYOffset)
    abilitiesHeader:SetText("Abilities")
    abilitiesHeader:SetTextColor(1, 1, 1, 1)
    
    leftYOffset = leftYOffset - 25
    if abilities and #abilities > 0 then
        local abilitiesFrame = leftColumn.abilitiesFrame or CreateFrame("Frame", nil, leftColumn)
        leftColumn.abilitiesFrame = abilitiesFrame
        abilitiesFrame:SetSize(leftWidth - 10, 80)  -- 2 rows of 3 abilities
        abilitiesFrame:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 5, leftYOffset)
        
        -- Create ability icons (6 abilities, 2 rows of 3)
        for i = 1, math.min(6, #abilities) do
            local abilityFrame = abilitiesFrame["ability" .. i] or CreateFrame("Frame", nil, abilitiesFrame, "BackdropTemplate")
            abilitiesFrame["ability" .. i] = abilityFrame
            abilityFrame:SetSize(35, 35)
            
            local row = math.floor((i - 1) / 3)
            local col = (i - 1) % 3
            abilityFrame:SetPoint("TOPLEFT", abilitiesFrame, "TOPLEFT", col * 40, -(row * 40))
            
            abilityFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8x8",
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1
            })
            abilityFrame:SetBackdropColor(0, 0, 0, 0.8)
            abilityFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            
            local abilityIcon = abilityFrame.icon or abilityFrame:CreateTexture(nil, "ARTWORK")
            abilityFrame.icon = abilityIcon
            abilityIcon:SetSize(33, 33)
            abilityIcon:SetPoint("CENTER", abilityFrame, "CENTER", 0, 0)
            
            local abilityID = abilities[i]
            if abilityID then
                local _, _, abilityIconID = C_PetBattles.GetAbilityInfoByID(abilityID)
                if abilityIconID then
                    abilityIcon:SetTexture(abilityIconID)
                else
                    -- Fallback to pet icon if ability icon not found
                    abilityIcon:SetTexture(speciesIcon)
                end
                
                -- Add tooltip functionality
                abilityFrame:EnableMouse(true)
                abilityFrame:SetScript("OnEnter", function(self)
                    -- Use the FloatingPetBattleAbility_Show method for proper pet battle tooltips
                    if FloatingPetBattleAbility_Show then
                        -- Get pet stats for the ability tooltip (using level 25 stats)
                        local maxHealth, power, speed = 1000, 300, 300  -- Default fallback values
                        
                        -- Try to get actual pet stats if we have breed data
                        local breeds = GetPetBreeds(petData.speciesID)
                        if breeds and breeds[1] then
                            maxHealth = breeds[1].health or 1000
                            power = breeds[1].power or 300
                            speed = breeds[1].speed or 300
                        end
                        
                        -- Show the native Blizzard pet battle ability tooltip
                        FloatingPetBattleAbility_Show(abilityID, maxHealth, power, speed)
                        
                        -- Position the tooltip near our ability frame and customize it
                        if FloatingPetBattleAbilityTooltip then
                            FloatingPetBattleAbilityTooltip:ClearAllPoints()
                            FloatingPetBattleAbilityTooltip:SetPoint("LEFT", self, "RIGHT", 10, 0)
                            
                            -- Set 100% opacity
                            FloatingPetBattleAbilityTooltip:SetAlpha(1.0)
                            
                            -- Hide the close button (X)
                            if FloatingPetBattleAbilityTooltip.CloseButton then
                                FloatingPetBattleAbilityTooltip.CloseButton:Hide()
                            end
                        end
                    else
                        -- Fallback to GameTooltip if FloatingPetBattleAbility_Show is not available
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:SetFrameStrata("TOOLTIP")
                        GameTooltip:SetFrameLevel(9999)
                        
                        local name, icon, petType, noStrongWeakHints = C_PetBattles.GetAbilityInfoByID(abilityID)
                        if name then
                            GameTooltip:SetText(name, 1, 1, 1)
                            GameTooltip:AddLine("Ability ID: " .. abilityID, 0.8, 0.8, 0.8)
                        else
                            GameTooltip:SetText("Pet Ability " .. abilityID, 1, 1, 1)
                        end
                        GameTooltip:Show()
                    end
                end)
                
                abilityFrame:SetScript("OnLeave", function(self)
                    -- Hide both tooltip types
                    if FloatingPetBattleAbilityTooltip then
                        FloatingPetBattleAbilityTooltip:Hide()
                    end
                    GameTooltip:Hide()
                end)
            end
        end
    end
    
    -- RIGHT COLUMN CONTENT
    
    -- Stat Icons Header (Column 2) - Compacted layout
    local statIconsFrame = rightColumn.statIconsFrame or CreateFrame("Frame", nil, rightColumn)
    rightColumn.statIconsFrame = statIconsFrame
    statIconsFrame:SetSize(rightWidth - 10, 25)
    statIconsFrame:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, -10)
    
    -- Health Icon (Red) - Heart symbol
    local healthIcon = statIconsFrame.healthIcon or statIconsFrame:CreateTexture(nil, "ARTWORK")
    statIconsFrame.healthIcon = healthIcon
    healthIcon:SetSize(20, 20)
    healthIcon:SetPoint("CENTER", statIconsFrame, "LEFT", 55, 0)  -- Centered over health column
    healthIcon:SetTexture("Interface/Icons/PetBattle_Health")
    healthIcon:SetVertexColor(0.8, 0.2, 0.2, 1)  -- Red
    
    -- Power Icon (Orange) - Attack symbol
    local powerIcon = statIconsFrame.powerIcon or statIconsFrame:CreateTexture(nil, "ARTWORK")
    statIconsFrame.powerIcon = powerIcon
    powerIcon:SetSize(20, 20)
    powerIcon:SetPoint("CENTER", statIconsFrame, "LEFT", 100, 0)  -- Centered over power column
    powerIcon:SetTexture("Interface/Icons/PetBattle_Attack")
    powerIcon:SetVertexColor(0.8, 0.6, 0.2, 1)  -- Orange
    
    -- Speed Icon (Blue) - Speed symbol
    local speedIcon = statIconsFrame.speedIcon or statIconsFrame:CreateTexture(nil, "ARTWORK")
    statIconsFrame.speedIcon = speedIcon
    speedIcon:SetSize(20, 20)
    speedIcon:SetPoint("CENTER", statIconsFrame, "LEFT", 145, 0)  -- Centered over speed column
    speedIcon:SetTexture("Interface/Icons/PetBattle_Speed")
    speedIcon:SetVertexColor(0.2, 0.6, 0.8, 1)  -- Blue
    
    -- Breeds Table (Column 2)
    local breedsFrame = rightColumn.breedsFrame or CreateFrame("Frame", nil, rightColumn)
    rightColumn.breedsFrame = breedsFrame
    breedsFrame:SetSize(rightWidth - 10, 200)
    breedsFrame:SetPoint("TOPLEFT", statIconsFrame, "BOTTOMLEFT", 0, -10)
    
    -- Generate breed data and create table rows
    local breeds = GetPetBreeds(petData.speciesID)
    local rowHeight = 18
    local rightYOffset = 0
    
    -- Get user's collection data for breed comparison
    local collectionComparison = nil
    if PCLcore.CollectionComparison then
        collectionComparison = PCLcore.CollectionComparison:CompareSpeciesCollection(petData.speciesID)
    end
    
    -- Debug output (can be removed later)
    if PCL_SETTINGS and PCL_SETTINGS.debug then
        if #breeds > 0 then
            -- Found breeds for species
            if collectionComparison then
                -- User has X breeds of Y total breeds
            end
        else
            -- No breed data found for species
        end
    end
    
    -- If no breeds found, show a "No breed data" message
    if #breeds == 0 then
        local noDataText = breedsFrame.noDataText or breedsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        breedsFrame.noDataText = noDataText
        noDataText:SetPoint("TOPLEFT", breedsFrame, "TOPLEFT", 0, -10)
        noDataText:SetText("No breed data available")
        noDataText:SetTextColor(0.6, 0.6, 0.6, 1)
        rightYOffset = rightYOffset - 25
    else
        -- Hide the no data text if breeds are found
        if breedsFrame.noDataText then
            breedsFrame.noDataText:Hide()
        end
    end
    
    for i, breedInfo in ipairs(breeds) do
        if i <= 10 then  -- Limit to reasonable number of breeds
            local rowFrame = breedsFrame["row" .. i] or CreateFrame("Frame", nil, breedsFrame)
            breedsFrame["row" .. i] = rowFrame
            rowFrame:SetSize(rightWidth - 20, rowHeight)
            rowFrame:SetPoint("TOPLEFT", breedsFrame, "TOPLEFT", 0, rightYOffset)
            
            -- Determine if user has this breed
            local hasThisBreed = false
            local breedCount = 0
            if collectionComparison and collectionComparison.isCollected then
                for _, ownedBreed in ipairs(collectionComparison.ownedBreeds) do
                    if ownedBreed.breedID == breedInfo.breedID then
                        hasThisBreed = true
                        breedCount = ownedBreed.count or 1
                        break
                    end
                end
            end
            
            -- Collection status indicator
            local statusIcon = rowFrame.statusIcon or rowFrame:CreateTexture(nil, "OVERLAY")
            rowFrame.statusIcon = statusIcon
            statusIcon:SetSize(12, 12)
            statusIcon:SetPoint("LEFT", rowFrame, "LEFT", -18, 0)
            
            if not collectionComparison or not collectionComparison.isCollected then
                -- Pet not collected at all - gray X
                statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
                statusIcon:SetVertexColor(0.5, 0.5, 0.5, 1)
            elseif hasThisBreed then
                -- User has this breed - green checkmark
                statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
                statusIcon:SetVertexColor(0, 1, 0, 1)
            else
                -- User has pet but missing this breed - red X
                statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
                statusIcon:SetVertexColor(1, 0, 0, 1)
            end
            statusIcon:Show()
            
            -- Breed name (H/H, B/B, P/P, etc.) with collection count if owned
            local breedName = rowFrame.breedName or rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowFrame.breedName = breedName
            breedName:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            
            local breedText = breedInfo.breedCode or "B/B"
            if hasThisBreed and breedCount > 1 then
                breedText = breedText .. " (" .. breedCount .. ")"
            end
            breedName:SetText(breedText)
            
            -- Color the breed name based on collection status
            if not collectionComparison or not collectionComparison.isCollected then
                breedName:SetTextColor(0.5, 0.5, 0.5, 1) -- Gray for uncollected pet
            elseif hasThisBreed then
                breedName:SetTextColor(0, 1, 0, 1) -- Green for owned breed
            else
                breedName:SetTextColor(1, 0.4, 0.4, 1) -- Light red for missing breed
            end
            
            -- Health stat (aligned under health icon) - Compacted layout
            local healthStat = rowFrame.healthStat or rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowFrame.healthStat = healthStat
            healthStat:SetPoint("LEFT", rowFrame, "LEFT", 35, 0)  -- Aligned with new health icon position
            healthStat:SetText(tostring(breedInfo.health or 1481))
            healthStat:SetTextColor(1, 1, 1, 1)
            healthStat:SetJustifyH("CENTER")
            healthStat:SetWidth(40)  -- Narrower width
            
            -- Power stat (aligned under power icon) - Compacted layout  
            local powerStat = rowFrame.powerStat or rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowFrame.powerStat = powerStat
            powerStat:SetPoint("LEFT", rowFrame, "LEFT", 80, 0)  -- Closer spacing
            powerStat:SetText(tostring(breedInfo.power or 276))
            powerStat:SetTextColor(1, 1, 1, 1)
            powerStat:SetJustifyH("CENTER")
            powerStat:SetWidth(40)  -- Narrower width
            
            -- Speed stat (aligned under speed icon) - Compacted layout
            local speedStat = rowFrame.speedStat or rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowFrame.speedStat = speedStat
            speedStat:SetPoint("LEFT", rowFrame, "LEFT", 125, 0)  -- Closer spacing
            speedStat:SetText(tostring(breedInfo.speed or 276))
            speedStat:SetTextColor(1, 1, 1, 1)
            speedStat:SetJustifyH("CENTER")
            speedStat:SetWidth(40)  -- Narrower width
            
            rightYOffset = rightYOffset - rowHeight
        end
    end
    
    -- Calculate final content height
    local finalMainHeight = math.max(math.abs(leftYOffset) + 80, math.abs(rightYOffset) + 50)
    mainFrame:SetHeight(finalMainHeight)
    
    yOffset = yOffset - finalMainHeight - 20
    contentHeight = contentHeight + finalMainHeight + 20
    
    -- Source section already positioned after model frame - removed duplicate
    -- Description section already positioned after model frame - removed duplicate
    
    -- Update scroll child height
    PCL_PetCard.scrollChild:SetHeight(contentHeight + 20)
end

--[[
  Show the pet card
]]
function PetCard:Show(petData)
    
    if not PCL_mainFrame then
        return
    end
    
    if not petData then
        return
    end
    
    
    -- Create or get the pet card frame
    if not PCL_PetCard then
        self:CreatePetCard()
    end
    
    -- Ensure PetCard is properly sized before showing
    self:ResizePetCard()
    
    -- Position the pet card to the right of the main window
    PCL_PetCard:ClearAllPoints()
    PCL_PetCard:SetPoint("TOPLEFT", PCL_mainFrame, "TOPRIGHT", 5, 0)  -- 5 pixels gap to the right
    
    -- Force height to match main window after positioning
    if PCL_mainFrame then
        local _, mainHeight = PCL_mainFrame:GetSize()
        if mainHeight and mainHeight > 0 then
            PCL_PetCard:SetHeight(mainHeight)
        end
    end
    
    -- Update the pet card content
    self:UpdateWindow(petData)
    
    -- Show the pet card
    PCL_PetCard:Show()
end

--[[
  Hide the pet card
]]
function PetCard:Hide()
    if PCL_PetCard then
        PCL_PetCard:Hide()
    end
    -- Also hide fullscreen if it's open
    if PCL_PetCard_Fullscreen then
        PCL_PetCard_Fullscreen:Hide()
    end
end

--[[
  Show pet card in fullscreen mode
]]
function PetCard:ShowFullscreen(petData)
    if not petData then
        return
    end
    
    -- Create fullscreen frame if it doesn't exist
    if not PCL_PetCard_Fullscreen then
        PCL_PetCard_Fullscreen = CreateFrame("Frame", "PCL_PetCard_Fullscreen", UIParent, "BackdropTemplate")
        PCL_PetCard_Fullscreen:SetSize(UIParent:GetWidth() * 0.8, UIParent:GetHeight() * 0.8)
        PCL_PetCard_Fullscreen:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        PCL_PetCard_Fullscreen:SetFrameStrata("DIALOG")
        PCL_PetCard_Fullscreen:EnableMouse(true)
        PCL_PetCard_Fullscreen:SetMovable(true)
        PCL_PetCard_Fullscreen:RegisterForDrag("LeftButton")
        PCL_PetCard_Fullscreen:SetScript("OnDragStart", function(self) self:StartMoving() end)
        PCL_PetCard_Fullscreen:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        -- Backdrop styling
        PCL_PetCard_Fullscreen:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = {left = 8, right = 8, top = 8, bottom = 8}
        })
        PCL_PetCard_Fullscreen:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
        PCL_PetCard_Fullscreen:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        
        -- Title bar
        local titleFrame = CreateFrame("Frame", nil, PCL_PetCard_Fullscreen, "BackdropTemplate")
        PCL_PetCard_Fullscreen.titleFrame = titleFrame
        titleFrame:SetHeight(30)
        titleFrame:SetPoint("TOPLEFT", PCL_PetCard_Fullscreen, "TOPLEFT", 8, -8)
        titleFrame:SetPoint("TOPRIGHT", PCL_PetCard_Fullscreen, "TOPRIGHT", -8, -8)
        titleFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8"
        })
        titleFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        
        -- Title text
        local titleText = titleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        PCL_PetCard_Fullscreen.titleText = titleText
        titleText:SetPoint("LEFT", titleFrame, "LEFT", 10, 0)
        titleText:SetText("Pet Details - Fullscreen View")
        titleText:SetTextColor(1, 0.82, 0, 1)
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, titleFrame, "UIPanelCloseButton")
        PCL_PetCard_Fullscreen.closeButton = closeButton
        closeButton:SetPoint("RIGHT", titleFrame, "RIGHT", -5, 0)
        closeButton:SetScript("OnClick", function(self)
            PCL_PetCard_Fullscreen:Hide()
        end)
        
        -- Large model frame
        local modelFrame = CreateFrame("Frame", nil, PCL_PetCard_Fullscreen, "BackdropTemplate")
        PCL_PetCard_Fullscreen.modelFrame = modelFrame
        modelFrame:SetPoint("TOPLEFT", titleFrame, "BOTTOMLEFT", 10, -10)
        modelFrame:SetPoint("BOTTOMRIGHT", PCL_PetCard_Fullscreen, "BOTTOMRIGHT", -10, 10)
        modelFrame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 4,
            insets = {left = 4, right = 4, top = 4, bottom = 4}
        })
        modelFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
        modelFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)
        
        -- Large 3D model
        local petModel = CreateFrame("PlayerModel", nil, modelFrame)
        PCL_PetCard_Fullscreen.petModel = petModel
        petModel:SetPoint("TOPLEFT", modelFrame, "TOPLEFT", 4, -4)
        petModel:SetPoint("BOTTOMRIGHT", modelFrame, "BOTTOMRIGHT", -4, 4)
        
        -- Enhanced camera controls for fullscreen
        petModel:EnableMouse(true)
        petModel:SetScript("OnMouseWheel", function(self, delta)
            -- Use SetCamDistanceScale for PlayerModel frames
            local currentScale = self.cameraScale or 2.0
            currentScale = currentScale - (delta * 0.3)  -- More sensitive in fullscreen
            currentScale = math.max(0.2, math.min(8.0, currentScale))  -- Wider zoom range for fullscreen
            self:SetCamDistanceScale(currentScale)
            self.cameraScale = currentScale  -- Store current scale
        end)
        
        -- Enhanced rotation controls
        petModel:SetScript("OnMouseDown", function(self, button)
            if button == "LeftButton" then
                self.isRotating = true
                self.startX, self.startY = GetCursorPosition()
            elseif button == "RightButton" then
                self.isPanning = true
                self.startX, self.startY = GetCursorPosition()
            end
        end)
        
        petModel:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                self.isRotating = false
            elseif button == "RightButton" then
                self.isPanning = false
            end
        end)
        
        petModel:SetScript("OnUpdate", function(self)
            if self.isRotating then
                local currentX, currentY = GetCursorPosition()
                if self.startX and self.startY then
                    local deltaX = (currentX - self.startX) * 0.01
                    local deltaY = (currentY - self.startY) * 0.01
                    
                    local currentRotation = self.currentRotation or 0.3
                    local currentPitch = self.currentPitch or 0
                    
                    currentRotation = currentRotation + deltaX
                    currentPitch = math.max(-1.5, math.min(1.5, currentPitch + deltaY))
                    
                    self:SetRotation(currentRotation)
                    self:SetModelScale(1)  -- Reset scale to apply pitch
                    
                    self.currentRotation = currentRotation
                    self.currentPitch = currentPitch
                    self.startX, self.startY = currentX, currentY
                end
            end
        end)
        
        -- Instructions text
        local instructionsText = modelFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        PCL_PetCard_Fullscreen.instructionsText = instructionsText
        instructionsText:SetPoint("BOTTOMLEFT", modelFrame, "BOTTOMLEFT", 10, 10)
        instructionsText:SetText("Mouse wheel: Zoom | Left click + drag: Rotate | Drag title bar: Move window")
        instructionsText:SetTextColor(0.7, 0.7, 0.7, 1)
    end
    
    -- Update the pet model in fullscreen
    local speciesName, speciesIcon, petType, companionID = C_PetJournal.GetPetInfoBySpeciesID(petData.speciesID)
    PCL_PetCard_Fullscreen.titleText:SetText((speciesName or "Unknown Pet") .. " - Fullscreen View")
    
    if PCL_PetCard_Fullscreen.petModel and companionID and companionID > 0 then
        local success = pcall(function()
            PCL_PetCard_Fullscreen.petModel:SetCreature(companionID)
        end)
        
        if success then
            PCL_PetCard_Fullscreen.petModel:Show()
            C_Timer.After(0.1, function()
                if PCL_PetCard_Fullscreen.petModel then
                    PCL_PetCard_Fullscreen.petModel:SetCamDistanceScale(2.0)  -- Start zoomed out a bit more
                    PCL_PetCard_Fullscreen.petModel:SetRotation(0.3)
                    PCL_PetCard_Fullscreen.petModel.currentRotation = 0.3
                    PCL_PetCard_Fullscreen.petModel.currentPitch = 0
                    if PCL_PetCard_Fullscreen.petModel.RefreshCamera then
                        PCL_PetCard_Fullscreen.petModel:RefreshCamera()
                    end
                end
            end)
        end
    end
    
    PCL_PetCard_Fullscreen:Show()
end

--[[
  Check if pet card is shown
]]
function PetCard:IsShown()
    return PCL_PetCard and PCL_PetCard:IsShown()
end

--[[
  Show pet card as hover tooltip (positioned relative to anchor frame)
]]
function PetCard:ShowAsTooltip(petSpeciesID, anchorFrame)
    if not petSpeciesID or not anchorFrame then
        return
    end
    
    -- Cancel any pending hide timer
    if hoverTimer then
        hoverTimer:Cancel()
        hoverTimer = nil
    end
    
    -- Store current hover state
    currentHoveredPet = petSpeciesID
    currentAnchorFrame = anchorFrame
    
    
    -- If this is the same pet that's already showing, don't recreate it
    if PCL_PetCard and PCL_PetCard:IsShown() and PCL_PetCard.currentSpeciesID == petSpeciesID then
        return
    end
    
    -- Create pet data structure using actual source information
    local speciesName, speciesIcon, petType, companionID, tooltipSource, tooltipDescription, isWild, canBattle, isTradeable, isUnique, obtainable = C_PetJournal.GetPetInfoBySpeciesID(petSpeciesID)
    
    local petData = {
        speciesID = petSpeciesID,
        source = tooltipSource or "Unknown source",
        description = tooltipDescription,
        zone = "Various locations"  -- This could be enhanced with actual zone data if available
    }
    
    -- Create or update the pet card
    if not PCL_PetCard then
        self:CreatePetCard()
    end
    
    -- Ensure PetCard is properly sized before showing
    self:ResizePetCard()
    
    -- Store the anchor frame and species ID for potential pinning
    if PCL_PetCard then
        PCL_PetCard.currentAnchorFrame = anchorFrame
        PCL_PetCard.currentSpeciesID = petSpeciesID
        PCL_PetCard.isPinned = false  -- Reset pinned state for hover
        
        -- Update with pet data
        self:UpdateWindow(petData)
    end
    
    -- Position relative to the anchor frame (more centrally positioned)
    PCL_PetCard:ClearAllPoints()
    
    -- If main frame is available, anchor to it instead of the specific icon
    if PCL_mainFrame and PCL_mainFrame:IsVisible() then
        PCL_PetCard:SetPoint("TOPLEFT", PCL_mainFrame, "TOPRIGHT", 5, 0)
        
        -- Force height to match main window
        local _, mainHeight = PCL_mainFrame:GetSize()
        if mainHeight and mainHeight > 0 then
            PCL_PetCard:SetHeight(mainHeight)
        end
    else
        -- Fallback: Try to center the card next to the anchor frame, slightly offset
        -- This positions it to the right of the anchor, but more vertically centered
        PCL_PetCard:SetPoint("LEFT", anchorFrame, "RIGHT", 15, 0)
        
        -- Make sure it stays on screen with better positioning logic
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()
        local frameRight = PCL_PetCard:GetRight()
        local frameLeft = PCL_PetCard:GetLeft()
        local frameTop = PCL_PetCard:GetTop()
        local frameBottom = PCL_PetCard:GetBottom()
        
        -- If the frame goes off the right side of screen, position it to the left of anchor
        if frameRight and frameRight > screenWidth then
            PCL_PetCard:ClearAllPoints()
            PCL_PetCard:SetPoint("RIGHT", anchorFrame, "LEFT", -15, 0)
        end
        
        -- If the frame goes off the top of screen, adjust vertically
        if frameTop and frameTop > screenHeight then
            PCL_PetCard:ClearAllPoints()
            if frameRight and frameRight > screenWidth then
                PCL_PetCard:SetPoint("BOTTOMRIGHT", anchorFrame, "BOTTOMLEFT", -15, -50)
            else
                PCL_PetCard:SetPoint("BOTTOMLEFT", anchorFrame, "BOTTOMRIGHT", 15, -50)
            end
        end
        
        -- If the frame goes off the bottom of screen, adjust vertically upward
        if frameBottom and frameBottom < 0 then
            PCL_PetCard:ClearAllPoints()
            if frameRight and frameRight > screenWidth then
                PCL_PetCard:SetPoint("TOPRIGHT", anchorFrame, "TOPLEFT", -15, 50)
            else
                PCL_PetCard:SetPoint("TOPLEFT", anchorFrame, "TOPRIGHT", 15, 50)
            end
        end
    end
    
    -- Set appropriate frame strata for tooltip behavior
    PCL_PetCard:SetFrameStrata("TOOLTIP")
    PCL_PetCard:SetFrameLevel(1000)
    
    -- Remove click functionality from the PetCard itself for hover tooltips
    PCL_PetCard:SetScript("OnMouseDown", nil)
    
    -- Show the frame
    PCL_PetCard:Show()
end


--[[
  Test the pet card with a sample pet
]]
function PetCard:Test()
    local sampleData = {
        speciesID = 39,  -- Mechanical Squirrel
        source = "Engineering",
        zone = "Various locations"
    }
    self:Show(sampleData)
end

--[[
  Test breed data functionality
]]
function PetCard:TestBreedData(speciesID)
    speciesID = speciesID or 40  -- Default to Westfall Chicken
    
    -- PCL Breed Data Test
    
    -- Check if breed data is loaded
    if not PCLcore.breedData then
        -- ERROR: PCLcore.breedData is not loaded
        return
    end
    
    if not PCLcore.breedData.species then
        -- ERROR: PCLcore.breedData.species is not loaded
        return
    end
    
    -- Check if this species has breed data
    local speciesData = PCLcore.breedData.species[speciesID]
    if not speciesData then
        -- No breed data found for species
        return
    end
    
    -- Species has X available breeds
    
    -- Test the breed functions
    local breeds = GetPetBreeds(speciesID)
    if #breeds > 0 then
        -- Breed calculation successful
        for i, breed in ipairs(breeds) do
            -- Breed info processed
        end
    else
        -- No breeds calculated (possible issue with breed calculation)
    end
    
    -- Test breed helper functions
    for _, breedID in ipairs(speciesData.breeds) do
        local breedName = PCLcore.GetBreedName(breedID)
        local modifiers = PCLcore.GetBreedModifiers(breedID)
        if modifiers then
            -- Breed modifier data processed
        end
    end
end

-- Export the PetCard module
PCLcore.PetCard = PetCard;

-- Add a test slash command
SLASH_PCLPETCARD1 = "/pcltest"
SlashCmdList["PCLPETCARD"] = function(msg)
    local speciesID = tonumber(msg)
    if not speciesID then
        speciesID = 39 -- Default to Mechanical Squirrel if no ID provided
    end
    
    -- Create simple pet data structure that the new UpdateWindow expects
    local petData = {
        speciesID = speciesID,
        source = "Test Source",
        zone = "Test Zone"
    }
    
    -- Show the pet card
    PetCard:Show(petData)
end

-- Add breed testing slash command
SLASH_PCLBREEDTEST1 = "/pclbreeds"
SlashCmdList["PCLBREEDTEST"] = function(msg)
    local speciesID = tonumber(msg)
    if not speciesID then
        speciesID = 39  -- Default to Mechanical Squirrel for testing
    end
    
    PetCard:TestBreedData(speciesID)
end

-- Add model variations testing slash command
SLASH_PCLMODELTEST1 = "/pclmodels"
SlashCmdList["PCLMODELTEST"] = function(msg)
    local speciesID = tonumber(msg)
    if not speciesID then
        speciesID = 4533  -- Meek Bloodlasher - has multiple variants
    end
    
    print("Testing model variations for species ID:", speciesID)
    
    -- Check if model variations data is loaded
    if not PCLcore or not PCLcore.PetModelVariations then
        print("ERROR: PCLcore.PetModelVariations not loaded")
        return
    end
    
    local variations = PCLcore.PetModelVariations[speciesID]
    if not variations then
        print("No model variations found for species", speciesID)
        return
    end
    
    print("Found model variations for species", speciesID)
    print("NPC ID:", variations.npc_id)
    print("Number of variation sets:", #variations.variations)
    
    for i, variation in ipairs(variations.variations) do
        print(string.format("  Variation %d: %s", i, variation.name or "Unnamed"))
        if variation.displays then
            for j, display in ipairs(variation.displays) do
                print(string.format("    Display %d: ID=%s, Probability=%.1f%%", 
                      j, display.id, display.probability))
            end
        end
    end
    
    -- Create simple pet data structure and show the card
    local petData = {
        speciesID = speciesID,
        source = "Model Variation Test",
        zone = "Test Zone"
    }
    
    -- Show the pet card to test the tab system
    PetCard:Show(petData)
end

-- Test comparison system command
SLASH_PCLTESTCOMPARE1 = "/pcltestcompare"
SlashCmdList["PCLTESTCOMPARE"] = function(msg)
    local speciesID = tonumber(msg)
    if not speciesID then
        speciesID = 39  -- Default to Mechanical Squirrel for testing
    end
    
    -- Testing Collection Comparison for Species
    
    if not PCLcore.CollectionComparison then
        -- Error: PCLcore.CollectionComparison not loaded
        return
    end
    
    local comparison = PCLcore.CollectionComparison:CompareSpeciesCollection(speciesID)
    
    -- Species and collection data processed
    
    if comparison.isCollected then
        -- Collection data processed
        
        if #comparison.ownedBreeds > 0 then
            local ownedText = ""
            for i, breed in ipairs(comparison.ownedBreeds) do
                if i > 1 then ownedText = ownedText .. ", " end
                ownedText = ownedText .. breed.breedLetters
                if breed.count > 1 then
                    ownedText = ownedText .. " (" .. breed.count .. ")"
                end
            end
            -- Owned breeds processed
        end
        
        if #comparison.missingBreeds > 0 then
            local missingText = ""
            for i, breed in ipairs(comparison.missingBreeds) do
                if i > 1 then missingText = missingText .. ", " end
                missingText = missingText .. breed.breedLetters
            end
            -- Missing breeds processed
        end
    end
end

-- PetCollector compatibility - safe interface that avoids DISPLAY global conflicts
PCLcore.PetCard.Display.Show = function(pet, locationIdx)
    if PetCard and PetCard.Show then
        PetCard:Show(pet, locationIdx)
    end
end

-- Alternative access method for PetCollector compatibility
_G["PCL_PetCard_Show"] = PCLcore.PetCard.Display.Show

-- Expose resize function for external use
PCLcore.PetCard.Resize = function()
    return PetCard:ResizePetCard()
end
