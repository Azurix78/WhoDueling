# WhoDueling 1.0.0

Addon multilingue pour **WoW Forever 1.60.1 / interface 16001**, par Syntaxucre.

Sous une demande de duel, affiche un bouton **Cibler**, les talents `xx/xx/xx`, les statistiques disponibles de l’adversaire et ton bilan contre lui. Aucun duel n’est accepté automatiquement.

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

Pour une installation manuelle, extraire `dist/WhoDueling-1.0.0.zip` dans AddOns. Le TOC doit être à `AddOns/WhoDueling/WhoDueling.toc`.

## Informations et limites

Voir le [guide complet](WhoDueling/README.md) pour les langues, le diagnostic, la provenance des statistiques et le protocole de validation en jeu.

L’historique personnel fonctionne sans addon chez l’adversaire. Les données globales et talents dépendent des API du client ; leur disponibilité réelle, le rendu et les restrictions de ciblage doivent encore être vérifiés en jeu. Les tests simulés ne remplacent pas cette étape.

## Développement

```powershell
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

Les tests Lua utilisent Fengari et vérifient aussi la syntaxe Lua 5.1. Le test PowerShell utilise uniquement des dossiers temporaires du projet. L’archive contient uniquement `WhoDueling/` ; les scripts d’installation restent dans le projet.

Références techniques : [événements de duel Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DuelInfoDocumentation.lua), [arbres de talents Forever](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_PlayerSpells/Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua), [statistiques natives](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Statistics/Camelot/StatisticsFrame.lua), [boutons sécurisés](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
