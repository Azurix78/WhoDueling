local _, addon = ...
local keys = { "target" }
local targetLabel = "Who dueled me?"
local translations = {
    enUS = { targetLabel },
    frFR = { targetLabel },
    deDE = { targetLabel },
    esES = { targetLabel },
    esMX = { targetLabel },
    itIT = { targetLabel },
    ptBR = { targetLabel },
    ruRU = { targetLabel },
    koKR = { targetLabel },
    zhCN = { targetLabel },
    zhTW = { targetLabel },
}
translations.enGB = translations.enUS
addon.Translations, addon.LocaleKeys = translations, keys
local selected = translations[GetLocale()] or translations.enUS
addon.L = { target = selected[1] or translations.enUS[1] }
