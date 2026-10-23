# Spécifications fonctionnelles

Retour à l'[index](README.md). Contrats et formules : [spécifications techniques](specifications-techniques.md). Guides joueur : [wiki](wiki/fr/Home.md).

Le mod n'ajoute ni objet, ni recette, ni action, ni menu contextuel, ni option sandbox. Il ajoute des informations d'affichage sur les aliments.

## F01 — Lignes de péremption dans l'infobulle

Au survol d'un aliment (objet `Food`), l'infobulle reçoit, sous les lignes vanilla, un bloc fourni par TooltipLib :

| Situation | Lignes affichées |
| --- | --- |
| Aliment qui ne vieillit pas (conserves, aliments secs : `offAgeMax` = 1 000 000 000) | « Does not expire » / « Ne se périme jamais » (gris), rien d'autre. |
| Cas général | Barre **Freshness / Fraîcheur**, puis **Stale in / Périmé dans** (si l'aliment est encore frais) et **Rotten in / Pourri dans**. |
| Congelé dans un congélateur en marche | Barre, puis « Frozen: not spoiling » / « Congelé : ne s'abîme pas ». Le jour de la coupure du réseau n'est jamais annoncé. |
| Pas encore congelé dans un congélateur en marche (aliment congelable) | Barre, **Frozen in / Congelé dans** (4 h de jeu au plus depuis un aliment non congelé), puis « Congelé : ne s'abîme pas ». Si l'aliment devient périmé ou pourri avant d'être congelé, la durée correspondante est affichée. |
| Aliment remplacé par un autre objet au lieu de pourrir (`ReplaceOnRotten` : glaces, sirop de betterave) | « Pourri dans » devient **Turns into <objet> in / Devient <objet> dans** ; jamais « Disparaît dans ». |
| Œuf fécondé | « Fertilized: does not expire » / « Fécondé : ne se périme pas » (gris), rien d'autre : le jeu le considère toujours frais. |
| Congelé ailleurs (décongélation en cours) | Barre, **Thawed in / Décongelé dans**, puis « Périmé dans » et « Pourri dans » comptés à partir de la fin de la décongélation (F04). |
| Aliment en cours de cuisson (cuisable, non congelé, chaleur > 1,6, ni cuit ni brûlé) | Barre, puis « Cooking: times shown once cooked » / « Cuisson : durées affichées une fois cuit » : la cuisson change les durées (F09). |
| Aliment qui ne s'abîme pas à cet endroit (réfrigérateur alimenté, option sandbox *Refrigeration Effectiveness* réglée sur « No decay ») | Barre, puis « Not spoiling here » / « Ne s'abîme pas ici ». |
| Aliment pourri | Barre vide, « Rotten » / « Pourri », puis **Disappears in / Disparaît dans** si F05 s'applique. |

La couleur suit le stade vanilla : vert tant que l'âge est inférieur à l'âge de péremption, orange une fois périmé, rouge une fois pourri.

Capture : [05-tooltip-fridge.png](images/screenshots/05-tooltip-fridge.png), [06-tooltip-thawing.png](images/screenshots/06-tooltip-thawing.png).

## F02 — Barre de fraîcheur

La barre est pleine pour un aliment neuf et vide pour un aliment pourri : elle représente la part de vie restante jusqu'à l'âge de pourriture de l'objet. Sans les durées exactes (F06), elle est arrondie au tiers supérieur (1/3, 2/3 ou pleine).

## F03 — Durées projetées comme le jeu fait vieillir la nourriture

Les durées tiennent compte :
- de l'option sandbox *Food Spoilage* (`FoodRotSpeed`) ;
- de l'option sandbox *Refrigeration Effectiveness* (`FridgeFactor`) pour un aliment dans un réfrigérateur ou un congélateur alimenté par un générateur, ou par le réseau jusqu'au jour de la coupure (`ElecShutModifier`) ; après la coupure, la projection repasse à la vitesse normale ;
- de la congélation : un aliment congelé ne vieillit pas avant d'être décongelé ;
- des âges de péremption et de pourriture **propres à l'objet** (un plat cuisiné diffère de l'aliment cru).

Les générateurs ajoutés par d'autres mods sont pris en compte s'ils alimentent les cases comme un générateur vanilla (position de générateur du chunk, par exemple les onduleurs de Live Wire) : c'est le seul courant local que le jeu utilise pour faire vieillir la nourriture.

Le mod n'annonce jamais le jour de la coupure du réseau, que le jeu tire au hasard et garde caché.

Les durées s'écrivent avec les unités les plus grandes d'abord, au plus trois unités non nulles parmi années (365 j), mois (30 j), semaines, jours, heures et minutes, par exemple « 2 sem 13 h 33 min » ; en dessous d'une minute : « < 1 min ».

## F04 — Décongélation

