# Architecture

Retour à l'[index](README.md). Les contrats détaillés (formules, signatures, clés) sont dans les [spécifications techniques](specifications-techniques.md).

## Vue d'ensemble

Le mod est **purement client et en lecture seule** : il lit l'état d'un aliment (`Food`) et de son conteneur, projette le temps restant avant péremption et pourriture avec les mêmes règles que `Food.updateAge` (42.21), puis l'affiche à deux endroits :

```
                ┌──────────────────────┐
                │ EFE_Core.lua         │  projection, états, formatage
                │ (table ErisFoodExpiry)│  lecture sandbox, GameTime, conteneur
                └──────────┬───────────┘
           ┌───────────────┼────────────────────┐
           ▼               ▼                    ▼
 EFE_Options.lua    EFE_Tooltip.lua      EFE_InventoryBar.lua
 PZAPI.ModOptions   fournisseur          enveloppe de
 (RequireTrait)     TooltipLib (item)    ISInventoryPane:drawItemDetails
                           │                    │
                           ▼                    ▼
                  infobulle d'objet     bande de 2 px dans la
                  (lignes TooltipLib)   liste dépliée de l'inventaire
```

Aucune commande réseau, aucune donnée sauvegardée, aucun événement Lua (`Events.*`) n'est utilisé.

## Arborescence du projet

```
ErisFoodExpiry/
├── README.md, CHANGELOG.md, LICENSE (MIT)
├── workshop.txt, preview.png, README.steam* (descriptions Workshop, 9 langues)
├── .luacheckrc, .gitattributes, .gitignore
├── tests/run_tests.py
├── docs/ (cette documentation)
└── Contents/mods/batman_ErisFoodExpiry/
    └── 42.21/
        ├── mod.info, icon.png, poster.png
        └── media/lua/
            ├── client/ErisFoodExpiry/
            │   ├── EFE_Core.lua
            │   ├── EFE_Options.lua
            │   ├── EFE_Tooltip.lua
            │   └── EFE_InventoryBar.lua
            └── shared/Translate/<LANGUE>/UI.json   (CN, DE, EN, ES, FR, IT, PL, PT, PTBR, RU)
```

Une seule variante, `42.21` ; il n'existe pas de dossier `common/` (voir les points à confirmer des [spécifications techniques](specifications-techniques.md#points-à-confirmer)).

### `mod.info`

