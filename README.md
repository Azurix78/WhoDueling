# WhoDueling 1.0.4

Addon multilingue pour **WoW Forever 1.60.1 / interface 16001**, par Syntaxucre.

Un petit bouton **Who dueled me?** apparaît sous une demande de duel ordinaire. Il sélectionne le joueur qui t’a défié, avec son prénom et son nom de famille complets. La version 1.0.4 garde uniquement cette fonction et conserve le ciblage validé en jeu en 1.0.3.

## Installation

Double-cliquer sur **[Installer-Addon.cmd](Installer-Addon.cmd)** à la racine du projet. La fenêtre affiche le résultat et attend une touche avant de se fermer. Si Windows exige les droits administrateur, accepter la demande UAC. Garder le lanceur à côté de `Install-Addon.ps1`, des dossiers `scripts` et `WhoDueling`.

Ou, depuis PowerShell dans le dossier du projet :

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Addon.ps1
```

Destination : `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\WhoDueling`.

Prévisualiser : ajouter `-WhatIf`. Choisir une autre installation : ajouter `-AddOnsPath 'D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns'`.

Le script vérifie les sources et les empreintes des fichiers copiés. Il copie uniquement les fichiers distribuables, écrase leurs versions précédentes et préserve les autres fichiers. Il refuse les chemins redirigés par une jonction. En cas de refus d’accès avec la commande PowerShell, ouvrir PowerShell **en tant qu’administrateur** et relancer.

**Première installation : redémarrer WoW**, puis activer WhoDueling. Pour cette mise à jour, **`/reload` suffit**.

Pour une installation manuelle, extraire `dist/WhoDueling-1.0.4.zip` dans AddOns. Le TOC doit être à `AddOns/WhoDueling/WhoDueling.toc`. Construire l’archive avec `Build-Release.ps1` si elle n’est pas présente après un téléchargement du dépôt.

## Utilisation

Le bouton se masque en combat et disparaît avec la demande de duel. Son libellé **Who dueled me?** est identique dans toutes les langues ; la description de l’addon reste traduite selon le client. L’adversaire n’a besoin d’aucun addon.

Voir le [guide](WhoDueling/README.md) pour les langues et les vérifications en jeu.

## Développement

```powershell
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

Les tests Lua utilisent Fengari et vérifient la syntaxe Lua 5.1. Les tests PowerShell utilisent des dossiers temporaires du projet. L’archive contient uniquement `WhoDueling/` ; les scripts d’installation restent dans le projet.

Références techniques : [noms complets Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua), [événements de duel](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DuelInfoDocumentation.lua), [boutons sécurisés](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
