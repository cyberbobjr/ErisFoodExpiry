-- ============================================================================
-- Food Expiry — spoilage projection and formatting
--
-- The projection follows Food.updateAge in 42.21:
--   age (days) += elapsed hours * FoodRotSpeed / 24
--   * FridgeFactor in a fridge or freezer powered by a generator, or still on
--     grid power (world age < ElecShutModifier days), then normal speed;
--   * 0 while the food is frozen (until it has thawed); fresh food in a
--     powered freezer freezes within 4 h, then stops aging.
-- Stale at age >= offAge, rotten at age >= offAgeMax (instance values, which
-- may differ from the item script after cooking or a recipe).
--
-- The engine uses two clocks for the grid shutoff: Food.updateAge compares
-- getWorldAgeHours() with ElecShutModifier * 24, while the real power cut
-- (SandboxOptions.doesPowerGridExist, ItemContainer.isPowered) compares
-- getWorldAgeDaysSinceBegin(), which adds (TimeSinceApo - 1) * 30 days. Aging
-- follows the first clock, freezing and thawing follow the second one.
-- ============================================================================

ErisFoodExpiry = ErisFoodExpiry or {}
local EFE = ErisFoodExpiry

EFE.NEVER = 1000000000 -- InventoryItem.offAge/offAgeMax default: never ages
EFE.MAX_PARTS = 3
EFE.NEVER_SHUT = 2147483647 -- ElecShutModifier of "Disabled" (SandboxOptions.randomElectricityShut)

local HOURS_TO_FREEZE = 4.0 -- Food.updateFreezing
local HOURS_TO_THAW = 1.5

-- Food.getFoodRotSpeed / getFridgeFactor (42.21), keyed by the sandbox value
local ROT_SPEED = { [1] = 1.7, [2] = 1.4, [3] = 1.0, [4] = 0.7, [5] = 0.4 }
local FRIDGE_FACTOR = { [1] = 0.4, [2] = 0.3, [3] = 0.2, [4] = 0.1, [5] = 0.03, [6] = 0.0 }

-- Sandbox values are read once per millisecond: a tooltip draws twice per
-- frame and the inventory strip once per visible row. No lasting cache, since
-- an option may change during a multiplayer game.
local cache, cacheStamp = {}, nil

local function sandboxValue(name)
    local stamp = getTimestampMs()
    if stamp ~= cacheStamp then
        cache, cacheStamp = {}, stamp
    end
    local value = cache[name]
    if value == nil then
        local option = getSandboxOptions():getOptionByName(name)
        value = option and tonumber(option:getValue()) or false
        cache[name] = value
    end
    return value or nil
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

local function isCold(container)
    return container ~= nil and (container:isFridge() or container:isFreezer())
end

-- Generator power, the only local power Food.updateAge knows: a generator
-- position of the chunk (IsoGridSquare.haveElectricity). Vanilla generators and
-- mods that power houses for the engine (such as inverters) register these
-- positions on the server and on every client (IsoGenerator.sync calls
-- setSurroundingElectricity on clients too), and the client ages the food it
-- shows with this same test. Power the engine does not see does not slow food
-- aging either, so it is not counted here.
function EFE.generatorPowered(container)
    local square = container:getSourceGrid()
    return square ~= nil and square:haveElectricity()
end

-- Game days for the age to grow by delta where the item is now, starting
-- startDays from now; nil when it does not age there (fridge factor "never").
local function agingDays(item, delta, startDays)
    local rot = EFE.rotSpeed()
    local container = item:getOutermostContainer()
    if not isCold(container) then
        return delta / rot
    end
    local cold = rot * EFE.fridgeFactor()
    if EFE.generatorPowered(container) then
        if cold <= 0 then return nil end
        return delta / cold
    end
    local shutDays = sandboxValue("ElecShutModifier") or -1
    local startAt = getGameTime():getWorldAgeHours() / 24 + startDays
    if shutDays > -1 and startAt < shutDays then
        local gridDays = shutDays - startAt
        local gridAge = gridDays * cold
        if delta <= gridAge then
            if cold <= 0 then return nil end
            return delta / cold
        end
        return gridDays + (delta - gridAge) / rot
    end
    return delta / rot
