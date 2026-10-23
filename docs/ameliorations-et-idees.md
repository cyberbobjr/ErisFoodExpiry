# Food Expiry (batman_ErisFoodExpiry) : améliorations et idées

- **Mod** : Food Expiry, fork d'Eris Food Expiry pour TooltipLib (Workshop 3815719265, non répertorié)
- **`id`** : `batman_ErisFoodExpiry` (`require=\TooltipLib`, `incompatible=\eris_food_expiry`, `versionMin=42.21`)
- **Version analysée** : 0.2.0 (CHANGELOG du 2026-10-08, `modversion=0.2.0`)
- **Date de l'analyse** : 2026-10-21
- **Build cible** : 42.21. Sources comparées : Java décompilé `E:\pz-decompiled\42.21.0\java`, Lua et scripts vanilla `D:\SteamLibrary\steamapps\common\ProjectZomboid\media`, TooltipLib 1.7.0 (Workshop 3694097672, variante `42`, lue sans rien modifier).
- **Périmètre** : `Contents/mods/batman_ErisFoodExpiry/42.21/` (4 fichiers Lua, 10 `UI.json`, `mod.info`), `README.md`, `CHANGELOG.md`, `README.steam*`, `workshop.txt`, `.luacheckrc`, `tests/run_tests.py`, `docs/steam/`. Base moteur consultée : `api-42-21.md` (vieillissement des aliments), `multiplayer.md` (âge recalculé par le client), `power-and-lights.md` (coupure du réseau), `mod-loading.md`.
- **État constaté** : `python tests/run_tests.py` affiche `OK` et `luacheck` ne signale aucun avertissement (0 sur 4 fichiers). Aucun test en jeu n'a été fait pour cette analyse.

