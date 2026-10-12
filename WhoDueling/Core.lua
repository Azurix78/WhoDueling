local addonName, addon = ...
local Logic, Data, UI, L = addon.Logic, addon.Data, addon.UI, addon.L
local PREFIX = "WHODUELING"
addon.version = "1.0.3"
local frame = CreateFrame("Frame")
addon.frame = frame
addon.metrics = { sent = 0, received = 0, rejected = 0, targetClicks = 0, targetHits = 0, inspectRequests = 0, inspectReplies = 0 }
addon.lastTarget = { name = "—", mode = "—", confirmed = false }
addon.lastInspect = "—"
local serial, lastInspect = 0, -10
local recentResults, lineIDs, replyTimes = {}, {}, {}
local inspectLease, duelContext

local function now() return GetTime() end
local function publicGUID(guid)
    return Logic.Public(guid) and type(guid) == "string" and guid:match("^Player%-%x+%-%x+$") and guid or nil
end

local function initialize()
    if addon.character then return true end
    local guid = publicGUID(Data.Call(UnitGUID, "player"))
    if not guid then return false end
    addon.playerName = Data.UnitName("player")
    if not addon.playerName then return false end
    addon.guid = guid
    WhoDuelingDB, addon.character = Logic.Character(WhoDuelingDB, guid)
    addon.character.name = addon.playerName
    addon.character.since = addon.character.since or Data.Call(GetServerTime) or 0
    addon.patterns = Logic.ResultPatterns(DUEL_WINNER_KNOCKOUT, DUEL_WINNER_RETREAT)
    Data.DiscoverCounters()
    addon.messaging = C_ChatInfo and type(C_ChatInfo.SendAddonMessage) == "function" and
        Data.Call(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX)
    -- Modern registration returns an enum; older APIs return a boolean.
    if addon.messaging == false then addon.messaging = nil end
    if Enum and Enum.RegisterAddonMessagePrefixResult and
        addon.messaging ~= true and addon.messaging ~= Enum.RegisterAddonMessagePrefixResult.Success then addon.messaging = nil end
    return true
end

local function ensureUI()
    if not UI.panel and not InCombatLockdown() then UI.Initialize() end
    return UI.panel ~= nil
end

function addon.CloseRequest()
    local request = addon.request
    if request then request.closed = true end
    addon.request = nil
    inspectLease = nil
    -- Inspection is a shared global resource: don't clear it behind
    -- Blizzard's inspection UI or another addon.
    if UI.panel then UI.Close() end
end

local function guidForRequest(request)
    local unit, guid = Data.FindUnit(request.name, request.guid)
    guid = publicGUID(guid)
    if guid and not request.guid then request.guid = guid end
    if not request.guid then
        local duelGUID = publicGUID(Data.Call(GetDuelerInfo))
        if duelGUID then
            local name, surname = Data.Call(UnitNameFromGUID, duelGUID)
            if not name then
                local _, _, _, _, _, firstName, lastName = Data.Call(GetPlayerInfoByGUID, duelGUID)
                name, surname = firstName, lastName
            end
            if Logic.SameName(Data.FullName(name, surname), request.name) then request.guid = duelGUID end
        end
    end
    if request.guid then Logic.Opponent(addon.character, request.name, request.guid) end
    return unit, request.guid
end

local function send(message, target)
    if not addon.messaging or #message > 240 then return false end
    local result = Data.Call(C_ChatInfo.SendAddonMessage, PREFIX, message, "WHISPER", target)
    if result == nil or result == false then return false end
    if Enum and Enum.SendAddonMessageResult and result ~= true and result ~= Enum.SendAddonMessageResult.Success then return false end
    return true
end

local function queryPeer(request)
    if not request.guid or request.closed or now() >= request.deadline then return end
    if request.attempts >= 2 or (request.sentAt and now() - request.sentAt < 5) or request.peerReplied then return end
    request.attempts, request.sentAt = request.attempts + 1, now()
    if send(table.concat({ Logic.PROTOCOL, "Q", request.token, addon.guid, request.guid }, "|"), request.name) then
        addon.metrics.sent = addon.metrics.sent + 1
    end
end

