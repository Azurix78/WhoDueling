local _, addon = ...
local UI, L = {}, addon.L
addon.UI = UI

local function text(frame, font)
    local region = frame:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    region:SetJustifyH("LEFT")
    region:SetWidth(296)
    region:SetWordWrap(true)
    return region
end

function UI.Initialize()
    -- The protected button has no parent/anchor dependency from Blizzard's
    -- popup. The informational panel can close independently during combat.
    local panel = CreateFrame("Frame", "WhoDuelingPanel", UIParent, "BackdropTemplate")
    panel:SetWidth(320)
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:Hide()
    UI.panel, UI.lines = panel, {}
    for i = 1, 3 do UI.lines[i] = text(panel, i == 1 and "GameFontNormal" or nil) end
    local tip = CreateFrame("Frame", nil, panel)
    tip:EnableMouse(true)
    tip:SetScript("OnEnter", function(owner)
        local talents = UI.talents
        if not talents then return end
        GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
        GameTooltip:SetText(L.talents)
        for i = 1, 3 do GameTooltip:AddLine(talents.names[i] .. ": " .. talents.points[i], 1, 1, 1) end
        GameTooltip:Show()
    end)
    tip:SetScript("OnLeave", function(owner) if GameTooltip:GetOwner() == owner then GameTooltip:Hide() end end)
    UI.tip = tip

    -- A separate secure anchor is positioned beside the panel out of combat.
    -- Never anchor the protected button to the popup or information panel.
    local anchor = CreateFrame("Frame", "WhoDuelingTargetAnchor", UIParent)
    anchor:SetSize(320, 1)
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    UI.anchor = anchor
    local button = CreateFrame("Button", "WhoDuelingTargetButton", anchor, "UIPanelButtonTemplate,SecureActionButtonTemplate")
    button:SetSize(296, 24)
    button:SetPoint("TOPLEFT", anchor, "TOPLEFT", 12, 0)
    button:SetFrameStrata("DIALOG")
    button:SetFrameLevel(panel:GetFrameLevel() + 10)
    button:SetText(L.target)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetScript("PreClick", function()
        if not InCombatLockdown() and addon.request then UI.SetTarget(addon.request.name) end
    end)
    button:HookScript("PostClick", function() addon.TargetClicked() end)
    UI.button = button
    RegisterStateDriver(button, "visibility", "hide")
end

function UI.SetTarget(name)
    if InCombatLockdown() then return end
    local unit = name and addon.Data.FindUnit(name, addon.request and addon.request.guid)
    -- Revalidate a unit token immediately before clicking; mouseover and
    -- nameplate tokens can be reused for a different player between frames.
    -- Prefer the native secure target action over executing macro text.
    local mode = unit and "target" or name and "macro" or nil
    local macro = name and not unit and ("/targetexact " .. name) or nil
    if UI.targetName == name and UI.targetUnit == unit and UI.targetMode == mode and UI.targetMacro == macro then return end
    UI.targetName, UI.targetUnit, UI.targetMode, UI.targetMacro = name, unit, mode, macro
    UI.button:SetAttribute("type", mode)
    UI.button:SetAttribute("unit", unit)
    UI.button:SetAttribute("macrotext", macro)
    RegisterStateDriver(UI.button, "visibility", name and "[combat] hide; show" or "hide")
end

function UI.PositionTarget()
    if InCombatLockdown() or not UI.panel:IsShown() then return end
    local top, left = UI.panel:GetTop(), UI.panel:GetLeft()
    if not top or not left then return end
    local y = top - UI.panel:GetHeight() + 40
    if left ~= UI.anchorLeft or y ~= UI.anchorY then
        UI.anchorLeft, UI.anchorY = left, y
        UI.anchor:ClearAllPoints()
        UI.anchor:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, y)
    end
end

local function formatStats(stats)
    if not stats then return L.unavailable end
    local wins, losses = stats.wins, stats.losses
    local total = wins ~= nil and losses ~= nil and tostring(wins + losses) or "—"
    return string.format(L.summary, total, wins ~= nil and tostring(wins) or "—", losses ~= nil and tostring(losses) or "—")
end

function UI.Render(request)
    if not request or request.closed then return end
    local waiting = GetTime() < request.deadline
    local talents = request.talents or request.sharedTalents
    local talentSource = request.talents and "" or request.sharedTalents and L.sharedTalents or ""
    local values = {
        request.name,
        L.talents .. ": " .. (talents and table.concat(talents.points, "/") or waiting and L.loading or L.unavailable),
        talentSource,
    }
    local y = -12
    for i, line in ipairs(UI.lines) do
        line:ClearAllPoints()
        line:SetPoint("TOPLEFT", UI.panel, "TOPLEFT", 12, y)
        line:SetText(values[i])
        local height = values[i] ~= "" and math.max(14, line:GetStringHeight()) or 0
        y = y - height - (height > 0 and 5 or 0)
    end
    UI.talents = talents
    UI.tip:ClearAllPoints()
    UI.tip:SetPoint("TOPLEFT", UI.lines[2], "TOPLEFT")
    UI.tip:SetSize(296, math.max(14, UI.lines[2]:GetStringHeight()))
    UI.panel:SetHeight(-y + 44)
    if not UI.combatLabel then UI.combatLabel = text(UI.panel) end
    UI.combatLabel:ClearAllPoints()
    UI.combatLabel:SetPoint("BOTTOMLEFT", UI.panel, "BOTTOMLEFT", 12, 16)
    UI.combatLabel:SetText(InCombatLockdown() and L.combat or "")
    UI.PositionTarget()
end

function UI.Attach(popup, request)
    UI.popup = popup
    UI.panel:ClearAllPoints()
    UI.panel:SetPoint("TOP", popup, "BOTTOM", 0, -6)
    if not popup.whoDuelingHooked then
        popup.whoDuelingHooked = true
        popup:HookScript("OnHide", function(frame)
            if UI.popup == frame then addon.CloseRequest() end
        end)
    end
    UI.panel:Show()
    UI.Render(request)
    UI.SetTarget(request.name)
end

function UI.Close()
    UI.popup, UI.talents = nil, nil
    UI.panel:Hide()
    if GameTooltip:GetOwner() == UI.tip then GameTooltip:Hide() end
    UI.SetTarget(nil) -- Combat state driver already hides the protected button.
end

function UI.StatsText(stats) return formatStats(stats) end
