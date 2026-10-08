-- ============================================================================
-- Eris Food Expiry (batman fork) — mod options
-- ============================================================================

require "ErisFoodExpiry/EFE_Core"

local EFE = ErisFoodExpiry

if not EFE.options and PZAPI and PZAPI.ModOptions then
    EFE.options = PZAPI.ModOptions:create("batman_ErisFoodExpiry", getText("UI_EFE_Title"))
    EFE.options:addTickBox("RequireTrait", getText("UI_EFE_RequireTrait"), false, getText("UI_EFE_RequireTrait_tooltip"))
end

function EFE.requireTrait()
    local option = EFE.options and EFE.options:getOption("RequireTrait")
    return option ~= nil and option:getValue() == true
end