local function inspectionBusy()
    return InspectFrame and InspectFrame.IsShown and InspectFrame:IsShown() or
        PlayerSpellsFrame and PlayerSpellsFrame.IsInspecting and PlayerSpellsFrame:IsInspecting()
end

local function tryData(request)
    if request.closed or now() >= request.deadline or InCombatLockdown() then return end
    local unit, guid = guidForRequest(request)
    queryPeer(request)
    if not unit or not guid then return end
    if not request.talents and not inspectLease and now() - lastInspect >= 2 and not inspectionBusy() and Data.Call(CanInspect, unit) then
        lastInspect = now()
        inspectLease = { request = request, guid = guid, unit = unit, at = now() }
        -- No inspection UI is opened and the player's target is not modified.
        if type(NotifyInspect) == "function" then
            local ok = pcall(NotifyInspect, unit)
            if not ok then inspectLease = nil
            else addon.metrics.inspectRequests = addon.metrics.inspectRequests + 1 end
        else inspectLease = nil end
    end
end

function addon.Request(name, surname)
    if not initialize() then return end
    addon.CloseRequest()
    name = Data.FullName(name, surname)
    if not name or name == addon.playerName then return end
    serial = serial + 1
    local request = { name = name, token = math.floor(now() * 1000) .. "-" .. serial,
        at = now(), deadline = now() + 10, attempts = 0 }
    addon.request = request
    duelContext = { name = name, at = now(), hardcore = false }
    guidForRequest(request)
    duelContext.guid = request.guid
    tryData(request)
end

function addon.TargetClicked()
    local request = addon.request
    if request and not request.closed and not InCombatLockdown() then
        addon.metrics.targetClicks = addon.metrics.targetClicks + 1
        addon.lastTarget = { name = request.name, guid = request.guid, at = now(), mode = UI.targetMode or "—", confirmed = false }
        addon.CheckTargeting()
        -- A click may expose an inspectable target after the initial timeout.
        -- Give the newly selected opponent a fresh inspection window.
        if now() >= request.deadline then request.deadline = now() + 10; request.expired = nil end
        tryData(request); UI.Render(request)
    end
end

function addon.CheckTargeting()
    local attempt = addon.lastTarget
    if not attempt.at or attempt.confirmed or now() - attempt.at > 1 then return end
    if Data.UnitName("target") == attempt.name and (not attempt.guid or Data.Call(UnitGUID, "target") == attempt.guid) then
        attempt.confirmed = true
        addon.metrics.targetHits = addon.metrics.targetHits + 1
    end
end

function addon.InspectReady(guid)
    local lease, request = inspectLease, addon.request
    if not publicGUID(guid) or not lease or not request or lease.request ~= request or guid ~= lease.guid or
        request.closed or now() >= request.deadline or Data.Call(UnitGUID, lease.unit) ~= guid then return end
    addon.metrics.inspectReplies = addon.metrics.inspectReplies + 1
    request.talents = Data.InspectTalents(lease.unit)
    addon.lastInspect = request.talents and table.concat(request.talents.points, "/") or L.unavailable
    inspectLease = nil
    if UI.panel then UI.Render(request) end
end

local function isCurrentOpponent(name, guid)
    if duelContext and duelContext.hardcore and duelContext.name == name and now() - duelContext.at < 600 then return false end
    if addon.request and not addon.request.closed and addon.request.name == name and addon.request.guid == guid then return true end
    if duelContext and not duelContext.hardcore and now() - duelContext.at < 60 and duelContext.name == name and
        (not duelContext.guid or duelContext.guid == guid) then return true end
    return publicGUID(Data.Call(GetDuelerInfo)) == guid
end

