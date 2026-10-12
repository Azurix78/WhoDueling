# WhoDueling

Version **1.0.4**, pour **WoW Forever 1.60.1 / interface 16001**. Auteur : Syntaxucre. Licence MIT.

Lorsqu’un joueur te demande un duel ordinaire, un petit bouton **Who dueled me?** apparaît sous la fenêtre Blizzard. Un clic sélectionne le joueur qui t’a défié, en conservant son **prénom et son nom de famille**. Le ciblage validé en jeu dans la version 1.0.3 est conservé.

Le bouton se masque en combat et disparaît lorsque la demande est acceptée, refusée, annulée ou expirée. La demande Blizzard conserve son fonctionnement habituel. Les duels à mort sont exclus.

La version 1.0.4 contient uniquement le ciblage : la récupération des talents, les statistiques, l’historique, les échanges entre addons et la commande de diagnostic ont été retirés. L’adversaire n’a besoin d’aucun addon.

## Installation

Double-cliquer sur `Installer-Addon.cmd` à la racine du projet, puis faire `/reload` pour cette mise à jour. Après une première installation, redémarrer WoW et activer WhoDueling.

Pour une installation manuelle, extraire le dossier `WhoDueling` dans `World of Warcraft/_classic_beta_/Interface/AddOns`. Le TOC doit se trouver à `AddOns/WhoDueling/WhoDueling.toc`, sans dossier intermédiaire.

## Langues et ciblage

Le bouton porte le libellé **Who dueled me?** dans toutes les langues. La description est traduite pour `enUS`, `enGB`, `frFR`, `deDE`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN` et `zhTW`, avec repli anglais pour une langue inconnue.

Forever utilise un prénom et un nom de famille, sans royaume. Les deux parties sont toujours conservées. Si une unité correspondante est accessible, le bouton utilise l’action sécurisée native de ciblage ; sinon il exécute par exemple `/targetexact Bia Fine`. Le joueur doit être présent et accessible au ciblage du client.

## Vérification

Les tests simulés couvrent les noms complets, les homonymes, les demandes successives, les fermetures de fenêtre, le combat et le positionnement du bouton. L’installateur et l’archive sont vérifiés dans des dossiers temporaires.

Après mise à jour, vérifier en jeu que seul le bouton apparaît, qu’il cible l’adversaire et qu’il disparaît avec la demande. Le ciblage en jeu a été confirmé par l’utilisateur en 1.0.3 ; le nouvel emplacement du bouton reste à confirmer dans le client.
