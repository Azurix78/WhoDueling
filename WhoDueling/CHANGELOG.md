# Changelog

## 1.0.4

- Simplified WhoDueling to a single compact targeting button below the regular duel request dialog.
- Set the button label to **Who dueled me?** in every client language.
- Preserved exact targeting using the challenger's complete first name and surname.
- Kept the button hidden during combat and removed it when the duel request closes.
- Removed talent inspection, statistics, duel history, addon messaging, and the diagnostic command.
- Prepared the upload archive with an English README, changelog, and MIT license.
- Updated all project documentation, addon descriptions, and installer messages to English.

## 1.0.3

- Corrected Forever's first-name and surname handling for targeting and player identification.
- Preserved both name parts in the `/targetexact` fallback.

## 1.0.2

- Removed achievement comparison requests that could trigger a Blizzard UI error.
- Added secure unit targeting and improved inspection diagnostics.

## 1.0.1

- Corrected duel statistic discovery to avoid using unrelated damage counters.

## 1.0.0

- Initial version with a duel request panel, targeting, talent inspection, and statistics.
