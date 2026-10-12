# CurseForge upload guide

The upload package is **`dist/WhoDueling-1.0.4.zip`**. Upload this archive as the addon file. The `curseforge` directory contains the project page materials; it is kept outside the addon ZIP.

## Create the project

Open the [CurseForge author dashboard](https://authors.curseforge.com/#/projects/create/choose-game) and use these values:

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Project name | WhoDueling |
| Suggested slug | whodueling, if available |
| Summary | Contents of `SUMMARY.txt` |
| Description | Contents of `DESCRIPTION.md`, using the Markdown editor |
| Class | Addons |
| Main category | PvP |
| License | MIT License |
| Logo | `icon.png` (512 × 512 PNG) |
| Source | https://github.com/Azurix78/WhoDueling |
| Issues | https://github.com/Azurix78/WhoDueling/issues |

The supplied logo is an original graphic. Its editable SVG source is `icon.svg`. Check the project name and slug in the form before submitting; availability is determined by CurseForge.

## Upload the file

| Field | Value |
| --- | --- |
| Upload file | `dist/WhoDueling-1.0.4.zip` |
| Display name | WhoDueling 1.0.4 |
| Game flavor | Forever / WoW Forever |
| Supported game version | 1.60.1 |
| Release type | Release |
| Changelog | Contents of `WhoDueling/CHANGELOG.md` |
| Required dependencies | None |

Select **Forever**, which is already available on CurseForge, and tag only the supported **1.60.1** version. A game's beta status is separate from the addon file's release type. CurseForge requires at least one Release file for a project to appear in the app by default. Submission is followed by CurseForge moderation.

The archive contains one top-level `WhoDueling` folder, its matching `WhoDueling.toc`, five Lua files, the English README and changelog, and the MIT license. Development files, installers, tests, and project page artwork are excluded.

The TOC already includes the website and license. No CurseForge project ID is hardcoded, and no placeholder ID is included.

## Rebuild and check

Run from the project root:

```powershell
npm install
npm test
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Packaging.Tests.ps1
```

The packaging checks rebuild the archive and compare every entry with its source file. To build the ZIP alone:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build-Release.ps1
```

The build prints the archive path and SHA256 checksum. For a future release, update the TOC version, `Core.lua`, `package.json`, the changelog, and the version references in the documentation before rebuilding.

Targeting was confirmed in game in 1.0.3. The compact button layout added in 1.0.4 is covered by simulated tests; check its placement in your client before publishing.

## References

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241-creating-and-submitting-a-project): project fields, ZIP uploads, release types, and moderation.
- [Submission guide](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips): English project text and original square PNG logo of at least 400 × 400 pixels.
- [WoW addon TOC guidance](https://support.curseforge.com/support/solutions/articles/9000209856): matching folder and TOC names and version tags.
- [Existing Forever addon listing](https://www.curseforge.com/wow/addons/foreverforge): Forever flavor and 1.60.1 game version.
