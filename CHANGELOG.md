# Changelog

## 0.1.1 — 2026-10-08

### Changed
- Option names, tooltips and the TooltipLib entry are translated by the game's options screen, like vanilla options. No visible change.
- Same freshness colours in the tooltip and in the inventory strip (green fresh, orange stale, red rotten).

## 0.1.0 — 2026-10-08

### First release
Fork of [B42] eris food expiry (Workshop 3392259028) and [B42.13] eris food expiry (Workshop 3629527156), rewritten for Build 42.21. Both originals use the mod ID `eris_food_expiry`: enable only one of the three.

### Added
- Expiry lines in the item tooltip through TooltipLib (required): freshness bar, "Stale in", "Rotten in", "Frozen: not spoiling", "Does not expire".
- Option (Options > Mods): require the Nutritionist trait for exact times; a readable package always shows them. Otherwise a rough state is shown.
- Thin freshness strip under each food in an expanded inventory stack.
- Translations: English, French, German, Spanish, Italian, Polish, Portuguese, Brazilian Portuguese, Russian, Simplified Chinese.

### Fixed (compared with the originals)
- Times follow the game's food aging: sandbox Food Spoilage and Refrigeration Effectiveness, fridge or freezer powered by a generator or by the grid until the shutoff day, frozen food paused, each item's own stale and rotten ages (cooked food).
- Time units always shown largest first (the originals could show "5m 2d 1w" or drop the years).
- The "Rotten" state label shows again.
- Option texts and translations load in 42.21 (JSON instead of the old .txt files).
- No more box drawn under the tooltip nor tooltip moving every frame.
- The inventory strip no longer overlaps the vanilla nutrition or cooking line.
- No error every frame with the old "Verbose" option (removed with the "Resolution" option, which only placed the old box).

### Multiplayer
- Display only, on each client: nothing is sent to the server, nothing is saved. Safe to add to or remove from an existing world.
