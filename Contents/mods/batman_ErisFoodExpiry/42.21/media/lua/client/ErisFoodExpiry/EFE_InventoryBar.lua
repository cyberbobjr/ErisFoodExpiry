-- ============================================================================
-- Food Expiry — freshness strip in the expanded item list
--
-- A row holds one line of text (itemHgt): the vanilla detail line is kept and
-- a thin strip is drawn along the bottom of the row, from the vanilla label to
-- the end of the vanilla progress bar.
-- ============================================================================

require "ISUI/ISInventoryPane"
require "ErisFoodExpiry/EFE_Core"
require "ErisFoodExpiry/EFE_Options"

local EFE = ErisFoodExpiry

local STRIP_HEIGHT = 2

local original = ISInventoryPane.drawItemDetails
if not original then
    print("[ErisFoodExpiry] ISInventoryPane.drawItemDetails missing: no freshness strip")
    return
end

-- Label of the vanilla progress bar drawn for this food, nil when vanilla
-- draws no bar (same branches as ISInventoryPane.drawItemDetails, 42.21).
local function vanillaBarLabel(item)
    if item:getMeltingTime() > 0 then return getText("IGUI_invpanel_Melting") .. ":" end
    if item:isIsCookable() and not item:isFrozen() and item:getHeat() > 1.6 then
        if item:isBurnt() then return nil end
        local cooking = item:getCookingTime()
        if cooking > item:getMinutesToBurn() then return getText("IGUI_invpanel_Burnt") .. ":" end
        if cooking > item:getMinutesToCook() then return getText("IGUI_invpanel_Burning") .. ":" end
        return getText("IGUI_invpanel_Cooking") .. ":"
    end
    if item:getFreezingTime() > 0 then return getText("IGUI_invpanel_FreezingTime") .. ":" end
    if item:getHungerChange() ~= 0 then return getText("IGUI_invpanel_Nutrition") .. ":" end
    return nil
end

function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)
    original(self, item, y, xoff, yoff, red)
    if not instanceof(item, "Food") or not EFE.canAge(item) or item:isFertilized() then return end
    local left = 40 + 30 + xoff
    -- vanilla bar position (drawTextAndProgressBar): label column of at least 120
    local column = 120
    local label = vanillaBarLabel(item)
    if label then
        column = math.max(column, 30 + getTextManager():MeasureStringX(self.font, label) + 20)
    end
    local width = column - 30 + self:getProgressBarWidth()
    local top = self.headerHgt + y * self.itemHgt + yoff + self.itemHgt - STRIP_HEIGHT - 1
    -- without the exact times, only the colour of the state
    local fraction = 1
    if EFE.canReadExact(item, getSpecificPlayer(self.player), EFE.requireTrait()) then
        fraction = EFE.freshFraction(item)
    end
    local done = math.floor(width * fraction)
    local c = EFE.COLORS[EFE.stage(item)]
    self:drawRect(left, top, done, STRIP_HEIGHT, 0.9, c[1], c[2], c[3])
    self:drawRect(left + done, top, width - done, STRIP_HEIGHT, 0.8, 0.25, 0.25, 0.25)
end
