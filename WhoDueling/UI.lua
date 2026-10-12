local _, addon = ...
local UI = {}
addon.UI = UI

function UI.Initialize()
    -- Keep the protected button independent of Blizzard's popup. Only its
    -- coordinates are copied out of combat; hiding a popup cannot taint it.
    local anchor = CreateFrame("Frame", "WhoDuelingTargetAnchor", UIParent)
    anchor:SetSize(120, 24)
    anchor:SetPoint("CENTER", UIParent, "CENTER", 0, -120)
    UI.anchor = anchor
    local button = CreateFrame("Button", "WhoDuelingTargetButton", anchor, "UIPanelButtonTemplate,SecureActionButtonTemplate")
    button:SetSize(120, 24)
    button:SetPoint("TOP", anchor, "TOP")
    button:SetFrameStrata("DIALOG")
    button:SetFrameLevel(10)
    button:SetText(addon.L.target)
    button:RegisterForClicks("LeftButtonUp")
    button:SetAttribute("useOnKeyDown", false)
    button:SetScript("PreClick", function()
        if not InCombatLockdown() and addon.request then UI.SetTarget(addon.request.name) end
    end)
    UI.button = button
    RegisterStateDriver(button, "visibility", "hide")
end

function UI.SetTarget(name)
    if InCombatLockdown() then return end
    local request = addon.request
    local unit, guid
    if name then unit, guid = addon.Data.FindUnit(name, request and request.guid) end
    if request and guid and not request.guid then request.guid = guid end
    -- Preserve the targeting action validated on Forever 1.0.3, including
    -- both name parts and immediate revalidation of reused unit tokens.
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
    if InCombatLockdown() or not UI.popup then return end
    local popup = UI.popup
    local left, top = popup:GetLeft(), popup:GetTop()
    if not left or not top then return end
    local scale = popup:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local x = (left + popup:GetWidth() / 2) * scale
    local y = (top - popup:GetHeight()) * scale - 6
    if x ~= UI.anchorX or y ~= UI.anchorY then
        UI.anchorX, UI.anchorY = x, y
        UI.anchor:ClearAllPoints()
        UI.anchor:SetPoint("TOP", UIParent, "BOTTOMLEFT", x, y)
    end
end

function UI.Attach(popup, request)
    UI.popup = popup
    if not popup.whoDuelingHooked then
        popup.whoDuelingHooked = true
        popup:HookScript("OnHide", function(frame)
            if UI.popup == frame then addon.CloseRequest() end
        end)
    end
    UI.PositionTarget()
    UI.SetTarget(request.name)
end

function UI.Close()
    UI.popup = nil
    UI.SetTarget(nil) -- The combat state driver already hides the button.
end
