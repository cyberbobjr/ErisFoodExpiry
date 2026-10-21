# FAQ and compatibility

**Nothing appears in the tooltip.**
Check that TooltipLib is enabled. Without it the mod writes `[ErisFoodExpiry] TooltipLib missing: no expiry lines in tooltips` in `console.txt`.

**Can I use it with the original eris food expiry?**
No. Both originals use the mod ID `eris_food_expiry`, declared incompatible: enable only one of them.

**Does it work with other tooltip mods?**
The lines go through TooltipLib, which handles the layout with the other mods that use it. The mod draws no box of its own under the tooltip.

**Does it work with other inventory mods?**
The inventory strip wraps the vanilla `ISInventoryPane:drawItemDetails` and always calls the previous version first. A mod that replaces the inventory list completely may hide the strip.

**Why did the time change when I moved the food?**
The time is projected from where the food is now (floor, bag, fridge, freezer, stove…).

**Why does canned food say "Does not expire"?**
The game gives it no stale or rotten age.

**Which languages?**
English, French, German, Spanish, Italian, Polish, Portuguese, Brazilian Portuguese, Russian, Simplified Chinese.

**Where do I report a bug?**
On the [Discord](https://discord.gg/QEsBya7hUA) or on [GitHub](https://github.com/cyberbobjr/ErisFoodExpiry/issues).
