-- ============================================================================
-- Eris Food Expiry (batman fork) — spoilage projection and formatting
--
-- Fork of eris_food_expiry (Workshop 3392259028). The projection follows
-- Food.updateAge in 42.21:
--   age (days) += elapsed hours * FoodRotSpeed / 24
--   * FridgeFactor in a fridge or freezer powered by a generator, or still on
--     grid power (world age < ElecShutModifier days), then normal speed;
--   * 0 while the food is frozen.
-- Stale at age >= offAge, rotten at age >= offAgeMax (instance values, which
-- may differ from the item script after cooking or a recipe).
-- ============================================================================

ErisFoodExpiry = ErisFoodExpiry or {}
local EFE = ErisFoodExpiry

EFE.NEVER = 1000000000 -- InventoryItem.offAge/offAgeMax default: never ages
EFE.MAX_PARTS = 3

-- Food.getFoodRotSpeed / getFridgeFactor (42.21), keyed by the sandbox value
local ROT_SPEED = { [1] = 1.7, [2] = 1.4, [3] = 1.0, [4] = 0.7, [5] = 0.4 }
local FRIDGE_FACTOR = { [1] = 0.4, [2] = 0.3, [3] = 0.2, [4] = 0.1, [5] = 0.03, [6] = 0.0 }

local function sandboxValue(name)
    local option = getSandboxOptions():getOptionByName(name)
    return option and tonumber(option:getValue()) or nil
end

function EFE.rotSpeed()
    return ROT_SPEED[sandboxValue("FoodRotSpeed")] or 1.0
end

function EFE.fridgeFactor()
    local factor = FRIDGE_FACTOR[sandboxValue("FridgeFactor")]
    if factor == nil then return 0.2 end
    return factor
end

function EFE.canAge(item)
    return item:getOffAgeMax() < EFE.NEVER
end

-- Game days until the item's age reaches targetAge where it is now.
-- Returns nil when it does not age there (frozen, or fridge factor "never").
function EFE.daysUntil(item, targetAge)
    local delta = targetAge - item:getAge()
    if delta <= 0 then return 0 end
    if item:isFrozen() then return nil end
    local rot = EFE.rotSpeed()
    local container = item:getOutermostContainer()
    if not container or not (container:isFridge() or container:isFreezer()) then
        return delta / rot
    end
    local cold = rot * EFE.fridgeFactor()
    local square = container:getSourceGrid()
    if square and square:haveElectricity() then
        if cold <= 0 then return nil end
        return delta / cold
    end
    local shutDays = getSandboxOptions():getElecShutModifier()
    local nowDays = getGameTime():getWorldAgeHours() / 24
    if shutDays > -1 and nowDays < shutDays then
        local gridDays = shutDays - nowDays
        local gridAge = gridDays * cold
        if delta <= gridAge then return delta / cold end
        return gridDays + (delta - gridAge) / rot
    end
    return delta / rot
end

-- Rough state for players who cannot read the exact time, consistent with
-- vanilla stale/rotten thresholds.
function EFE.stateKey(item)
    local age, offAge, offAgeMax = item:getAge(), item:getOffAge(), item:getOffAgeMax()
    if age >= offAgeMax then return "UI_EFE_StateRotten" end
    if age >= offAge then
        if offAgeMax > offAge and (age - offAge) / (offAgeMax - offAge) >= 0.5 then
            return "UI_EFE_StateAlmostRotten"
        end
        return "UI_EFE_StateRotting"
    end
    local left = offAge > 0 and (offAge - age) / offAge or 0
    if left > 2 / 3 then return "UI_EFE_StateVeryFresh" end
    if left > 1 / 3 then return "UI_EFE_StateFresh" end
    return "UI_EFE_StateOk"
end

-- Remaining life, 1 = brand new, 0 = rotten.
function EFE.freshFraction(item)
    local offAgeMax = item:getOffAgeMax()
    if offAgeMax <= 0 then return 0 end
    local f = (offAgeMax - item:getAge()) / offAgeMax
    if f < 0 then return 0 end
    if f > 1 then return 1 end
    return f
end

local UNITS = {
    { key = "UI_EFE_Years", days = 365 },
    { key = "UI_EFE_Months", days = 30 },
    { key = "UI_EFE_Weeks", days = 7 },
    { key = "UI_EFE_Days", days = 1 },
    { key = "UI_EFE_Hours", days = 1 / 24 },
    { key = "UI_EFE_Minutes", days = 1 / 1440 },
}

-- "1 yr 2 mth 3 d": the largest non-zero units, at most maxParts of them,
-- in order (the original walked a hash table with pairs: random order).
function EFE.formatDays(days, maxParts)
    maxParts = maxParts or EFE.MAX_PARTS
    local minutes = math.floor(days * 1440 + 0.5)
    local parts = {}
    for i = 1, #UNITS do
        local size = math.floor(UNITS[i].days * 1440 + 0.5)
        local count = math.floor(minutes / size)
        if count > 0 then
            minutes = minutes - count * size
            if #parts < maxParts then
                parts[#parts + 1] = count .. " " .. getText(UNITS[i].key)
            end
        end
    end
    if #parts == 0 then return "< 1 " .. getText("UI_EFE_Minutes") end
    return table.concat(parts, " ")
end

local function hasTrait(character, trait)
    return trait ~= nil and character:hasTrait(trait)
end

-- Same rule as Food.DoTooltip for the nutrition block: Nutritionist, or a
-- readable package (not illiterate, not too dark, label present).
function EFE.canReadExact(item, character, requireTrait)
    if not requireTrait then return true end
    if not character then return false end
    if hasTrait(character, CharacterTrait.NUTRITIONIST) or hasTrait(character, CharacterTrait.NUTRITIONIST2) then
        return true
    end
    if not item:isPackaged() then return false end
    if hasTrait(character, CharacterTrait.ILLITERATE) then return false end
    if instanceof(character, "IsoPlayer") and character:tooDarkToRead() then return false end
    return item:getModData().NoLabel == nil
end
