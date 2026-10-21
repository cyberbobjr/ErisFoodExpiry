# Spécifications techniques

Retour à l'[index](README.md). Vue d'ensemble : [architecture](architecture.md). Comportement visible : [spécifications fonctionnelles](specifications-fonctionnelles.md).

## Version et identifiants

| Élément | Valeur |
| --- | --- |
| Build cible | 42.21 (`versionMin=42.21`, variante unique `42.21/`) |
| ID du mod | `batman_ErisFoodExpiry` |
| Workshop | 3815719265, visibilité `unlisted`, titre « Food Expiry » |
| Version | `modversion=0.2.0` (CHANGELOG 0.2.0 du 2026-10-08) |
| Prérequis | `require=\TooltipLib` (Workshop 3694097672) |
| Incompatible | `incompatible=\eris_food_expiry` (Workshop 3392259028 et 3629527156) |
| Côté | client seulement (`media/lua/client`) |

## Objets, scripts, commandes réseau, ModData

- Aucun script d'objet, de recette ni de son.
- Aucune commande `sendClientCommand` / `sendServerCommand`, aucun abonnement à `Events.*`.
- ModData : **lecture seule** de la clé vanilla `NoLabel` de l'aliment (`item:getModData().NoLabel ~= nil` = étiquette illisible). Rien n'est écrit.
- Aucune option sandbox propre.

## Options sandbox vanilla lues

Lues par `getSandboxOptions():getOptionByName(nom):getValue()` à chaque calcul.

| Option | Valeur → effet dans la projection (`EFE_Core.lua`) |
| --- | --- |
| `FoodRotSpeed` (« Food Spoilage » : Very Fast … Very Slow) | 1 → ×1,7 ; 2 → ×1,4 ; 3 → ×1,0 ; 4 → ×0,7 ; 5 → ×0,4 ; autre ou absente → 1,0 (`Food.getFoodRotSpeed` 42.21) |
| `FridgeFactor` (« Refrigeration Effectiveness » : Very Low … No decay) | 1 → 0,4 ; 2 → 0,3 ; 3 → 0,2 ; 4 → 0,1 ; 5 → 0,03 ; 6 → 0,0 (aucune dégradation) ; autre → 0,2 (`Food.getFridgeFactor` 42.21) |
| `ElecShutModifier` (dérivé de « Electricity Shutoff ») | lu par `getSandboxOptions():getElecShutModifier()` : jour de coupure du réseau ; une valeur ≤ −1 désactive la période de réseau dans la projection |
| `DaysForRottenFoodRemoval` (« Rotten Food Removal ») | < 0 (ou absente) : pas de ligne « Disparaît dans » ; sinon nombre de jours après la pourriture |

## Projection des durées

Toutes les durées sont en **jours de jeu**. `NEVER = 1 000 000 000` (valeur par défaut d'`offAge`/`offAgeMax` d'un objet qui ne vieillit pas).

- `canAge(item)` : `getOffAgeMax() < NEVER`.
- `stage(item)` : `"rotten"` si `age >= offAgeMax`, `"stale"` si `age >= offAge`, sinon `"fresh"`.
- `freshFraction(item)` : `(offAgeMax − age) / offAgeMax`, bornée à [0, 1] ; 0 si `offAgeMax <= 0`.

### Vieillissement là où se trouve l'objet (`agingDays`, local)

Pour faire croître l'âge de `delta` à partir de `startDays` jours dans le futur, avec `rot = rotSpeed()` :

1. Conteneur le plus extérieur absent, ou ni réfrigérateur ni congélateur : `delta / rot`.
2. Sinon `cold = rot × fridgeFactor()`.
   - Case du conteneur avec `haveElectricity()` (générateur) : `delta / cold`, ou `nil` si `cold <= 0`.
   - Sinon, si `ElecShutModifier > −1` et `début = worldAgeHours / 24 + startDays < ElecShutModifier` : `gridDays = ElecShutModifier − début`, `gridAge = gridDays × cold` ; si `delta <= gridAge` → `delta / cold` (`nil` si `cold <= 0`), sinon `gridDays + (delta − gridAge) / rot`.
   - Sinon : `delta / rot`.

### Décongélation (`thawDays`)