| Clé | Valeur |
| --- | --- |
| `id` | `batman_ErisFoodExpiry` |
| `name` | `batman_Eris Food Expiry (TooltipLib fork)` |
| `require` | `\TooltipLib` |
| `incompatible` | `\eris_food_expiry` (ID commun aux deux mods d'origine) |
| `versionMin` | `42.21` |
| `modversion` | `0.2.0` |
| `loadModAfter` | absent |

## Modules Lua

Tous les fichiers sont sous `media/lua/client/ErisFoodExpiry/` : rien n'est chargé par un serveur dédié.

| Module | Responsabilité | `require` |
| --- | --- | --- |
| `EFE_Core.lua` | Crée la table globale `ErisFoodExpiry` (alias local `EFE`). Lit les options sandbox, projette les durées (`daysUntil`, `thawDays`, `removalDays`), calcule le stade (`stage`), l'état approximatif (`stateKey`), la fraction de fraîcheur, formate les durées et décide si le personnage peut lire les durées exactes (`canReadExact`). | aucun |
| `EFE_Options.lua` | Crée l'option de mod `RequireTrait` par `PZAPI.ModOptions` (une seule fois, garde `EFE.options`) et expose `EFE.requireTrait()`. | `ErisFoodExpiry/EFE_Core` |
| `EFE_Tooltip.lua` | Enregistre le fournisseur TooltipLib `batman_ErisFoodExpiry` (cible `item`, aliments seulement) qui ajoute la barre de fraîcheur et les lignes de durée. S'arrête avec un message console si TooltipLib manque. | `TooltipLib/Core`, `ErisFoodExpiry/EFE_Core`, `ErisFoodExpiry/EFE_Options` |
| `EFE_InventoryBar.lua` | Enveloppe `ISInventoryPane:drawItemDetails` : appelle d'abord la version précédente, puis trace une bande de fraîcheur de 2 px au bas de la ligne d'un aliment périssable. S'arrête avec un message console si la fonction vanilla manque. | `ISUI/ISInventoryPane`, `ErisFoodExpiry/EFE_Core` |

## Flux de données

1. **Lecture** à chaque affichage : `Food:getAge()`, `getOffAge()`, `getOffAgeMax()`, `isFrozen()`, `isThawing()`, `getFreezingTime()`, `isPackaged()`, `getModData().NoLabel` ; conteneur le plus extérieur (`getOutermostContainer`) : `isFridge`, `isFreezer`, `isPowered`, `getTemperature`, `getSourceGrid():haveElectricity()`, `getParent()` (composteur) ; options sandbox `FoodRotSpeed`, `FridgeFactor`, `DaysForRottenFoodRemoval`, `getElecShutModifier()` ; `getGameTime():getWorldAgeHours()`.
2. **Projection** par `EFE_Core` (formules dans les [spécifications techniques](specifications-techniques.md#projection-des-durées)).
3. **Affichage** : lignes TooltipLib (`addProgress`, `addKeyValue`, `addLabel`) et `drawRect` dans le panneau d'inventaire.

**Multijoueur** : l'autorité reste au jeu. Le client recalcule lui-même l'âge des aliments affichés (`ISInventoryPane` appelle `updateAge`) et reçoit les options sandbox du serveur ; le mod ne fait que lire ces valeurs locales.

## Persistance

Aucune : pas de ModData écrite (seule la clé vanilla `NoLabel` est lue), pas de fichier, pas de ModData globale. L'option `RequireTrait` est enregistrée par le jeu avec les options de mod du client. Le mod peut être ajouté ou retiré d'une partie existante.

## Intégrations et points d'extension

- **TooltipLib** (Workshop 3694097672, ID `TooltipLib`, prérequis) : le mod n'en contient aucune copie ; il utilise `TooltipLib.registerProvider` et l'objet `ctx` du rappel. La bibliothèque gère le dessin et la cohabitation avec les autres mods d'infobulle.
- **Mods d'origine** `eris_food_expiry` : déclarés `incompatible=` ; le sélecteur de mods du jeu empêche leur activation simultanée.
- **Autres mods qui enveloppent `ISInventoryPane:drawItemDetails`** : l'enveloppe appelle toujours la fonction précédente (capturée au chargement du fichier) avec les mêmes arguments.
- **API Lua** : la table globale `ErisFoodExpiry` est accessible aux autres mods, mais aucune stabilité n'est promise (voir les [spécifications techniques](specifications-techniques.md#api-lua-erisfoodexpiry)).

## Outillage

- `tests/run_tests.py` (Python) :
  - contrôles Lua sous `lupa` avec des doublures minimales de l'API Java 42.21 (projection, fridge, coupure du réseau, congélation, décongélation, suppression des aliments pourris, composteur, formatage, états, lecture des étiquettes, lignes de l'infobulle, bande d'inventaire) ; ignorés si `lupa` est absent ;
  - traductions : chaque clé `UI_EFE_*` citée par le Lua existe dans chaque `UI.json` ;
  - descriptions Workshop : taille UTF-8 (8 000 octets moins le suffixe ajouté à l'envoi), balises BBCode équilibrées, mêmes liens et images dans tous les `README.steam*`, images `raw.githubusercontent.com/…/main/…` présentes dans le dépôt ;
  - validation du projet par `Workshop/.claude/tools/pz_workshop_project.py` si présent (titre, visibilité, étiquettes, `preview.png`, `mod.info`, `workshop.txt` identique à `README.steam`).
- `.luacheckrc` : Lua 5.1, globales non contrôlées, lignes de 130 caractères.
- Pas de CI (`.github/` absent).