function addon.Message(prefix, message, channel, sender)
    if not Logic.Public(prefix) or prefix ~= PREFIX or not initialize() then return end
    if not Logic.Public(channel) or channel ~= "WHISPER" then addon.metrics.rejected = addon.metrics.rejected + 1; return end
    local fields, name = Logic.Decode(message), Logic.Name(sender)
    if not fields or not name or fields[5] ~= addon.guid or fields[4] == addon.guid then
        addon.metrics.rejected = addon.metrics.rejected + 1; return
    end
    if fields[2] == "Q" then
        local unit = Data.FindUnit(name, fields[4])
        if not unit or not isCurrentOpponent(name, fields[4]) or InCombatLockdown() or
            (replyTimes[name] and now() - replyTimes[name] < 5) then addon.metrics.rejected = addon.metrics.rejected + 1; return end
        replyTimes[name] = now()
        local stats, source, talents = Data.SelfProfile()
        local function value(v) return v ~= nil and tostring(v) or "-" end
        local reply = { Logic.PROTOCOL, "R", fields[3], addon.guid, fields[4], source,
            value(stats.wins), value(stats.losses), value(talents and talents.treeID) }
        for i = 1, 3 do reply[#reply + 1] = value(talents and talents.points[i]) end
        send(table.concat(reply, "|"), name)
        return
    end
    local request = addon.request
    if not request or request.closed or now() >= request.deadline or not request.sentAt or request.peerReplied or
        name ~= request.name or fields[3] ~= request.token or fields[4] ~= request.guid then
        addon.metrics.rejected = addon.metrics.rejected + 1; return
    end
    request.peerReplied = true
    if fields[6] ~= "N" and (fields[7] ~= "-" or fields[8] ~= "-") then
        request.sharedStats = { wins = Logic.Count(fields[7]), losses = Logic.Count(fields[8]) }
        request.sharedSource = fields[6]
    end
    if fields[9] ~= "-" then
        request.sharedTalents = Data.SharedTalents(tonumber(fields[9]), { tonumber(fields[10]), tonumber(fields[11]), tonumber(fields[12]) })
    end
    addon.metrics.received = addon.metrics.received + 1
    if UI.panel then UI.Render(request) end
end

function addon.Result(message, lineID)
    if not initialize() then return end
    local winner, loser = Logic.ParseResult(message, addon.patterns)
    if not winner or (winner ~= addon.playerName and loser ~= addon.playerName) then return end
    local opponent = winner == addon.playerName and loser or winner
    if duelContext and duelContext.hardcore and duelContext.name == opponent and now() - duelContext.at < 600 then return end
    -- Chat line IDs distinguish separate identical results; a short fallback
    -- window handles clients lacking IDs without suppressing later rematches.
    if Logic.Public(lineID) and type(lineID) == "number" and lineID > 0 then
        if lineIDs[lineID] then return end
        lineIDs[lineID] = now()
    else
        local signature = winner .. ":" .. loser
        if recentResults[signature] and now() - recentResults[signature] < 2 then return end
        recentResults[signature] = now()
    end
    local _, guid = Data.FindUnit(opponent)
    guid = publicGUID(guid)
    if not guid and duelContext and duelContext.name == opponent then guid = duelContext.guid end
    local record = Logic.Opponent(addon.character, opponent, guid)
    local key = winner == addon.playerName and "wins" or "losses"
    record[key], addon.character[key] = record[key] + 1, addon.character[key] + 1
    record.name, record.last = opponent, Data.Call(GetServerTime) or 0
    addon.CloseRequest()
end

function addon.Tick()
    if not addon.character then return end
    addon.CheckTargeting()
    local request = addon.request
    if request then
        if ensureUI() and not request.attached then
            local popup = StaticPopup_FindVisible and StaticPopup_FindVisible("DUEL_REQUESTED")
            if popup then request.attached = true; UI.Attach(popup, request)
            elseif now() - request.at > 1 then addon.CloseRequest(); return end
        end
        if request.attached and (not UI.popup or not UI.popup:IsShown() or UI.popup.which ~= "DUEL_REQUESTED") then
            addon.CloseRequest(); return
        end
        if request.attached then UI.PositionTarget() end
        if request.attached and not InCombatLockdown() then UI.SetTarget(request.name) end
        if inspectLease and now() - inspectLease.at > 3 then inspectLease = nil end
        if now() < request.deadline then tryData(request)
        elseif not request.expired then
            request.expired = true; inspectLease = nil
            if UI.panel then UI.Render(request) end
        end
    end
    for _, map in ipairs({ recentResults, lineIDs, replyTimes }) do
        for key, time in pairs(map) do if now() - time > 60 then map[key] = nil end end
    end
end

local function printLine(key, value)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff80c0ffWhoDueling|r · " .. L[key] .. ": " .. tostring(value)) end
end

function addon.Diagnostic()
    if not initialize() then printLine("identity", L.unavailable); return end
    if not addon.request then Data.DiscoverCounters() end
    local yes = function(value) return value and L.yes or L.no end
    local version, build, _, interface = Data.Call(GetBuildInfo)
    printLine("diagnostic", addon.version)
    printLine("build", tostring(version) .. " / " .. tostring(build) .. " / " .. tostring(interface))
    printLine("locale", GetLocale())
    printLine("identity", addon.playerName .. " / " .. addon.guid)
    printLine("inspect", yes(C_Traits and C_Traits.GetGroupCurrencyInfo and NotifyInspect))
    printLine("counters", (Data.counters.wins or "—") .. " / " .. (Data.counters.losses or "—"))
    printLine("counterNames", (Data.counterNames.wins or L.unavailable) .. " / " .. (Data.counterNames.losses or L.unavailable))
    printLine("game", UI.StatsText(Data.Statistics(false)))
    printLine("messaging", yes(addon.messaging))
    for _, key in ipairs({ "sent", "received", "rejected" }) do printLine(key, addon.metrics[key]) end
    printLine("targetAction", addon.lastTarget.name .. " / " .. addon.lastTarget.mode .. " / " .. yes(addon.lastTarget.confirmed))
    for _, key in ipairs({ "targetClicks", "targetHits", "inspectRequests", "inspectReplies" }) do printLine(key, addon.metrics[key]) end
    printLine("lastInspect", addon.lastInspect)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff80c0ffWhoDueling|r · " .. L.sharing) end
end

local function onStartDuel(unit, hardcore)
    if not initialize() then return end
    local name = Data.UnitName(unit or "target") or Logic.Name(unit)
    if name then duelContext = { name = name, guid = publicGUID(Data.Call(UnitGUID, unit or "target")), at = now(), hardcore = hardcore == true } end
end

local hooked = false
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... ~= addonName then return end
        initialize(); ensureUI()
        if not hooked and type(StartDuel) == "function" and type(hooksecurefunc) == "function" then hooksecurefunc("StartDuel", onStartDuel); hooked = true end
    elseif event == "PLAYER_LOGIN" then initialize(); ensureUI(); Data.DiscoverCounters()
    elseif event == "DUEL_REQUESTED" then addon.Request(...)
    elseif event == "DUEL_TO_THE_DEATH_REQUESTED" then
        if initialize() then
            addon.CloseRequest()
            duelContext = { name = Data.FullName(...), at = now(), hardcore = true }
        end
    elseif event == "DUEL_FINISHED" then addon.CloseRequest()
    elseif event == "INSPECT_READY" then addon.InspectReady(...)
    elseif event == "CHAT_MSG_ADDON" then addon.Message(...)
    elseif event == "CHAT_MSG_SYSTEM" then
        local message = ...
        addon.Result(message, select(11, ...))
    elseif event == "PLAYER_REGEN_DISABLED" then
        if UI.panel and addon.request then UI.Render(addon.request) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ensureUI() then
            UI.SetTarget(addon.request and addon.request.attached and addon.request.name or nil)
            if addon.request then UI.Render(addon.request); tryData(addon.request) end
        end
    elseif event == "PLAYER_TARGET_CHANGED" or event == "UPDATE_MOUSEOVER_UNIT" or event == "NAME_PLATE_UNIT_ADDED" then
        addon.CheckTargeting()
        if addon.request then tryData(addon.request) end
    end
end)
for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "DUEL_REQUESTED", "DUEL_TO_THE_DEATH_REQUESTED", "DUEL_FINISHED",
    "INSPECT_READY", "CHAT_MSG_ADDON", "CHAT_MSG_SYSTEM", "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "NAME_PLATE_UNIT_ADDED" }) do
    pcall(frame.RegisterEvent, frame, event)
end
local elapsed = 0
frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.25 then elapsed = 0; addon.Tick() end
end)
SLASH_WHODUELING1 = "/whodueling"
SlashCmdList.WHODUELING = function(message)
    if message and message:match("^%s*diagnostic%s*$") then addon.Diagnostic()
    elseif DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage(L.help) end
end