end

-- Age gained per game day right now where the item is (Food.updateAge).
local function agingRate(item)
    local rot = EFE.rotSpeed()
    local container = item:getOutermostContainer()
    if not isCold(container) then return rot end
    if EFE.generatorPowered(container) then return rot * EFE.fridgeFactor() end
    local shutDays = sandboxValue("ElecShutModifier") or -1
    if shutDays > -1 and getGameTime():getWorldAgeHours() / 24 < shutDays then
        return rot * EFE.fridgeFactor()
    end
    return rot
end

-- Game days until the grid shutoff stops the fridge or freezer the item is in
-- (SandboxOptions.doesPowerGridExist: world age in days since the start of the
-- apocalypse <= ElecShutModifier). nil when it is not running on grid power:
-- generator, no power, shutoff disabled.
function EFE.powerCutDays(item)
    local container = item:getOutermostContainer()
    if not isCold(container) or EFE.generatorPowered(container) or not container:isPowered() then
        return nil
    end
    local shut = sandboxValue("ElecShutModifier")
    if shut == nil or shut < 0 or shut >= EFE.NEVER_SHUT then return nil end
    local days = shut - getGameTime():getWorldAgeDaysSinceBegin()
    if days < 0 then return nil end
    return days
end

-- Game days until frozen food has thawed (Food.updateFreezing, 42.21): 1.5 h
-- from fully frozen, twice as long in a powered fridge, six times faster in
-- a container warmer than 1.0. nil while it stays frozen (powered freezer).
function EFE.thawDays(item)
    if not item:isFrozen() or not item:isThawing() then return nil end
    local hours = HOURS_TO_THAW
    local container = item:getOutermostContainer()
    if container then
        if container:isFridge() and container:isPowered() then hours = hours * 2 end
        if container:getTemperature() > 1.0 then hours = hours / 6 end
    end
    return item:getFreezingTime() / 100 * hours / 24
end

-- Game days until food in a powered freezer is frozen (Food.updateFreezing,
-- 42.21: freezingTime += hours / 4 * 100, frozen at 100; Food.isFreezing:
-- canBeFrozen, below 100, in a powered freezer). nil when it is not freezing.
function EFE.freezeDays(item)
    if item:isFrozen() or not item:isFreezing() then return nil end
    return (100 - item:getFreezingTime()) / 100 * HOURS_TO_FREEZE / 24
end

-- Game days until the item's age reaches targetAge where it is now: frozen
-- food does not age until it has thawed, freezing food stops aging once
-- frozen. In a freezer on grid power, frozen food thaws after the shutoff
-- (1.5 h in the unpowered freezer, which stays at 1.0), then ages again.
-- nil when it never gets there.
function EFE.daysUntil(item, targetAge)
    local delta = targetAge - item:getAge()
    if delta <= 0 then return 0 end
    local cut = EFE.powerCutDays(item)
    local startDays = 0
    if item:isFrozen() then
        startDays = EFE.thawDays(item)
        if startDays == nil then
            if cut == nil then return nil end
            startDays = cut + item:getFreezingTime() / 100 * HOURS_TO_THAW / 24
        end
    end
    local days = agingDays(item, delta, startDays)
    local freeze = EFE.freezeDays(item)
    if freeze == nil or (days ~= nil and days <= freeze) or (cut ~= nil and cut <= freeze) then
        -- not freezing, target reached first, or power cut before it is frozen
        if days == nil then return nil end
        return startDays + days
    end
    if cut == nil then return nil end
    -- ages until frozen, stays frozen until the shutoff, then thaws
    local gained = freeze * agingRate(item)
    local resume = cut + HOURS_TO_THAW / 24
    local rest = agingDays(item, delta - gained, resume)
    if rest == nil then return nil end
    return resume + rest
