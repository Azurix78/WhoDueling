local _, addon = ...
local keys = { "target" }
local translations = {
    enUS = { "Target" },
    frFR = { "Cibler" },
    deDE = { "Anvisieren" },
    esES = { "Seleccionar" },
    esMX = { "Seleccionar" },
    itIT = { "Seleziona" },
    ptBR = { "Selecionar" },
    ruRU = { "Выбрать" },
    koKR = { "대상 지정" },
    zhCN = { "选中" },
    zhTW = { "選取" },
}
translations.enGB = translations.enUS
addon.Translations, addon.LocaleKeys = translations, keys
local selected = translations[GetLocale()] or translations.enUS
addon.L = { target = selected[1] or translations.enUS[1] }
