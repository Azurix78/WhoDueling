# WhoDueling 1.0.4

A small addon for **WoW Forever 1.60.1 / interface 16001**, by Syntaxucre.

When a player challenges you to a regular duel, a **Who dueled me?** button appears below the Blizzard dialog. Click it to target the challenger using their complete first name and surname. The button hides during combat and disappears when the request closes.

## CurseForge upload

The ready-to-upload file is **`dist/WhoDueling-1.0.4.zip`**. Select the **Forever** flavor and game version **1.60.1**.

The [upload guide](curseforge/UPLOAD.md) includes all project and file fields. Project page materials:

- [English description](curseforge/DESCRIPTION.md)
- [Summary](curseforge/SUMMARY.txt)
- [Changelog](WhoDueling/CHANGELOG.md)
- [512 × 512 PNG logo](curseforge/icon.png) and [editable SVG](curseforge/icon.svg)

The ZIP contains only the installable `WhoDueling/` folder. Installers, tests, development files, and project page materials stay outside it.

## Installation

Install using the CurseForge app for your Forever installation, or extract the ZIP's `WhoDueling` folder into your game's `Interface/AddOns` directory. The TOC must be at `AddOns/WhoDueling/WhoDueling.toc`.

For installation from this source project, double-click **[Installer-Addon.cmd](Installer-Addon.cmd)**. The window displays the result and waits for a key before closing. Accept the Windows administrator prompt if needed. Keep the launcher next to `Install-Addon.ps1`, `scripts/`, and `WhoDueling/`.

Alternatively, run PowerShell from the project directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Install-Addon.ps1
```

The default destination is `C:\Program Files (x86)\World of Warcraft\_classic_beta_\Interface\AddOns\WhoDueling`.

Add `-WhatIf` to preview the copy. Choose another installation with `-AddOnsPath 'D:\Games\World of Warcraft\_classic_beta_\Interface\AddOns'`.

The installer verifies source files and copied hashes, overwrites distributed files, and preserves other files. It rejects symbolic links and junctions. If the PowerShell command reports access denied, open PowerShell **as administrator** and run it again.

After the first installation, **restart WoW** and enable WhoDueling. For an update while the addon is already loaded, use **`/reload`**.

See the [addon guide](WhoDueling/README.md) for usage and validation details. All project text and the button label are in English.

## Development and packaging

```powershell
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

Lua tests use Fengari and check Lua 5.1 syntax. PowerShell tests use temporary directories in the project and check installation, updates, path handling, and ZIP entry hashes. The build prints the upload archive path and its SHA256 checksum.

To recreate the project page logo on Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\curseforge\Build-Icon.ps1
```

## Source and license

[Source code](https://github.com/Azurix78/WhoDueling) · [Issues](https://github.com/Azurix78/WhoDueling/issues) · [MIT license](WhoDueling/LICENSE)

Technical references: [Forever names](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXMLUtil/Camelot/NameUtil.lua), [duel events](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/DuelInfoDocumentation.lua), and [secure buttons](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_FrameXML/SecureTemplates.lua).
