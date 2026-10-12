local _, addon = ...
local Logic = {}
addon.Logic = Logic

-- Secret values must never be compared, formatted or persisted by this addon.
function Logic.Public(value)
    return not issecretvalue or not issecretvalue(value)
end

function Logic.Name(name, surname)
    if not Logic.Public(name) or not Logic.Public(surname) or type(name) ~= "string" then return nil end
    name = name:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    -- Player links may display only the first name. Use the full identity
    -- stored in the link, where the surname separator is a hyphen.
    name = name:gsub("|Hplayer:([^:|]+)[^|]*|h[^|]*|h", "%1"):gsub("^%[", ""):gsub("%]$", "")
    name = name:gsub("|%d[%d%-]*%((.-)%)", "%1")
    -- WoW's grammar annotation follows a name on some RU/KR messages.
    name = name:gsub("|[1234567890]+", "")
    local constants = Constants and Constants.CharacterNameSeparatorConsts
    local separator = constants and constants.CHARACTERNAME_SURNAME_SEPARATOR or " "
    if type(separator) ~= "string" or #separator ~= 1 then return nil end
    local first, last = name:match("^([^%s%-]+)[ %-]([^%s%-]+)$")
    if not first then first = name end
    if surname ~= nil and surname ~= "" then
        if type(surname) ~= "string" or last and last ~= surname then return nil end
        last = surname
    end
    -- Forever has no realms: the two required parts are first name/surname.
    -- Never guess a surname or target a potentially ambiguous first name.
    local function valid(part)
        return type(part) == "string" and part ~= "" and #part <= 80 and
            not part:find("[%s|%c/;%-\\%[%]\"]")
    end
    if not valid(first) or not valid(last) then return nil end
    return first .. separator .. last
end

function Logic.SameName(a, b)
    return a ~= nil and b ~= nil and a == b
end
