local ADDON, ns = ...
local List = {}
ns.List = List
local MAX_COST = MAX_ITEM_COST or 3
local HONOR_ICON = "Interface\\PVPFrame\\PVP-Currency-"
local ARENA_ICON = "Interface\\PVPFrame\\PVP-ArenaPoints-Icon"
local goods = {}
local buyback = {}
local CYR = {}
for b = 0x90, 0x9F do CYR[string.char(0xD0, b)] = string.char(0xD0, b + 0x20) end
for b = 0xA0, 0xAF do CYR[string.char(0xD0, b)] = string.char(0xD1, b - 0x20) end
CYR[string.char(0xD0, 0x81)] = string.char(0xD1, 0x91)
local CYR_PAT = string.char(0xD0) .. "[" .. string.char(0x81, 0x90) .. "-" .. string.char(0xAF) .. "]"
local UP = {}
for k, v in pairs(CYR) do UP[v] = k end
function ns.Lower(s)
    s = (s or ""):lower()
    return (s:gsub(CYR_PAT, CYR))
end
function ns.UpperFirst(s)
    if not s or s == "" then return s end
    local two = s:sub(1, 2)
    if UP[two] then return UP[two] .. s:sub(3) end
    return s:sub(1, 1):upper() .. s:sub(2)
end
local EN2RU, RU2EN = {}, {}
local function eachChar(s, fn)
    local i = 1
    while i <= #s do
        local b = s:byte(i)
        local n = (b >= 0xF0 and 4) or (b >= 0xE0 and 3) or (b >= 0xC0 and 2) or 1
        fn(s:sub(i, i + n - 1))
        i = i + n
    end
end
local function buildLayout()
    local en, ru = ns.layout.en, ns.layout.ru
    local at = 1
    eachChar(ru, function(ch)
        local key = en:sub(at, at)
        if key ~= "" then
            EN2RU[key] = ch
            RU2EN[ch] = key
        end
        at = at + 1
    end)
