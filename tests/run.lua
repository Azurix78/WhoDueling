local passed = 0
local function eq(a, b, label)
    if a ~= b then error((label or "assertion") .. ": expected " .. tostring(b) .. ", got " .. tostring(a), 2) end
end
local function test(name, fn)
    local ok, err = pcall(fn)
    if not ok then error("FAIL " .. name .. ": " .. tostring(err), 0) end
    passed = passed + 1; print("PASS " .. name)
end

local function frame(parent)
    local f = { parent = parent, scripts = {}, hooks = {}, attributes = {}, events = {},
        shown = false, width = 1, height = 1, left = 400, top = 400, scale = 1 }
    function f:SetScript(event, fn) self.scripts[event] = fn end
    function f:HookScript(event, fn) self.hooks[event] = fn end
    function f:RegisterEvent(event) self.events[event] = true end
    function f:SetAttribute(key, value) assert(not COMBAT, "protected attributes changed in combat"); self.attributes[key] = value end
    function f:SetPoint(...) assert(not COMBAT, "protected position changed in combat"); self.point = { ... } end
    function f:ClearAllPoints() assert(not COMBAT, "protected position changed in combat"); self.point = nil end
    function f:SetSize(w, h) self.width, self.height = w, h end
    function f:GetWidth() return self.width end
    function f:GetHeight() return self.height end
    function f:GetLeft() return self.left end
    function f:GetTop() return self.top end
    function f:GetEffectiveScale() return self.scale end
    function f:SetFrameStrata(value) self.strata = value end
    function f:SetFrameLevel(value) self.level = value end
    function f:SetText(value) self.text = value end
    function f:RegisterForClicks(...) self.clicks = { ... } end
    function f:Show() self.shown = true end
    function f:Hide() self.shown = false; if self.hooks.OnHide then self.hooks.OnHide(self) end end
    function f:IsShown() return self.shown end
    return f
end

