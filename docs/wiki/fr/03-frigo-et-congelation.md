# Réfrigérateur et congélation

## Réfrigérateurs et congélateurs

Un réfrigérateur ou un congélateur ralentit la dégradation selon l'option sandbox d'efficacité de la réfrigération, tant qu'il a du courant :

- **générateur** : le ralentissement s'applique tant que la case est alimentée par un générateur ;
- **réseau électrique** : le ralentissement s'applique jusqu'au jour de coupure de l'électricité du sandbox ; la durée projetée repasse à la vitesse normale pour la part postérieure à ce jour. L'infobulle affiche **Courant coupé dans** : le temps avant que la coupure arrête l'appareil (rien si la coupure est désactivée).

Les générateurs ajoutés par d'autres mods sont pris en compte s'ils alimentent les cases comme un générateur vanilla (par exemple les onduleurs de Live Wire) : c'est le seul courant local que le jeu utilise pour faire vieillir la nourriture.

Avec plus d'un mois depuis l'apocalypse (option sandbox), le jeu coupe le courant avant de changer la vitesse de dégradation au réfrigérateur ; la projection suit les deux, comme le jeu.

Si l'efficacité de la réfrigération est réglée sur aucune dégradation, un réfrigérateur alimenté affiche **Ne s'abîme pas ici**.

Un arrêt futur du générateur (panne de carburant) n'est pas anticipé : la durée change quand il se produit.

## Aliments congelés

Un aliment congelé ne s'abîme pas avant d'être décongelé.

- Dans un **congélateur en marche** : **Congelé : ne s'abîme pas**. Un aliment pas encore congelé affiche d'abord **Congelé dans** : il gèle en 4 heures de jeu au plus, puis ne s'abîme plus. Sur le réseau, suivent **Courant coupé dans**, puis **Périmé dans** et **Pourri dans** comptés après la coupure et 1,5 heure de décongélation.
- **Partout ailleurs** : **Décongelé dans**, puis **Périmé dans** et **Pourri dans** comptés à partir de la fin de la décongélation.

![Steak en train de décongeler](../../images/screenshots/06-tooltip-thawing.png)

La décongélation prend 1,5 heure de jeu depuis un état entièrement congelé, deux fois plus dans un réfrigérateur alimenté, et six fois moins dans un conteneur chaud (cuisinière, barbecue…). Un aliment partiellement congelé met proportionnellement moins de temps.

## Suppression des aliments pourris

Si l'option sandbox de suppression des aliments pourris est active, un aliment pourri affiche **Disparaît dans** : le temps avant que le jeu le supprime. Un composteur conserve les aliments pourris : rien n'y est affiché.
