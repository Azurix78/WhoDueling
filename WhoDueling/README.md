# WhoDueling

Version **1.0.3**, pour **WoW Forever 1.60.1 / interface 16001**. Auteur : Syntaxucre. Licence MIT. Aucune dépendance en jeu.

## Utilisation

Lorsqu’un joueur te demande un duel ordinaire, un panneau apparaît sous la demande Blizzard avec **Cibler** et ses talents **`xx/xx/xx`**. Survole la ligne des talents pour voir les noms des trois arbres et leurs points dans l’ordre du client.

L’addon tente une inspection dès la demande, sans changer ta cible ni ouvrir la fenêtre d’inspection. Le clic **Cibler** sélectionne l’adversaire et retente l’inspection si nécessaire, sans accepter le duel. Lorsqu’une unité correspondante est accessible (cible, survol, plaque de nom, groupe…), le bouton utilise l’action sécurisée native de ciblage. Sinon il utilise `/targetexact` avec le prénom et le nom de famille complets. Par exemple : `/targetexact Bia Fine`. Le ciblage dépend de la présence du joueur et des restrictions du client.

Forever n’a plus de royaumes : les deux chaînes renvoyées par les API de noms représentent le prénom et le nom de famille. Les noms au format des liens (`Bia-Fine`) sont normalisés vers le format du client (`Bia Fine`). Aucun nom de famille n’est supprimé ni deviné ; un prénom seul est ignoré pour éviter de sélectionner un homonyme. L’addon utilise l’identité non modifiée du joueur, même si son nom de famille est masqué dans les réglages d’affichage.

Les informations sont en **Chargement…** pendant dix secondes au maximum, puis **Indisponible** si aucune donnée n’est reçue. Un nouveau clic peut relancer l’inspection après ce délai. Des talents absents ne sont jamais affichés comme `0/0/0` ; des points à zéro réellement fournis par le jeu sont conservés.

Le bouton est masqué en combat et remplacé par **Disponible hors combat**. Le panneau disparaît lorsque la demande Blizzard se ferme. Les duels à mort ne sont pas pris en charge.

## Correctifs récents

- Le panneau se concentre sur le ciblage et les talents ; les statistiques de l’adversaire et le bilan personnel ne sont plus affichés.
- L’addon ne demande plus de comparaison des hauts faits. Cette requête pouvait déclencher l’erreur Blizzard `GetCategoryNumAchievements`, avec `id="summary"`, sur le client testé.
- Depuis 1.0.3, le bouton et l’inspection utilisent le prénom et le nom de famille complets. Les API de royaume ne sont plus utilisées. Les noms provenant des unités, demandes, GUID et messages privés sont comparés sous le même format.
- Le bouton privilégie une unité vérifiée au clic et utilise explicitement le relâchement du bouton gauche.
- L’inspection peut retrouver l’arbre à partir de la spécialisation inspectée si sa configuration ne fournit pas les identifiants d’arbres.
- Le diagnostic indique les clics, les ciblages confirmés et les requêtes/réponses d’inspection.

## Inspection et partage

Les talents directement inspectés sont prioritaires et ne nécessitent **aucun addon chez l’adversaire**. L’inspection exige que le joueur soit accessible et inspectable par le client. Une réponse périmée ou concernant un autre GUID est ignorée. WhoDueling attend lorsque la fenêtre d’inspection native est utilisée.

Si les deux adversaires possèdent WhoDueling, une requête privée d’addon peut compléter les talents manquants. La mention **Talents partagés par l’adversaire** distingue ces données de l’inspection directe. Les noms d’arbres viennent de ton client lorsqu’ils sont disponibles.

Le partage utilise le préfixe `WHODUELING`, vérifie le joueur et la demande et limite la fréquence des échanges. Aucun message de chat visible, canal public, serveur externe ou compte n’est utilisé. Les restrictions du client, notamment entre factions, peuvent empêcher les réponses. Pour le partage sur Forever, les deux joueurs doivent utiliser **1.0.3 ou plus récent**, qui gère correctement les prénoms et noms de famille. Le protocole reste en version 2.

Les données existantes de `WhoDuelingDB` sont conservées. Pour rester compatible avec le protocole 2, l’addon peut encore partager ses propres compteurs disponibles et maintenir son historique interne. Ces compteurs n’interviennent pas dans le panneau ni dans l’inspection des talents. Le diagnostic peut afficher les statistiques de ton propre personnage sans demander de comparaison avec un autre joueur.

## Langues

Les textes et descriptions sont traduits pour `enUS`, `enGB` (alias anglais), `frFR`, `deDE`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN` et `zhTW`. La langue est choisie via `GetLocale()`, avec repli anglais pour une locale inconnue ou une clé manquante. Le panneau ajuste sa hauteur aux textes longs. Leur rendu et leur terminologie restent à vérifier dans les clients correspondants.

## Diagnostic

Taper **`/whodueling diagnostic`** après une demande et un clic sur **Cibler**. Les informations utiles sont :

- **Dernier ciblage (joueur / action / confirmé)** : l’adversaire attendu, l’action `target` ou `macro` et la confirmation de sa présence en cible après le clic.
- **Clics Cibler / Ciblages confirmés** : nombre de clics et de sélections vérifiées depuis le chargement de l’addon.
- **Requêtes d’inspection / Réponses d’inspection** : inspections demandées et réponses acceptées pour le GUID attendu.
- **Derniers talents inspectés** : répartition obtenue, ou **Indisponible** lorsque la réponse ne fournit pas de talents lisibles.

Les compteurs repartent à zéro après `/reload`. « Oui » à la ligne **Inspection des talents** confirme la présence des fonctions, sans garantir leur résultat. Cette commande ne contacte aucun joueur. Les échanges peuvent rester à zéro si l’adversaire n’a pas l’addon.

En cas d’erreur, conserver son texte complet, le diagnostic et les étapes de reproduction. BugGrabber/BugSack peuvent aider à recueillir les erreurs.

## Installation manuelle

Extraire le dossier `WhoDueling` dans `World of Warcraft/_classic_beta_/Interface/AddOns`. Le fichier doit être à `AddOns/WhoDueling/WhoDueling.toc`, sans dossier intermédiaire. Redémarrer le jeu après la première installation et activer l’addon ; `/reload` suffit pour cette mise à jour.

Le projet fournit aussi `Installer-Addon.cmd` pour une installation par double-clic et `Install-Addon.ps1` pour une installation depuis PowerShell. Voir le README à la racine du projet.

## Vérification en jeu — à effectuer

1. Recevoir une demande en ayant un autre joueur en cible. Cliquer **Cibler** et vérifier la sélection exacte, sans acceptation du duel. Tester deux personnages avec le même prénom et des noms de famille différents, avec et sans plaque de nom accessible.
2. Comparer `xx/xx/xx` et les noms d’arbres à l’inspection native. Tester un adversaire sans addon, puis un partenaire avec WhoDueling.
3. Tester un joueur non inspectable ou hors de portée : vérifier **Indisponible**, puis se rapprocher et cliquer de nouveau.
4. Refuser, laisser expirer et accepter des demandes successives ; vérifier que les anciennes réponses ne remplissent pas le nouveau panneau.
5. Recevoir une demande en combat, puis sortir du combat ; vérifier le bouton et l’identité de l’adversaire.
6. Ouvrir les hauts faits avant une demande et vérifier l’absence de l’erreur `GetCategoryNumAchievements`. Tester les facteurs d’échelle, noms accentués et différentes langues.

Les tests simulés couvrent ces chemins de code, mais ne reproduisent pas les actions protégées et les réponses du véritable client. La confirmation en jeu reste nécessaire.
