# Lire les étiquettes

Survolez un aliment : le mod ajoute ses lignes en bas de l'infobulle.

![Infobulle au réfrigérateur](../../images/screenshots/05-tooltip-fridge.png)

| Ligne | Signification |
| --- | --- |
| Barre **Fraîcheur** | Vie restante avant pourriture : pleine pour un aliment neuf, vide pour un aliment pourri. Verte tant qu'il est frais, orange une fois périmé, rouge une fois pourri. |
| **Périmé dans** | Temps avant péremption (affiché seulement tant que l'aliment est frais). |
| **Pourri dans** | Temps avant pourriture. |
| **Décongelé dans** | Aliment congelé hors d'un congélateur en marche : temps avant décongélation. Voir [Réfrigérateur et congélation](03-frigo-et-congelation.md). |
| **Congelé : ne s'abîme pas** | Aliment congelé dans un congélateur en marche. |
| **Congelé dans** | Aliment qu'on vient de mettre dans un congélateur en marche : temps avant qu'il soit congelé (4 heures de jeu au plus). |
| **Courant coupé dans** | Réfrigérateur ou congélateur sur le réseau électrique : temps avant que la coupure de l'électricité l'arrête. Voir [Réfrigérateur et congélation](03-frigo-et-congelation.md). |
| **Cuisson : durées affichées une fois cuit** | Aliment en cours de cuisson : la cuisson peut changer ses durées (les marmites de riz ou de pâtes repartent de zéro), elles reviennent une fois l'aliment cuit. |
| **Devient … dans** | Aliment qui se transforme en un autre objet au lieu de pourrir (la glace fond, le sirop de betterave devient du sucre). |
| **Fécondé : ne se périme pas** | Œuf fécondé : le jeu le garde frais. |
| **Ne s'abîme pas ici** | L'aliment ne vieillit pas là où il est (réfrigérateur alimenté, option sandbox d'efficacité de la réfrigération réglée sur aucune dégradation). |
| **Ne se périme jamais** | Aliment qui ne s'abîme jamais, comme les conserves et les aliments secs. |
| **Pourri** + **Disparaît dans** | Aliment pourri ; la seconde ligne n'apparaît que si l'option sandbox de suppression des aliments pourris est active, et pas dans un composteur. |

Les captures montrent le jeu en anglais (« Stale in », « Rotten in », « Thawed in »).

## Format des durées

Unités les plus grandes d'abord, trois au plus : années (365 jours), mois (30 jours), semaines, jours, heures, minutes. Exemple : `2 sem 13 h 33 min`. Moins d'une minute : `< 1 min`.

## Des durées qui suivent le jeu

Le temps restant est projeté comme le jeu fait vieillir la nourriture : vitesse de dégradation du sandbox, effet du réfrigérateur ou du congélateur, congélation, âges de péremption et de pourriture propres à chaque objet (un plat cuisiné diffère de l'aliment cru). Il est recalculé à chaque affichage de l'infobulle : déplacer l'aliment le change.

## État approximatif

Si l'[option](04-options.md) « Durées exactes avec Nutritionniste » est active et que votre personnage ne peut pas lire les durées exactes, la barre reste, arrondie au tiers, et une ligne donne un état approximatif : **Très frais**, **Frais**, **Semble correct**, **Commence à pourrir**, **Presque pourri** ou **Pourri**. Une seconde ligne, sans durée, dit ce qui arrive à l'aliment là où il est : **Congelé : ne s'abîme pas**, **Décongélation en cours**, **Congélation en cours**, **Cuisson**, **Ne s'abîme pas ici**, ou **Va disparaître** pour un aliment pourri que le jeu supprimera. La bande de l'inventaire n'affiche alors que la couleur.

## Bande dans l'inventaire

Dépliez une pile dans l'inventaire ou dans un conteneur : chaque aliment périssable reçoit une fine bande au bas de sa ligne, aux mêmes couleurs que la barre de fraîcheur, du libellé de la ligne de détail vanilla jusqu'à la fin de sa barre. La ligne de détail vanilla reste visible.

> Capture à faire : pile d'aliments dépliée dans l'inventaire avec des bandes verte, orange et rouge.
