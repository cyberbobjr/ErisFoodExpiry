-- ============================================================================
-- Food Expiry — tooltip lines through TooltipLib
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

-- Rotten food: when the sandbox Rotten Food Removal will delete it.
local function addRemoval(ctx, item)
    local removal = EFE.removalDays(item)
    if removal then
        ctx:addKeyValue(getText("UI_EFE_RemovedIn"), EFE.formatDays(removal), LABEL, VALUE)
    end
end

-- Players who cannot read the exact times: rough state, what happens to the
-- food where it is, and a removal warning, without any time.
local function addRough(ctx, item, stage, color)
    ctx:addProgress(getText("UI_EFE_Freshness"), EFE.roughFraction(EFE.freshFraction(item)), LABEL, color)
    ctx:addLabel(getText(EFE.stateKey(item, stage)), color)
    local condition = EFE.conditionKey(item)
    if condition then ctx:addLabel(getText(condition), VALUE) end
    if stage == "rotten" and EFE.removalDays(item) then
        ctx:addLabel(getText("UI_EFE_RemovedSoon"), VALUE)
    end
end

TooltipLib.registerProvider({
    id = "batman_ErisFoodExpiry",
    target = "item",
    description = "UI_EFE_TooltipProvider",
    enabled = function(item)
        return instanceof(item, "Food")
    end,
    callback = function(ctx)
        local item = ctx.item
        if not EFE.canAge(item) then
            ctx:addLabel(getText("UI_EFE_NeverPerish"), MUTED)
            return
        end
        if item:isFertilized() then
            ctx:addLabel(getText("UI_EFE_Fertilized"), MUTED)
            return
        end
        local stage = EFE.stage(item)
        local color = EFE.COLORS[stage]
        local character = ctx.tooltip and ctx.tooltip:getCharacter() or nil
        if not EFE.canReadExact(item, character, EFE.requireTrait()) then
            addRough(ctx, item, stage, color)
            return
        end
        ctx:addProgress(getText("UI_EFE_Freshness"), EFE.freshFraction(item), LABEL, color)
        if EFE.isCooking(item) then
            ctx:addLabel(getText("UI_EFE_Cooking"), VALUE)
            return
        end
        if item:isFrozen() then
            local thaw = EFE.thawDays(item)
            if thaw == nil then
                ctx:addLabel(getText("UI_EFE_Frozen"), VALUE)
                return
            end
            ctx:addKeyValue(getText("UI_EFE_ThawedIn"), EFE.formatDays(thaw), LABEL, VALUE)
        end
        local freeze = EFE.freezeDays(item)
        if freeze then
            ctx:addKeyValue(getText("UI_EFE_FrozenIn"), EFE.formatDays(freeze), LABEL, VALUE)
        end
        local replacement = EFE.replacementName(item)
        local rottenLabel = replacement and getText("UI_EFE_TurnsInto", replacement) or getText("UI_EFE_RottenIn")
        if stage == "rotten" then
            if replacement then
                ctx:addKeyValue(rottenLabel, EFE.formatDays(0), LABEL, VALUE)
                return
            end
            ctx:addLabel(getText("UI_EFE_StateRotten"), color)
            addRemoval(ctx, item)
            return
        end
        local stale = stage == "fresh" and EFE.daysUntil(item, item:getOffAge()) or nil
        if stale then
            ctx:addKeyValue(getText("UI_EFE_StaleIn"), EFE.formatDays(stale), LABEL, VALUE)
        end
        local rotten = EFE.daysUntil(item, item:getOffAgeMax())
        if rotten == nil then
            ctx:addLabel(getText(freeze and "UI_EFE_Frozen" or "UI_EFE_Paused"), VALUE)
            return
        end
        ctx:addKeyValue(rottenLabel, EFE.formatDays(rotten), LABEL, VALUE)
    end,
})
