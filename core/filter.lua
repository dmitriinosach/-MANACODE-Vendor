local ADDON, ns = ...
local Filter = {}
ns.Filter = Filter
local RANGED = { WARRIOR = true, ROGUE = true, HUNTER = true }
local HEIRLOOM = 7
local AMMO_SLOT = "INVTYPE_AMMO"
local THROWN_SLOT = "INVTYPE_THROWN"
local ARROW, BULLET = 1, 2
local STAT = {
    ITEM_MOD_STRENGTH_SHORT = "str",
    ITEM_MOD_AGILITY_SHORT = "agi",
    ITEM_MOD_INTELLECT_SHORT = "int",
    ITEM_MOD_SPIRIT_SHORT = "spi",
    ITEM_MOD_SPELL_POWER_SHORT = "sp",
}
local ALIEN = {
    WARRIOR = { int = true, spi = true, sp = true, agi = true },
    DEATHKNIGHT = { int = true, spi = true, sp = true, agi = true },
    ROGUE = { int = true, spi = true, sp = true },
    HUNTER = { str = true, spi = true, sp = true },
    MAGE = { str = true, agi = true },
    WARLOCK = { str = true, agi = true },
    PRIEST = { str = true, agi = true },
    PALADIN = { agi = true },
}
local WORN_CORE = { 1, 3, 5, 6, 7, 8, 9, 10 }
local WORN_MIN = 5
local CORE_SLOT = {
    INVTYPE_HEAD = true, INVTYPE_SHOULDER = true, INVTYPE_CHEST = true, INVTYPE_ROBE = true,
    INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_WAIST = true,
    INVTYPE_LEGS = true, INVTYPE_FEET = true,
}
local USABLE = "usable"
local TREE = {
    { key = "mine", subs = { "mineClass", "mineProf", "mineStat", "mineWear" } },
    { key = USABLE },
    { key = "ammo", subs = { "arrow", "bullet", "thrown" } },
    { key = "rank" },
    { key = "coins", subs = { "hideSilver", "hideCopper", "hideGear", "hideLevel" }, nocount = true },
    { key = "look", subs = { "qualityName", "qualityFrame", "qualityGlow" }, nocount = true },
}
function Filter.Tree()
    return TREE
end
local function branchOf(key)
    for _, node in ipairs(TREE) do
        if node.key == key then return node.subs and node or nil end
    end
    return nil
end
local function classToken()
    local _, token = UnitClass("player")
    return token or "NONE"
end
local function defaults()
    local ammo = not RANGED[classToken()]
    return {
        mineClass = true, mineProf = false, mineStat = false, mineWear = false,
        arrow = ammo, bullet = ammo, thrown = ammo,
        rank = false,
        hideSilver = true, hideCopper = true, hideGear = true, hideLevel = false,
        qualityName = false, qualityFrame = true, qualityGlow = true,
    }
end
local kept
local function store()
    if kept then return kept end
    local db = ns.DB()
    if type(db.filters) ~= "table" then db.filters = {} end
    local key = classToken()
    local t = db.filters[key]
    if type(t) ~= "table" then
        t = {}
        db.filters[key] = t
    end
    for k, v in pairs(defaults()) do
        if t[k] == nil then t[k] = v end
    end
    kept = t
    return t
end
function Filter.Get(key)
    if key == USABLE then return ns.DB().usableOnly and true or false end
    local t = store()
    local node = branchOf(key)
    if not node then return t[key] and true or false end
    for _, leaf in ipairs(node.subs) do
        if not t[leaf] then return false end
    end
    return true
end
function Filter.Some(key)
    if key == USABLE then return Filter.Get(USABLE) end
    local t = store()
    local node = branchOf(key)
    if not node then return t[key] and true or false end
    for _, leaf in ipairs(node.subs) do
        if t[leaf] then return true end
    end
    return false
end
function Filter.Set(key, on)
    if key == USABLE then
        ns.DB().usableOnly = on and true or false
        return
    end
    local t = store()
    local node = branchOf(key)
    if node then
        for _, leaf in ipairs(node.subs) do t[leaf] = on and true or false end
    else
        t[key] = on and true or false
    end
end
function Filter.Count()
    local t = store()
    local n = 0
    for _, node in ipairs(TREE) do
        if node.nocount then
        elseif node.subs then
            for _, leaf in ipairs(node.subs) do
                if Filter.Get(leaf) then n = n + 1 end
            end
        elseif Filter.Get(node.key) then
            n = n + 1
        end
    end
    return n
