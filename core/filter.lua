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
    { key = "mine", switch = true, section = "filterHide",
      subs = { "mineClass", "mineNever", "mineArmor", "mineStat", "mineProf", USABLE } },
    { key = "ammo", switch = true, subs = { "arrow", "bullet", "thrown", "food" } },
    { key = "rank" },
    { key = "price", look = true, section = "filterLook",
      subs = { "showSilver", "showCopper", "showPayItem", "showLevel" } },
    { key = "look", look = true, subs = { "qualityName", "qualityFrame", "qualityGlow" } },
}
local RENAMED = {
    hideSilver = { to = "showSilver", flip = true },
    hideCopper = { to = "showCopper", flip = true },
    hideGear = { to = "showPayItem", flip = true },
    hideLevel = { to = "showLevel", flip = true },
    mineWear = { to = "mineArmor" },
}
function Filter.Tree()
    return TREE
end
local function nodeOf(key)
    for _, node in ipairs(TREE) do
        if node.key == key then return node end
    end
    return nil
end
local parentOf = {}
for _, node in ipairs(TREE) do
    for _, leaf in ipairs(node.subs or {}) do parentOf[leaf] = node end
end
local function classToken()
    local _, token = UnitClass("player")
    return token or "NONE"
end
local function defaults()
    local ammo = not RANGED[classToken()]
    return {
        mineOn = true, ammoOn = true,
        mineClass = true, mineNever = true, mineArmor = false, mineStat = false, mineProf = false,
        arrow = ammo, bullet = ammo, thrown = ammo, food = false,
        rank = false,
        showSilver = false, showCopper = false, showPayItem = false, showLevel = true,
        qualityName = false, qualityFrame = true, qualityGlow = false,
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
    for old, r in pairs(RENAMED) do
        if t[old] ~= nil then
            if t[r.to] == nil then t[r.to] = (r.flip and not t[old]) or (not r.flip and t[old]) or false end
            t[old] = nil
        end
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
    local node = nodeOf(key)
    if node and node.switch then return t[key .. "On"] and true or false end
    if not node or not node.subs then return t[key] and true or false end
    for _, leaf in ipairs(node.subs) do
        if not t[leaf] then return false end
    end
    return true
end
function Filter.Some(key)
    local node = nodeOf(key)
    if not node or not node.subs then return Filter.Get(key) end
    for _, leaf in ipairs(node.subs) do
        if Filter.Get(leaf) then return true end
    end
    return false
end
function Filter.Active(key)
    local parent = parentOf[key]
    if parent and parent.switch and not Filter.Get(parent.key) then return false end
    return Filter.Get(key)
end
function Filter.Set(key, on)
    if key == USABLE then
        ns.DB().usableOnly = on and true or false
        return
    end
    local t = store()
    local node = nodeOf(key)
    if node and node.switch then
        t[key .. "On"] = on and true or false
    elseif node and node.subs then
        for _, leaf in ipairs(node.subs) do t[leaf] = on and true or false end
    else
        t[key] = on and true or false
    end
end
function Filter.ShowAll()
    local t = store()
    for _, node in ipairs(TREE) do
        if node.switch then
            t[node.key .. "On"] = false
        elseif not node.look and not node.subs then
            t[node.key] = false
        end
    end
end
local hidden = 0
function Filter.Hidden()
    return hidden
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
    if t.showCopper then return 1 end
    if t.showSilver then return 100 end
    return 10000
end
local function alienClass(row)
    if row.classes and row.classes ~= "" and #classNames() > 0 then
        if not mineByName(row.classes) then return true end
    end
    local owner = row.id and ns.reagentClass and ns.reagentClass[row.id]
    return owner ~= nil and not strfind(owner, classToken(), 1, true)
end
local function alienNever(row)
    return ns.Uses ~= nil and ns.Uses.Gear(row) == "never"
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
local function tipStat(row)
    if not row.stat then return nil end
    for key, short in pairs(STAT) do
        if _G[key] == row.stat then return short end
    end
    return nil
end
local function alienStat(row)
    if not row.link or not row.equipSlot or row.equipSlot == "" then return false end
    wipe(statBuf)
    GetItemStats(row.link, statBuf)
    for key in pairs(STAT) do
        if (statBuf[key] or 0) > 0 then return Filter.AlienStat(classToken(), statBuf) end
    end
    local short = tipStat(row)
    local alien = ALIEN[classToken()]
    return short ~= nil and alien ~= nil and alien[short] == true
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
local function alienArmor(row, kind)
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
    local A = Filter.Active
    local usable = A(USABLE)
    local mineClass, mineNever = A("mineClass"), A("mineNever")
    local mineProf, mineStat, mineArmor = A("mineProf"), A("mineStat"), A("mineArmor")
    local arrow, bullet, thrown, food = A("arrow"), A("bullet"), A("thrown"), A("food")
    local anyAmmo = arrow or bullet or thrown
    local best = A("rank") and bestRanks(src, UnitLevel("player") or 0) or nil
    local worn = mineArmor and Filter.WornKind() or nil
    for _, row in ipairs(src) do
        local drop = usable and not row.usable
        if not drop and row.quality ~= HEIRLOOM then
            if mineClass and alienClass(row) then drop = true end
            if not drop and mineNever and alienNever(row) then drop = true end
            if not drop and mineProf and alienProf(row) then drop = true end
            if not drop and mineStat and alienStat(row) then drop = true end
            if not drop and mineArmor and alienArmor(row, worn) then drop = true end
            if not drop and anyAmmo then
                local kind = ammoKind(row)
                if kind == "ammo" then
                    drop = arrow and bullet
                elseif kind == "arrow" then
                    drop = arrow
                elseif kind == "bullet" then
                    drop = bullet
                elseif kind == "thrown" then
                    drop = thrown
                end
            end
            if not drop and food and ns.Uses and ns.Uses.Food(row) then drop = true end
            if not drop and best then
                local base, rank = rankOf(row.name)
                if base and best[base] and best[base].rank ~= rank then drop = true end
            end
        end
        if not drop then out[#out + 1] = row end
    end
    hidden = #src - #out
    return out
end
