# Food Expiry — documentation

Mod Project Zomboid Build 42.21 (`batman_ErisFoodExpiry`, Workshop 3815719265, non répertorié) : fraîcheur des aliments et temps exact avant péremption et pourriture, dans l'infobulle (par TooltipLib) et en fine bande dans la liste dépliée de l'inventaire. Fork réécrit des deux objets Workshop « eris food expiry » (3392259028 et 3629527156).

La présentation GitHub (anglais) est dans le [README](../README.md) racine, l'historique des versions dans le [CHANGELOG](../CHANGELOG.md).

| Document | Rôle |
| --- | --- |
| [architecture.md](architecture.md) | Architecture logicielle : arborescence du mod, modules Lua, flux, persistance, intégrations, outillage. |
| [specifications-fonctionnelles.md](specifications-fonctionnelles.md) | Ce que voit le joueur : lignes de l'infobulle, bande d'inventaire, option, effets des options sandbox, solo/MP, limites (F01…). |
| [specifications-techniques.md](specifications-techniques.md) | Contrats précis : formules de projection, API Lua `ErisFoodExpiry`, fournisseur TooltipLib, option, clés de traduction, contraintes de version. |
| [ameliorations-et-idees.md](ameliorations-et-idees.md) | Améliorations de code proposées et idées de fonctionnalités (propositions, sans autorisation d'implémentation). |
| [wiki/](wiki/) | Source du wiki GitHub : guides joueur et administrateur en anglais ([wiki/en/Home.md](wiki/en/Home.md)) et en français ([wiki/fr/Home.md](wiki/fr/Home.md)). |
| [images/](images/) | Images de la documentation et de la page Workshop : `screenshots/` (captures en jeu), `art/` (illustrations). |

## Images

| Fichier | Contenu | Utilisé par |
| --- | --- | --- |
| [images/screenshots/05-tooltip-fridge.png](images/screenshots/05-tooltip-fridge.png) | Infobulle d'un steak haché dans un réfrigérateur : fraîcheur, « Stale in », « Rotten in ». | `README.steam*`, `workshop.txt`, wiki |
| [images/screenshots/06-tooltip-thawing.png](images/screenshots/06-tooltip-thawing.png) | Infobulle d'un steak congelé en train de décongeler : « Thawed in », puis les durées. | `README.steam*`, `workshop.txt`, wiki |
| [images/art/02-fridge.jpg](images/art/02-fridge.jpg) | Illustration : réfrigérateur alimenté par un générateur. | `README.steam*`, `workshop.txt` |
| [images/art/03-frozen.jpg](images/art/03-frozen.jpg) | Illustration : viande congelée, horloge en pause. | `README.steam*`, `workshop.txt` |
| [images/art/04-read-the-label.jpg](images/art/04-read-the-label.jpg) | Illustration : lire l'étiquette des aliments. | `README.steam*`, `workshop.txt` |

Les URL des images de la page Workshop pointent vers `https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/docs/images/…` : elles ne s'affichent qu'une fois ce chemin poussé sur `main`. `tests/run_tests.py` vérifie que chaque image citée par `README.steam` existe dans le dépôt.
