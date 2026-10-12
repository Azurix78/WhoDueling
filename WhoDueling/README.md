# WhoDueling

Version **1.0.4**, for **WoW Forever 1.60.1 / interface 16001**. Author: Syntaxucre. MIT license.

When a player challenges you to a regular duel, a small **Who dueled me?** button appears below the Blizzard dialog. Clicking it targets the challenger using their complete **first name and surname**. This keeps the targeting behavior confirmed in game in version 1.0.3.

The button is hidden during combat and disappears when the request is accepted, declined, cancelled, or expires. The Blizzard duel dialog works as usual. Duels to the death are excluded.

Version 1.0.4 provides targeting only. Talent inspection, statistics, duel history, addon messaging, and the diagnostic command have been removed. Your opponent does not need an addon.

## Installation

Double-click `Installer-Addon.cmd` in the project root, then use `/reload` for this update. After the first installation, restart WoW and enable WhoDueling.

To install manually, extract the `WhoDueling` folder into `World of Warcraft/_classic_beta_/Interface/AddOns`. The TOC file must be located at `AddOns/WhoDueling/WhoDueling.toc`, with no extra folder in between.

## Languages and targeting

The button is labelled **Who dueled me?** in every language. The addon description is translated for `enUS`, `enGB`, `frFR`, `deDE`, `esES`, `esMX`, `itIT`, `ptBR`, `ruRU`, `koKR`, `zhCN`, and `zhTW`, with an English fallback for unknown locales.

Forever uses a first name and surname, without realms. Both parts are always preserved. When a matching unit is available, the button uses the native secure targeting action. Otherwise, it runs a command such as `/targetexact Bia Fine`. The player must be present and targetable by the client.

## Validation

Simulated tests cover full names, players sharing the same first name, successive requests, dialog closure, combat, and button positioning. The installer and archive are checked using temporary directories.

After updating, check in game that only the button appears, that it targets the challenger, and that it disappears with the request. Targeting was confirmed in game by the user in version 1.0.3; the new button position still needs to be confirmed in the client.
