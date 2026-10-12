# WhoDueling

Version **1.0.1**, pour **WoW Forever 1.60.1 / interface 16001**. Auteur : Syntaxucre. Licence MIT. Aucune dépendance en jeu.

## Utilisation

Lorsqu’un joueur te demande un duel ordinaire, un panneau apparaît sous la demande Blizzard. **Cibler** sélectionne ce joueur sans accepter le duel. Le panneau affiche ses talents, ses statistiques disponibles et ton bilan contre lui depuis l’installation.

L’addon tente une inspection dès la demande, sans changer ta cible ni ouvrir la fenêtre d’inspection. Il retente lorsque tu cibles l’adversaire. Les informations sont en chargement pendant dix secondes au maximum. L’absence d’une information donne **Indisponible**, jamais un faux zéro. Un total nécessite à la fois un nombre de victoires et de défaites ; une valeur partielle est indiquée par un tiret.

Le bouton est masqué en combat et remplacé par **Disponible hors combat**. Le panneau disparaît lorsque la demande se ferme. Les duels à mort ne sont pas pris en charge.

## Provenance des données

- **Statistiques du jeu** : compteurs lus directement pour l’adversaire, si Forever autorise leur comparaison.
- **Partagées par l’adversaire · statistiques du jeu** : compteurs personnels que son addon a lus dans son client.
- **Partagées par l’adversaire · depuis son installation** : duels confirmés enregistrés par son addon. Ce compteur est partiel et déclaratif ; il n’est pas son total historique officiel.
- **Ton bilan contre ce joueur** : tes duels ordinaires confirmés, reçus comme lancés, enregistrés pendant que WhoDueling fonctionne.

Les talents partagés sont les points de sa configuration active. Les noms d’arbres viennent de ton client lorsque leurs données sont disponibles. Survole la ligne des talents pour voir chaque arbre.

Les statistiques du jeu sont recherchées dans le catalogue du client par leur nom localisé exact (« Duels won / Duels lost » en anglais, « Duels gagnés / Duels perdus » en français). Aucun ID d’une autre édition n’est supposé valide : sur Forever 1.60.1 build 70338, les IDs 527 et 528 vus dans le diagnostic de 1.0.0 désignent des dégâts reçus. Une traduction non reconnue, un compteur absent ou plusieurs compteurs ambigus donnent une information indisponible. Le total affiché est victoires + défaites, pas le nombre de demandes envoyées. Un tiret renvoyé par le jeu reste une information inconnue.

## Partage et sauvegarde

Si les deux adversaires possèdent WhoDueling, une requête privée d’addon est envoyée pour compléter les informations. Aucun message de chat visible, canal public, serveur externe ou compte n’est utilisé. L’addon ne répond qu’à un adversaire de duel identifié et accessible à proximité. Les échanges peuvent échouer, notamment entre factions ou en cas de restrictions/délais du client. L’historique personnel reste disponible.

Les deux joueurs doivent utiliser **1.0.1 ou plus récent** (protocole 2). Les messages de 1.0.0 sont rejetés, car cette version pouvait partager des dégâts reçus sous forme de statistiques de duel. La mise à jour conserve les données locales déjà enregistrées.

Les échanges contiennent les GUID des personnages, un identifiant temporaire de requête, les compteurs et les points de talents avec l’identifiant de leur arbre. Les données reçues ne constituent pas un classement certifié et ne modifient jamais ton historique local.

`WhoDuelingDB` est sauvegardé par WoW dans les SavedVariables de l’addon. Chaque personnage a ses compteurs et ses bilans par adversaire. Le GUID distingue les personnages lorsqu’il est disponible ; sinon le nom avec royaume est utilisé. Aucune donnée antérieure à l’installation n’est reconstituée. Une déconnexion ou un rechargement pendant un duel peut empêcher son enregistrement. Le client doit lire correctement les SavedVariables pour conserver l’historique entre connexions.

## Langues

Les boutons, infobulles, compteurs, états, messages et descriptions sont traduits pour `enUS`, `enGB` (alias anglais), `frFR`, `deDE`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN` et `zhTW`. La langue est choisie via `GetLocale()`, avec repli anglais pour une locale inconnue ou une clé manquante.

Le panneau ajuste sa hauteur aux textes longs. Les traductions sont complètes dans le code ; leur terminologie et leur rendu nécessitent une relecture dans les clients correspondants. Les résultats sont analysés à partir des formats système Blizzard de ton client, y compris les paramètres positionnels et variantes grammaticales. Un message non reconnu est ignoré.

## Diagnostic

Taper **`/whodueling diagnostic`** pour afficher la version du client, la langue, les API disponibles, les IDs et noms des compteurs de duel reconnus, les compteurs personnels et les statistiques d’échange. « Yes » confirme uniquement la présence des fonctions, pas la réussite d’une inspection ni l’accès aux données de l’adversaire. Cette commande ne demande aucune information à d’autres joueurs ; les échanges peuvent donc rester à zéro avant une demande de duel.

En cas d’erreur, conserver son texte complet, le résultat du diagnostic et les étapes de reproduction. BugGrabber/BugSack peuvent aider à recueillir les erreurs.

## Installation manuelle

Extraire le dossier `WhoDueling` dans `World of Warcraft/_classic_beta_/Interface/AddOns`. Le fichier doit être à `AddOns/WhoDueling/WhoDueling.toc`, sans dossier intermédiaire. Redémarrer le jeu après la première installation et activer l’addon ; `/reload` suffit pour une mise à jour sans ajout de fichier.

## Vérification en jeu — à effectuer

1. Recevoir une demande sans avoir l’adversaire en cible ; vérifier le panneau et le clic Cibler, sans acceptation du duel.
2. Vérifier les talents avec l’inspection native et les compteurs avec les statistiques du personnage inspecté. Tester un joueur sans points de talent et un joueur non inspectable.
3. Refuser, laisser expirer et accepter des demandes successives. Recevoir une demande en combat puis sortir du combat ; vérifier qu’aucun ancien adversaire n’est ciblé.
4. Gagner, perdre et fuir des duels, reçus comme lancés ; vérifier une seule modification du bilan par résultat. Refuser une demande ne doit rien ajouter.
5. Tester un partenaire avec WhoDueling puis sans l’addon, et des factions différentes. Vérifier les mentions de provenance et les informations indisponibles.
6. Faire `/reload`, puis une déconnexion/reconnexion ; vérifier la persistance et la séparation entre personnages.
7. Vérifier le panneau avec plusieurs fenêtres Blizzard, des textes longs, différents facteurs d’échelle et des noms accentués. Tester le rendu dans les différentes langues.
8. Vérifier l’absence d’erreur Lua et de blocage d’action protégée avec BugGrabber/BugSack. Les simulations ne reproduisent pas les protections natives du client.
