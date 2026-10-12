# WhoDueling 1.0.3

Addon multilingue pour **WoW Forever 1.60.1 / interface 16001**, par Syntaxucre.

Sous une demande de duel, affiche un bouton **Cibler** et les talents `xx/xx/xx`, avec les noms des trois arbres en infobulle. Aucun duel n’est accepté automatiquement.

## Installation dans ton client

Double-cliquer sur **[Installer-Addon.cmd](Installer-Addon.cmd)** à la racine du projet. La fenêtre affiche le résultat et attend une touche avant de se fermer. Si Windows exige les droits administrateur, accepter la demande UAC. Garder le lanceur à côté de `Install-Addon.ps1`, des dossiers `scripts` et `WhoDueling`.

Ou, depuis PowerShell dans le dossier du projet :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Addon.ps1
```

Destination : `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\WhoDueling`.

Prévisualiser : ajouter `-WhatIf`. Choisir une autre installation : ajouter `-AddOnsPath 'D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns'`.

Le script vérifie les sources et les empreintes des fichiers copiés. Il ne déploie que l’addon et sa documentation, sans toucher aux autres addons ni aux données WTF. Le lanceur à double-clic demande les droits administrateur seulement en cas de refus d’accès. Pour la commande PowerShell ci-dessus, ouvrir PowerShell **en tant qu’administrateur** et relancer si nécessaire.

**Première installation : redémarrer WoW**, puis activer WhoDueling. Pour une mise à jour sans nouveau fichier Lua, `/reload` suffit ; sinon redémarrer.

Pour une installation manuelle, extraire `dist/WhoDueling-1.0.3.zip` dans AddOns. Le TOC doit être à `AddOns/WhoDueling/WhoDueling.toc`. L’archive se construit avec `Build-Release.ps1` si elle n’est pas présente après un téléchargement du dépôt.

La version 1.0.3 corrige le format des noms sur Forever : les deux chaînes représentent le **prénom et le nom de famille**, sans royaume. Le bouton conserve les deux parties et utilise par exemple `/targetexact Bia Fine`. Les formats `Bia-Fine` des liens et `Bia Fine` du client sont normalisés pour le ciblage, l’inspection et les échanges privés. Un prénom seul ne suffit pas pour sélectionner un joueur.

La requête de comparaison des hauts faits, retirée en 1.0.2 pour éviter l’erreur Blizzard `GetCategoryNumAchievements` (`id="summary"`), reste désactivée. Le diagnostic indique les ciblages confirmés et les réponses d’inspection. Les données sauvegardées sont conservées.

## Informations et limites

Voir le [guide complet](WhoDueling/README.md) pour les langues, le diagnostic, l’inspection, le partage et les vérifications en jeu.

L’inspection directe ne nécessite aucun addon chez l’adversaire. Pour compléter les talents par échange privé, mettre les deux addons à jour vers 1.0.3 ou plus récent. La disponibilité des talents, le rendu et les actions sécurisées doivent encore être confirmés dans le client ; les tests simulés ne remplacent pas cette étape.

## Développement

```powershell
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

Les tests Lua utilisent Fengari et vérifient aussi la syntaxe Lua 5.1. Le test PowerShell utilise uniquement des dossiers temporaires du projet. L’archive contient uniquement `WhoDueling/` ; les scripts d’installation restent dans le projet.

Références techniques : [prénoms et noms de famille Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua), [événements de duel Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DuelInfoDocumentation.lua), [arbres de talents Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua), [boutons sécurisés](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
