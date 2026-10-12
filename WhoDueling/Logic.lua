local _, addon = ...
local Logic = {}
addon.Logic = Logic
-- Version 1 peers could mislabel damage statistics as duels. Reject their
-- profiles; both players must update before using shared game statistics.
Logic.PROTOCOL = "2"

-- Secret values must never be compared, formatted or persisted by this addon.
function Logic.Public(value)
    return not issecretvalue or not issecretvalue(value)
end

function Logic.Count(value)
    if not Logic.Public(value) then return nil end
    if type(value) == "string" then
        value = value:gsub("\194\160", " "):gsub("\226\128\175", " ")
        if not value:match("^%d+$") then
            local first, rest = value:match("^(%d%d?%d?)([ ,%.]%d.*)$")
            if not first then return nil end
            local separator = rest:sub(1, 1)
            while rest ~= "" do
                if rest:sub(1, 1) ~= separator or not rest:sub(2, 4):match("^%d%d%d$") then return nil end
                first, rest = first .. rest:sub(2, 4), rest:sub(5)
            end
            value = first
        end
        value = tonumber(value)
    end
    if type(value) ~= "number" or value ~= value or value < 0 or value > 1000000000 or value % 1 ~= 0 then return nil end
    return value
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

local function escape(value)
    return (value:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

-- Compile Blizzard printf templates, including reordered %2$s parameters.
-- Grammar choices are expanded to alternatives, never stripped from templates.
local function expandGrammar(template, depth)
    if depth > 8 then return {} end
    local a, b, first, second = template:find("|[12]([^;]*);([^;]*);")
    local alternatives
    if a then alternatives = first .. ":" .. second
    else a, b, alternatives = template:find("|[345]([^;]+);") end
    if not a then return { template } end
    local result = {}
    for choice in (alternatives .. ":"):gmatch("(.-):") do
        for _, expanded in ipairs(expandGrammar(template:sub(1, a - 1) .. choice .. template:sub(b + 1), depth + 1)) do
            result[#result + 1] = expanded
            if #result >= 64 then return result end
        end
    end
    return result
end

local function compile(template)
    local pattern, slots, position, implicit = "^", {}, 1, 0
    while position <= #template do
        local a, b, slot = template:find("%%(%d+)%$s", position)
        local sa, sb = template:find("%%s", position)
        if sa and (not a or sa < a) then a, b, slot = sa, sb, nil end
        if not a then pattern = pattern .. escape(template:sub(position)); break end
        pattern = pattern .. escape(template:sub(position, a - 1)) .. "(.-)"
        implicit = implicit + 1
        slots[#slots + 1] = tonumber(slot) or implicit
        position = b + 1
    end
    return { pattern = pattern .. "$", slots = slots }
end

function Logic.ResultPatterns(knockout, retreat)
    local result = {}
    for _, entry in ipairs({ { knockout, false }, { retreat, true } }) do
        if type(entry[1]) == "string" then
            local template = entry[1]:gsub("|%d[%d%-]*%((.-)%)", "%1")
            for _, variant in ipairs(expandGrammar(template, 0)) do
                local item = compile(variant)
                if #item.slots == 2 then item.retreat = entry[2]; result[#result + 1] = item end
            end
        end
    end
    return result
end

function Logic.ParseResult(message, patterns)
    if not Logic.Public(message) or type(message) ~= "string" then return nil end
    message = message:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|H[^|]+|h([^|]+)|h", "%1"):gsub("|%d[%d%-]*%((.-)%)", "%1")
    for _, variant in ipairs(expandGrammar(message, 0)) do
      for _, item in ipairs(patterns) do
        local captures = { variant:match(item.pattern) }
        if #captures == 2 then
            local names = {}
            for i, slot in ipairs(item.slots) do names[slot] = Logic.Name(captures[i]) end
            if names[1] and names[2] and names[1] ~= names[2] then
                if item.retreat then return names[2], names[1] end
                return names[1], names[2]
            end
        end
      end
    end
end

function Logic.NewRecord()
    return { wins = 0, losses = 0 }
end

function Logic.Character(db, guid)
    if type(db) ~= "table" or db.version ~= 1 or type(db.characters) ~= "table" then
        db = { version = 1, characters = {}, previous = db }
    end
    local char = db.characters[guid]
    if type(char) ~= "table" then char = {}; db.characters[guid] = char end
    char.wins = Logic.Count(char.wins) or 0
    char.losses = Logic.Count(char.losses) or 0
    if type(char.opponents) ~= "table" then char.opponents = {} end
    if type(char.names) ~= "table" then char.names = {} end
    return db, char
end

function Logic.Opponent(char, name, guid)
    local key = guid or char.names[name] or name
    if guid then
        -- Merge only the exact full-name fallback, not an old character GUID.
        local fallback = char.opponents[name]
        if type(fallback) == "table" and name ~= guid then
            local existing = char.opponents[guid] or Logic.NewRecord()
            if type(existing) ~= "table" then existing = Logic.NewRecord() end
            existing.wins = (Logic.Count(existing.wins) or 0) + (Logic.Count(fallback.wins) or 0)
            existing.losses = (Logic.Count(existing.losses) or 0) + (Logic.Count(fallback.losses) or 0)
            char.opponents[guid], char.opponents[name] = existing, nil
        end
        char.names[name] = guid
    end
    local record = char.opponents[key]
    if type(record) ~= "table" then record = Logic.NewRecord(); char.opponents[key] = record end
    record.wins, record.losses = Logic.Count(record.wins) or 0, Logic.Count(record.losses) or 0
    return record
end

-- Protocol 2: Q|token|requesterGUID|recipientGUID
-- R|token|senderGUID|recipientGUID|G/L/N|wins/-|losses/-|treeID/-|p1/-|p2/-|p3/-
-- No translated strings or executable content travel over the wire.
function Logic.Decode(message)
    if not Logic.Public(message) or type(message) ~= "string" or #message > 240 then return nil end
    local fields = {}
    for field in (message .. "|"):gmatch("(.-)|") do fields[#fields + 1] = field end
    if fields[1] ~= Logic.PROTOCOL or (fields[2] ~= "Q" and fields[2] ~= "R") then return nil end
    if not fields[3] or not fields[3]:match("^%d+%-%d+$") or #fields[3] > 40 then return nil end
    for i = 4, 5 do
        if not fields[i] or #fields[i] > 80 or not fields[i]:match("^Player%-%x+%-%x+$") then return nil end
    end
    if fields[2] == "Q" then if #fields ~= 5 then return nil end; return fields end
    if #fields ~= 12 or not fields[6]:match("^[GLN]$") then return nil end
    for i = 7, 12 do
        if fields[i] ~= "-" and (not fields[i]:match("^%d+$") or not Logic.Count(fields[i])) then return nil end
    end
    if fields[6] == "N" and (fields[7] ~= "-" or fields[8] ~= "-") then return nil end
    if fields[6] == "L" and (fields[7] == "-" or fields[8] == "-") then return nil end
    local talents = fields[9] ~= "-" and fields[10] ~= "-" and fields[11] ~= "-" and fields[12] ~= "-"
    if talents and tonumber(fields[9]) == 0 then return nil end
    if talents then for i = 10, 12 do if tonumber(fields[i]) > 1000 then return nil end end end
    if not talents and (fields[9] ~= "-" or fields[10] ~= "-" or fields[11] ~= "-" or fields[12] ~= "-") then return nil end
    return fields
end
