-- ============================================================================
-- Eris Food Expiry (batman fork) — freshness strip in the expanded item list
--
-- The original drew a second text line in the same row (itemHgt fits one
-- line) and shifted the vanilla line up by half a font height: both texts
-- overlapped. The vanilla detail line (nutrition, cooking, freezing) is kept
-- untouched; a thin freshness strip is drawn along the bottom of the row.
-- ============================================================================

require "ISUI/ISInventoryPane"
require "ErisFoodExpiry/EFE_Core"

local EFE = ErisFoodExpiry

local STRIP_HEIGHT = 2
local BACKGROUND = { r = 0.25, g = 0.25, b = 0.25, a = 0.8 }

local original = ISInventoryPane.drawItemDetails
if not original then
    print("[ErisFoodExpiry] ISInventoryPane.drawItemDetails missing: no freshness strip")
    return
end

function ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)
    original(self, item, y, xoff, yoff, red)
    if not instanceof(item, "Food") or not EFE.canAge(item) then return end
    local fraction = EFE.freshFraction(item)
    local left = 40 + 30 + xoff
    -- vanilla label column (min 120) + progress bar, as in drawTextAndProgressBar
    local width = 120 - 30 + self:getProgressBarWidth()
    local top = self.headerHgt + y * self.itemHgt + yoff + self.itemHgt - STRIP_HEIGHT - 1
    local done = math.floor(width * fraction)
    -- green while fresh, orange once stale, red near the end
    local r, g
    if item:getAge() < item:getOffAge() then
        r, g = 0.3, 0.85
    elseif fraction > 0.1 then
        r, g = 1, 0.6
    else
        r, g = 0.9, 0.25
    end
    self:drawRect(left, top, done, STRIP_HEIGHT, 0.9, r, g, 0.2)
    self:drawRect(left + done, top, width - done, STRIP_HEIGHT, BACKGROUND.a, BACKGROUND.r, BACKGROUND.g, BACKGROUND.b)
end