end

-- Game days until rotten food is removed from the map (sandbox Rotten Food
-- Removal, Food.updateRotting): age > offAgeMax + DaysForRottenFoodRemoval.
-- nil when the option is off (-1), in a composter, which keeps it, or for
-- food replaced by another item when it rots (ReplaceOnRotten).
function EFE.removalDays(item)
    if EFE.replacementName(item) then return nil end
    local removal = sandboxValue("DaysForRottenFoodRemoval") or -1
    if removal < 0 then return nil end
    local container = item:getOutermostContainer()
    if container and instanceof(container:getParent(), "IsoCompost") then return nil end
    return EFE.daysUntil(item, item:getOffAgeMax() + removal)
end

-- Food being cooked (same test as the vanilla "Cooking" bar,
-- ISInventoryPane.drawItemDetails): its times change once cooked (rice and
-- pasta pots restart at age 0, ReplaceOnCooked items are replaced, Food.update).
function EFE.isCooking(item)
    return item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6
        and not item:isCooked() and not item:isBurnt()
end

EFE.COLORS = {
    fresh = { 0.3, 0.85, 0.3, 1 },
    stale = { 1, 0.75, 0.2, 1 },
    rotten = { 0.9, 0.25, 0.2, 1 },
}

-- Display name of the item that replaces this one when it rots
-- (ReplaceOnRotten, Food.updateRotting: module of the item + name), nil when
-- it rots normally. Script names are already translated on the client.
function EFE.replacementName(item)
    local name = item:getReplaceOnRotten()
    if name == nil or name == "" then return nil end
    local script = getScriptManager():FindItem(item:getModule() .. "." .. name)
    return script and script:getDisplayName() or name
end

-- "fresh", "stale" or "rotten", as the game reads it (Food.isFresh and
-- Food.isRotten: a fertilized egg stays fresh).
function EFE.stage(item)
    if item:isRotten() then return "rotten" end
    if item:isFresh() then return "fresh" end
    return "stale"
end

-- Rough state for players who cannot read the exact time.
function EFE.stateKey(item, stage)
    local age, offAge, offAgeMax = item:getAge(), item:getOffAge(), item:getOffAgeMax()
    stage = stage or EFE.stage(item)
    if stage == "rotten" then return "UI_EFE_StateRotten" end
    if stage == "stale" then
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

-- What happens to the food where it is, without a time, for players who
-- cannot read the exact times; nil when it simply ages.
function EFE.conditionKey(item)
    if EFE.isCooking(item) then return "UI_EFE_Cooking" end
    if item:isFrozen() then
        return EFE.thawDays(item) and "UI_EFE_Thawing" or "UI_EFE_Frozen"
    end
    if EFE.freezeDays(item) then return "UI_EFE_Freezing" end
    if EFE.daysUntil(item, item:getOffAgeMax()) == nil then return "UI_EFE_Paused" end
    return nil
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

-- Freshness rounded up to a third, for players who cannot read the exact time.
function EFE.roughFraction(fraction)
    return math.ceil(fraction * 3 - 1e-9) / 3
end

local UNITS = {
    { key = "UI_EFE_Years", days = 365 },
    { key = "UI_EFE_Months", days = 30 },
    { key = "UI_EFE_Weeks", days = 7 },
    { key = "UI_EFE_Days", days = 1 },
    { key = "UI_EFE_Hours", days = 1 / 24 },
    { key = "UI_EFE_Minutes", days = 1 / 1440 },
}

-- "1 yr 2 mth 3 d": the largest non-zero units, at most maxParts of them.
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
-- readable package (not illiterate, not too dark, label present). An unknown
-- character cannot read it.
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
