local addonName, addon = ...
local Data, UI = addon.Data, addon.UI
addon.version = "1.0.4"
local frame = CreateFrame("Frame")
addon.frame = frame

local function ensureUI()
    if not UI.button and not InCombatLockdown() then UI.Initialize() end
    return UI.button ~= nil
end

function addon.CloseRequest()
    addon.request = nil
    if UI.button then UI.Close() end
end

function addon.Request(name, surname)
    addon.CloseRequest()
    name = Data.FullName(name, surname)
    if not name or name == Data.UnitName("player") then return end
    addon.request = { name = name, at = GetTime() }
end

function addon.Tick()
    local request = addon.request
    if not request then return end
    if not request.attached and ensureUI() then
        local popup = StaticPopup_FindVisible and StaticPopup_FindVisible("DUEL_REQUESTED")
        if popup then
            request.attached = true
            UI.Attach(popup, request)
        elseif GetTime() - request.at > 1 then
            addon.CloseRequest()
            return
        end
    end
    if request.attached then
        if not UI.popup or not UI.popup:IsShown() or UI.popup.which ~= "DUEL_REQUESTED" then
            addon.CloseRequest()
            return
        end
        UI.PositionTarget()
        UI.SetTarget(request.name)
    end
end

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if ... == addonName then ensureUI() end
    elseif event == "PLAYER_LOGIN" then
        ensureUI()
    elseif event == "DUEL_REQUESTED" then
        addon.Request(...)
    elseif event == "DUEL_FINISHED" or event == "DUEL_TO_THE_DEATH_REQUESTED" then
        addon.CloseRequest()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if ensureUI() then
            UI.SetTarget(nil)
            addon.Tick()
        end
    end
end)

for _, event in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "DUEL_REQUESTED",
    "DUEL_FINISHED", "DUEL_TO_THE_DEATH_REQUESTED", "PLAYER_REGEN_ENABLED" }) do
    frame:RegisterEvent(event)
end

local elapsed = 0
frame:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.25 then elapsed = 0; addon.Tick() end
end)