Légende du statut : **confirmé statiquement** (lecture du code du mod et du Java ou Lua vanilla 42.21) ; **à vérifier en jeu** (déduction ou comportement qui dépend de l'exécution).

---

## Partie 1 : améliorations de code

### C01 : un aliment mis dans un congélateur alimenté n'est pas projeté comme « bientôt congelé »
- **Problème** : un aliment frais (`isFrozen()` faux) posé dans un congélateur alimenté gèle en 4 h de jeu au plus, puis ne vieillit plus. Le mod applique le facteur froid à toute la durée restante et affiche par exemple « Pourri dans 25 j ». Le joueur pense donc que la viande pourrira au congélateur.
- **Preuve** :
  - `EFE_Core.lua:86-97` : `daysUntil` ne traite que `isFrozen()`.
  - `EFE_Core.lua:44-68` : `agingDays` ne connaît que le froid ou la vitesse normale.
  - `Food.java:1990-1996` : `isFreezing()` vrai si `canBeFrozen`, `freezingTime < 100`, congélateur et `isPowered()`.
  - `Food.java:758-761` : `freezingTime += heures / 4 × 100`.
  - `Food.java:1959-1962` : `frozen` ne passe à vrai qu'à 100.
  - `Food.java:686-687` : aucun vieillissement une fois congelé.
- **Risque** : bug d'affichage (durée très surestimée), le plus visible du mod. C'est un usage courant (congélateur au début de la partie).
- **Correction** : dans `daysUntil`, si `not item:isFrozen() and item:isFreezing()`, calculer `freezeDays = (100 - getFreezingTime()) / 100 × 4 / 24`. Si la cible est atteinte pendant ce temps (`agingDays` limité à `freezeDays`), rendre cette durée ; sinon rendre `nil`. Dans l'infobulle, afficher « Congelé dans 2 h 10 min » puis « Ne s'abîme pas une fois congelé ». Il faut une nouvelle clé `UI_EFE_FrozenIn`, traduite dans les 10 langues. Ajouter un test lupa qui reproduit `isFreezing` du Java. Un aliment `CantBeFrozen` (51 dans `food.txt`) garde le facteur froid.
- **Statut : corrigé (commit d7e1955), à vérifier en jeu** (confirmé statiquement ; durée affichée à contrôler en jeu).
- **Priorité** : haute. **Effort** : S.

### C02 : aliments `ReplaceOnRotten` présentés comme « Pourri dans » et « Disparaît dans »
- **Problème** : sept objets vanilla ne pourrissent pas. Arrivés à `offAgeMax`, ils sont remplacés par un autre objet : les glaces et esquimaux deviennent leur version fondue, et le sirop de betterave devient du sucre. Le mod affiche « Pourri dans » et, si l'option sandbox est active, « Disparaît dans ». Pour le sirop, l'infobulle annonce donc la perte d'un produit que le joueur attend.
- **Preuve** :
  - `scripts/generated/items/food.txt:599` (`SugarBeetSyrupPot` → `SugarBeetSugarPot`), puis `:12425`, `:12464`, `:12486`, `:12539`, `:12561`, `:12582`, `:12604` (glaces).
  - `Food.java:597-623` : remplacement par `ReplaceOnRotten` avant la disparition.
  - `Food.java:2075` : `getReplaceOnRotten()`.
  - `EFE_Tooltip.lua:58-71`.
- **Risque** : bug d'affichage et texte trompeur.
- **Correction** : si `item:getReplaceOnRotten()` n'est pas vide, remplacer « Pourri dans » par « Se transforme dans » suivi du nom du remplaçant. Le nom s'obtient par `getScriptManager():FindItem(module .. "." .. nom):getDisplayName()`, déjà traduit sur le client. Ne pas afficher « Disparaît dans » ni l'état « Pourri » pour ces objets. Nouvelle clé `UI_EFE_TurnsInto`.
- **Statut : corrigé (commit d7e1955), à vérifier en jeu**.
- **Priorité** : moyenne. **Effort** : S.

### C03 : l'état est recalculé au lieu de lire `isFresh()` / `isRotten()` (œufs fécondés)
- **Problème** : `EFE.stage` compare `getAge()` aux seuils. Pour un œuf fécondé, le Java considère l'œuf toujours frais et jamais pourri. Le mod lui donne pourtant la couleur orange ou rouge, l'état « Pourri » et un compte à rebours.
- **Preuve** :
  - `EFE_Core.lua:118-123`, `:126-140`.
  - `Food.java:1653-1665` : `isRotten()` et `isFresh()` rendent `false` et `true` si `isFertilized()`.
- **Risque** : bug d'affichage sur l'élevage (B42).
- **Correction** : faire reposer `stage` sur `item:isRotten()` et `item:isFresh()`. Pour un œuf fécondé, afficher une ligne « Fécondé : ne se périme pas » sans compte à rebours. La durée avant l'éclosion n'est pas calculable : seul `getTimeToHatch()` est public, `fertilizedTime` n'a pas de getter (`Food.java:2183-2210`). La disparition d'un œuf fécondé pourri (`Food.java:626-637` ne teste pas `isFertilized`) est à vérifier en jeu.
- **Statut : corrigé (commit d7e1955), à vérifier en jeu** (confirmé statiquement pour l'état ; disparition à vérifier en jeu).
- **Priorité** : moyenne. **Effort** : S.

### C04 : « Congelé : ne s'abîme pas » au congélateur branché sur le réseau, sans parler de la coupure
- **Problème** : au congélateur alimenté par le réseau, l'infobulle dit « ne s'abîme pas » sans limite de temps. À la coupure de l'électricité, l'aliment dégèle en 1,5 h, puis vieillit à vitesse normale. Autre point : la coupure réelle et le changement de vitesse de vieillissement ne tombent pas le même jour.
  - La coupure réelle (`isPowered`, `doesPowerGridExist`) compare `getWorldAgeDaysSinceBegin()`, qui inclut `(TimeSinceApo - 1) × 30`.
  - Le vieillissement compare `getWorldAgeHours()` à `ElecShutModifier × 24`.
  - Si `TimeSinceApo > 1`, le congélateur s'arrête donc avant le jour retenu par `agingDays`.
- **Preuve** :
  - `EFE_Tooltip.lua:49-54`, `EFE_Core.lua:56-66`.
  - `GameTime.java:826-834`.
  - `SandboxOptions.java:1230-1231`.
  - `Food.java:691-696`.
  - `ItemContainer.java:2218-2220`, `:2280-2281`.
- **Risque** : information trompeuse juste avant la coupure, qui est justement le moment où le joueur en a besoin.
- **Correction** : avec un courant du réseau seulement (pas de générateur, `doesPowerGridExist()` vrai), ajouter « Courant coupé dans X ». Calculer X depuis `ElecShutModifier - getWorldAgeDaysSinceBegin()`, la même formule que la coupure réelle, puis donner la durée de décongélation et le temps restant ensuite. Garder la formule de `Food.updateAge` pour la vitesse de vieillissement, et écrire dans un commentaire que le moteur utilise deux horloges différentes. Voir aussi I01.
- **Statut : abandonné** (décision du 2026-10-23 : annoncer la coupure, ou une échéance calculée d'après elle, est de la triche ; le jeu tire ce jour au hasard et le garde caché). La ligne « Courant coupé dans » et la projection au congélateur après la coupure ont été retirées ; la projection au réfrigérateur sur le réseau ne se sert plus du jour de coupure (facteur froid tant que le réseau ralentit le vieillissement, correction à l'affichage suivant la coupure) ; l'écart des deux horloges reste documenté dans la base moteur.
- **Priorité** : moyenne. **Effort** : M.

### C05 : le mode « durées exactes avec Nutritionniste » laisse passer des valeurs exactes
- **Problème** : quand l'option est active et que l'emballage est illisible, le mod n'affiche qu'un état approximatif. Pourtant, trois éléments restent exacts :
  - la barre « Fraîcheur » donne la proportion exacte (`addProgress` toujours appelé) ;
  - la bande de l'inventaire est toujours dessinée ;
  - « Disparaît dans » reste exact (le test l'attend ainsi).
- **Preuve** :
  - `EFE_Tooltip.lua:42` (barre), `:44-47` (état et disparition).
  - `EFE_InventoryBar.lua:21-33` (aucun test de l'option).
  - `tests/run_tests.py:256-259`.
- **Risque** : incohérence de jeu. L'option perd une partie de son sens.
- **Correction** : à décider par l'utilisateur. Une piste : en mode approximatif, arrondir la barre au tiers (1/3, 2/3, 1), qui correspond aux seuils de `stateKey`. Pour la bande de l'inventaire, n'afficher que la couleur. « Disparaît dans » pourrait devenir « Va bientôt disparaître ».
- **Statut : corrigé, à vérifier en jeu** (options appliquées : barre arrondie au tiers supérieur, bande d'inventaire entièrement de la couleur du stade, « Va disparaître » sans durée ; tests lupa).
- **Priorité** : basse (choix de conception). **Effort** : S.

### C06 : le mode approximatif masque l'état congelé, en pause ou en décongélation
- **Problème** : sans durée exacte, l'infobulle sort à la ligne 47 avant de traiter le gel. Un joueur sans le trait voit « Très frais » sur une viande congelée ou dans un frigo réglé sur « aucune dégradation ».
- **Preuve** : `EFE_Tooltip.lua:44-48`, puis `:49-56` et `:64-66`, jamais atteintes dans ce mode.
- **Risque** : information de jeu perdue. Le vanilla montre pourtant la barre de congélation à tout le monde.
- **Correction** : afficher « Congelé », « Décongèle » ou « Ne s'abîme pas ici » avant de sortir, sans durée.
- **Statut : corrigé, à vérifier en jeu** (`EFE.conditionKey` : « Congelé : ne s'abîme pas », « Décongélation en cours », « Congélation en cours », « Cuisson… », « Ne s'abîme pas ici » après l'état approximatif ; tests lupa).
- **Priorité** : basse. **Effort** : S.

### C07 : la bande de l'inventaire se décale par rapport à la barre vanilla
- **Problème** : la bande est placée pour une colonne de libellé de 120 px. Le vanilla décale sa barre à `40 + max(120, 30 + largeur du texte + 20)`. Avec un libellé long, la bande s'arrête avant la fin de la barre vanilla : « Nutrition : » ou « Congélation : » selon la langue, une grande police, ou les libellés de cuisson. La largeur de la barre vanilla est aussi supposée fixe.
- **Preuve** : `EFE_InventoryBar.lua:25-27` ; `ISInventoryPane.lua:2640-2643`, `:2615-2617`, `:2682-2688`.
- **Risque** : défaut visuel qui dépend de la langue et de la police.
- **Correction** : recalculer le décalage du libellé vanilla de la même branche. Plus simple et plus stable : tracer la bande sur une largeur fixe depuis `40 + 30 + xoff` jusqu'à `self.column3 - 8`, sans chercher à s'aligner sur la barre.
- **Statut : corrigé, à vérifier en jeu** (libellé de la barre vanilla recalculé dans la même branche que `drawItemDetails`, bande jusqu'à la fin de la barre ; rendu à contrôler en FR, DE et RU, police Large).
- **Priorité** : basse. **Effort** : S.

### C08 : `formatDays` peut associer des unités éloignées et donne une fausse précision
- **Problème** : `formatDays` garde les trois unités non nulles les plus grandes, même si elles ne se suivent pas. On peut donc lire « 1 an 5 min » ou « 2 sem 3 h ». Pour une projection de plusieurs semaines, les minutes n'ont pas de sens. Autres points :
  - le préfixe « < 1 » et l'ordre « nombre espace unité » sont écrits en dur ;
  - le chinois reçoit « 3 天 » avec une espace qu'il n'utilise pas.
- **Preuve** : `EFE_Core.lua:162-178`, en particulier `:172` et `:176` ; `tests/run_tests.py:185-187` (le test attend « 1 j 5 min »).
- **Risque** : lisibilité et traduction.
- **Correction** :
  - ne garder que deux unités consécutives (« 2 sem 3 j », « 5 h 20 min ») et arrondir la dernière ;
  - ajouter une clé de format `UI_EFE_Amount` = `%1 %2` (CN `%1%2`) et une clé `UI_EFE_LessThan` ;
  - mettre le test à jour.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : S.

### C09 : la cuisson qui remet l'âge à zéro n'est pas prise en compte
- **Problème** : dans un four, certains plats changent de seuils une fois cuits. Les marmites et poêles de riz ou de pâtes repartent à `age = 0`, `offAge = 1`, `offAgeMax = 2`, et d'autres objets sont remplacés via `ReplaceOnCooked`. Pendant la cuisson, l'infobulle montre donc une durée qui va changer. Le vanilla dessine déjà sa barre « Cuisson » dans la liste.
- **Preuve** : `Food.java:353-410`, notamment `:403-407` et `:375-397`.
- **Risque** : faible, mais la durée affichée est trompeuse quelques minutes.
- **Correction** : quand `isCookable() and getHeat() > 1.6 and not isCooked()`, remplacer les durées par « En cuisson » (voir I12 pour un compte à rebours).
- **Statut : corrigé, à vérifier en jeu** (`EFE.isCooking` = test de la barre vanilla « Cuisson », ni cuit ni brûlé : « Cuisson : durées affichées une fois cuit » à la place des durées).
- **Priorité** : basse. **Effort** : S.

### C10 : générateur vu par un client multijoueur
- **Problème** : `agingDays` appelle `getSourceGrid():haveElectricity()` sur le client. Ce test lit les positions de générateur du chunk client (`IsoChunk.isGeneratorPoweringSquare`). Si cette liste diffère de celle du serveur juste après la pose ou le retrait d'un générateur, la projection du client se trompe jusqu'au chargement suivant. L'âge réel est calculé par le serveur ; le client le recalcule seulement pour l'affichage (`multiplayer.md`).
- **Preuve** : `EFE_Core.lua:51-55` ; `IsoGridSquare.java:8223-8228`.
- **Risque** : MP, durée fausse dans un cas limite. Aucun risque pour l'autorité serveur, puisque le mod n'envoie rien.
- **Correction** : aucune avant observation. Test proposé : client MP, frigo branché sur un générateur posé pendant la session, comparer l'infobulle avant et après reconnexion.
- **Statut : corrigé statiquement, à vérifier en jeu** (test unique `EFE.generatorPowered` = `haveElectricity`, seul courant local lu par `Food.updateAge` ; le client reçoit les positions de générateur à chaque synchronisation, `IsoGenerator.java:550-567`, et les mods comme Live Wire les inscrivent aussi chez les clients par `addGeneratorPos` ; un courant que le moteur ne voit pas ne ralentit pas non plus le vieillissement réel). Test MP proposé inchangé : générateur posé pendant la session, infobulle avant et après reconnexion.
- **Priorité** : basse. **Effort** : S (test).

### C11 : calculs répétés à chaque passe de rendu
- **Problème** : TooltipLib appelle le rappel à chaque image, avec une passe de mesure et une passe de rendu (`Hook.lua:455-462`). Chaque appel recalcule plusieurs fois les mêmes valeurs :
  - `EFE.stage` (lignes 41, 46, et par `stateKey`) ;
  - `getSandboxOptions():getOptionByName(...)`, une recherche par nom, 4 à 6 fois.
  - La bande de l'inventaire calcule aussi `stage` et `freshFraction` pour chaque ligne visible.
- **Preuve** : `EFE_Core.lua:23-36`, `:102-104` ; `EFE_Tooltip.lua:41-71`.
- **Risque** : performance négligeable aujourd'hui, à surveiller si des lignes s'ajoutent (I03, I05).
- **Correction** :
  - calculer `stage` une fois par appel ;
  - mémoriser les valeurs sandbox le temps d'un appel, sans cache durable : une option sandbox peut changer en cours de partie en MP (`load-warnings.md`) ;
  - en option, `cacheable = true, maxAge = 30` dans `registerProvider`, avec `cacheKey` = `getAge()` arrondi et l'identifiant du conteneur.
- **Statut : corrigé** (options sandbox mémorisées le temps d'une milliseconde, `getTimestampMs`, sans cache durable ; `stage` calculé une fois par appel et passé à `stateKey` ; test lupa du nombre de lectures). Le cache TooltipLib (`cacheable`) n'est pas utilisé.
- **Priorité** : basse. **Effort** : S.

### C12 : repli `getSpecificPlayer(0)` en écran partagé
- **Problème** : si `ctx.tooltip:getCharacter()` est `nil`, le mod lit les traits du joueur 0. En écran partagé, le joueur 2 verrait alors les durées selon les traits du joueur 1.
- **Preuve** : `EFE_Tooltip.lua:43`.
- **Risque** : faible, seulement en écran partagé.
- **Correction** : si le personnage est inconnu, considérer que la durée n'est pas lisible (le même choix que `canReadExact(…, nil, true)`) plutôt que de supposer le joueur 0.
- **Statut : corrigé** (aucun repli `getSpecificPlayer(0)` : personnage inconnu = durées non lisibles si l'option est active ; test lupa).
- **Priorité** : basse. **Effort** : S.

### C13 : version minimale de TooltipLib non contrôlée
- **Problème** : le mod utilise les champs `description` et `addProgress` de TooltipLib sans vérifier sa version. Une copie plus ancienne de TooltipLib, par exemple dans un modpack, les ignorerait ou refuserait l'inscription en silence. Le message de `EFE_Tooltip.lua:10` ne couvre que l'absence totale de la bibliothèque.
- **Preuve** : `EFE_Tooltip.lua:9-12`, `:28-31` ; TooltipLib `Core.lua:301` (`checkVersion`), `:314-333` (`minVersion`).
- **Risque** : compatibilité.
- **Correction** : passer `minVersion = "<version testée>"` dans `registerProvider` (à relever, la variante installée est 1.7.0). Tester la valeur rendue par `registerProvider` et écrire un message anglais si elle est fausse.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : S.

### C14 : tests incomplets sur les cas du moteur
- **Problème** : la suite lupa ne couvre pas les cas suivants :
  - gel en cours (C01) ;
  - `ReplaceOnRotten` (C02) ;
  - œuf fécondé (C03) ;
  - `getSourceGrid()` égal à `nil` (le double rend toujours une table : `tests/run_tests.py:48`) ;
  - `canBeFrozen` (le double d'`isThawing` l'ignore : `:59-64`).
  La vérification des traductions ne détecte ni les clés en trop, ni les valeurs vides, ni les clés absentes de `EN` (`:283-293`).
- **Risque** : maintenance. Les corrections C01 à C03 n'auraient aucun garde-fou.
- **Correction** : reproduire fidèlement dans les doubles `isFreezing`, `isFertilized`, `getReplaceOnRotten` et `canBeFrozen` du Java, comme le demande la préférence « faithful Java mocks ». Ajouter les cas ; comparer chaque `UI.json` à `EN` dans les deux sens.
- **Statut : corrigé (commit d7e1955), à vérifier en jeu** (traduction : clés comparées à EN dans les deux sens ; tests C01-C03 ajoutés).
- **Priorité** : moyenne (préalable à C01-C03). **Effort** : S.

### C15 : `.luacheckrc` copié d'un autre projet, globales non contrôlées
- **Problème** : le commentaire cite MTIR et exclut un dossier `source/**` inexistant. `global = false` désactive tout contrôle des globales : une faute de frappe dans `getText` ou `instanceof` passerait.
- **Preuve** : `.luacheckrc:3-5`, `:10`.
- **Risque** : maintenance.
- **Correction** :
  - ajouter `globals = { "ErisFoodExpiry", "ISInventoryPane" }` ;
  - lister en `read_globals` les quelques API utilisées (`getText`, `getSandboxOptions`, `getGameTime`, `instanceof`, `getSpecificPlayer`, `CharacterTrait`, `PZAPI`, `TooltipLib`) ;
  - retirer la mention de MTIR.
- **Statut : corrigé** (globales contrôlées : `globals` et `read_globals` du mod, contrôle désactivé pour `autotest/**` ; mention de MTIR et `source/**` retirées ; une globale inconnue est signalée `W113`).
- **Priorité** : basse. **Effort** : S.

### C16 : noms affichés hétérogènes
- **Problème** : le mod porte quatre noms différents :
  - `mod.info` : `batman_Eris Food Expiry (TooltipLib fork)` ;
  - titre Workshop : « Food Expiry » ;
  - titre des options EN : « Eris Food Expiry (batman fork) » ;
  - les traductions varient encore : FR « (fork batman) », DE et RU « fork TooltipLib », CN « TooltipLib 分支 ».
- **Preuve** : `mod.info:1` ; `workshop.txt:3` ; `Translate/*/UI.json` (`UI_EFE_Title`).
- **Risque** : le joueur cherche le mod sous plusieurs noms dans le menu Mods et dans Options > Mods.
- **Correction** : choisir un seul nom (par exemple « Food Expiry ») pour `UI_EFE_Title` dans les dix langues et pour `name=`, en gardant `id` inchangé.
- **Statut : corrigé** (`name=Food Expiry` et `UI_EFE_Title` = « Food Expiry » dans les dix langues ; `id` inchangé).
- **Priorité** : basse. **Effort** : S.

### C17 : descriptions Workshop et langues manquantes
- **Problème** : le mod est traduit en italien et en polonais, mais aucun `README.steam.it` ni `README.steam.pl` n'existe. Plusieurs langues vanilla n'ont aucune traduction : JP, KO, TR, UA, CH, NL, CS, HU, ES_MX…
- **Preuve** : `README.steam*` (7 fichiers) ; `Translate/` (10 dossiers) ; `media/lua/shared/Translate/` vanilla (29 dossiers).
- **Risque** : traduction et visibilité.
- **Correction** :
  - ajouter les descriptions IT et PL ;
  - en priorité, les langues à forte audience : JP, KO, TR, UA ;
  - reprendre le vocabulaire vanilla de `Tooltip.json` (`Tooltip_food_Stale`, `Tooltip_food_Frozen`…) comme pour FR.
- **Statut** : confirmé statiquement.
- **Priorité** : basse. **Effort** : M.

### C18 : dossier `common/` absent et images Workshop liées à `docs/steam/`
- **Problème** :
  - `Contents/mods/batman_ErisFoodExpiry/` ne contient que `42.21/`. Le jeu l'accepte (`mod-loading.md`, sélection de variante : `<variante>/mod.info` suffit), mais la convention du dossier de travail demande un `common/` à côté.
  - Toutes les images des descriptions sont des liens `raw.githubusercontent.com/.../main/docs/steam/...`. Déplacer ou renommer `docs/steam/` casserait la page Workshop publiée, sans nouvelle mise en ligne. La réorganisation de `docs/` en cours est donc concernée.
- **Preuve** : arborescence du mod ; `README.steam:7`, `:30`, `:44-46`, `:58` ; `tests/run_tests.py:306-309`, qui détecte une image absente.
- **Risque** : maintenance et publication.
- **Correction** : créer `common/` vide (avec un `.gitkeep`, git ne suit pas les dossiers vides). Garder `docs/steam/` à ce chemin, ou mettre à jour toutes les descriptions et republier dans la même opération.
- **Statut : corrigé** (`common/.gitkeep` créé ; `docs/steam/` conservé à son chemin).
- **Priorité** : basse (`common`), moyenne (liens d'images pendant la réorganisation). **Effort** : S.

---

## Partie 2 : idées de fonctionnalités

### I01 : compte à rebours de la coupure de courant sur un frigo ou un congélateur
- **Description** : dans l'infobulle d'un aliment au froid sur le réseau, ajouter « Courant coupé dans 3 j ». Ajouter ensuite, si besoin, « puis pourri dans… » ou « puis décongelé dans… ».
- **Intérêt pour le joueur** : savoir quand vider le congélateur ou brancher un générateur, sans rien faire de plus que survoler l'objet.
- **Faisabilité** :
  - `getSandboxOptions():getElecShutModifier()`, `doesPowerGridExist()`, `getGameTime():getWorldAgeDaysSinceBegin()` (formule de la coupure réelle, voir C04) ;
  - `square:haveElectricity()` pour exclure les générateurs ;
  - `ElecShutModifier = -1` : jamais de réseau.
- **Impact MP** : aucun. Options sandbox lues sur le client, valeurs du serveur.
- **Dépendances** : aucune. Complète C04.
- **Effort** : S.

### I02 : bilan d'un frigo ou d'un congélateur au survol du meuble
- **Description** : en survolant un réfrigérateur, un congélateur ou un comptoir, afficher « 12 aliments ; le premier pourrit dans 2 j (lait) ; 3 périmés ».
- **Intérêt** : un coup d'œil dans la cuisine, sans ouvrir chaque meuble.
- **Faisabilité** :
  - surface `target = "object"` de TooltipLib (`HookWorldObject.lua`) ;
  - `IsoObject:getContainerByIndex(i):getItems()` ;
  - la même projection que les objets ;
  - appeler `item:updateAge()` côté client avant de lire l'âge d'un objet hors fenêtre d'inventaire (`multiplayer.md`).
- **Impact MP** : le contenu d'un meuble n'est connu du client qu'une fois chargé ou ouvert. TooltipLib propose `mpContainers` (requête serveur et cache de 2 s) ; son contenu exact est à étudier, à vérifier en jeu. Sinon, n'afficher le bilan que pour les meubles déjà ouverts pendant la session.
- **Dépendances** : TooltipLib (surface `object`).
- **Effort** : M (solo) à L (MP).

### I03 : tri « par fraîcheur » dans l'inventaire
- **Description** : un en-tête ou une entrée du menu contextuel de l'inventaire qui trie les aliments du plus proche de pourrir au plus frais.
- **Intérêt** : « manger d'abord ce qui va tourner », en un clic.
- **Faisabilité** : fonctions de tri d'`ISInventoryPane` (`sortByName`, `sortByType`, `itemSortByNameInc`…) et ajout d'un comparateur. Les en-têtes sont des `ISResizableButton` : un troisième bouton ou une entrée de menu est plus sûr que la refonte des colonnes.
- **Impact MP** : aucun (local).
- **Dépendances** : risque de conflit avec les mods qui remplacent `ISInventoryPane` (à vérifier par mod).
- **Effort** : M.

### I04 : pastille de fraîcheur sur la ligne repliée d'une pile
- **Description** : aujourd'hui, la bande n'apparaît que dans une pile dépliée (`ISInventoryPane.lua:2553`, branche `count > 1`). Ajouter une pastille ou une bande sur la ligne de tête, à la couleur du pire objet de la pile.
- **Intérêt** : voir sans rien déplier qu'un tas de pommes contient une pomme pourrie.
- **Faisabilité** : envelopper `ISInventoryPane:renderdetails` ou dessiner après la ligne de catégorie. Les objets de la pile sont dans `v.items`. Tous les objets sont déjà vieillis par `updateAge` dans la liste (`:2266`).
- **Impact MP** : aucun.
- **Dépendances** : à tester avec les mods d'inventaire courants.
- **Effort** : M.

### I05 : infobulle d'une pile, du plus frais au plus abîmé
- **Description** : sur une pile repliée, ajouter « 5 autres : de 1 j à 4 j ».
- **Intérêt** : une seule infobulle pour décider quoi cuisiner.
- **Faisabilité** : l'infobulle TooltipLib reçoit un seul objet (`ctx.item`). Il faut retrouver la pile survolée depuis `ISInventoryPane` (`self.mouseOverOption`, `self.items`) au moment du rendu. C'est faisable mais fragile.
- **Impact MP** : aucun.
- **Dépendances** : TooltipLib (version des champs `ctx`).
- **Effort** : M.

### I06 : « Jeter les aliments pourris » depuis un meuble ou un sac
- **Description** : une entrée du menu contextuel d'un conteneur, qui dépose au sol ou dans une poubelle tous les aliments `isRotten()`.
- **Intérêt** : vider un frigo pourri en un geste au lieu de vingt glisser-déposer.
- **Faisabilité** : `OnFillInventoryObjectContextMenu` ou `OnFillWorldObjectContextMenu`, puis la file vanilla `ISInventoryTransferAction` vers le sol ou la poubelle, avec les mêmes contrôles que le vanilla.
- **Impact MP** : les transferts vanilla passent par l'autorité serveur (transactions Java, `combat-and-xp.md`). Aucune commande propre.
- **Dépendances** : aucune. Exclure le composteur (`IsoCompost`) et les objets `ReplaceOnRotten` (C02).
- **Effort** : M.

### I07 : option serveur qui impose la règle du Nutritionniste
- **Description** : une option sandbox `ErisFoodExpiry.RequireTrait` (Désactivé / Choix du joueur / Imposé) en plus de l'option du joueur.
- **Intérêt** : sur un serveur exigeant, tout le monde joue avec les mêmes informations. Aujourd'hui, chaque joueur coche ce qu'il veut (`EFE_Options.lua:83-91`).
- **Faisabilité** : `media/sandbox-options.txt` dans `42.21/media` (format `VERSION = 1,` puis `option ErisFoodExpiry.RequireTrait { type = enum, … }`, `mod-loading.md`). Lecture par `getSandboxOptions():getOptionByName("ErisFoodExpiry.RequireTrait")`.
- **Impact MP** : valeur du serveur transmise au client. C'est seulement de l'affichage : un client modifié peut toujours voir les durées, ce qui est acceptable (« anti-triche basse priorité »).
- **Dépendances** : traduction des libellés sandbox (`Sandbox_…` dans `Sandbox.json`).
- **Effort** : S.

### I08 : durées exactes selon le niveau de Cuisine
- **Description** : en plus du Nutritionniste et de l'emballage lisible, donner les durées exactes à partir de Cuisine 3 (réglable), et un état plus fin au-dessous.
- **Intérêt** : récompenser la compétence avec une information qui reste dans le monde du jeu.
- **Faisabilité** : `character:getPerkLevel(Perks.Cooking)` dans `canReadExact` (`EFE_Core.lua:186-196`).
- **Impact MP** : aucun (niveau connu du client pour son personnage).
- **Dépendances** : I07 pour un seuil fixé par le serveur.
- **Effort** : S.

### I09 : date « À consommer avant » sur les emballages
- **Description** : pour un aliment emballé et lisible, afficher une date du calendrier du jeu (« Avant le 14 août ») au lieu, ou en plus, d'une durée.
- **Intérêt** : immersif, cela ressemble à ce que l'on lit sur une vraie boîte et cela rejoint la règle « emballage lisible ».
- **Faisabilité** : `getGameTime():getDay()`, `getMonth()` (comptés depuis 0, `api-42-21.md` « calendrier de `GameTime` »), plus la durée projetée. Noms des mois traduits par les clés vanilla du calendrier (à relever).
- **Impact MP** : aucun.
- **Dépendances** : option d'affichage (durée, date, les deux).
- **Effort** : S.

### I10 : palette pour daltoniens et repère « périmé » sur la barre
- **Description** :
  - option de palette bleu, jaune et violet, ou d'après `getCore():getGoodHighlitedColor()` et `getBadHighlitedColor()`, déjà réglables dans les options d'accessibilité vanilla ;
  - petit trait sur la bande et la barre au seuil `offAge / offAgeMax`.
- **Intérêt** : le vert, l'orange et le rouge actuels se distinguent mal pour une partie des joueurs. Le trait montre d'un coup d'œil la part de vie « fraîche ».
- **Faisabilité** : `EFE.COLORS` (`EFE_Core.lua:111-115`) ; `drawRect` dans `EFE_InventoryBar.lua:31-32`. Le trait dans la barre TooltipLib dépend de `addProgress`, qui ne gère qu'une couleur (dessin propre ou `postRender`).
- **Impact MP** : aucun.
- **Dépendances** : TooltipLib pour la barre de l'infobulle.
- **Effort** : S.

### I11 : détails sur Maj (`detailOnly`) et réglage de la verbosité
- **Description** : n'afficher par défaut que la barre et « Pourri dans ». Maj (touche de détail de TooltipLib) ajoute « Périmé dans », la décongélation, la disparition et les facteurs (frigo, générateur, réseau). Ajouter des options « Masquer "Ne se périme jamais" » (bruit sur toutes les conserves) et « Nombre d'unités (1 à 3) ».
- **Intérêt** : des infobulles plus courtes, moins de bruit sur les objets secs.
- **Faisabilité** : champ `detailOnly` ou `ctx.detail` de TooltipLib (`Core.lua:324`, `Hook.lua:470`) ; `PZAPI.ModOptions:addTickBox` et `addComboBox`.
- **Impact MP** : aucun.
- **Dépendances** : TooltipLib.
- **Effort** : S.

### I12 : compte à rebours de cuisson et de brûlure
- **Description** : dans un four ou sur un barbecue allumé, afficher « Cuit dans 6 min, brûle dans 14 min ».
- **Intérêt** : le vanilla ne montre qu'une barre ; une durée évite de brûler le repas pendant qu'on fait autre chose.
- **Faisabilité** : `getCookingTime`, `getMinutesToCook`, `getMinutesToBurn`, `getHeat()`. La vitesse vaut `heat / 1,5` par minute de jeu, ×0,05 si le conteneur est à 1,6 ou moins (`Food.java:362-367`). La chaleur change pendant la montée en température : donner une estimation.
- **Impact MP** : `cookingTime` est envoyé au client par `sendItemStats` à chaque minute de cuisson (`Food.java:359-361`) ; valeur fiable côté client à vérifier en jeu.
- **Dépendances** : aucune ; remplace l'affichage trompeur de C09.
- **Effort** : M.

### I13 : avertissement discret quand un aliment porté devient périmé ou pourri
- **Description** : un texte flottant (« Votre lait est périmé ») quand un aliment de l'inventaire principal change d'état. Option désactivée par défaut.
- **Intérêt** : ne plus découvrir trop tard une viande pourrie dans le sac.
- **Faisabilité** : le Java déclenche `OnContainerUpdate(item)` sur le client quand frais ou pourri change (`Food.java:698-705`), mais seulement lors d'un `updateAge` côté client, c'est-à-dire fenêtre d'inventaire ouverte. Il faudrait sonder l'inventaire principal toutes les 10 minutes de jeu (`EveryTenMinutes`) avec `updateAge()`, puis afficher par `HaloTextHelper.addText`.
- **Impact MP** : appeler `updateAge` sur la copie cliente reste local (`multiplayer.md`) ; aucune commande réseau.
- **Dépendances** : traductions des messages.
- **Effort** : M.

### I14 : infobulle dans les emplacements de fabrication (`itemSlot`)
- **Description** : afficher la même fraîcheur dans les emplacements d'ingrédients de la fenêtre de fabrication et de cuisine.
- **Intérêt** : choisir les ingrédients les plus vieux au moment de cuisiner, là où la décision se prend.
- **Faisabilité** : TooltipLib accepte `target = "itemSlot"` (`Core.lua:132-139`). Appeler `item:updateAge()` avant la lecture, car l'objet n'est pas vieilli par `ISInventoryPane` dans cette fenêtre.
- **Impact MP** : aucun.
- **Dépendances** : TooltipLib.
- **Effort** : S.

### I15 : autonomie du générateur dans la projection
- **Description** : pour un frigo alimenté par générateur, afficher « Générateur vide dans ~1 j 4 h », puis la durée restante à vitesse normale.
- **Intérêt** : relier la nourriture à la corvée d'essence.
- **Faisabilité** : retrouver le ou les générateurs qui alimentent la case, ce qui est difficile depuis Lua (positions par chunk non listées, `power-and-lights.md`). Lire `IsoGenerator:getFuel()` et estimer la consommation (`totalPowerDraw` en ModData moteur, à vérifier). Approximation seulement.
- **Impact MP** : carburant connu du client par la synchronisation de l'objet (à vérifier en jeu).
- **Dépendances** : compatibilité avec les mods d'électricité (par exemple LiveWire de l'utilisateur).
- **Effort** : L.

### I16 : composteur : temps avant le compost
- **Description** : pour un aliment dans un composteur, remplacer « Pourri » par « Compost dans X ».
- **Intérêt** : rendre lisible une mécanique B42 peu documentée en jeu.
- **Faisabilité** : champ `compostTime` de `Food` (`Food.java:122`) et logique d'`IsoCompost`, à relever. Hypothèse non vérifiée qu'un getter public existe.
- **Impact MP** : compost calculé par le serveur ; valeur cliente à vérifier.
- **Dépendances** : aucune.
- **Effort** : M (après relevé du Java).

### I17 : objets au sol et cadavres d'animaux
- **Description** : afficher la fraîcheur de la viande au sol et des carcasses (objets `Food` d'animal) au survol dans le monde.
- **Intérêt** : savoir si une carcasse vaut encore le dépeçage.
- **Faisabilité** : surface `object` de TooltipLib sur un `IsoWorldInventoryObject` (`getItem()`), avec `updateAge()` côté client. Pour les carcasses (`IsoDeadBody` d'animal), l'âge passe par un autre chemin (à relever).
- **Impact MP** : objet au sol connu du client ; aucune commande.
- **Dépendances** : TooltipLib.
- **Effort** : M.

---

## Partie 3 : priorisation

| Rang | Action | Pourquoi | Effort |
|---|---|---|---|
| 1 | C14 puis C01 : doubles fidèles, puis projection « congelé dans… » au congélateur | Bug le plus visible (durée fausse sur la viande au congélateur) ; corrigé en quelques lignes une fois le test en place | S |
| 2 | C02 + C03 : `ReplaceOnRotten` et `isFresh()`/`isRotten()` vanilla | Textes faux sur les glaces, le sucre de betterave et les œufs fécondés ; corrections locales | S |
| 3 | I01 + C04 : coupure de courant annoncée | Information décisive au moment de la coupure, faite avec les API déjà utilisées | S-M |
| 4 | I07 : option sandbox du Nutritionniste (avec C05/C06) | Rend l'option cohérente en multijoueur, demande peu de code | S |
| 5 | I04 ou I03 : fraîcheur visible sans déplier, ou tri par fraîcheur | Le geste le plus naturel (ouvrir le frigo et voir) ; plus de valeur que l'infobulle seule | M |

Au passage, garder le chemin `docs/steam/` (C18), car les images de la page Workshop publiée en dépendent.

---

## Note finale

Ce document propose des pistes. Rien n'est implémenté sans validation explicite de l'utilisateur. Les points marqués « à vérifier en jeu » demandent un test (solo, puis client MP si besoin) avant toute conclusion. Les numéros de ligne correspondent à la version 0.2.0 et au Java 42.21.0 lus le 2026-10-21. Ils sont à relire après une mise à jour du mod, de TooltipLib ou du jeu.