`nil` si l'objet n'est pas congelé ou ne décongèle pas (`isThawing()` faux : congélateur en marche). Sinon `heures = 1,5`, ×2 si le conteneur est un réfrigérateur `isPowered()`, ÷6 si `getTemperature() > 1,0` ; résultat `getFreezingTime() / 100 × heures / 24` (d'après `Food.updateFreezing` 42.21).

### Échéance d'un âge (`daysUntil`)

`delta = cible − age` ; 0 si `delta <= 0`. Pour un objet congelé, `startDays = thawDays(item)` (`nil` → `nil`). Résultat `startDays + agingDays(item, delta, startDays)`, ou `nil` si l'objet n'atteint jamais la cible à cet endroit.

### Suppression d'un aliment pourri (`removalDays`)

`nil` si `DaysForRottenFoodRemoval < 0` ou si le parent du conteneur est un `IsoCompost` ; sinon `daysUntil(item, offAgeMax + DaysForRottenFoodRemoval)` (d'après `Food.updateRotting` 42.21).

### État approximatif (`stateKey`)

| Clé | Condition |
| --- | --- |
| `UI_EFE_StateRotten` | stade `rotten` |
| `UI_EFE_StateAlmostRotten` | stade `stale` et `offAgeMax > offAge` et `(age − offAge) / (offAgeMax − offAge) >= 0,5` |
| `UI_EFE_StateRotting` | stade `stale`, autres cas |
| `UI_EFE_StateVeryFresh` | stade `fresh`, `left > 2/3` avec `left = (offAge − age) / offAge` (0 si `offAge <= 0`) |
| `UI_EFE_StateFresh` | `left > 1/3` |
| `UI_EFE_StateOk` | sinon |

### Formatage (`formatDays(days, maxParts)`)

Arrondi à la minute (`floor(days × 1440 + 0,5)`), unités `UI_EFE_Years` (365 j), `UI_EFE_Months` (30 j), `UI_EFE_Weeks` (7 j), `UI_EFE_Days`, `UI_EFE_Hours`, `UI_EFE_Minutes` ; seules les unités non nulles, au plus `maxParts` (défaut `MAX_PARTS = 3`), séparées par une espace, au format `"<n> <unité traduite>"`. Zéro unité : `"< 1 " .. getText("UI_EFE_Minutes")`.

### Lecture des durées exactes (`canReadExact(item, character, requireTrait)`)

Vrai si `requireTrait` est faux ; faux sans personnage ; vrai avec `CharacterTrait.NUTRITIONIST` ou `CharacterTrait.NUTRITIONIST2` ; sinon il faut `item:isPackaged()`, pas `CharacterTrait.ILLITERATE`, pas `tooDarkToRead()` (pour un `IsoPlayer`) et `getModData().NoLabel == nil` (même règle que `Food.DoTooltip` pour le bloc nutritionnel).

## Fournisseur TooltipLib

```lua
TooltipLib.registerProvider({
    id = "batman_ErisFoodExpiry",
    target = "item",
    description = "UI_EFE_TooltipProvider",   -- clé, traduite par l'écran d'options
    enabled = function(item) return instanceof(item, "Food") end,
    callback = function(ctx) ... end,
})
```

Méthodes de `ctx` utilisées : `ctx.item`, `ctx.tooltip:getCharacter()` (repli `getSpecificPlayer(0)`), `ctx:addProgress(libellé, fraction, couleurLibellé, couleurBarre)`, `ctx:addKeyValue(clé, valeur, couleurClé, couleurValeur)`, `ctx:addLabel(texte, couleur)`. Ordre des lignes : voir [F01](specifications-fonctionnelles.md#f01--lignes-de-péremption-dans-linfobulle).

Couleurs (RGBA) : libellé `{1, 1, 0.8, 1}`, valeur `{0.9, 0.9, 0.9, 1}`, atténué `{0.65, 0.65, 0.65, 1}` ; stades `fresh {0.3, 0.85, 0.3, 1}`, `stale {1, 0.75, 0.2, 1}`, `rotten {0.9, 0.25, 0.2, 1}` (`EFE.COLORS`, partagés avec la bande d'inventaire).

Si `TooltipLib.registerProvider` n'est pas une fonction, le fichier écrit `[ErisFoodExpiry] TooltipLib missing: no expiry lines in tooltips` et s'arrête.

## Bande d'inventaire

`ISInventoryPane:drawItemDetails(item, y, xoff, yoff, red)` est remplacée par une enveloppe qui appelle d'abord la fonction capturée au chargement, puis, pour un `Food` avec `canAge` :

- `left = 40 + 30 + xoff`, `width = 120 − 30 + self:getProgressBarWidth()` (colonne de libellé vanilla de 120 px minimum + barre, comme `drawTextAndProgressBar`) ;
- `top = self.headerHgt + y × self.itemHgt + yoff + self.itemHgt − 2 − 1` ;
- partie remplie `floor(width × freshFraction)` dans la couleur du stade (alpha 0,9), reste gris `{0.25, 0.25, 0.25}` (alpha 0,8), hauteur `STRIP_HEIGHT = 2`.

Si `ISInventoryPane.drawItemDetails` n'existe pas au chargement : message `[ErisFoodExpiry] ISInventoryPane.drawItemDetails missing: no freshness strip`, pas d'enveloppe.

## Option de mod

```lua
EFE.options = PZAPI.ModOptions:create("batman_ErisFoodExpiry", "UI_EFE_Title")
EFE.options:addTickBox("RequireTrait", "UI_EFE_RequireTrait", false, "UI_EFE_RequireTrait_tooltip")
```

Créée une seule fois (garde `ErisFoodExpiry.options`). `EFE.requireTrait()` rend `true` seulement si l'option existe et vaut `true`. Valeur locale au client.

## API Lua `ErisFoodExpiry`

Table globale créée par `EFE_Core.lua` (`ErisFoodExpiry = ErisFoodExpiry or {}`). Usage interne ; aucune stabilité promise aux autres mods.

| Membre | Signature / valeur |
| --- | --- |
| `NEVER`, `MAX_PARTS`, `COLORS` | constantes ci-dessus |
| `rotSpeed()`, `fridgeFactor()` | facteurs sandbox |
| `canAge(item)`, `stage(item)`, `stateKey(item)`, `freshFraction(item)` | état de l'aliment |
| `thawDays(item)`, `daysUntil(item, targetAge)`, `removalDays(item)` | jours de jeu ou `nil` |
| `formatDays(days, maxParts)` | texte |
| `canReadExact(item, character, requireTrait)` | booléen |
| `options`, `requireTrait()` | définis par `EFE_Options.lua` |

## Traductions

`media/lua/shared/Translate/<LANGUE>/UI.json` (format JSON 42.21), langues `CN`, `DE`, `EN`, `ES`, `FR`, `IT`, `PL`, `PT`, `PTBR`, `RU`. Préfixe unique `UI_EFE_` ; 24 clés :

`UI_EFE_Title`, `UI_EFE_RequireTrait`, `UI_EFE_RequireTrait_tooltip`, `UI_EFE_TooltipProvider`, `UI_EFE_Freshness`, `UI_EFE_StaleIn`, `UI_EFE_RottenIn`, `UI_EFE_ThawedIn`, `UI_EFE_RemovedIn`, `UI_EFE_Paused`, `UI_EFE_Frozen`, `UI_EFE_NeverPerish`, `UI_EFE_StateVeryFresh`, `UI_EFE_StateFresh`, `UI_EFE_StateOk`, `UI_EFE_StateRotting`, `UI_EFE_StateAlmostRotten`, `UI_EFE_StateRotten`, `UI_EFE_Years`, `UI_EFE_Months`, `UI_EFE_Weeks`, `UI_EFE_Days`, `UI_EFE_Hours`, `UI_EFE_Minutes`.

`UI_EFE_Title`, `UI_EFE_RequireTrait`, `UI_EFE_RequireTrait_tooltip` et `UI_EFE_TooltipProvider` sont passés **en clé** (traduits par `MainOptions`) ; les autres sont traduits par `getText` à l'affichage. Messages console en anglais.

## Compatibilités vérifiées

- Statiquement : TooltipLib (API `registerProvider` et `ctx` utilisées par le code ; aucune copie de la bibliothèque dans le dépôt) ; enveloppe d'`ISInventoryPane:drawItemDetails` qui préserve l'appel précédent.
- Contrôles automatisés : `tests/run_tests.py` (voir [architecture](architecture.md#outillage)).
- Aucune validation en jeu n'est consignée dans ce dépôt en dehors des captures `images/screenshots/`.

## Points à confirmer

- Pas de dossier `common/` sous `Contents/mods/batman_ErisFoodExpiry/` : le mod est publié et chargé ainsi ; à confirmer si un `common/` vide devient nécessaire pour l'outillage ou le jeu.
