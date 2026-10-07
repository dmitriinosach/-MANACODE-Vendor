local ADDON, ns = ...
local Scan = {}
ns.Scan = Scan
local TIP_NAME = "HTP_VendorScanTip"
local tip = CreateFrame("GameTooltip", TIP_NAME, UIParent, "GameTooltipTemplate")
tip:SetOwner(UIParent, "ANCHOR_NONE")
local function pattern(template)
    local p = template:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
    p = p:gsub("%%%%%d+%%%$s", "(.-)")
    p = p:gsub("%%%%%d+%%%$d", "(%%d+)")
    p = p:gsub("%%%%s", "(.-)")
    p = p:gsub("%%%%c", "(.-)")
    p = p:gsub("%%%%d", "(%%d+)")
    return "^" .. p .. "$"
end
local SET_PAT = pattern(ITEM_SET_NAME)
local CLASSES_PAT = pattern(ITEM_CLASSES_ALLOWED)
local SKILL_PAT = ITEM_MIN_SKILL and pattern(ITEM_MIN_SKILL) or nil
local KNOWN = ITEM_SPELL_KNOWN
local LEVEL_PREFIX = TOOLTIP_UNIT_LEVEL:gsub("%%s.*$", "")
local REAGENT_PREFIX = SPELL_REAGENTS:gsub("|n", ""):gsub("%s+$", "")
local USE_PREFIX = ITEM_SPELL_TRIGGER_ONUSE or ""
local REP_PAT = ITEM_REQ_REPUTATION and pattern(ITEM_REQ_REPUTATION) or nil
local STANDINGS = {}
for i = 1, 8 do
    local label = _G["FACTION_STANDING_LABEL" .. i]
    if label then STANDINGS[label] = i end
end
local function repOf(t)
    if not REP_PAT then return nil end
    local a, b = t:match(REP_PAT)
    if not a then return nil end
    if STANDINGS[a] then return STANDINGS[a], b end
    if STANDINGS[b] then return STANDINGS[b], a end
    return nil
end
local QUOTE = '"'
local GUILL_L = string.char(0xC2, 0xAB)
local GUILL_R = string.char(0xC2, 0xBB)
local function quoted(t)
    if #t > 2 and t:sub(1, 1) == QUOTE and t:sub(-1) == QUOTE then
        return t:sub(2, -2)
    end
    if #t > 4 and t:sub(1, 2) == GUILL_L and t:sub(-2) == GUILL_R then
        return t:sub(3, -3)
    end
    return nil
