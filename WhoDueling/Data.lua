local _, addon = ...
local Logic, Data = addon.Logic, {}
local unpack = unpack or table.unpack
addon.Data = Data

function Data.Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local function pack(...) return { n = select("#", ...), ... } end
    local values = pack(pcall(fn, ...))
    if not values[1] then return nil end
    for i = 2, values.n do if not Logic.Public(values[i]) then return nil end end
    return unpack(values, 2, values.n)
end

function Data.FullName(name, surname)
    return Logic.Name(name, surname)
end

function Data.UnitName(unit)
    return Data.FullName(Data.Call(UnitNameUnmodified or UnitName or UnitFullName, unit))
end

function Data.FindUnit(name, guid)
    local units = { "target", "mouseover", "focus", "targettarget" }
    for i = 1, 4 do units[#units + 1] = "party" .. i end
    for i = 1, 40 do units[#units + 1] = "raid" .. i end
    if C_NamePlate and C_NamePlate.GetNamePlates then
        local plates = Data.Call(C_NamePlate.GetNamePlates)
        if type(plates) == "table" then
            for _, plate in ipairs(plates) do
                local token = plate.namePlateUnitToken
                if Logic.Public(token) and type(token) == "string" then units[#units + 1] = token end
            end
        end
    end
    for _, unit in ipairs(units) do
        if Data.Call(UnitIsPlayer, unit) then
            local unitGUID = Data.Call(UnitGUID, unit)
            if (not guid or unitGUID == guid) and Logic.SameName(Data.UnitName(unit), name) then return unit, unitGUID end
        end
    end
end
