-- ============================================================================
-- Eris Food Expiry (batman fork) — tooltip lines through TooltipLib
--
-- The original replaced ISToolTipInv.render, drew its own box under the
-- vanilla tooltip and moved the tooltip with setX on every frame. TooltipLib
-- adds the lines inside the vanilla tooltip instead.
-- ============================================================================

require "TooltipLib/Core"
require "ErisFoodExpiry/EFE_Core"
require "ErisFoodExpiry/EFE_Options"

if not TooltipLib or type(TooltipLib.registerProvider) ~= "function" then
    print("[ErisFoodExpiry] TooltipLib missing: no expiry lines in tooltips")
    return
end

local EFE = ErisFoodExpiry

local LABEL = { 1, 1, 0.8, 1 }
local VALUE = { 0.9, 0.9, 0.9, 1 }
local MUTED = { 0.65, 0.65, 0.65, 1 }
local FRESH = { 0.3, 0.85, 0.3, 1 }
local STALE = { 1, 0.75, 0.2, 1 }
local ROTTEN = { 0.9, 0.25, 0.2, 1 }

local function stateColor(item)
    if item:getAge() >= item:getOffAgeMax() then return ROTTEN end
    if item:getAge() >= item:getOffAge() then return STALE end
    return FRESH
end

local function durationText(item, targetAge)
    local days = EFE.daysUntil(item, targetAge)
    if days == nil then return getText("UI_EFE_Paused") end
    return EFE.formatDays(days)
end

TooltipLib.registerProvider({
    id = "batman_ErisFoodExpiry",
    target = "item",
    description = getText("UI_EFE_TooltipProvider"), -- shown as is in TooltipLib options
    enabled = function(item)
        return instanceof(item, "Food")
    end,
    callback = function(ctx)
        local item = ctx.item
        if not EFE.canAge(item) then
            ctx:addLabel(getText("UI_EFE_NeverPerish"), MUTED)
            return
        end
        local color = stateColor(item)
        ctx:addProgress(getText("UI_EFE_Freshness"), EFE.freshFraction(item), LABEL, color)
        local character = ctx.tooltip and ctx.tooltip:getCharacter() or getSpecificPlayer(0)
        if not EFE.canReadExact(item, character, EFE.requireTrait()) then
            ctx:addLabel(getText(EFE.stateKey(item)), color)
            return
        end
        if item:isFrozen() then
            ctx:addLabel(getText("UI_EFE_Frozen"), VALUE)
        end
        local age = item:getAge()
        if age < item:getOffAge() then
            ctx:addKeyValue(getText("UI_EFE_StaleIn"), durationText(item, item:getOffAge()), LABEL, VALUE)
        end
        if age < item:getOffAgeMax() then
            ctx:addKeyValue(getText("UI_EFE_RottenIn"), durationText(item, item:getOffAgeMax()), LABEL, VALUE)
        else
            ctx:addLabel(getText("UI_EFE_StateRotten"), ROTTEN)
        end
    end,
})
