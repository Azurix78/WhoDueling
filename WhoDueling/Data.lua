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

function Data.UnitName(unit)
    local name, realm = Data.Call(UnitFullName or UnitName, unit)
    return Logic.Name(name, realm or addon.realm)
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

function Data.Talents(configID)
    if not C_Traits or not configID then return nil end
    local config = Data.Call(C_Traits.GetConfigInfo, configID)
    if type(config) ~= "table" or type(config.treeIDs) ~= "table" then return nil end
    for _, treeID in ipairs(config.treeIDs) do
        local display = Data.Call(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
        if type(display) == "table" and #display == 3 then
            local ordered = {}
            for i, group in ipairs(display) do
                if not Logic.Public(group.groupID) or not Logic.Public(group.orderIndex) or
                    type(group.groupID) ~= "number" or type(group.orderIndex) ~= "number" then return nil end
                ordered[i] = group
            end
            table.sort(ordered, function(a, b) return a.orderIndex < b.orderIndex end)
            local ids = { ordered[1].groupID, ordered[2].groupID, ordered[3].groupID }
            local infos = Data.Call(C_Traits.GetGroupCurrencyInfo, configID, ids)
            if type(infos) ~= "table" then return nil end
            local result = { points = {}, names = {}, treeID = treeID }
            for i, group in ipairs(ordered) do
                for _, info in ipairs(infos) do
                    if Logic.Public(info.traitNodeGroupID) and info.traitNodeGroupID == group.groupID and type(info.currencyInfos) == "table" then
                        local currency = info.currencyInfos[1]
                        result.points[i] = currency and Logic.Count(currency.spent)
                    end
                end
                if not result.points[i] then return nil end
                result.names[i] = Logic.Public(group.displayName) and type(group.displayName) == "string" and group.displayName or string.format(addon.L.treeUnknown, i)
            end
            return result
        end
    end
end

function Data.SharedTalents(treeID, points)
    local result = { treeID = treeID, points = points, names = {} }
    local groups = C_Traits and Data.Call(C_Traits.GetGroupDisplayInfoByTreeID, treeID)
    local ordered = {}
    if type(groups) == "table" and #groups == 3 then
        for i, group in ipairs(groups) do
            if not Logic.Public(group.orderIndex) or type(group.orderIndex) ~= "number" then groups = nil; break end
            ordered[i] = group
        end
        if groups then table.sort(ordered, function(a, b) return a.orderIndex < b.orderIndex end) end
    end
    for i = 1, 3 do
        local name = groups and ordered[i] and ordered[i].displayName
        result.names[i] = Logic.Public(name) and type(name) == "string" and name or string.format(addon.L.treeUnknown, i)
    end
    return result
end

-- Known historical IDs are candidates only. Require membership in this
-- client's statistics catalogue before any GetStatistic/GetComparisonStatistic.
function Data.DiscoverCounters()
    Data.counters, Data.counterNames = {}, {}
    local categories = Data.Call(GetStatisticsCategoryList)
    if type(categories) ~= "table" then return end
    for _, category in pairs(categories) do
        if Logic.Public(category) and type(category) == "number" then
            local count = Data.Call(GetCategoryNumAchievements, category)
            if Logic.Count(count) and count <= 1000 then
                for index = 1, count do
                    local _, skip, id = Data.Call(GetStatistic, category, index)
                    if not skip and (id == 527 or id == 528) then
                        local _, name = Data.Call(GetAchievementInfo, id)
                        if type(name) == "string" and name ~= "" then
                            local key = id == 527 and "wins" or "losses"
                            Data.counters[key], Data.counterNames[key] = id, name
                        end
                    end
                end
            end
        end
    end
end

function Data.Statistics(compare)
    local result, fn = {}, compare and GetComparisonStatistic or GetStatistic
    for key, id in pairs(Data.counters or {}) do result[key] = Logic.Count(Data.Call(fn, id)) end
    if result.wins ~= nil or result.losses ~= nil then return result end
end

function Data.SelfProfile()
    local native = Data.Statistics(false)
    local talents = C_ClassTalents and Data.Talents(Data.Call(C_ClassTalents.GetActiveConfigID))
    return native or { wins = addon.character.wins, losses = addon.character.losses }, native and "G" or "L", talents
end
