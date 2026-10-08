# Eris Food Expiry (TooltipLib fork)

Project Zomboid Build 42.21 mod: food freshness and the exact time before it goes stale and rots, in the item tooltip (through [TooltipLib](https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672)) and as a thin strip in the expanded inventory list.

Fork of two Workshop items, both with mod ID `eris_food_expiry` (declared `incompatible=`):
- [[B42] eris food expiry](https://steamcommunity.com/sharedfiles/filedetails/?id=3392259028)
- [[B42.13] eris food expiry](https://steamcommunity.com/sharedfiles/filedetails/?id=3629527156)

Mod ID `batman_ErisFoodExpiry`, requires `TooltipLib`. Published unlisted on the Steam Workshop.

## Layout
- `EFE_Core.lua`: spoilage projection after `Food.updateAge` (42.21) and time formatting.
- `EFE_Tooltip.lua`: TooltipLib provider.
- `EFE_InventoryBar.lua`: freshness strip after vanilla `ISInventoryPane:drawItemDetails`.
- `EFE_Options.lua`: mod option `RequireTrait`.
- `docs/steam/`: illustrations of the Workshop page (linked from `README.steam*`).

## Multiplayer
Client only. The client recomputes the age of displayed food itself (`ISInventoryPane` calls `updateAge`), sandbox values come from the server. No network command, no saved data.

## Tests
`python tests/run_tests.py` (lupa, translations, Workshop descriptions, project validation).

## Licence
MIT for this rewritten code and the illustrations (see LICENSE). The idea and the name come from eris's mod; the originals state no licence and none of their files are included.
