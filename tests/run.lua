local passed = 0
local function eq(a, b, label)
    if a ~= b then error((label or "assertion") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err), 0) end
    passed = passed + 1; print("PASS " .. name)
end
local function loadFile(file, addon)
    assert((loadstring or load)(assert(TEST_FILES[file]), "@" .. file))("WhoDueling", addon)
end
local function newFrame(parent)
    local f = { scripts = {}, hooks = {}, attributes = {}, shown = false, parent = parent, height = 1 }
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:HookScript(event, fn) self.hooks[event] = fn end
    function f:RegisterEvent(event) self.events = self.events or {}; self.events[event] = true end
    function f:SetAttribute(key, value) assert(not COMBAT, "attribute changed in combat"); self.attributes[key] = value end
    function f:SetPoint(...) self.point = { ... } end
    function f:ClearAllPoints() self.point = nil end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:SetHeight(h) self.height = h end
    function f:GetHeight() return self.height end
    function f:SetWidth(w) self.width = w end
    function f:SetFrameStrata(_) end
    function f:SetBackdrop(_) end
    function f:EnableMouse(_) end
    function f:RegisterForClicks(...) self.clicks = { ... } end
    function f:SetJustifyH(_) end
    function f:SetWordWrap(_) end
    function f:SetText(t) self.text = t end
    function f:GetStringHeight() return math.max(14, math.ceil(#(self.text or "") / 42) * 14) end
    function f:GetLeft() return self.left or 400 end
    function f:GetTop() return self.top or 400 end
    function f:CreateFontString(...) return newFrame(self) end
    function f:Show() self.shown = true end
    function f:Hide()
        self.shown = false
        if self.hooks.OnHide then self.hooks.OnHide(self) end
    end
    function f:IsShown() return self.shown end
    return f
end

local function environment(locale, database)
    COMBAT = false
    local env = { time = 100, sent = {}, inspections = {}, comparisons = {}, units = {}, calls = {}, chats = {}, hooks = {},
        entries = { { id = 527, name = "Largest hit received", quantity = "12345" },
            { id = 528, name = "Total damage received", quantity = "67890" },
            { id = 9001, key = "wins" }, { id = 9002, key = "losses" } } }
    local me, other = "Player-1-000001", "Player-1-000002"
    env.me, env.other = me, other
    env.units.player = { name = "Moi", guid = me }
    env.units.target = { name = "Rival", guid = other }
    GetLocale = function() return locale or "frFR" end
    GetTime = function() return env.time end
    GetServerTime = function() return 1800000000 end
    GetNormalizedRealmName = function() return "Realm" end
    GetRealmName = GetNormalizedRealmName
    GetBuildInfo = function() return "1.60.1", "70338", "date", 16001 end
    UnitFullName = function(unit) local u = env.units[unit]; if u then return u.name, "Realm" end end
    UnitName = UnitFullName
    UnitGUID = function(unit) return env.units[unit] and env.units[unit].guid end
    UnitIsPlayer = function(unit) return env.units[unit] ~= nil end
    InCombatLockdown = function() return COMBAT end
    issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    CanInspect = function(unit) return env.inspectable ~= false and env.units[unit] ~= nil end
    NotifyInspect = function(unit) env.inspections[#env.inspections + 1] = unit end
    SetAchievementComparisonUnit = function(unit) env.comparisons[#env.comparisons + 1] = unit end
    GetDuelerInfo = function() return env.dueler end
    GetPlayerInfoByGUID = function(guid)
        for _, unit in pairs(env.units) do
            if unit.guid == guid then return "Mage", "MAGE", "Human", "Human", 2, unit.name, "Realm" end
        end
    end
    GetStatisticsCategoryList = function() return env.noCounters and {} or env.categories or { 1 } end
    GetCategoryNumAchievements = function(_) return #env.entries end
    GetStatistic = function(id, index)
        if index then local row = env.entries[index]; return row.quantity or "0", row.skip or false, row.id end
        env.calls[#env.calls + 1] = id
        for _, row in ipairs(env.entries) do
            if row.id == id then return row.key and env.native and env.native[row.key] or row.quantity end
        end
    end
    GetComparisonStatistic = function(id)
        for _, row in ipairs(env.entries) do
            if row.id == id then return row.key and env.compared and env.compared[row.key] or row.quantity end
        end
    end
    GetAchievementInfo = function(id)
        for _, row in ipairs(env.entries) do
            if row.id == id then return id, row.name or env.addon.L[row.key == "wins" and "statWins" or "statLosses"] end
        end
    end
    C_NamePlate = { GetNamePlates = function() return env.plates or {} end }
    Constants = { TraitConsts = { INSPECT_TRAIT_CONFIG_ID = -1 } }
    C_Traits = {
        HasValidInspectData = function() return not env.invalidTalents end,
        GetConfigInfo = function(id) if env.invalidTalents then return nil end; return { treeIDs = { 42 } } end,
        GetGroupDisplayInfoByTreeID = function(id)
            return { { groupID = 30, orderIndex = 3, displayName = "Givre" },
                { groupID = 10, orderIndex = 1, displayName = "Arcane" },
                { groupID = 20, orderIndex = 2, displayName = "Feu" } }
        end,
        GetGroupCurrencyInfo = function(id, ids)
            if env.invalidTalents then return nil end
            return { { traitNodeGroupID = 20, currencyInfos = { { spent = 21 } } },
                { traitNodeGroupID = 30, currencyInfos = { { spent = 30 } } },
                { traitNodeGroupID = 10, currencyInfos = { { spent = 0 } } } }
        end,
    }
    C_ClassTalents = { GetActiveConfigID = function() return 7 end }
    Enum = { RegisterAddonMessagePrefixResult = { Success = 0 }, SendAddonMessageResult = { Success = 0 } }
    C_ChatInfo = {
        RegisterAddonMessagePrefix = function(prefix) eq(prefix, "WHODUELING"); return 0 end,
        SendAddonMessage = function(prefix, message, channel, name)
            env.sent[#env.sent + 1] = { prefix = prefix, message = message, channel = channel, name = name }
            return env.sendError and 1 or 0
        end,
    }
    UIParent = newFrame()
    GameTooltip = newFrame()
    function GameTooltip:SetOwner(owner, _) self.owner = owner end
    function GameTooltip:GetOwner() return self.owner end
    function GameTooltip:AddLine(...) end
    DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) env.chats[#env.chats + 1] = message end }
    CreateFrame = function(_, _, parent, template) local f = newFrame(parent); f.template = template; return f end
    RegisterStateDriver = function(f, name, condition) assert(not COMBAT, "driver changed in combat"); f.driver = condition end
    env.popup = newFrame()
    env.popup.which = "DUEL_REQUESTED"
    env.popup:Show()
    StaticPopup_FindVisible = function(which) if env.popup:IsShown() and env.popup.which == which then return env.popup end end
    StartDuel = function(...) if env.hooks.StartDuel then env.hooks.StartDuel(...) end end
    hooksecurefunc = function(name, fn) env.hooks[name] = fn end
    InspectFrame, PlayerSpellsFrame, AchievementFrameComparison = nil, nil, nil
    DUEL_WINNER_KNOCKOUT = "%s a vaincu %s en duel."
    DUEL_WINNER_RETREAT = "%s a fui face à %s en duel."
    WhoDuelingDB = database
    SlashCmdList = {}
    local addon = {}
    for _, file in ipairs({ "Localization.lua", "Logic.lua", "Data.lua", "UI.lua", "Core.lua" }) do loadFile(file, addon) end
    env.addon = addon
    function env.event(event, ...) addon.frame.scripts.OnEvent(addon.frame, event, ...) end
    function env.advance(seconds) env.time = env.time + seconds; addon.Tick() end
    env.event("ADDON_LOADED", "WhoDueling")
    return env
end

test("all locales are complete and preserve format placeholders", function()
    local addon = environment().addon
    for locale, translation in pairs(addon.Translations) do
        eq(#translation, #addon.LocaleKeys, locale)
        for i, english in ipairs(addon.Translations.enUS) do
            assert(type(translation[i]) == "string" and translation[i] ~= "", locale)
            local function placeholders(s) return (s:gsub("[^%%]", "")) end
            eq(placeholders(translation[i]), placeholders(english), locale .. " / " .. addon.LocaleKeys[i])
            if english:find("%%s") then assert(pcall(string.format, translation[i], "10", "6", "4")) end
            if english:find("%%d") then assert(pcall(string.format, translation[i], 3)) end
        end
        if locale ~= "enUS" and locale ~= "enGB" then assert(TEST_TOC:find("## Notes-" .. locale .. ":", 1, true)) end
    end
    eq(environment("enGB").addon.L.target, "Target")
    eq(environment("unknown").addon.L.target, "Target")
end)

test("counts reject missing, fractional, negative, secret and malformed values", function()
    local logic = environment().addon.Logic
    for _, value in ipairs({ "--", "", "1.5", "1,23", "1e2", "NaN", -1, 1.5, { secret = true } }) do eq(logic.Count(value), nil) end
    eq(logic.Count("0"), 0); eq(logic.Count("1,234,567"), 1234567)
    eq(logic.Count("1.234"), 1234); eq(logic.Count("1\194\160234"), 1234)
    eq(logic.Count("1\226\128\175234"), 1234)
end)

test("macro names reject injection and normalize realms and links", function()
    local l = environment().addon.Logic
    eq(l.Name("Rival\n/duel Moi", "Realm"), nil)
    eq(l.Name("Rival;/duel", "Realm"), nil)
    eq(l.Name("Rival", "La Croisade"), "Rival-LaCroisade")
    eq(l.Name("|Hplayer:Rival|h[Rival]|h", "Realm"), "Rival-Realm")
end)

test("Blizzard result templates support every locale and literal pattern symbols", function()
    local l = environment().addon.Logic
    local templates = {
        "%s has defeated %s in a duel.", "%s a vaincu %s en duel.", "%s hat %s in einem Duell besiegt.",
        "%s ha derrotado a %s en un duelo.", "%s ha sconfitto %s in duello.", "%s derrotou %s em um duelo.",
        "%s побеждает %s в дуэли.", "%s 님이 %s 님과의 결투에서 승리했습니다.",
        "%s在决斗中战胜了%s。", "%s在決鬥中擊敗了%s。", "%s (%s) [duel] + win?",
    }
    for _, template in ipairs(templates) do
        local patterns = l.ResultPatterns(template, nil)
        local winner, loser = l.ParseResult(string.format(template, "Moi", "Rival"), patterns, "Realm")
        eq(winner, "Moi-Realm"); eq(loser, "Rival-Realm")
    end
    local p = l.ResultPatterns("%2$s lost to %1$s.", "%1$s fled from %2$s.")
    local w, loser = l.ParseResult("Rival lost to Moi.", p, "Realm"); eq(w, "Moi-Realm"); eq(loser, "Rival-Realm")
    w, loser = l.ParseResult("Rival fled from Moi.", p, "Realm"); eq(w, "Moi-Realm"); eq(loser, "Rival-Realm")
end)

test("grammar alternatives, Korean particles and Russian wrappers", function()
    local l = environment().addon.Logic
    local p = l.ResultPatterns("%s |4has:have; beaten %s.", nil)
    eq(l.ParseResult("Moi has beaten Rival.", p, "Realm"), "Moi-Realm")
    eq(l.ParseResult("Moi have beaten Rival.", p, "Realm"), "Moi-Realm")
    eq(l.ParseResult("Moi |4has:have; beaten Rival.", p, "Realm"), "Moi-Realm")
    p = l.ResultPatterns("%s|1이;가; %s 승리.", nil)
    eq(l.ParseResult("Moi가 Rival 승리.", p, "Realm"), "Moi-Realm")
    p = l.ResultPatterns("%s побеждает |3-6(%s).", nil)
    local w, loser = l.ParseResult("Moi побеждает |3-6(Rival).", p, "Realm")
    eq(w, "Moi-Realm"); eq(loser, "Rival-Realm")
end)

test("button targets exact challenger without changing target or accepting duel", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Rival-Realm")
    eq(e.addon.UI.button.driver, "[combat] hide; show")
    eq(e.units.target.name, "Rival"); eq(e.addon.UI.panel:IsShown(), true)
    assert(e.addon.UI.button.parent ~= e.popup and e.addon.UI.button.parent ~= e.addon.UI.panel)
    eq(#e.sent, 1); eq(#e.inspections, 1); eq(#e.comparisons, 1)
    e.addon.UI.button.hooks.PostClick(); eq(#e.sent, 1)
    e.popup:Hide(); eq(e.addon.request, nil)
    eq(e.addon.UI.button.attributes.macrotext, nil); eq(e.addon.UI.panel:IsShown(), false)
end)

test("mouseovers and nameplates allow inspection without targeting the player", function()
    local e = environment(); e.units.mouseover = e.units.target; e.units.target = nil
    e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    eq(e.inspections[1], "mouseover"); eq(e.units.target, nil)
    e = environment(); e.units.nameplate1 = e.units.target; e.units.target = nil
    e.plates = { { namePlateUnitToken = "nameplate1" } }
    e.event("DUEL_REQUESTED", "Rival"); eq(e.inspections[1], "nameplate1")
end)

test("inspection sorts groups, preserves zero and ignores wrong or obsolete GUIDs", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival")
    e.event("INSPECT_READY", e.me); eq(e.addon.request.talents, nil)
    e.event("INSPECT_READY", e.other)
    eq(table.concat(e.addon.request.talents.points, "/"), "0/21/30")
    eq(e.addon.request.talents.names[1], "Arcane")
    e.units.target = { name = "Autre", guid = "Player-1-000003" }
    e.event("DUEL_REQUESTED", "Autre"); e.advance(2.1)
    e.event("INSPECT_READY", e.other); eq(e.addon.request.talents, nil)
end)

test("late responses and target changes cannot populate the wrong player's data", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival")
    e.units.target = { name = "Autre", guid = "Player-1-000003" }
    e.event("INSPECT_READY", e.other); eq(e.addon.request.talents, nil)
    e.compared = { wins = "10", losses = "3" }
    e.event("INSPECT_ACHIEVEMENT_READY", e.other); eq(e.addon.request.stats, nil)
    e.advance(10); e.event("INSPECT_READY", e.other); eq(e.addon.request.talents, nil)
    e.event("DUEL_FINISHED"); e.event("INSPECT_READY", e.other); eq(e.addon.request, nil)
end)

test("missing inspection becomes unavailable after ten seconds", function()
    local e = environment(); e.units.target = nil; e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    assert(e.addon.UI.lines[2].text:find(e.addon.L.loading, 1, true))
    e.advance(10)
    assert(e.addon.UI.lines[2].text:find(e.addon.L.unavailable, 1, true))
    eq(e.addon.UI.lines[5].text, e.addon.L.unavailable)
    eq(#e.sent, 0); eq(#e.inspections, 0)
end)

test("native stats require catalogued counters and missing values are not zero", function()
    local e = environment(); e.noCounters = true; e.addon.Data.DiscoverCounters()
    e.native = { wins = "55", losses = "22" }
    eq(e.addon.Data.Statistics(false), nil)
    e.noCounters = false; e.addon.Data.DiscoverCounters()
    eq(e.addon.Data.Statistics(false).wins, 55)
    e.event("DUEL_REQUESTED", "Rival"); e.compared = { wins = "0", losses = "--" }
    e.event("INSPECT_ACHIEVEMENT_READY", e.other)
    eq(e.addon.request.stats.wins, 0); eq(e.addon.request.stats.losses, nil)
    local text = e.addon.UI.StatsText(e.addon.request.stats)
    assert(text:find("— duels", 1, true)); assert(text:find("0 victoires", 1, true))
end)

test("the reported Forever damage counters cannot become duel statistics", function()
    local e = environment("enUS")
    GetAchievementInfo = function(id)
        return id, id == 527 and "Largest hit received" or "Total damage received"
    end
    e.native = { wins = "12345", losses = "67890" }
    e.addon.Data.DiscoverCounters()
    eq(e.addon.Data.counters.wins, nil)
    eq(e.addon.Data.counters.losses, nil)
    eq(e.addon.Data.Statistics(false), nil)
    local stats, source = e.addon.Data.SelfProfile()
    eq(source, "L"); eq(stats.wins, 0); eq(stats.losses, 0)
end)

test("duel counters are discovered by meaning, independently of their IDs", function()
    for _, locale in ipairs({ "enUS", "frFR", "deDE", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }) do
        local e = environment(locale)
        e.entries[3].id, e.entries[4].id = 7771, 7772
        e.native = { wins = "12", losses = "8" }
        e.addon.Data.DiscoverCounters()
        eq(e.addon.Data.counters.wins, 7771); eq(e.addon.Data.counters.losses, 7772)
        eq(e.addon.Data.counterNames.wins, e.addon.L.statWins)
        eq(e.addon.Data.Statistics(false).wins, 12)
        for _, id in ipairs(e.calls) do assert(id ~= 527 and id ~= 528) end
    end
end)

test("unknown and ambiguous statistic names fail closed", function()
    local e = environment("enUS")
    e.entries[3].name = "Duels won yesterday"
    e.entries[4].name = "Something else"
    e.addon.Data.DiscoverCounters()
    eq(e.addon.Data.counters.wins, nil); eq(e.addon.Data.counters.losses, nil)
    e.entries[3].name, e.entries[4].name = nil, nil
    e.entries[#e.entries + 1] = { id = 9003, key = "wins" }
    e.addon.Data.DiscoverCounters()
    eq(e.addon.Data.counters.wins, nil); eq(e.addon.Data.counters.losses, 9002)
    e.entries[#e.entries] = nil
    e.categories = { 1, 2 }
    e.addon.Data.DiscoverCounters()
    eq(e.addon.Data.counters.wins, 9001); eq(e.addon.Data.counters.losses, 9002)
end)

test("combat does not mutate protected attributes and clears stale targets on exit", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    COMBAT = true; e.event("PLAYER_REGEN_DISABLED"); e.popup:Hide()
    e.popup:Show(); e.units.target = { name = "Autre", guid = "Player-1-000003" }
    e.event("DUEL_REQUESTED", "Autre"); e.advance(0.25)
    eq(e.addon.UI.combatLabel.text, e.addon.L.combat)
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Rival-Realm")
    COMBAT = false; e.event("PLAYER_REGEN_ENABLED")
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Autre-Realm")
    COMBAT = true; e.event("DUEL_FINISHED"); COMBAT = false; e.event("PLAYER_REGEN_ENABLED")
    eq(e.addon.UI.button.driver, "hide"); eq(e.addon.UI.button.attributes.macrotext, nil)
end)

test("other popups and refused requests don't record duels", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    e.popup.which = "TRADE_REQUEST"; e.advance(0.25)
    eq(e.addon.request, nil); eq(e.addon.character.wins, 0); eq(e.addon.character.losses, 0)
end)

test("secure button follows a moved popup outside combat", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    local firstY = e.addon.UI.anchorY
    e.addon.UI.panel.top = 520; e.addon.UI.panel.left = 600; e.advance(0.25)
    eq(e.addon.UI.anchorLeft, 600); eq(e.addon.UI.anchorY, firstY + 120)
    COMBAT = true; e.addon.UI.panel.top = 700; e.advance(0.25)
    eq(e.addon.UI.anchorY, firstY + 120)
end)

test("unusable new request removes the previous opponent's action", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    e.event("DUEL_REQUESTED", { secret = true })
    eq(e.addon.request, nil); eq(e.addon.UI.button.attributes.macrotext, nil)
    eq(e.addon.UI.button.driver, "hide")
end)

test("API wrapper preserves nil holes and rejects secret return values", function()
    local d = environment().addon.Data
    local a, b, c, fourth = d.Call(function() return nil, 2, nil, 4 end)
    eq(a, nil); eq(b, 2); eq(c, nil); eq(fourth, 4)
    eq(d.Call(function() return { secret = true } end), nil)
end)

local function response(e, source, wins, losses)
    return table.concat({ e.addon.Logic.PROTOCOL, "R", e.addon.request.token, e.other, e.me, source,
        wins or "-", losses or "-", "42", "0", "21", "30" }, "|")
end

test("shared profiles preserve provenance and native data has priority", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
    e.event("CHAT_MSG_ADDON", "WHODUELING", response(e, "L", "6", "4"), "WHISPER", "Rival-Realm")
    eq(e.addon.request.sharedStats.wins, 6); eq(e.addon.request.sharedSource, "L")
    eq(e.addon.UI.lines[6].text, e.addon.L.sharedLocal)
    eq(e.addon.request.sharedTalents.names[1], "Arcane")
    e.compared = { wins = "100", losses = "25" }; e.event("INSPECT_ACHIEVEMENT_READY", e.other)
    eq(e.addon.UI.lines[6].text, e.addon.L.game)
    assert(e.addon.UI.lines[5].text:find("125", 1, true))
    eq(e.addon.character.wins, 0)
end)

test("malformed, spoofed, stale, unsolicited and broadcast replies are rejected", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival")
    local good = response(e, "G", "50", "20")
    for _, message in ipairs({ "evil", good .. "|extra", good:gsub("|50|", "|-1|"), good:gsub("|21|", "|999999|"), good:gsub("|42|", "|-|"), good:gsub("2|R|", "3|R|", 1) }) do
        e.event("CHAT_MSG_ADDON", "WHODUELING", message, "WHISPER", "Rival-Realm")
    end
    e.event("CHAT_MSG_ADDON", "WHODUELING", good, "CHANNEL", "Rival-Realm")
    e.event("CHAT_MSG_ADDON", "WHODUELING", good, "WHISPER", "Imposteur-Realm")
    eq(e.addon.request.sharedStats, nil)
    e.advance(10); e.event("CHAT_MSG_ADDON", "WHODUELING", good, "WHISPER", "Rival-Realm")
    eq(e.addon.request.sharedStats, nil); assert(e.addon.metrics.rejected >= 9)
end)

test("old profiles that could mislabel damage are rejected", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival")
    local old = response(e, "G", "12345", "67890"):gsub("^2|", "1|")
    e.event("CHAT_MSG_ADDON", "WHODUELING", old, "WHISPER", "Rival-Realm")
    eq(e.addon.request.sharedStats, nil); eq(e.addon.metrics.rejected, 1)
    local current = response(e, "L", "6", "4")
    e.event("CHAT_MSG_ADDON", "WHODUELING", current, "WHISPER", "Rival-Realm")
    eq(e.addon.request.sharedStats.wins, 6)
end)

test("peer queries and retries are rate limited", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival")
    for i = 1, 16 do e.advance(0.25) end
    eq(#e.sent, 1); e.advance(1); eq(#e.sent, 2)
    e.advance(4); eq(#e.sent, 2); e.advance(1); eq(#e.sent, 2)
end)

test("outgoing challenger answers only a verified nearby current opponent", function()
    local e = environment(); StartDuel("target", false)
    local query = table.concat({ e.addon.Logic.PROTOCOL, "Q", "100-1", e.other, e.me }, "|")
    e.event("CHAT_MSG_ADDON", "WHODUELING", query, "WHISPER", "Rival-Realm")
    eq(#e.sent, 1)
    local f = e.addon.Logic.Decode(e.sent[1].message)
    eq(f[6], "L"); eq(f[7], "0"); eq(f[8], "0")
    e.event("CHAT_MSG_ADDON", "WHODUELING", query, "WHISPER", "Rival-Realm"); eq(#e.sent, 1)
    e.time = e.time + 5; e.native = { wins = "12", losses = "8" }
    e.event("CHAT_MSG_ADDON", "WHODUELING", query, "WHISPER", "Rival-Realm")
    eq(e.addon.Logic.Decode(e.sent[2].message)[6], "G")
    e.units.target = nil; e.time = e.time + 5
    e.event("CHAT_MSG_ADDON", "WHODUELING", query, "WHISPER", "Rival-Realm"); eq(#e.sent, 2)
    e = environment(); e.event("CHAT_MSG_ADDON", "WHODUELING", query, "WHISPER", "Rival-Realm"); eq(#e.sent, 0)
end)

test("incoming and outgoing wins, losses and retreat count exactly once", function()
    local e = environment(); e.event("DUEL_REQUESTED", "Rival"); e.event("DUEL_FINISHED")
    e.addon.Result("Moi a vaincu Rival en duel.", 1)
    e.addon.Result("Moi a vaincu Rival en duel.", 1)
    eq(e.addon.character.wins, 1)
    StartDuel("target", false); e.addon.Result("Rival a vaincu Moi en duel.", 2)
    eq(e.addon.character.losses, 1)
    e.addon.Result("Rival a fui face à Moi en duel.", 3)
    eq(e.addon.character.wins, 2)
    local record = e.addon.Logic.Opponent(e.addon.character, "Rival-Realm", e.other)
    eq(record.wins, 2); eq(record.losses, 1)
    e.addon.Result("Other a vaincu Rival en duel.", 4); eq(e.addon.character.wins, 2)
    e.addon.Result("Moi a vaincu Rival en duel.", 5); eq(e.addon.character.wins, 3)
end)

test("duplicate fallback window allows later rematches", function()
    local e = environment(); e.addon.Result("Moi a vaincu Rival en duel.")
    e.addon.Result("Moi a vaincu Rival en duel."); eq(e.addon.character.wins, 1)
    e.time = e.time + 3; e.addon.Result("Moi a vaincu Rival en duel."); eq(e.addon.character.wins, 2)
end)

test("hardcore requests are excluded from the panel and records", function()
    local e = environment(); e.event("DUEL_TO_THE_DEATH_REQUESTED", "Rival")
    e.addon.Result("Moi a vaincu Rival en duel.", 1); eq(e.addon.character.wins, 0)
    eq(e.addon.request, nil)
    StartDuel("target", true); e.addon.Result("Rival a vaincu Moi en duel.", 2); eq(e.addon.character.losses, 0)
    e.event("DUEL_REQUESTED", "Rival"); e.addon.Result("Moi a vaincu Rival en duel.", 3); eq(e.addon.character.wins, 1)
end)

test("SavedVariables persist and characters/GUIDs remain separate", function()
    local e = environment(); e.addon.Result("Moi a vaincu Rival en duel.", 1)
    local db = WhoDuelingDB
    e = environment("deDE", db); eq(e.addon.character.wins, 1)
    local l = e.addon.Logic
    local _, otherCharacter = l.Character(db, "Player-1-000099"); eq(otherCharacter.wins, 0)
    local char = { opponents = {}, names = {} }
    l.Opponent(char, "Rival-Realm").wins = 2
    eq(l.Opponent(char, "Rival-Realm", "Player-1-000002").wins, 2)
    eq(l.Opponent(char, "Rival-Realm", "Player-1-000003").wins, 0)
    eq(char.opponents["Player-1-000002"].wins, 2)
end)

test("native inspection UI is not interrupted", function()
    local e = environment(); InspectFrame = newFrame(); InspectFrame:Show()
    e.event("DUEL_REQUESTED", "Rival"); eq(#e.inspections, 0)
    InspectFrame:Hide(); e.advance(2); eq(#e.inspections, 1)
end)

test("localized panel accommodates long strings and diagnostic stays local", function()
    for _, locale in ipairs({ "enUS", "frFR", "deDE", "esES", "esMX", "itIT", "ptBR", "ruRU", "koKR", "zhCN", "zhTW" }) do
        local e = environment(locale); e.event("DUEL_REQUESTED", "Rival"); e.advance(0.25)
        local height = 0
        for _, line in ipairs(e.addon.UI.lines) do height = height + line:GetStringHeight() end
        assert(e.addon.UI.panel.height > height)
        local sent = #e.sent
        e.addon.Diagnostic(); eq(#e.sent, sent); assert(#e.chats > 10)
        eq(e.chats[#e.chats], "|cff80c0ffWhoDueling|r · " .. e.addon.L.sharing)
        assert(e.chats[1]:find("1.0.1", 1, true))
    end
end)

print(passed .. " behavioral tests passed.")