Un aliment congelé hors d'un congélateur en marche affiche le temps avant décongélation complète, d'après son état de congélation : 1,5 h depuis un état entièrement congelé, deux fois plus long dans un réfrigérateur alimenté, six fois plus rapide dans un conteneur plus chaud que la normale (cuisinière, barbecue…). Les durées de péremption et de pourriture commencent à la fin de la décongélation.

## F05 — Disparition des aliments pourris

Si l'option sandbox *Rotten Food Removal* (`DaysForRottenFoodRemoval`) est active, un aliment pourri affiche le temps avant sa suppression par le jeu (âge supérieur à l'âge de pourriture plus le nombre de jours de l'option). Rien n'est affiché si l'option est désactivée ou si l'aliment est dans un composteur, qui le conserve.

## F06 — Option « durées exactes avec Nutritionniste »

Option de mod (Options > Mods > « Food Expiry »), case **Exact times need Nutritionist / Durées exactes avec Nutritionniste**, désactivée par défaut, réglée par chaque joueur sur sa machine.

- Désactivée : tout le monde voit les durées exactes.
- Activée : les durées exactes s'affichent si le personnage a le trait Nutritionniste (trait ou métier), ou si l'aliment est emballé et que son étiquette est lisible, avec la même règle que le bloc nutritionnel vanilla : personnage non illettré, assez de lumière pour lire, étiquette présente (pas de clé ModData `NoLabel`).
- Sinon, la barre de fraîcheur, arrondie au tiers, reste affichée avec un **état approximatif**, suivi si besoin d'une ligne sans durée sur ce qui arrive à l'aliment : « Frozen: not spoiling » / « Congelé : ne s'abîme pas », **Thawing / Décongélation en cours**, **Freezing / Congélation en cours**, « Cuisson : durées affichées une fois cuit » ou « Ne s'abîme pas ici ». La bande d'inventaire (F07) n'affiche alors que la couleur du stade :

| État | Condition |
| --- | --- |
| Very fresh / Très frais | plus des 2/3 du temps avant péremption restants |
| Fresh / Frais | entre 1/3 et 2/3 restants |
| Looks okay / Semble correct | moins d'1/3 restant |
| Starting to rot / Commence à pourrir | périmé, moins de la moitié de l'intervalle péremption → pourriture écoulée |
| Almost rotten / Presque pourri | périmé, au moins la moitié de cet intervalle écoulée |
| Rotten / Pourri | pourri, suivi de **Will disappear / Va disparaître** (sans durée) si F05 s'applique |

## F07 — Bande de fraîcheur dans l'inventaire

Dans la liste de l'inventaire ou d'un conteneur, quand une pile est dépliée, chaque aliment périssable reçoit une fine bande (2 px) au bas de sa ligne, du libellé de la ligne de détail vanilla, qui reste affichée, jusqu'à la fin de sa barre (Nutrition, Congélation, Cuisson…), quelle que soit la longueur du libellé dans la langue et la police choisies. La bande a la couleur du stade (F01) et la longueur de la fraction de fraîcheur (F02) ; le reste est gris. Sans les durées exactes (F06), la bande est entièrement de la couleur du stade. Les aliments qui ne se périment pas et les autres objets n'ont pas de bande.

> Capture à faire : pile d'aliments dépliée dans l'inventaire montrant les bandes verte, orange et rouge.

## F08 — Traductions

Textes du mod en anglais, français, allemand, espagnol, italien, polonais, portugais, portugais du Brésil, russe et chinois simplifié. Le nom de l'option, son infobulle et la description du fournisseur TooltipLib sont traduits par l'écran d'options du jeu.

## F09 — Cuisson

Pendant la cuisson, les durées sont remplacées par « Cuisson : durées affichées une fois cuit » : cuire peut remettre l'âge à zéro (marmites et poêles de riz ou de pâtes) ou remplacer l'objet (`ReplaceOnCooked`). Les durées reviennent une fois l'aliment cuit.

## Solo et multijoueur

- Solo et multijoueur identiques : le mod n'affiche que des valeurs connues du client.
- En multijoueur, le mod doit être installé sur le serveur pour que les clients le téléchargent ; aucune commande n'est envoyée au serveur et rien n'est sauvegardé. Ajout ou retrait sans risque sur un monde existant.
- Chaque joueur règle l'option F06 pour lui-même ; l'administrateur n'a rien à configurer en dehors des options sandbox vanilla déjà citées.

## Limites connues

- Les durées sont une **projection depuis l'état actuel** : déplacer l'aliment, une coupure de générateur, un changement de température ou d'option sandbox change la valeur à l'affichage suivant.
- Une coupure de générateur future n'est pas anticipée.
- Au réfrigérateur sur le réseau, la projection change de vitesse au jour de coupure (`ElecShutModifier`) : une durée longue laisse deviner ce jour.
- Le temps avant décongélation ne prévoit pas de recongélation.
- Incompatible avec les mods d'origine `eris_food_expiry` (ne pas activer ensemble).
- TooltipLib est obligatoire : sans lui, aucune ligne n'apparaît dans l'infobulle (la bande d'inventaire reste active).
