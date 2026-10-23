# Changelog

## Unreleased

### Added
- Fridges and freezers on grid power show "Power cut in", the time before the electricity shutoff stops them. In a freezer, frozen food then shows when it will go stale and rot after the shutoff and the thaw, instead of only "Frozen: not spoiling".
- Food being cooked shows "Cooking: times shown once cooked": cooking can change its times (rice and pasta pots start over).

### Changed
- The mod is now called "Food Expiry" everywhere: mod list, mod options and Workshop page.
- "Exact times need Nutritionist" option: without the exact times, the freshness bar is rounded to a third, the inventory strip shows only the colour, and rotten food shows "Will disappear" instead of an exact time.
- Without the exact times, the tooltip still tells when food is frozen, thawing, freezing, cooking or not spoiling where it is.

### Fixed
- The inventory strip now ends with the vanilla bar, whatever the language and font size.
- Split screen, "Exact times need Nutritionist" on: when the tooltip does not say which player reads it, the rough state is shown instead of exact times based on player 1's traits.

## 0.3.0 — 2026-10-21

### Fixed
- Fresh food put in a running freezer now shows "Frozen in" followed by "Frozen: not spoiling", instead of a far-off rotting date.
- Food that turns into another item instead of rotting (ice cream, sugar beet syrup) shows "Turns into <item> in" and no longer "Rotten in" or "Disappears in".
- Fertilized eggs show "Fertilized: does not expire", like the game, instead of a stale or rotten countdown.

## 0.2.0 — 2026-10-08

### Added
- Thawing food: "Thawed in" countdown, then the stale and rotten times counted from the end of thawing (faster near a heat source, slower in a running fridge).
- Rotten food: "Disappears in" when the sandbox Rotten Food Removal option is on. Not shown in a composter, which keeps it.

### Changed
- Frozen food in a running freezer shows a single line, "Frozen: not spoiling".
- Food that does not spoil where it is (fridge set to "No decay") shows a single line, "Not spoiling here".
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