end
local stats
local diet
local function stemOf(w)
    if #w <= 2 then return w end
    local cut = (w:byte(#w) >= 0x80) and 2 or 1
    return w:sub(1, #w - cut)
end
local function loadDiet()
    if diet then return diet end
    diet = { health = stemOf(ns.Lower(HEALTH or "")), mana = stemOf(ns.Lower(MANA or "")) }
    return diet
end
local function enchantUse(t)
    if USE_PREFIX == "" or t:sub(1, #USE_PREFIX) ~= USE_PREFIX then return false end
    if not ns.Has("enchantStem") then return false end
    return strfind(ns.Lower(t), ns.Lower(ns.T("enchantStem")), 1, true) ~= nil
end
local function dietOf(t, have)
    if USE_PREFIX == "" or t:sub(1, #USE_PREFIX) ~= USE_PREFIX then return have end
    local d = loadDiet()
    local low = ns.Lower(t)
    if d.health ~= "" and strfind(low, d.health, 1, true) then return "food" end
    if have == nil and d.mana ~= "" and strfind(low, d.mana, 1, true) then return "drink" end
    return have
end
local function loadStats()
    if stats then return stats end
    stats = {}
    local dull = ITEM_MOD_STAMINA_SHORT
    for key, val in pairs(_G) do
        if type(key) == "string" and type(val) == "string"
            and strfind(key, "^ITEM_MOD_") and strfind(key, "_SHORT$")
            and #val >= 5 and not strfind(val, "%%") then
            stats[#stats + 1] = { name = val, low = ns.Lower(val), dull = (val == dull) }
        end
    end
    table.sort(stats, function(a, b) return #a.low > #b.low end)
    return stats
end
local function statOf(text)
    if not text or text == "" then return nil end
    local low = ns.Lower(text)
    local weak
    for _, s in ipairs(loadStats()) do
        if strfind(low, s.low, 1, true) then
            if s.dull then
                weak = weak or s.name
            else
                return s.name
            end
        end
    end
    return weak
end
local items = {}
local reagents
local function line(i)
    local fs = _G[TIP_NAME .. "TextLeft" .. i]
    return fs and fs:GetText()
end
local function reset()
    tip:SetOwner(UIParent, "ANCHOR_NONE")
    tip:ClearLines()
end
function Scan.Reset()
    wipe(items)
end
function Scan.Item(index, link, name)
    local c = link and items[link]
    if c then return c end
    c = { set = nil, classes = nil, known = false, product = nil, desc = nil, req = nil,
          stat = nil, diet = nil, skill = nil, enchant = false, repRank = nil, repFaction = nil }
    local want = name and name:match("^[^:]+:%s*(.+)$")
    want = want and ns.Lower(want)
    local body = {}
    reset()
    tip:SetMerchantItem(index)
    for i = 2, tip:NumLines() do
        local fs = _G[TIP_NAME .. "TextLeft" .. i]
        local t = fs and fs:GetText()
        if t then
            t = t:gsub("|n", " ")
            t = t:gsub("^[%s%c]+", ""):gsub("[%s%c]+$", "")
            local set = t:match(SET_PAT)
            if set then c.set = set end
            local cls = t:match(CLASSES_PAT)
            if cls then c.classes = cls end
            if SKILL_PAT and not c.skill then
                local _, lvl = t:match(SKILL_PAT)
                if lvl then c.skill = tonumber(lvl) end
            end
            if t == KNOWN then c.known = true end
            if want and not c.product and ns.Lower(t) == want then c.product = t end
            if not c.desc then
                local inner = quoted(t)
                if inner then c.desc = (inner:gsub("%.$", "")) end
            end
            c.diet = dietOf(t, c.diet)
            if enchantUse(t) then c.enchant = true end
            if not c.repRank then c.repRank, c.repFaction = repOf(t) end
            if not c.req and t ~= "" then
                local cr, cg, cb = fs:GetTextColor()
                if cr and cr > 0.9 and cg < 0.35 and cb < 0.35 then c.req = t end
            end
            body[#body + 1] = t
        end
    end
    local all = table.concat(body, " ")
    c.stat = statOf(all)
    local incomplete = (want and not c.product and not c.desc) and true or false
    if link and not incomplete then items[link] = c end
    return c, incomplete
end
function Scan.Dump(index)
    local out = {}
    reset()
    tip:SetMerchantItem(index)
    for i = 1, tip:NumLines() do
        local l = line(i) or ""
        local rfs = _G[TIP_NAME .. "TextRight" .. i]
        local r = rfs and rfs:GetText()
        out[i] = r and (l .. "  >>  " .. r) or l
    end
    return out
end
function Scan.NpcTitle()
    if not UnitExists("npc") then return nil end
    reset()
    tip:SetUnit("npc")
    local t = line(2)
    if not t or t == "" then return nil end
    if t:sub(1, #LEVEL_PREFIX) == LEVEL_PREFIX then return nil end
    return t
end
local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end
function Scan.MyReagents()
    if reagents then return reagents end
    reagents = {}
    for tab = 1, GetNumSpellTabs() do
        local _, _, offset, num = GetSpellTabInfo(tab)
        for s = offset + 1, offset + num do
            reset()
            tip:SetSpell(s, BOOKTYPE_SPELL)
            for i = 2, tip:NumLines() do
                local t = line(i)
                if t then
                    t = t:gsub("|n", ",")
                    if t:sub(1, #REAGENT_PREFIX) == REAGENT_PREFIX then
                        for name in t:sub(#REAGENT_PREFIX + 1):gmatch("[^,%c]+") do
                            name = trim(name):gsub("%s*%(%d+%)$", "")
                            if name ~= "" then reagents[ns.Lower(name)] = true end
                        end
                    end
                end
            end
        end
    end
    return reagents
end
function Scan.ForgetReagents()
    reagents = nil
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("LEARNED_SPELL_IN_TAB")
watcher:SetScript("OnEvent", Scan.ForgetReagents)
