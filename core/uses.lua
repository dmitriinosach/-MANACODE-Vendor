local ADDON, ns = ...
local Uses = {}
ns.Uses = Uses
local WEAPON_CLASS, ARMOR_CLASS, CONSUMABLE_CLASS = 1, 2, 4
local WEAPON_SUBS, ARMOR_SUBS = 17, 10
local FOOD_SUB = 1
local ANY_WEAPON = { [12] = true, [17] = true }
local ANY_ARMOR = { [1] = true, [2] = true }
local CLOAK = "INVTYPE_CLOAK"
local MANA = 0
local WEAK_SHARE = 0.25
local MAX_PROF_LINES = 4
local WEAPONS = {
    WARRIOR = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15 },
    PALADIN = { 1, 2, 5, 6, 7, 8, 9 },
    HUNTER = { 1, 2, 3, 4, 7, 8, 9, 10, 11, 13, 14, 15 },
    ROGUE = { 1, 3, 4, 5, 8, 11, 13, 14, 15 },
    PRIEST = { 5, 10, 13, 16 },
    DEATHKNIGHT = { 1, 2, 5, 6, 7, 8, 9 },
    SHAMAN = { 1, 2, 5, 6, 10, 11, 13 },
    MAGE = { 8, 10, 13, 16 },
    WARLOCK = { 8, 10, 13, 16 },
    DRUID = { 5, 6, 7, 10, 11, 13 },
}
local ARMOR = {
    WARRIOR = { [3] = 1, [4] = 1, [5] = 40, [6] = 1 },
    PALADIN = { [3] = 1, [4] = 1, [5] = 40, [6] = 1, [7] = 1 },
    HUNTER = { [3] = 1, [4] = 40 },
    ROGUE = { [3] = 1 },
    PRIEST = {},
    DEATHKNIGHT = { [3] = 1, [4] = 1, [5] = 1, [10] = 1 },
    SHAMAN = { [3] = 1, [4] = 40, [6] = 1, [9] = 1 },
    MAGE = {},
    WARLOCK = {},
    DRUID = { [3] = 1, [8] = 1 },
}
local COLOR_SPELL = { 0.4, 0.8, 1 }
local COLOR_MINE = { 0.55, 0.9, 0.45 }
local COLOR_ALT = { 0.75, 0.75, 0.75 }
local COLOR_HINT = { 0.6, 0.6, 0.6 }
local COLOR_BAD = { 1, 0.45, 0.45 }
local weaponSet
local function weaponsOf(class)
    weaponSet = weaponSet or {}
    local set = weaponSet[class]
    if set then return set end
    set = {}
    for _, i in ipairs(WEAPONS[class] or {}) do set[i] = true end
    weaponSet[class] = set
    return set
end
local layoutOk
local function layoutKnown()
    if layoutOk == nil then
        layoutOk = select("#", GetAuctionItemSubClasses(WEAPON_CLASS)) == WEAPON_SUBS
            and select("#", GetAuctionItemSubClasses(ARMOR_CLASS)) == ARMOR_SUBS
    end
    return layoutOk
end
local function classToken()
    local _, token = UnitClass("player")
    return token or "NONE"
end
function Uses.Gear(row)
    if not row.itemType or not row.subType or row.equipSlot == CLOAK or not layoutKnown() then return nil end
    local classes = ns.Groups.Types().classes
    local idx = ns.Groups.SubIndex(row.itemType, row.subType)
    if not idx then return nil end
    local class = classToken()
    if not WEAPONS[class] then return nil end
    local level = UnitLevel("player") or 0
    if row.itemType == classes[WEAPON_CLASS] then
        if ANY_WEAPON[idx] then return nil end
        if not weaponsOf(class)[idx] then return "never" end
    elseif row.itemType == classes[ARMOR_CLASS] then
        if ANY_ARMOR[idx] then return nil end
        local from = ARMOR[class][idx]
        if not from then return "never" end
        if from > level then return "level", from end
    else
        return nil
    end
    if not row.usable and (row.minLevel or 0) <= level and (row.req == nil or row.req == row.subType) then
        return "train"
    end
    return nil
end
function Uses.Food(row)
    if not row.diet or not row.itemType then return nil end
    if row.itemType ~= ns.Groups.Types().classes[CONSUMABLE_CLASS] then return nil end
    if ns.Groups.SubIndex(row.itemType, row.subType) ~= FOOD_SUB then return nil end
    local maxMana = UnitPowerMax("player", MANA) or 0
    if row.mp and not row.hp and maxMana == 0 then return ns.T("useNoMana") end
    if row.buff then return nil end
    local maxHp = UnitHealthMax("player") or 0
    if row.hp and maxHp > 0 and row.hp < maxHp * WEAK_SHARE then
        return ns.T("useWeakFood", row.hp, maxHp)
    end
    if row.mp and not row.hp and maxMana > 0 and row.mp < maxMana * WEAK_SHARE then
        return ns.T("useWeakDrink", row.mp, maxMana)
    end
    return nil
end
local function put(out, text, c)
    out[#out + 1] = { text = text, r = c[1], g = c[2], b = c[3] }
end
local function profText(u)
    if u.who then return ns.T("useAlt", u.who, u.prof, u.n) end
    if u.n == 1 then
        return ns.T("useProfOne", u.prof, u.ex) .. ns.T(u.up > 0 and "useSkillOne" or "useNoSkill")
    end
    return ns.T("useProfMany", u.prof, u.n) .. (u.up > 0 and ns.T("useSkillUp", u.up) or ns.T("useNoSkill"))
end
function Uses.Lines(row, out)
    out = out or {}
    wipe(out)
    local spell = row.name and ns.Scan.MyReagents()[ns.Lower(row.name)]
    if type(spell) == "string" then put(out, ns.T("useSpell", spell), COLOR_SPELL) end
    local list = ns.Prof.Uses(row.id)
    local own = false
    if list then
        for i, u in ipairs(list) do
            if i > MAX_PROF_LINES then
                put(out, ns.T("useMore", #list - MAX_PROF_LINES), COLOR_ALT)
                break
            end
            if not u.who then own = true end
            put(out, profText(u), u.who and COLOR_ALT or COLOR_MINE)
        end
    end
    if not own and row.id and ns.reagentAny and ns.reagentAny[row.id] and not ns.Prof.Known() then
        put(out, ns.T("useOpenProf"), COLOR_HINT)
    end
    local food = Uses.Food(row)
    if food then put(out, food, COLOR_BAD) end
    local gear, level = Uses.Gear(row)
    if gear == "never" then
        put(out, ns.T("useGearNever"), COLOR_BAD)
    elseif gear == "level" then
        put(out, ns.T("useGearLevel", level), COLOR_HINT)
    elseif gear == "train" then
        put(out, ns.T("useGearTrain"), COLOR_HINT)
    end
    return out
end
