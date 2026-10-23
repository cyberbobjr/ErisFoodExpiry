-- Luacheck: Lua 5.1, the language of Kahlua (Project Zomboid).
std = "lua51"
-- Globals written by the mod: its table and the vanilla method it wraps.
globals = { "ErisFoodExpiry", "ISInventoryPane" }
-- Game and library API read by the mod: anything else is a typo.
read_globals = {
    "CharacterTrait", "PZAPI", "TooltipLib",
    "getGameTime", "getSandboxOptions", "getScriptManager", "getSpecificPlayer", "getText",
    "getTextManager", "getTimestampMs", "instanceof",
}
-- The in-game test hooks (pz-autotest) use much more of the game API.
files["autotest/**"] = { global = false }
-- Vanilla signatures often impose unused parameters.
unused_args = false
codes = true
max_line_length = 130