local function environment(locale, initialCombat)
    COMBAT = false
    local e = { time = 100, units = {}, created = {}, forbiddenCalls = 0, targetCalls = 0 }
    e.me, e.other = "Player-1-000001", "Player-1-000002"
    e.units.player = { name = "Moi", surname = "Famille", guid = e.me }
    e.units.target = { name = "Autre", surname = "Famille", guid = "Player-1-000003" }
    GetLocale = function() return locale or "frFR" end
    GetTime = function() return e.time end
    GetNormalizedRealmName, GetRealmName = nil, nil
    UnitName = function(unit) local u = e.units[unit]; if u then return u.name, u.surname end end
    UnitNameUnmodified, UnitFullName = UnitName, UnitName
    UnitGUID = function(unit) return e.units[unit] and e.units[unit].guid end
    UnitIsPlayer = function(unit) return e.units[unit] and e.units[unit].player ~= false or false end
    InCombatLockdown = function() return COMBAT end
    issecretvalue = function(value) return type(value) == "table" and value.secret == true end
    Constants = { CharacterNameSeparatorConsts = { CHARACTERNAME_SURNAME_SEPARATOR = " " } }
    C_NamePlate = { GetNamePlates = function() return e.plates or {} end }
    local function forbidden() e.forbiddenCalls = e.forbiddenCalls + 1; error("removed feature was called") end
    NotifyInspect, CanInspect, SetAchievementComparisonUnit = forbidden, forbidden, forbidden
    GetStatisticsCategoryList, GetCategoryNumAchievements, GetStatistic = forbidden, forbidden, forbidden
    StartDuel, AcceptDuel, CancelDuel = forbidden, forbidden, forbidden
    C_ChatInfo = { RegisterAddonMessagePrefix = forbidden, SendAddonMessage = forbidden }
    WhoDuelingDB = { marker = "old data" }
    SlashCmdList = {}
    UIParent = frame()
    e.popup = frame(); e.popup:SetSize(320, 100); e.popup.which = "DUEL_REQUESTED"; e.popup:Show()
    StaticPopup_FindVisible = function(which) if e.popup:IsShown() and e.popup.which == which then return e.popup end end
    CreateFrame = function(_, name, parent, template)
        local f = frame(parent); f.name, f.template = name, template
        e.created[#e.created + 1] = f
        return f
    end
    RegisterStateDriver = function(f, _, condition)
        assert(not COMBAT, "protected visibility changed in combat")
        f.driver = condition; f.shown = condition == "[combat] hide; show" and not COMBAT
    end
    COMBAT = initialCombat or false
    local addon = {}
    for _, file in ipairs({ "Localization.lua", "Logic.lua", "Data.lua", "UI.lua", "Core.lua" }) do
        assert((loadstring or load)(TEST_FILES[file], "@" .. file))("WhoDueling", addon)
    end
    e.addon = addon
    function e.event(event, ...) addon.frame.scripts.OnEvent(addon.frame, event, ...) end
    function e.advance(seconds) e.time = e.time + seconds; addon.Tick() end
    function e.combat(value)
        COMBAT = value
        for _, f in ipairs(e.created) do if f.driver then f.shown = f.driver == "[combat] hide; show" and not value end end
        e.event(value and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
    end
    function e.click()
        local b = addon.UI.button
        if not b or not b:IsShown() or COMBAT then return end
        eq(b.clicks[1], "LeftButtonUp"); eq(b.attributes.useOnKeyDown, false)
        if b.scripts.PreClick then b.scripts.PreClick(b, "LeftButton", false) end
        if b.attributes.type == "target" then
            local unit = e.units[b.attributes.unit]
            if unit then e.units.target = unit; e.targetCalls = e.targetCalls + 1 end
        elseif b.attributes.type == "macro" then
            local name = b.attributes.macrotext:match("^/targetexact (.+)$")
            for _, unit in pairs(e.units) do
                if addon.Data.FullName(unit.name, unit.surname) == name then
                    e.units.target = unit; e.targetCalls = e.targetCalls + 1; break
                end
            end
        end
        if b.hooks.PostClick then b.hooks.PostClick(b, "LeftButton", false) end
    end
    e.event("ADDON_LOADED", "WhoDueling")
    return e
end

test("all locales provide the English button label and description", function()
    local addon = environment().addon
    eq(#addon.LocaleKeys, 1)
    for locale, row in pairs(addon.Translations) do
        eq(#row, 1); assert(type(row[1]) == "string" and row[1] ~= "")
        eq(environment(locale).addon.UI.button.text, row[1])
    end
    assert(TEST_TOC:find("## Notes: A small button to target the player challenging you to a duel.", 1, true))
    eq(environment("unknown").addon.L.target, "Who dueled me?")
    eq(environment("enGB").addon.L.target, "Who dueled me?")
end)

test("full first-name surname identity preserves accents and rejects incomplete or injected names", function()
    local l = environment().addon.Logic
    eq(l.Name("Bia", "Fine"), "Bia Fine")
    eq(l.Name("Bia-Fine"), "Bia Fine")
    eq(l.Name("Bia Fine", "Fine"), "Bia Fine")
    eq(l.Name("|Hplayer:Bia-Fine:1|h[Bia]|h"), "Bia Fine")
    eq(l.Name("Élise", "Lumière"), "Élise Lumière")
    for _, name in ipairs({ "Bia", "Bia Fine Autre", "Bia\nFine", "Bia /duel", "[target=player] Fine" }) do eq(l.Name(name), nil) end
    eq(l.Name("Bia", { secret = true }), nil)
    eq(l.Name("Bia", "Fine\n/target Moi"), nil)
    eq(l.Name("Bia Fine", "Autre"), nil)
end)

test("only a small secure button is displayed with no remaining data features", function()
    local e = environment()
    eq(#e.created, 3); eq(e.addon.UI.panel, nil); eq(e.addon.UI.tip, nil)
    eq(e.addon.UI.button.width, 120); eq(e.addon.UI.button.height, 24)
    assert(e.addon.UI.button.template:find("SecureActionButtonTemplate", 1, true))
    assert(e.addon.UI.button.parent ~= e.popup)
    eq(e.addon.UI.button:IsShown(), false)
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    eq(e.addon.UI.button:IsShown(), true); eq(e.addon.UI.button.text, "Who dueled me?")
    e.advance(20); e.click()
    eq(e.forbiddenCalls, 0); eq(WhoDuelingDB.marker, "old data")
    eq(next(SlashCmdList), nil)
    eq(e.addon.frame.events.INSPECT_READY, nil)
    eq(e.addon.frame.events.CHAT_MSG_ADDON, nil)
    eq(e.addon.frame.events.CHAT_MSG_SYSTEM, nil)
    assert(not TEST_TOC:find("SavedVariables", 1, true))
end)

test("the challenger is targeted only on click without accepting the duel", function()
    local e = environment()
    e.units.mouseover = { name = "Bia", surname = "Fine", guid = e.other }
    local previous = e.units.target
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    eq(e.units.target, previous); eq(e.targetCalls, 0)
    eq(e.addon.UI.button.attributes.type, "target")
    eq(e.addon.UI.button.attributes.unit, "mouseover")
    e.click(); eq(e.units.target.guid, e.other); eq(e.targetCalls, 1)
    eq(e.popup:IsShown(), true); eq(e.forbiddenCalls, 0)
end)

test("the fallback macro preserves both name parts and selects the correct homonym", function()
    local e = environment()
    e.units.target = { name = "Bia", surname = "Autre", guid = "Player-1-000003" }
    e.units.nearby = { name = "Bia", surname = "Fine", guid = e.other }
    e.event("DUEL_REQUESTED", "Bia-Fine"); e.advance(0.25)
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Bia Fine")
    e.click(); eq(e.units.target.guid, e.other)
end)

test("known nameplates and group units use the secure unit action", function()
    for _, token in ipairs({ "nameplate1", "party1" }) do
        local e = environment()
        e.units[token] = { name = "Bia", surname = "Fine", guid = e.other }
        if token == "nameplate1" then e.plates = { { namePlateUnitToken = token } } end
        e.event("DUEL_REQUESTED", "Bia", "Fine"); e.advance(0.25)
        eq(e.addon.UI.button.attributes.unit, token)
        e.click(); eq(e.units.target.guid, e.other)
    end
end)

test("recycled unit tokens are checked again immediately before clicking", function()
    local e = environment()
    e.units.nameplate1 = { name = "Bia", surname = "Fine", guid = e.other }
    e.plates = { { namePlateUnitToken = "nameplate1" } }
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    eq(e.addon.UI.button.attributes.unit, "nameplate1")
    e.units.nameplate1 = { name = "Bia", surname = "Autre", guid = "Player-1-000004" }
    local previous = e.units.target
    e.click(); eq(e.units.target, previous)
    eq(e.addon.UI.button.attributes.unit, nil)
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Bia Fine")
end)

test("successive requests replace the previous name and GUID", function()
    local e = environment()
    e.units.mouseover = { name = "Bia", surname = "Fine", guid = e.other }
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    eq(e.addon.request.guid, e.other)
    e.units.focus = { name = "Rival", surname = "Autre", guid = "Player-1-000005" }
    e.event("DUEL_REQUESTED", "Rival Autre"); e.advance(0.25)
    eq(e.addon.request.guid, "Player-1-000005")
    eq(e.addon.UI.targetName, "Rival Autre")
    e.click(); eq(e.units.target.guid, "Player-1-000005")
end)

test("popup closure or duel finish hides the button and clears its action", function()
    for _, reason in ipairs({ "accepted", "declined", "cancelled", "expired", "finished" }) do
        local e = environment()
        e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
        if reason == "finished" then e.event("DUEL_FINISHED") else e.popup:Hide() end
        eq(e.addon.request, nil); eq(e.addon.UI.button:IsShown(), false)
        eq(e.addon.UI.button.attributes.type, nil)
        eq(e.addon.UI.button.attributes.unit, nil)
        eq(e.addon.UI.button.attributes.macrotext, nil)
    end
end)

test("unrelated or absent popups do not retain a targeting action", function()
    local e = environment()
    e.popup:Hide(); e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(1.1)
    eq(e.addon.request, nil); eq(e.addon.UI.button:IsShown(), false)
    e.popup:Show(); e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    e.popup.which = "TRADE_REQUEST"; e.advance(0.25)
    eq(e.addon.request, nil); eq(e.addon.UI.button.driver, "hide")
end)

test("combat suspends targeting and replaces stale actions on exit", function()
    local e = environment()
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    e.combat(true); eq(e.addon.UI.button:IsShown(), false)
    e.popup:Hide(); e.popup:Show()
    e.event("DUEL_REQUESTED", "Rival Autre"); e.advance(0.25)
    eq(e.addon.UI.targetName, "Bia Fine")
    e.click(); eq(e.targetCalls, 0)
    e.combat(false)
    eq(e.addon.UI.button:IsShown(), true)
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Rival Autre")
    e.combat(true); e.popup:Hide(); e.combat(false)
    eq(e.addon.UI.button:IsShown(), false); eq(e.addon.UI.button.attributes.type, nil)
end)

test("loading during combat delays creation of the protected button", function()
    local e = environment("frFR", true)
    eq(e.addon.UI.button, nil)
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    eq(e.addon.UI.button, nil)
    e.combat(false)
    eq(e.addon.UI.button:IsShown(), true)
    eq(e.addon.UI.button.attributes.macrotext, "/targetexact Bia Fine")
end)

test("button stays centred below a moving scaled popup and freezes position in combat", function()
    local e = environment()
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    eq(e.addon.UI.anchorX, 560); eq(e.addon.UI.anchorY, 294)
    e.popup.left, e.popup.top, e.popup.scale = 600, 500, 0.8
    e.advance(0.25); eq(e.addon.UI.anchorX, 608); eq(e.addon.UI.anchorY, 314)
    e.combat(true); e.popup.top = 700; e.advance(0.25)
    eq(e.addon.UI.anchorY, 314)
    e.combat(false); eq(e.addon.UI.anchorY, 474)
end)

test("invalid or incomplete requests clear the previous action", function()
    local e = environment()
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    e.event("DUEL_REQUESTED", "Bia")
    eq(e.addon.request, nil); eq(e.addon.UI.button:IsShown(), false)
    e.event("DUEL_REQUESTED", { secret = true })
    eq(e.addon.request, nil)
end)

test("hardcore requests close the ordinary duel button", function()
    local e = environment()
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(0.25)
    e.event("DUEL_TO_THE_DEATH_REQUESTED", "Bia Fine")
    eq(e.addon.request, nil); eq(e.addon.UI.button:IsShown(), false)
end)

test("targeting remains available while the popup stays open beyond the old data timeout", function()
    local e = environment()
    e.units.nearby = { name = "Bia", surname = "Fine", guid = e.other }
    e.event("DUEL_REQUESTED", "Bia Fine"); e.advance(60)
    eq(e.addon.UI.button:IsShown(), true)
    e.click(); eq(e.units.target.guid, e.other)
    eq(e.forbiddenCalls, 0)
end)

test("unit names remain complete when surname display is disabled or APIs fall back", function()
    local e = environment()
    UnitName = function() return "Bia" end
    UnitNameUnmodified = function() return "Bia", "Fine" end
    eq(e.addon.Data.UnitName("mouseover"), "Bia Fine")
    UnitNameUnmodified = nil
    UnitName = function() return "Bia", "Fine" end
    eq(e.addon.Data.UnitName("mouseover"), "Bia Fine")
end)

test("API wrapper preserves nil holes and rejects secret identities", function()
    local d = environment().addon.Data
    local a, b, c, fourth = d.Call(function() return nil, 2, nil, 4 end)
    eq(a, nil); eq(b, 2); eq(c, nil); eq(fourth, 4)
    eq(d.Call(function() return { secret = true } end), nil)
end)

print(passed .. " behavioral tests passed.")
