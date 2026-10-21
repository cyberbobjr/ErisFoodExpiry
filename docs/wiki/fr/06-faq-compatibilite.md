# FAQ et compatibilité

**Rien n'apparaît dans l'infobulle.**
Vérifiez que TooltipLib est activé. Sans lui, le mod écrit `[ErisFoodExpiry] TooltipLib missing: no expiry lines in tooltips` dans `console.txt`.

**Puis-je l'utiliser avec l'eris food expiry d'origine ?**
Non. Les deux mods d'origine utilisent l'ID `eris_food_expiry`, déclaré incompatible : n'en activez qu'un.

**Fonctionne-t-il avec d'autres mods d'infobulle ?**
Les lignes passent par TooltipLib, qui gère la mise en page avec les autres mods qui l'utilisent. Le mod ne dessine aucun cadre propre sous l'infobulle.

**Fonctionne-t-il avec d'autres mods d'inventaire ?**
La bande d'inventaire enveloppe `ISInventoryPane:drawItemDetails` vanilla et appelle toujours d'abord la version précédente. Un mod qui remplace entièrement la liste d'inventaire peut masquer la bande.

**Pourquoi la durée a-t-elle changé quand j'ai déplacé l'aliment ?**
La durée est projetée depuis l'endroit où se trouve l'aliment (sol, sac, réfrigérateur, congélateur, cuisinière…).

**Pourquoi une conserve indique-t-elle « Ne se périme jamais » ?**
Le jeu ne lui donne aucun âge de péremption ni de pourriture.

**Quelles langues ?**
Anglais, français, allemand, espagnol, italien, polonais, portugais, portugais du Brésil, russe, chinois simplifié.

**Où signaler un bogue ?**
Sur le [Discord](https://discord.gg/QEsBya7hUA) ou sur [GitHub](https://github.com/cyberbobjr/ErisFoodExpiry/issues).