end
local myNames
local function classNames()
    if myNames then return myNames end
    local token = classToken()
    local out = {}
    local male = LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[token]
    local female = LOCALIZED_CLASS_NAMES_FEMALE and LOCALIZED_CLASS_NAMES_FEMALE[token]
    local plain = UnitClass("player")
    for _, name in ipairs({ male, female, plain }) do
        if name and name ~= "" then out[#out + 1] = name end
    end
    if #out == 0 then return out end
    myNames = out
    return myNames
end
local function mineByName(classes)
    for _, name in ipairs(classNames()) do
        if strfind(classes, name, 1, true) then return true end
    end
    return false
end
function Filter.Unit()
    local t = store()
    if not t.hideCopper then return 1 end
    if not t.hideSilver then return 100 end
    return 10000
end
local function alienClass(row)
    if row.classes and row.classes ~= "" and #classNames() > 0 then
        if not mineByName(row.classes) then return true end
    end
    local owner = row.id and ns.reagentClass and ns.reagentClass[row.id]
    if owner and not strfind(owner, classToken(), 1, true) then return true end
    return false
end
local function alienProf(row)
    if not row.id or not ns.reagentAny or not ns.reagentAny[row.id] then return false end
    if ns.reagentClass and ns.reagentClass[row.id] then return false end
    return not row.mine
end
function Filter.AlienStat(class, stats)
    local alien = ALIEN[class]
    if not alien or not stats then return false end
    local bad, good = false, false
    for key, short in pairs(STAT) do
        if (stats[key] or 0) > 0 then
            if alien[short] then bad = true else good = true end
        end
    end
    return bad and not good
end
local statBuf = {}
local function alienStat(row)
    if not row.link or not row.equipSlot or row.equipSlot == "" then return false end
    wipe(statBuf)
    GetItemStats(row.link, statBuf)
    return Filter.AlienStat(classToken(), statBuf)
end
function Filter.WornKind()
    local count, best, top = {}, nil, 0
    for _, slot in ipairs(WORN_CORE) do
        local link = GetInventoryItemLink("player", slot)
        local sub = link and select(7, GetItemInfo(link)) or nil
        if sub then
            count[sub] = (count[sub] or 0) + 1
            if count[sub] > top then
                best, top = sub, count[sub]
            end
        end
    end
    if top < WORN_MIN then return nil end
    return best
end
local function alienWear(row, kind)
    if not kind or not row.subType or not CORE_SLOT[row.equipSlot or ""] then return false end
    return row.subType ~= kind
end
local function ammoKind(row)
    if row.equipSlot == THROWN_SLOT then return "thrown" end
    if row.equipSlot ~= AMMO_SLOT then return nil end
    local at = ns.Groups.SubIndex(row.itemType, row.subType)
    if at == ARROW then return "arrow" end
    if at == BULLET then return "bullet" end
    return "ammo"
end
local ROMAN = { I = 1, V = 5, X = 10, L = 50, C = 100 }
local function rankOf(name)
    if not name then return nil end
    local base, tail = name:match("^(.-)%s+([IVXLC]+)$")
    if not base or base == "" then return nil end
    local total, prev = 0, 0
    for i = #tail, 1, -1 do
        local v = ROMAN[tail:sub(i, i)]
        if not v then return nil end
        if v < prev then
            total = total - v
        else
            total = total + v
            prev = v
        end
    end
    return base, total
end
local function bestRanks(rows, level)
    local best = {}
    for _, r in ipairs(rows) do
        local base, rank = rankOf(r.name)
        if base then
            local ok = (r.minLevel or 0) <= level
            local b = best[base]
            if not b then
                best[base] = { rank = rank, ok = ok }
            elseif ok and not b.ok then
                b.rank, b.ok = rank, true
            elseif ok == b.ok then
                if (ok and rank > b.rank) or (not ok and rank < b.rank) then b.rank = rank end
            end
        end
    end
    return best
end
function Filter.Apply(src, out)
    out = out or {}
    wipe(out)
    local t = store()
    local anyAmmo = t.arrow or t.bullet or t.thrown
    local best = t.rank and bestRanks(src, UnitLevel("player") or 0) or nil
    local worn = t.mineWear and Filter.WornKind() or nil
    for _, row in ipairs(src) do
        local drop = false
        if row.quality ~= HEIRLOOM then
            if t.mineClass and alienClass(row) then drop = true end
            if not drop and t.mineProf and alienProf(row) then drop = true end
            if not drop and t.mineStat and alienStat(row) then drop = true end
            if not drop and t.mineWear and alienWear(row, worn) then drop = true end
            if not drop and anyAmmo then
                local kind = ammoKind(row)
                if kind == "ammo" then
                    drop = t.arrow and t.bullet
                elseif kind then
                    drop = t[kind] and true or false
                end
            end
            if not drop and best then
                local base, rank = rankOf(row.name)
                if base and best[base] and best[base].rank ~= rank then drop = true end
            end
        end
        if not drop then out[#out + 1] = row end
    end
    return out
end