end
buildLayout()
function ns.Layouts(q)
    if not q or q == "" then return nil end
    local toRu, toEn, hasRu, hasEn = "", "", false, false
    eachChar(q, function(ch)
        local ru, en = EN2RU[ch], RU2EN[ch]
        if ru then hasRu = true end
        if en then hasEn = true end
        toRu = toRu .. (ru or ch)
        toEn = toEn .. (en or ch)
    end)
    local out = { q }
    if hasRu then out[#out + 1] = toRu end
    if hasEn then out[#out + 1] = toEn end
    return out
end
local SEPS = { " - ", " — " }
local function lastSep(name)
    local cut, len
    for _, sep in ipairs(SEPS) do
        local from = 1
        while true do
            local a = strfind(name, sep, from, true)
            if not a then break end
            if not cut or a > cut then cut, len = a, #sep end
            from = a + 1
        end
    end
    return cut, len
end
function ns.NameBody(name)
    if not name or name == "" then return nil end
    local cut = lastSep(name)
    if not cut or cut < 4 then return nil end
    local body = (name:sub(1, cut - 1):gsub("%s+$", ""))
    if body == "" then return nil end
    return body
end
function ns.NameRest(name)
    if not name or name == "" then return nil end
    local cut, len = lastSep(name)
    if not cut or cut < 4 then return nil end
    local rest = (name:sub(cut + len):gsub("^%s+", ""))
    if rest == "" then return nil end
    return rest
end
local function costOf(index)
    local honor, arena, n = GetMerchantItemCostInfo(index)
    honor, arena, n = honor or 0, arena or 0, n or 0
    if honor == 0 and arena == 0 and n == 0 then return nil end
    local cost = { honor = honor, arena = arena, items = {} }
    for i = 1, math.min(n, MAX_COST) do
        local tex, value, link = GetMerchantItemCostItem(index, i)
        if tex then cost.items[#cost.items + 1] = { tex = tex, n = value or 0, link = link } end
    end
    return cost
end
local function trim(t, n)
    for i = #t, n + 1, -1 do t[i] = nil end
end
function List.Scan()
    local n = GetMerchantNumItems() or 0
    local missing = false
    for i = 1, n do
        local name, tex, price, quantity, stock, usable, extended = GetMerchantItemInfo(i)
        local link = GetMerchantItemLink(i)
        local row = goods[i] or {}
        goods[i] = row
        row.index, row.name, row.tex, row.link = i, name, tex, link
        row.price = price or 0
        row.quantity = quantity or 1
        row.stock = stock or -1
        row.usable = usable and true or false
        row.cost = extended and costOf(i) or nil
        local _, _, quality, iLevel, minLevel, itemType, subType, _, equipSlot
        if link then _, _, quality, iLevel, minLevel, itemType, subType, _, equipSlot = GetItemInfo(link) end
        row.quality = quality
        row.iLevel = iLevel or 0
        row.minLevel = minLevel or 0
        row.id = link and tonumber(link:match("item:(%d+)")) or nil
        row.itemType = itemType
        row.subType = subType
        row.equipSlot = equipSlot or ""
        local info, incomplete = ns.Scan.Item(i, link, name)
        if incomplete then missing = true end
        row.set, row.classes, row.known = info.set, info.classes, info.known
        row.prod = nil
        row.prodName = info.product
        row.desc = info.desc
        row.req = info.req
        row.skill = info.skill
        row.stat = info.stat
        row.diet = info.diet
        row.enchant = info.enchant
        row.repRank, row.repFaction = info.repRank, info.repFaction
        if info.product then
            local _, _, pq, pil, _, pt, ps, _, pslot = GetItemInfo(info.product)
            if pt then
                row.prod = { quality = pq, iLevel = pil or 0, itemType = pt, subType = ps, equipSlot = pslot or "" }
            else
                missing = true
            end
        end
        if link and not quality then missing = true end
    end
    trim(goods, n)
    return goods, missing
end
function List.Buyback()
    local n = GetNumBuybackItems() or 0
    for i = 1, n do
        local name, tex, price, quantity, stock, usable = GetBuybackItemInfo(i)
        local link = GetBuybackItemLink(i)
        local row = buyback[i] or {}
        buyback[i] = row
        row.index, row.name, row.tex, row.link = i, name, tex, link
        row.price = price or 0
        row.quantity = quantity or 1
        row.stock = -1
        row.usable = usable and true or false
        row.cost = nil
        row.quality = link and select(3, GetItemInfo(link)) or nil
    end
    trim(buyback, n)
    return buyback, false
end
local function hit(name, vars)
    local low = ns.Lower(name)
    for _, v in ipairs(vars) do
        if strfind(low, v, 1, true) then return true end
    end
    return false
end
function List.Filter(src, query, usableOnly, out)
    out = out or {}
    wipe(out)
    local vars = query and query ~= "" and ns.Layouts(ns.Lower(query)) or nil
    for _, row in ipairs(src) do
        if (not usableOnly or row.usable)
            and (not vars or hit(row.name, vars)) then
            out[#out + 1] = row
        end
    end
    return out
end
local function amount(n)
    return n > 1 and (tostring(n) .. " ") or ""
end
ns.Amount = amount
local GOLD = 10000
local ROUND_OVER = 5 * GOLD
function List.Coin(copper)
    local unit = (ns.Filter and ns.Filter.Unit()) or 1
    if unit < GOLD and copper > ROUND_OVER then unit = GOLD end
    if unit > 1 and copper >= unit then
        copper = math.ceil(copper / unit) * unit
    end
    return GetCoinTextureString(copper)
end
function List.Purse(copper)
    local unit = (ns.Filter and ns.Filter.Unit()) or 1
    if unit > 1 and copper >= unit then
        copper = math.floor(copper / unit) * unit
    end
    return GetCoinTextureString(copper)
end
local function wearable(link)
    if not link then return false end
    local slot = select(9, GetItemInfo(link))
    return slot ~= nil and slot ~= ""
end
List.Wearable = wearable
function List.PriceParts(row, mult, noGear, out)
    mult = mult or 1
    local parts = out or {}
    wipe(parts)
    if row.price > 0 then parts[#parts + 1] = List.Coin(row.price * mult) end
    local c = row.cost
    if c then
        if c.honor > 0 then
            local faction = UnitFactionGroup("player") or "Alliance"
            parts[#parts + 1] = amount(c.honor * mult) .. ns.Icon(HONOR_ICON .. faction)
        end
        if c.arena > 0 then
            parts[#parts + 1] = amount(c.arena * mult) .. ns.Icon(ARENA_ICON)
        end
        for _, it in ipairs(c.items) do
            if not (noGear and wearable(it.link)) then
                parts[#parts + 1] = amount(it.n * mult) .. ns.Icon(it.tex)
            end
        end
    end
    return parts
end
local PRICE_SEP = "  "
List.PriceSep = PRICE_SEP
function List.PriceText(row, mult, noGear)
    return table.concat(List.PriceParts(row, mult, noGear), PRICE_SEP)
end
local ICON_NUDGE = -1
local CUR_SIZE, CUR_NUDGE = 13, -2
ns.IconSize = CUR_SIZE
function ns.Icon(path, size)
    size = size or CUR_SIZE
    local nudge = (size == 0) and ICON_NUDGE or CUR_NUDGE
    return "|T" .. path .. ":" .. size .. ":" .. size .. ":0:" .. nudge .. "|t"
end
function List.Wallet(src, out)
    out = out or {}
    wipe(out)
    local seen = {}
    local honor, arena = false, false
    for _, row in ipairs(src) do
        local c = row.cost
        if c then
            if c.honor > 0 then honor = true end
            if c.arena > 0 then arena = true end
            for _, it in ipairs(c.items) do
                local id = (not wearable(it.link)) and it.link and it.link:match("item:(%d+)") or nil
                if id and not seen[id] then
                    seen[id] = true
                    out[#out + 1] = {
                        tex = it.tex, link = it.link, id = id,
                        title = it.link and GetItemInfo(it.link) or nil,
                        count = GetItemCount(it.link),
                    }
                end
            end
        end
    end
    if honor then
        local faction = UnitFactionGroup("player") or "Alliance"
        out[#out + 1] = { tex = HONOR_ICON .. faction, count = (GetHonorCurrency()) or 0,
            title = HONOR_POINTS, hint = "curHonor" }
    end
    if arena then
        out[#out + 1] = { tex = ARENA_ICON, count = (GetArenaCurrency()) or 0,
            title = ARENA_POINTS, hint = "curArena" }
    end
    return out
end
function List.CostLines(row, out)
    out = out or {}
    wipe(out)
    local c = row.cost
    if not c then return out end
    local function add(name, need, have, tex, link)
        out[#out + 1] = { name = name, need = need, have = have or 0, tex = tex, link = link }
    end
    if c.honor > 0 then
        local faction = UnitFactionGroup("player") or "Alliance"
        add(HONOR_POINTS, c.honor, GetHonorCurrency(), HONOR_ICON .. faction)
    end
    if c.arena > 0 then add(ARENA_POINTS, c.arena, GetArenaCurrency(), ARENA_ICON) end
    for _, it in ipairs(c.items) do
        add(it.link and GetItemInfo(it.link) or nil,
            it.n, it.link and GetItemCount(it.link) or 0, it.tex, it.link)
    end
    return out
end
local UNLIMITED = 999
function List.CanAfford(row)
    local best = UNLIMITED
    local function cap(have, need)
        if need and need > 0 then
            local n = math.floor((have or 0) / need)
            if n < best then best = n end
        end
    end
    cap((GetMoney()), row.price)
    local c = row.cost
    if c then
        cap((GetHonorCurrency()), c.honor)
        cap((GetArenaCurrency()), c.arena)
        for _, it in ipairs(c.items) do
            cap(it.link and GetItemCount(it.link) or 0, it.n)
        end
    end
    if row.stock and row.stock >= 0 and row.stock < best then best = row.stock end
    return best
end
function List.BuyMany(index, count)
    local maxStack = GetMerchantItemMaxStack(index) or 1
    if maxStack < 1 then maxStack = 1 end
    local left, guard = count, 0
    while left > 0 and guard < 200 do
        local take = left < maxStack and left or maxStack
        BuyMerchantItem(index, take)
        left = left - take
        guard = guard + 1
    end
end
function List.RepairInfo()
    local cost, canPay = GetRepairAllCost()
    return CanMerchantRepair() and true or false, cost or 0, canPay and true or false,
        CanGuildBankRepair() and true or false
end
