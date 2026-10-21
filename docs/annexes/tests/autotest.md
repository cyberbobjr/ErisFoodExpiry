# Tests en jeu automatiques (pz-autotest)

Le mod se teste en vrai jeu, sans personne devant le PC, par le lanceur générique `pz-autotest`
(`.claude/tools/pz-autotest/README.md` du dossier `C:\Users\cyber\Zomboid\Workshop`).

| Fichier | Rôle |
| --- | --- |
| [`autotest.json`](../../../autotest.json) | Mods chargés (TooltipLib, dépendance `require=`, lu dans le Workshop Steam et copié ; puis le mod), sauvegarde solo, serveur et client MP. |
| [`autotest/efe_hooks.lua`](../../../autotest/efe_hooks.lua) | Parcours nominal exécuté côté client (solo et client MP 1). |

## Commandes

Depuis `C:\Users\cyber\Zomboid\Workshop` (un seul jeu à la fois : `--wait-idle` attend qu'aucun jeu ne tourne) :

```powershell
python .claude/tools/pz-autotest/pz_autotest.py check ErisFoodExpiry                    # configuration, mods, hooks
python .claude/tools/pz-autotest/pz_autotest.py sp    ErisFoodExpiry --wait-idle 3600   # client solo
python .claude/tools/pz-autotest/pz_autotest.py mp    ErisFoodExpiry --wait-idle 3600   # serveur dédié + 1 client (le client teste)
python .claude/tools/pz-autotest/pz_autotest.py sp    ErisFoodExpiry --dry-run --keep-cache   # préparation seule
luacheck autotest/efe_hooks.lua --config .luacheckrc                                     # depuis ErisFoodExpiry
```

Codes de sortie : 0 tout passe, 1 tests en échec, 2 délai / démarrage / erreur des hooks, 3 jeu déjà lancé.
Résultats : `ErisFoodExpiry/runs/<date>-<mode>-<jeton>/summary.txt` (ignoré par git), lignes `PASS`, `FAIL`, `INFO`.

## Ce que vérifie le parcours

Aliment de test `Base.Steak` (frais 2 jours, pourri à 4), créé puis retiré à la fin :

1. Stade du mod (frais, rassis, pourri) contre `Food.isFresh` / `isRotten` du jeu, à plusieurs âges.
2. Lignes de l'infobulle du fournisseur TooltipLib (« Stale in », « Rotten in », « Thawed in », « Paused »,
   « Frozen ») égales à la projection du mod.
3. Vieillissement réel par le moteur (`Food.updateAge`, `setLastAged` reculé de la durée projetée) : encore frais
   à 97 %, rassis (ou pourri) à 103 %, âge sur la cible à 100 %.

Cas : inventaire du joueur, réfrigérateur et congélateur créés par script (`ItemContainer.new` sur la case du
joueur : sans objet du monde, jamais alimentés ; générateur selon la case), aliment congelé dans l'inventaire et
dans le congélateur non alimenté, puis le réfrigérateur ou congélateur de la sauvegarde le plus proche (20 cases)
s'il existe. En MP, le test tourne sur le client (le serveur ne fait qu'héberger), qui recalcule lui-même l'âge des
aliments affichés. L'option du mod « temps exacts seulement si lisibles » cachée : la ligne d'état est vérifiée à
la place. Près de la coupure de courant (`ElecShutModifier`), le contrôle moteur du réfrigérateur est sauté
(ligne `INFO`).

Non couvert : rendu de l'infobulle et de la bande d'inventaire à l'œil, décongélation réelle (horloge de gel non
reculable depuis Lua), suppression des aliments pourris (`DaysForRottenFoodRemoval`).
