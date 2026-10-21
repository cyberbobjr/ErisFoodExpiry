-- Food Expiry in-game test (pz-autotest): nominal path on a single player client and on
-- a multiplayer client (client hooks only, the mod is display only).
-- For fresh food in the player's inventory, chilled food in a fridge and frozen food:
--   1. the mod's stage matches the engine (Food.isFresh / isRotten) at several ages;
--   2. the lines of the mod's TooltipLib provider ("Stale in", "Rotten in", "Thawed in",
--      "Paused") show the mod's projection;
--   3. the engine ages the food (Food.updateAge with InventoryItem.setLastAged rewound)
--      by the projected time: still fresh at 97 %, stale at 103 %, age on target at 100 %.
-- The fridge and freezer are containers created by script (ItemContainer.new, on the
-- player's square, no world object: never powered), plus the nearest real fridge or
-- freezer of the save when one is loaded near the player. Test items are removed at the end.
local H = {}
local lines, okAll, passed, failed = {}, true, 0, 0
local EFE
local PROVIDER_ID = "batman_ErisFoodExpiry"
local FOOD = "Base.Steak" -- DaysFresh 2, DaysTotallyRotten 4, can be frozen (42.21)
local created = {}
local readable = true -- exact times shown (mod option RequireTrait off, or a readable label)

local function rec(ok, name, detail)
    if ok then passed = passed + 1 else okAll = false; failed = failed + 1 end
    lines[#lines + 1] = (ok and "PASS " or "FAIL ") .. name .. (detail and (" - " .. tostring(detail)) or "")
end

local function info(msg)
    lines[#lines + 1] = "INFO " .. msg
end

local function check(name, fn)
    local ok, res, detail = pcall(fn)
    if not ok then
        rec(false, name, "error: " .. tostring(res))
        return
    end
    if res == nil then
        info(name .. " skipped" .. (detail and (": " .. tostring(detail)) or ""))
        return
    end
    rec(res == true, name, detail)
end

local function now()
    return getGameTime():getWorldAgeHours()
end

local function fmt(x)
    if x == nil then return "nil" end
    return string.format("%.5f", x)
end

-- Lines shown by the mod's TooltipLib provider for an item (fake layout context).
local function tooltipLines(item)
    local provider = TooltipLib and TooltipLib._providers and TooltipLib._providers[PROVIDER_ID]
    if not provider or type(provider.callback) ~= "function" then return nil end
    local out = {}
    local ctx = { item = item }
    function ctx.addLabel(_, text) out[#out + 1] = { label = tostring(text) } end
    function ctx.addKeyValue(_, key, value) out[#out + 1] = { key = tostring(key), value = tostring(value) } end
    function ctx.addProgress(_, label, fraction) out[#out + 1] = { key = tostring(label), fraction = fraction } end
    provider.callback(ctx)
    return out
end

local function valueOf(out, text)
    for _, l in ipairs(out or {}) do
        if l.key == text then return l.value end
    end
    return nil
end

local function hasLabel(out, key)
    local text = getText(key)
    for _, l in ipairs(out or {}) do
        if l.label == text then return true end
    end
    return false
end

local function describe(out)
    local parts = {}
    for _, l in ipairs(out or {}) do
        if l.label then parts[#parts + 1] = l.label
        elseif l.value then parts[#parts + 1] = l.key .. " " .. l.value
        else parts[#parts + 1] = l.key .. " " .. fmt(l.fraction) end
    end
    return table.concat(parts, " | ")
end

-- A test food in `container`, aged `age` days, aging from now (lastAged = now).
local function newFood(container, age, frozen)
    local item = instanceItem(FOOD)
    container:AddItem(item)
    created[#created + 1] = { item = item, container = container }
    item:updateAge() -- lastAged and lastFrozenUpdate = now
    if frozen then item:freeze() end
    item:setAge(age)
    return item
end

-- Age of the item once the engine has aged it for `hours` game hours where it is.
local function engineAge(item, hours)
    item:setLastAged(now() - hours)
    item:updateAge()
    return item:getAge()
end

-- The projection may cross the power shutoff of a fridge: the test ages the item over the
-- past hours, the mod projects over the next ones. Skip the engine check near the shutoff.
local function nearShutoff(container, hours)
    if not (container:isFridge() or container:isFreezer()) then return false end
    local square = container:getSourceGrid()
    if square and square:haveElectricity() then return false end
    local shut = getSandboxOptions():getElecShutModifier()
    if shut < 0 then return false end
    return math.abs(now() - shut * 24) < hours * 1.1 + 0.25
end

-- Stage of the mod against Food.isFresh / isRotten at several ages.
local function checkStages(label, container)
    local item = newFood(container, 0)
    local offAge, offAgeMax = item:getOffAge(), item:getOffAgeMax()
    local ages = { 0, offAge - 0.01, offAge, (offAge + offAgeMax) / 2, offAgeMax - 0.01, offAgeMax, offAgeMax + 1 }
    local bad = {}
    for _, a in ipairs(ages) do
        item:setAge(a)
        local stage = EFE.stage(item)
        local expected = item:isRotten() and "rotten" or (item:isFresh() and "fresh" or "stale")
        if stage ~= expected then bad[#bad + 1] = fmt(a) .. ": " .. stage .. " / engine " .. expected end
    end
    check(label .. ": stage matches isFresh/isRotten (offAge " .. offAge .. ", offAgeMax " .. offAgeMax .. ")",
        function() return #bad == 0, #bad > 0 and table.concat(bad, "; ") or nil end)
end

-- Projection to `target` ("offAge" or "offAgeMax") against the engine.
local function checkProjection(label, container, targetName)
    local probe = newFood(container, 0)
    local target = targetName == "offAge" and probe:getOffAge() or probe:getOffAgeMax()
    local isPast = function(item)
        if targetName == "offAge" then return not item:isFresh() end
        return item:isRotten()
    end
    -- Small delta so that the rewound time stays after the world start and within a day.
    local maxHours = math.min(24, (now() - 1) / 1.05)
    local delta = 0.05
    probe:setAge(target - delta)
    local days = EFE.daysUntil(probe, target)
    if days and days * 24 > maxHours then
        delta = delta * maxHours / (days * 24) * 0.9
        probe:setAge(target - delta)
        days = EFE.daysUntil(probe, target)
    end
    local out = tooltipLines(probe)
    -- Rotten line: "Turns into <item> in" for food replaced when it rots (EFE.replacementName).
    local replacement = EFE.replacementName and EFE.replacementName(probe)
    local lineText = targetName == "offAge" and getText("UI_EFE_StaleIn")
        or (replacement and getText("UI_EFE_TurnsInto", replacement) or getText("UI_EFE_RottenIn"))
    if days == nil then
        check(label .. ": paused aging shown", function()
            local freezing = EFE.freezeDays and EFE.freezeDays(probe)
            local key = freezing and "UI_EFE_Frozen" or "UI_EFE_Paused"
            return hasLabel(out, readable and key or EFE.stateKey(probe)), describe(out)
        end)
        check(label .. ": engine does not age it either", function()
            local before = probe:getAge()
            local after = engineAge(probe, 1)
            return math.abs(after - before) < 1e-6, fmt(before) .. " -> " .. fmt(after)
        end)
        return
    end
    local hours = days * 24
    check(label .. ": tooltip " .. lineText .. " = projection", function()
        if not readable then
            return hasLabel(out, EFE.stateKey(probe)), "exact times hidden, state label | " .. describe(out)
        end
        local shown = valueOf(out, lineText)
        local expected = EFE.formatDays(days)
        return shown == expected, "shown '" .. tostring(shown) .. "', projected '" .. expected .. "' (" .. fmt(hours)
            .. " h) | " .. describe(out)
    end)
    if nearShutoff(container, hours) then
        info(label .. ": engine check skipped, power shutoff within the projected time")
        return
    end
    check(label .. ": engine age on target after the projected " .. fmt(hours) .. " h", function()
        local item = newFood(container, target - delta)
        local age = engineAge(item, hours)
        return math.abs(age - target) <= delta * 0.02 + 1e-4,
            "age " .. fmt(age) .. ", target " .. fmt(target) .. ", delta " .. fmt(delta)
    end)
    check(label .. ": not yet " .. (targetName == "offAge" and "stale" or "rotten") .. " at 97 %", function()
        local item = newFood(container, target - delta)
        engineAge(item, hours * 0.97)
        return not isPast(item), "age " .. fmt(item:getAge())
    end)
    check(label .. ": " .. (targetName == "offAge" and "stale" or "rotten") .. " at 103 %", function()
        local item = newFood(container, target - delta)
        engineAge(item, hours * 1.03)
        return isPast(item), "age " .. fmt(item:getAge())
    end)
end

-- Frozen food: thaw time shown, no aging while frozen, aging after the thaw.
local function checkFrozen(label, container)
    local item = newFood(container, 1, true)
    check(label .. ": frozen", function()
        return item:isFrozen(), "freezingTime " .. fmt(item:getFreezingTime())
    end)
    local out = tooltipLines(item)
    local thaw = EFE.thawDays(item)
    if item:isThawing() then
        check(label .. ": tooltip " .. getText("UI_EFE_ThawedIn") .. " = projection", function()
            if not readable then
                return hasLabel(out, EFE.stateKey(item)), "exact times hidden, state label | " .. describe(out)
            end
            local shown = valueOf(out, getText("UI_EFE_ThawedIn"))
            local expected = thaw and EFE.formatDays(thaw) or "nil"
            return thaw ~= nil and shown == expected, "shown '" .. tostring(shown) .. "', projected '" .. expected
                .. "' | " .. describe(out)
        end)
        check(label .. ": projection = thaw + aging of the same food unfrozen", function()
            local twin = newFood(container, 1)
            local a, b = EFE.daysUntil(item, item:getOffAge()), EFE.daysUntil(twin, twin:getOffAge())
            if nearShutoff(container, (a or 0) * 24) then return nil, "power shutoff within the projected time" end
            return a ~= nil and b ~= nil and math.abs(a - (thaw + b)) < 1e-4,
                "frozen " .. fmt(a) .. ", thaw " .. fmt(thaw) .. ", unfrozen " .. fmt(b)
        end)
    else
        check(label .. ": stays frozen, tooltip " .. getText("UI_EFE_Frozen"), function()
            local key = readable and "UI_EFE_Frozen" or EFE.stateKey(item)
            return thaw == nil and hasLabel(out, key), describe(out)
        end)
    end
    check(label .. ": engine does not age frozen food", function()
        local before = item:getAge()
        local after = engineAge(item, 1)
        return item:isFrozen() and math.abs(after - before) < 1e-6, fmt(before) .. " -> " .. fmt(after)
    end)
end

-- The nearest real fridge or freezer loaded near the player, or nil.
local function findAppliance(p, radius)
    local cell = getCell()
    local px, py, pz = math.floor(p:getX()), math.floor(p:getY()), math.floor(p:getZ())
    for r = 0, radius do
        for x = px - r, px + r do
            for y = py - r, py + r do
                if math.abs(x - px) == r or math.abs(y - py) == r then
                    local sq = cell:getGridSquare(x, y, pz)
                    local objs = sq and sq:getObjects()
                    if objs then
                        for i = 0, objs:size() - 1 do
                            local o = objs:get(i)
                            for c = 0, o:getContainerCount() - 1 do
                                local cont = o:getContainerByIndex(c)
                                if cont and (cont:isFridge() or cont:isFreezer()) then return cont end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function containerInfo(c)
    local square = c:getSourceGrid()
    return string.format("type %s, powered %s, generator %s, temperature %s", tostring(c:getType()),
        tostring(c:isPowered()), tostring(square ~= nil and square:haveElectricity()), fmt(c:getTemperature()))
end

local function cleanup()
    for i = #created, 1, -1 do
        local c = created[i]
        pcall(function() c.container:Remove(c.item) end)
    end
    created = {}
end

function H.start(ctx)
    local p = getPlayer()
    if not p then return false, "no player" end
    EFE = ErisFoodExpiry
    rec(EFE ~= nil and EFE.daysUntil ~= nil, "mod loaded (ErisFoodExpiry)")
    rec(TooltipLib ~= nil and TooltipLib.hasProvider ~= nil and TooltipLib.hasProvider(PROVIDER_ID),
        "TooltipLib provider registered")
    if not EFE or not EFE.daysUntil then return true end
    if tooltipLines(instanceItem(FOOD)) == nil then
        rec(false, "TooltipLib provider callback readable (TooltipLib._providers)")
    end
    local so = getSandboxOptions()
    info(string.format("side %s, client %s, world age %.2f h, FoodRotSpeed %s (%.2f), FridgeFactor %s (%.2f), ElecShut %s",
        tostring(ctx.side), tostring(isClient()), now(), tostring(so:getOptionByName("FoodRotSpeed"):getValue()),
        EFE.rotSpeed(), tostring(so:getOptionByName("FridgeFactor"):getValue()), EFE.fridgeFactor(),
        tostring(so:getElecShutModifier())))
    readable = EFE.canReadExact(instanceItem(FOOD), p, EFE.requireTrait())
    info("exact times readable: " .. tostring(readable) .. " (option RequireTrait " .. tostring(EFE.requireTrait()) .. ")")

    local inv = p:getInventory()
    local sq = p:getCurrentSquare()
    local fridge = ItemContainer.new("fridge", sq, nil)
    local freezer = ItemContainer.new("freezer", sq, nil)
    info("script fridge: " .. containerInfo(fridge))

    local ok, err = pcall(function()
        checkStages("inventory", inv)
        checkProjection("inventory fresh", inv, "offAge")
        checkProjection("inventory stale", inv, "offAgeMax")
        checkStages("fridge", fridge)
        checkProjection("fridge fresh", fridge, "offAge")
        checkProjection("fridge stale", fridge, "offAgeMax")
        checkFrozen("frozen in inventory", inv)
        checkFrozen("frozen in unpowered freezer", freezer)
        local real = findAppliance(p, 20)
        if real then
            info("save appliance: " .. containerInfo(real))
            local name = real:isFreezer() and "save freezer" or "save fridge"
            checkProjection(name .. " fresh", real, "offAge")
            if real:isFreezer() then checkFrozen(name .. " frozen", real) end
        else
            info("no fridge or freezer of the save within 20 tiles: script containers only")
        end
    end)
    if not ok then rec(false, "test run", "error: " .. tostring(err)) end
    cleanup()
    return true
end

function H.done(ctx)
    return true
end

function H.result(ctx)
    return { ok = okAll, summary = string.format("%d PASS, %d FAIL", passed, failed), lines = lines }
end

return { client = H }
