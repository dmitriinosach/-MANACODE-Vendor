local ADDON, ns = ...
local Groups = {}
ns.Groups = Groups
local SHARE = 0.4
local KIND_MIN = 8
local KIND_RANK = { enchant = 1, gear = 2, recipe = 3, mount = 4, other = 5 }
local JEWELCRAFTING_SPELL = 25229
local COOKING_SPELL = 2550
local SLOT_ORDER = {
    "INVTYPE_HEAD", "INVTYPE_NECK", "INVTYPE_SHOULDER", "INVTYPE_CLOAK",
    "INVTYPE_CHEST", "INVTYPE_ROBE", "INVTYPE_BODY", "INVTYPE_TABARD",
    "INVTYPE_WRIST", "INVTYPE_HAND", "INVTYPE_WAIST", "INVTYPE_LEGS", "INVTYPE_FEET",
    "INVTYPE_FINGER", "INVTYPE_TRINKET",
    "INVTYPE_WEAPON", "INVTYPE_2HWEAPON", "INVTYPE_WEAPONMAINHAND", "INVTYPE_WEAPONOFFHAND",
    "INVTYPE_HOLDABLE", "INVTYPE_SHIELD", "INVTYPE_RANGED", "INVTYPE_RANGEDRIGHT",
    "INVTYPE_THROWN", "INVTYPE_RELIC", "INVTYPE_BAG", "INVTYPE_QUIVER", "INVTYPE_AMMO",
}
local SLOT_RANK = {}
for i, slot in ipairs(SLOT_ORDER) do SLOT_RANK[slot] = i end
local SLOT_MERGE = { INVTYPE_ROBE = "INVTYPE_CHEST", INVTYPE_RANGEDRIGHT = "INVTYPE_RANGED" }
local ARMOR_SLOT = {
    INVTYPE_HEAD = true, INVTYPE_NECK = true, INVTYPE_SHOULDER = true, INVTYPE_CLOAK = true,
    INVTYPE_CHEST = true, INVTYPE_WRIST = true, INVTYPE_HAND = true, INVTYPE_WAIST = true,
    INVTYPE_LEGS = true, INVTYPE_FEET = true, INVTYPE_FINGER = true, INVTYPE_TRINKET = true,
}
local NOT_GEAR = { INVTYPE_AMMO = true, INVTYPE_BAG = true, INVTYPE_QUIVER = true }
local MISC_SLOT = {
    INVTYPE_NECK = true, INVTYPE_FINGER = true, INVTYPE_TRINKET = true,
    INVTYPE_TABARD = true, INVTYPE_BODY = true, INVTYPE_HOLDABLE = true,
    INVTYPE_CLOAK = true,
}
local types
local subCache = {}
local NO_SUBS = {}
local sockets
local COLOR_RED, COLOR_BLUE, COLOR_YELLOW = 1, 2, 3
local COLOR_PURPLE, COLOR_GREEN, COLOR_ORANGE, COLOR_META = 4, 5, 6, 7
local function classWithSub(classes, subName)
    if not subName then return nil end
    for i = 1, #classes do
        for _, sub in ipairs({ GetAuctionItemSubClasses(i) }) do
            if sub == subName then return i end
        end
    end
    return nil
end
local function loadTypes()
    if types then return types end
    local classes = { GetAuctionItemClasses() }
    local at = classWithSub(classes, GetSpellInfo(COOKING_SPELL))
        or classWithSub(classes, GetSpellInfo(JEWELCRAFTING_SPELL))
    types = { classes = classes, recipe = at and classes[at] or nil }
    return types
end
function Groups.Types()
    return loadTypes()
end
local function subOrder(itemType)
    if not itemType then return NO_SUBS end
    local o = subCache[itemType]
    if o then return o end
    o = {}
    local classes = loadTypes().classes
    for i = 1, #classes do
        if classes[i] == itemType then
            for k, name in ipairs({ GetAuctionItemSubClasses(i) }) do o[name] = k end
            break
        end
    end
    subCache[itemType] = o
    return o
end
local function firstWord(s)
    return s and s:match("^(%S+)") or nil
end
local function stemOf(w)
    if not w then return nil end
    local s = w
    for _ = 1, 2 do
        local last = s:byte(#s)
        local cut = (last and last >= 0x80) and 2 or 1
        if #s - cut < 4 then break end
        s = s:sub(1, #s - cut)
    end
    return s
end
local function akin(a, b)
    if a == b then return true end
    local n, lim = 0, math.min(#a, #b)
    while n < lim and a:byte(n + 1) == b:byte(n + 1) do n = n + 1 end
    return n >= 4
end
local function loadSockets()
    if sockets then return sockets end
    sockets = { ok = false }
    local red = ns.Lower(firstWord(EMPTY_SOCKET_RED) or "")
    local blue = ns.Lower(firstWord(EMPTY_SOCKET_BLUE) or "")
    local yellow = ns.Lower(firstWord(EMPTY_SOCKET_YELLOW) or "")
    local meta = ns.Lower(firstWord(EMPTY_SOCKET_META) or "")
    if red == "" or blue == "" or yellow == "" then return sockets end
    sockets.red, sockets.blue = stemOf(red), stemOf(blue)
    sockets.yellow, sockets.meta = stemOf(yellow), stemOf(meta)
    local classes = loadTypes().classes
    for i = 1, #classes do
        local subs = { GetAuctionItemSubClasses(i) }
        if #subs >= COLOR_META
            and akin(ns.Lower(subs[COLOR_RED]), red)
            and akin(ns.Lower(subs[COLOR_BLUE]), blue)
            and akin(ns.Lower(subs[COLOR_YELLOW]), yellow) then
            sockets.colors = subs
            sockets.itemType = classes[i]
            sockets.ok = true
            break
        end
    end
    return sockets
end
function Groups.Sockets()
    return loadSockets()
end
function Groups.SubIndex(itemType, subType)
    if not itemType or not subType then return nil end
    return subOrder(itemType)[subType]
end
local MISC_SUBS = 6
local MISC_REAGENT, MISC_MOUNT = 2, 6
local misc
function Groups.Misc()
    if misc ~= nil then return misc.ok and misc or nil end
    misc = { ok = false }
    local classes = loadTypes().classes
    local last, subs
    for i = #classes, 1, -1 do
        local list = { GetAuctionItemSubClasses(i) }
        if #list == MISC_SUBS then
            last, subs = i, list
            break
        end
    end
    if not last then return nil end
    misc.itemType = classes[last]
    misc.reagent = subs[MISC_REAGENT]
    misc.mount = subs[MISC_MOUNT]
    misc.ok = true
    return misc
end
function Groups.ColorOf(desc)
    local s = loadSockets()
    if not s.ok or not desc then return nil end
    local d = ns.Lower(desc)
    local r = strfind(d, s.red, 1, true) ~= nil
    local b = strfind(d, s.blue, 1, true) ~= nil
    local y = strfind(d, s.yellow, 1, true) ~= nil
    local idx
    if s.meta ~= "" and strfind(d, s.meta, 1, true) then idx = COLOR_META
    elseif r and b then idx = COLOR_PURPLE
    elseif r and y then idx = COLOR_ORANGE
    elseif y and b then idx = COLOR_GREEN
    elseif r then idx = COLOR_RED
    elseif b then idx = COLOR_BLUE
    elseif y then idx = COLOR_YELLOW
    end
    local name = idx and s.colors[idx]
    if not name then return nil end
    return name, idx
end
local function myAmmoSub()
    local link = GetInventoryItemLink("player", INVSLOT_AMMO)
    return link and select(7, GetItemInfo(link)) or nil
end
function Groups.MarkMine(rows)
    local my = ns.Scan.MyReagents()
    local ammo = myAmmoSub()
    local className = UnitClass("player")
    for _, r in ipairs(rows) do
        r.mine = (r.name and my[ns.Lower(r.name)])
            or (ammo and r.subType == ammo)
            or (r.classes and className and strfind(r.classes, className, 1, true) ~= nil)
            or false
    end
end
local function isGear(r)
    return r.equipSlot ~= nil and r.equipSlot ~= "" and not NOT_GEAR[r.equipSlot]
end
local function idOf(link)
    return link and link:match("item:(%d+)") or nil
end
local function kindOf(r)
    if isGear(r) then return "gear" end
    if r.enchant then return "enchant" end
    local t = loadTypes()
    if r.itemType == t.recipe or r.prodName then return "recipe" end
    local misc = Groups.Misc()
    if misc and r.subType == misc.mount then return "mount" end
    return "other"
end
local function kindLabel(k)
    if k == "gear" then return ns.T("kindGear") end
    if k == "enchant" then return ns.T("groupEnchant") end
    if k == "recipe" then return loadTypes().recipe or ns.T("kindRecipe") end
    if k == "mount" then
        local misc = Groups.Misc()
        return misc and misc.mount or ns.T("kindMount")
    end
    return ns.T("groupOther")
end
local function slotOf(r)
    return SLOT_MERGE[r.equipSlot] or r.equipSlot or ""
end
function Groups.MarkPay(rows)
    local paidWith = {}
    for _, r in ipairs(rows) do
        if r.cost then
            for _, it in ipairs(r.cost.items) do
                local id = idOf(it.link)
                if id then paidWith[id] = true end
            end
        end
    end
    for _, r in ipairs(rows) do
        r.currency = r.cost ~= nil
        local id = idOf(r.link)
        r.swap = (r.cost ~= nil and kindOf(r) == "other") and true or false
    end
end
local function tierOf(r)
    if r.swap then return 0 end
    if r.currency then return 1 end
    return 2
end
local STALE_GAP = 20
local WORN_SLOTS = { 1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18 }
local MIN_WORN = 5
function Groups.WornLevel()
    local sum, n = 0, 0
    for _, slot in ipairs(WORN_SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then
            local lvl = select(4, GetItemInfo(link))
            if lvl and lvl > 0 then
                sum = sum + lvl
                n = n + 1
            end
        end
    end
    if n < MIN_WORN then return nil end
    return sum / n
end
function Groups.MarkStale(rows)
    for _, r in ipairs(rows) do r.stale = false end
    local worn = Groups.WornLevel()
    if not worn then return worn end
    local edge = worn - STALE_GAP
    for _, r in ipairs(rows) do
        if isGear(r) and r.iLevel and r.iLevel > 0 and r.iLevel < edge then
            r.stale = true
        end
    end
    return worn
end
function Groups.Counts(rows)
    local t = loadTypes()
    local c = { n = #rows, set = 0, recipe = 0, gear = 0, mine = 0, noInfo = 0, prod = 0, desc = 0,
        named = 0, bodies = 0, stale = 0, topType = nil, topCount = 0, topSubs = 0, rep = 0, kinds = 0 }
    local seenBody, byType, seenKind = {}, {}, {}
    for _, r in ipairs(rows) do
        local body = ns.NameBody(r.name)
        if body then
            c.named = c.named + 1
            if not seenBody[body] then
                seenBody[body] = true
                c.bodies = c.bodies + 1
            end
        end
        if r.set then c.set = c.set + 1 end
        if r.itemType == t.recipe or r.prodName then c.recipe = c.recipe + 1 end
        if isGear(r) then c.gear = c.gear + 1 end
        if r.mine then c.mine = c.mine + 1 end
        if not r.itemType then c.noInfo = c.noInfo + 1 end
        if r.prod then c.prod = c.prod + 1 end
        if r.desc then c.desc = c.desc + 1 end
        if r.stale then c.stale = c.stale + 1 end
        if r.repRank then c.rep = c.rep + 1 end
        local k = kindOf(r)
        if k ~= "other" and not seenKind[k] then
            seenKind[k] = true
            c.kinds = c.kinds + 1
        end
        if r.itemType then
            local e = byType[r.itemType]
            if not e then
                e = { n = 0, subs = {}, nsub = 0 }
                byType[r.itemType] = e
            end
            e.n = e.n + 1
            local s = r.subType or ""
            if not e.subs[s] then
                e.subs[s] = true
                e.nsub = e.nsub + 1
            end
        end
    end
    for name, e in pairs(byType) do
        if e.n > c.topCount then
            c.topType, c.topCount, c.topSubs = name, e.n, e.nsub
        end
    end
    return c
end
function Groups.Mode(rows)
    local n = #rows
    if n == 0 then return "plain" end
    local c = Groups.Counts(rows)
    local need = SHARE * n
    if c.set >= need then return "set" end
    if c.rep >= need then return "rep" end
    if c.topCount >= need and c.topSubs >= 2 and c.topSubs * 2 <= c.topCount then return "sub" end
    if c.recipe >= need then return "recipe" end
    if c.mine >= need then return "reagent" end
    if c.gear >= need then return "slot" end
    if c.named >= need and c.bodies * 2 <= c.named then return "name" end
    if n >= KIND_MIN and c.kinds >= 2 then return "kind" end
    return "plain"
end
local function setBases(rows)
    local names = {}
    for _, r in ipairs(rows) do
        if r.set then names[r.set] = true end
    end
    local list = {}
    for name in pairs(names) do list[#list + 1] = name end
    local base = {}
    for _, name in ipairs(list) do
        local best = name
        local lname = ns.Lower(name)
        for _, other in ipairs(list) do
            if #other < #best and strfind(lname, ns.Lower(other), 1, true) then
                best = other
            end
        end
        base[name] = best
    end
    return base
end
local function byName(a, b)
    if a.name ~= b.name then return (a.name or "") < (b.name or "") end
    return a.index < b.index
end
local function byGrade(a, b)
    if (a.quality or 0) ~= (b.quality or 0) then return (a.quality or 0) > (b.quality or 0) end
    if a.iLevel ~= b.iLevel then return a.iLevel > b.iLevel end
    return byName(a, b)
end
local function nameTail(name)
    return ns.Lower((name or ""):gsub("^%S+%s*", ""))
end
local function byKind(a, b)
    local ka, kb = KIND_RANK[kindOf(a)], KIND_RANK[kindOf(b)]
    if ka ~= kb then return ka < kb end
    if ka == KIND_RANK.enchant then
        local ta, tb = nameTail(a.name), nameTail(b.name)
        if ta ~= tb then return ta < tb end
        if a.price ~= b.price then return a.price < b.price end
        return byName(a, b)
    end
    if ka == KIND_RANK.gear then
        local sa, sb = SLOT_RANK[slotOf(a)] or 99, SLOT_RANK[slotOf(b)] or 99
        if sa ~= sb then return sa < sb end
        if a.iLevel ~= b.iLevel then return a.iLevel > b.iLevel end
    end
    return byName(a, b)
end
local SORT = {
    rep = byKind,
    kind = byKind,
    set = function(a, b)
        local sa = SLOT_RANK[SLOT_MERGE[a.equipSlot] or a.equipSlot] or 99
        local sb = SLOT_RANK[SLOT_MERGE[b.equipSlot] or b.equipSlot] or 99
        if sa ~= sb then return sa < sb end
        if a.iLevel ~= b.iLevel then return a.iLevel < b.iLevel end
        return byName(a, b)
    end,
    sub = byGrade,
    slot = function(a, b)
        if (a.subType or "") ~= (b.subType or "") then return (a.subType or "") < (b.subType or "") end
        if a.iLevel ~= b.iLevel then return a.iLevel > b.iLevel end
        return byName(a, b)
    end,
    reagent = function(a, b) return a.index < b.index end,
    name = byName,
    recipe = function(a, b)
        local ka, kb = a.known and 1 or 0, b.known and 1 or 0
        if ka ~= kb then return ka < kb end
        local pa, pb = a.prod, b.prod
        local qa, qb = pa and pa.quality or 0, pb and pb.quality or 0
        if qa ~= qb then return qa > qb end
        return byName(a, b)
    end,
}
local SUB_MIN = 6
local function subSort(g, cmp)
    local n = #g.items
    if n < SUB_MIN then return false end
    local withStat, gear, kinds, seen = 0, 0, 0, {}
    for _, r in ipairs(g.items) do
        if r.stat then
            withStat = withStat + 1
            if not seen[r.stat] then
                seen[r.stat] = true
                kinds = kinds + 1
            end
        end
        if isGear(r) then gear = gear + 1 end
    end
    if gear > 0 or kinds < 2 or withStat * 2 < n then return false end
    table.sort(g.items, function(a, b)
        local ha, hb = a.stat ~= nil, b.stat ~= nil
        if ha ~= hb then return ha end
        if ha and a.stat ~= b.stat then return a.stat < b.stat end
        if cmp then return cmp(a, b) end
        return a.index < b.index
    end)
    g.subs = true
    return true
end
local function textKey(r)
    local body = ns.NameBody(r.name)
    if body then return "#" .. body end
    if r.desc then return "~" .. r.desc end
    return nil
end
local function subKey(itemType, subType)
    if not subType or subType == "" then return nil end
    local order = subOrder(itemType)
    if next(order) == nil then return nil end
    return "u:" .. subType, order[subType] or 50
end
local function slotKey(slot)
    slot = SLOT_MERGE[slot] or slot
    return "l:" .. slot, 100 + (SLOT_RANK[slot] or 99)
end
local function classify(mode, r, bases)
    if r.swap then return "@swap", -20 end
    if mode == "set" then
        local base = r.set and bases[r.set]
        return base and ("s:" .. base) or nil, 0
    elseif mode == "sub" then
        if r.enchant and not isGear(r) then return "@enchant", 40 end
        if isGear(r) and MISC_SLOT[r.equipSlot] then return slotKey(r.equipSlot) end
        return subKey(r.itemType, r.subType)
    elseif mode == "slot" then
        if not isGear(r) then return r.enchant and "@enchant" or nil, 900 end
        return slotKey(r.equipSlot)
    elseif mode == "reagent" then
        if r.mine then return "@mine", -1 end
        return subKey(r.itemType, r.subType)
    elseif mode == "recipe" then
        local p = r.prod
        if p then
            if isGear(p) then return slotKey(p.equipSlot) end
            local key, rank = subKey(p.itemType, p.subType)
            if key then return key, rank end
        end
        local color, idx = Groups.ColorOf(r.desc)
        if color then return "u:" .. color, idx end
        local key = textKey(r)
        if key then return key, 300 end
        return subKey(r.itemType, r.subType)
    elseif mode == "name" then
        local key = textKey(r)
        return key, key and 300 or nil
    elseif mode == "rep" then
        local rank = r.repRank or 0
        return "r:" .. rank, rank
    elseif mode == "kind" then
        local k = kindOf(r)
        return "k:" .. k, KIND_RANK[k]
    end
end
local function labelOf(key)
    if key == "@mine" then return ns.T("groupMine") end
    if key == "@swap" then return ns.T("groupSwap") end
    if key == "@enchant" then return ns.T("groupEnchant") end
    if key:sub(1, 2) == "r:" then
        local rank = tonumber(key:sub(3)) or 0
        return rank > 0 and (_G["FACTION_STANDING_LABEL" .. rank] or key) or ns.T("groupNoRep")
    end
    if key:sub(1, 2) == "k:" then return kindLabel(key:sub(3)) end
    local pfx, rest = key:sub(1, 2), key:sub(3)
    if pfx == "l:" then return _G[rest] or rest end
    if pfx == "s:" or pfx == "u:" then return rest end
    return key:sub(2)
end
local function isText(key)
    local c = key:sub(1, 1)
    return c == "#" or c == "~"
end
local function commonHead(keys)
    if #keys < 2 then return 0 end
    local p = keys[1]
    for i = 2, #keys do
        local s = keys[i]
        local lim = math.min(#p, #s)
        local n = 0
        while n < lim and p:byte(n + 1) == s:byte(n + 1) do n = n + 1 end
        if n == 0 then return 0 end
        p = p:sub(1, n)
    end
    for i = #p, 1, -1 do
        if p:sub(i, i) == " " then return i end
    end
    return 0
end
local function commonTail(keys)
    if #keys < 2 then return 0 end
    local n = #keys[1]
    for i = 2, #keys do
        local a, b = keys[1], keys[i]
        local lim = math.min(n, #b)
        local k = 0
        while k < lim and a:byte(#a - k) == b:byte(#b - k) do k = k + 1 end
        n = k
        if n == 0 then return 0 end
    end
    local first = keys[1]
    for i = #first - n + 1, #first do
        if first:sub(i, i) == " " then return #first - i + 1 end
    end
    return 0
end
local function headFits(keys, head)
    if head == 0 then return 0 end
    for _, k in ipairs(keys) do
        if k:sub(head, head) ~= " " then return 0 end
    end
    return head
end
local function tailFits(keys, tail)
    if tail == 0 then return 0 end
    for _, k in ipairs(keys) do
        local at = #k - tail + 1
        if at < 1 or k:sub(at, at) ~= " " then return 0 end
    end
    return tail
end
local SHORT_WORD = 3
local function charCount(word)
    local n = 0
    for i = 1, #word do
        local c = word:byte(i)
        if c < 128 or c >= 192 then n = n + 1 end
    end
    return n
end
local function keepShortWord(key, head)
    if head == 0 then return 0 end
    local prev = 0
    for i = head - 1, 1, -1 do
        if key:sub(i, i) == " " then
            prev = i
            break
        end
    end
    if prev == 0 then return head end
    return charCount(key:sub(prev + 1, head - 1)) <= SHORT_WORD and prev or head
end
local function pluralLabel(body)
    local dict = ns.locales[ns.CurrentLocale()]
    local plural = dict and dict.plural
    if not plural then return nil end
    local first, rest = body:match("^(%S+)(.*)$")
    local p = first and plural[ns.Lower(first)]
    if not p then return nil end
    return p .. rest
end
local AFFIX_WORDS = 2
local AFFIX_MIN = 3
local AFFIX_KEEP = 3
local affixBuf = {}
local function affixOf(rows, k)
    local count, best, top, n = {}, nil, 0, 0
    for _, r in ipairs(rows) do
        if r.name then
            n = n + 1
            local w = wipe(affixBuf)
            for word in r.name:gmatch("%S+") do w[#w + 1] = word end
            local seen = {}
            for i = 1, #w - k + 1 do
                local part = table.concat(w, " ", i, i + k - 1)
                if not seen[part] then
                    seen[part] = true
                    count[part] = (count[part] or 0) + 1
                    if count[part] > top then
                        best, top = part, count[part]
                    end
                end
            end
        end
    end
    if not best or top < AFFIX_MIN or top * 2 < n then return nil end
    return best
end
local function wordAt(name, affix)
    local at = name:find(affix, 1, true)
    while at do
        local before = at == 1 or name:sub(at - 1, at - 1) == " "
        local last = at + #affix
        local after = last > #name or name:sub(last, last) == " "
        if before and after then return at end
        at = name:find(affix, at + 1, true)
    end
    return nil
end
local function cutAffix(rows, affix)
    local done = false
    for _, r in ipairs(rows) do
        local name = r.name
        local at = name and wordAt(name, affix)
        if at then
            local rest = name:sub(1, at - 1) .. name:sub(at + #affix)
            rest = rest:gsub("%s+", " ")
            rest = rest:gsub("^ ", ""):gsub(" $", "")
            if charCount(rest) >= AFFIX_KEEP then
                r.short = ns.UpperFirst(rest)
                done = true
            end
        end
    end
    return done
end
function Groups.Affix(rows)
    local affix = affixOf(rows, AFFIX_WORDS)
    if affix and cutAffix(rows, affix) then return affix end
    return nil
end
local function shortenText(groups)
    local keys = {}
    for _, g in ipairs(groups) do
        if g.viaText then keys[#keys + 1] = g.key:sub(2) end
    end
    local head = headFits(keys, keepShortWord(keys[1] or "", commonHead(keys)))
    local tail = tailFits(keys, commonTail(keys))
    for _, g in ipairs(groups) do
        if g.viaText then
            local body = g.key:sub(2)
            local label = pluralLabel(body)
            if label then
                g.label = label
            elseif head > 0 or tail > 0 then
                local last = #body - tail
                if last > head then
                    local rest = body:sub(head + 1, last)
                    if rest ~= "" then g.label = ns.UpperFirst(rest) end
                end
            end
        end
    end
end
local SEP = { ["-"] = true, [":"] = true }
local function shortNames(g)
    if g.key:sub(1, 1) == "#" then
        for _, r in ipairs(g.items) do
            local rest = ns.NameRest(r.name)
            if rest then r.short = ns.UpperFirst(rest) end
        end
        return
    end
    local names = {}
    for _, r in ipairs(g.items) do names[#names + 1] = r.name or "" end
    local head = commonHead(names)
    if head < 3 or not SEP[names[1]:sub(head - 1, head - 1)] then return end
    for _, r in ipairs(g.items) do
        local rest = (r.name or ""):sub(head + 1)
        if rest == "" then return end
    end
    for _, r in ipairs(g.items) do
        r.short = ns.UpperFirst(r.name:sub(head + 1))
    end
end
function Groups.Split(rows, mode)
    local bases = setBases(rows)
    local groups, byKey, order = {}, {}, {}
    local other = { key = "@other", label = ns.T("groupOther"), items = {}, rank = 10000,
        tier = 9, fresh = false, prio = 2 }
    for _, r in ipairs(rows) do
        local base = (not r.swap) and r.set and bases[r.set] or nil
        local key, rank
        if base then
            key, rank = "s:" .. base, 0
        else
            key, rank = classify(mode, r, bases)
        end
        if key == nil then
            other.items[#other.items + 1] = r
        else
            local g = byKey[key]
            if not g then
                order[key] = #groups + 1
                g = { key = key, label = labelOf(key), items = {}, rank = rank or 500,
                    viaText = isText(key), tier = 9, fresh = false,
                    prio = (key == "@swap" and 0) or (key:sub(1, 2) == "s:" and 1) or 2 }
                byKey[key] = g
                groups[#groups + 1] = g
            end
            local tier = tierOf(r)
            if tier < g.tier then g.tier = tier end
            if not r.stale then g.fresh = true end
            g.items[#g.items + 1] = r
        end
    end
    if #other.items > 0 then groups[#groups + 1] = other end
    shortenText(groups)
    table.sort(groups, function(a, b)
        if a.prio ~= b.prio then return a.prio < b.prio end
        if a.fresh ~= b.fresh then return a.fresh end
        if a.tier ~= b.tier then return a.tier < b.tier end
        if a.rank ~= b.rank then return a.rank < b.rank end
        if a.viaText and b.viaText then return a.label < b.label end
        return (order[a.key] or 0) < (order[b.key] or 0)
    end)
    local cmp = SORT[mode]
    for _, g in ipairs(groups) do
        local set = g.key:sub(1, 2) == "s:"
        if set then
            table.sort(g.items, SORT.set)
        elseif mode == "rep" or mode == "kind" then
            table.sort(g.items, cmp)
            local by = (mode == "rep") and "kind" or (g.key == "k:gear" and "slot" or nil)
            if by then
                local seen, n = {}, 0
                for _, r in ipairs(g.items) do
                    local k = by == "kind" and kindOf(r) or slotOf(r)
                    if not seen[k] then
                        seen[k] = true
                        n = n + 1
                    end
                end
                if n >= 2 then g.divBy = by end
            end
        elseif not subSort(g, cmp) and cmp then
            table.sort(g.items, cmp)
        end
        if not set and g.key ~= "@other" then shortNames(g) end
    end
    return groups
end
local function emit(out, r, div, pair)
    if pair then
        div = nil
        local last = out[#out]
        if last and last.kind == "pair" and not last.b then
            last.b = r
            return
        end
    end
    if pair then
        out[#out + 1] = { kind = "pair", a = r, div = div or nil }
    else
        out[#out + 1] = { kind = "item", row = r, div = div or nil }
    end
end
function Groups.Plain(rows, out, pair)
    for _, r in ipairs(rows) do emit(out, r, nil, pair) end
    return out
end
local function withDiet(items, out, pair)
    local drink, food = 0, 0
    for _, r in ipairs(items) do
        if r.diet == "drink" then drink = drink + 1 elseif r.diet == "food" then food = food + 1 end
    end
    if drink == 0 or food == 0 then return false end
    for _, want in ipairs({ "drink", "food" }) do
        out[#out + 1] = { kind = "div", label = ns.T(want == "drink" and "dietDrink" or "dietFood") }
        for _, r in ipairs(items) do
            if r.diet == want then emit(out, r, nil, pair) end
        end
    end
    for _, r in ipairs(items) do
        if not r.diet then emit(out, r, nil, pair) end
    end
    return true
end
local ROLE_KEYS = {
    tank = { "ITEM_MOD_DEFENSE_SKILL_RATING_SHORT", "ITEM_MOD_PARRY_RATING_SHORT",
        "ITEM_MOD_DODGE_RATING_SHORT", "ITEM_MOD_BLOCK_RATING_SHORT" },
    dps = { "ITEM_MOD_HIT_RATING_SHORT", "ITEM_MOD_HIT_MELEE_RATING_SHORT",
        "ITEM_MOD_HIT_RANGED_RATING_SHORT", "ITEM_MOD_HIT_SPELL_RATING_SHORT" },
    heal = { "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_POWER_REGEN0_SHORT", "ITEM_MOD_MANA_REGENERATION_SHORT" },
}
local ROLE_ORDER = { "tank", "dps", "heal" }
local ROLE_PVP = "ITEM_MOD_RESILIENCE_RATING_SHORT"
local statSum = {}
local function groupRole(items)
    wipe(statSum)
    local gear = false
    for _, r in ipairs(items) do
        if r.link and isGear(r) then
            GetItemStats(r.link, statSum)
            gear = true
        end
    end
    if not gear then return nil end
    local pvp = (statSum[ROLE_PVP] or 0) > 0
    for _, role in ipairs(ROLE_ORDER) do
        if not (pvp and role == "tank") then
            for _, key in ipairs(ROLE_KEYS[role]) do
                if (statSum[key] or 0) > 0 then return role end
            end
        end
    end
    return "dps"
end
function Groups.TierTag(lvl)
    local t = ns.Tiers
    return lvl and t and t.tier and t.tier[lvl] or nil
end
function Groups.Tag(items)
    local t = ns.Tiers
    if not t then return nil end
    for _, r in ipairs(items) do
        local low = ns.Lower(r.name or "")
        for word, tag in pairs(t.season or {}) do
            if string.find(low, word, 1, true) then return tag end
        end
    end
    local lvl
    for _, r in ipairs(items) do
        if (r.iLevel or 0) > 0 then
            if lvl and lvl ~= r.iLevel then return nil end
            lvl = r.iLevel
        end
    end
    return Groups.TierTag(lvl)
end
local MAX_TIERS = 4
local function setMatrix(g)
    local seen, tiers = {}, {}
    local steps = false
    for _, r in ipairs(g.items) do
        local lvl = r.iLevel or 0
        if not seen[lvl] then
            seen[lvl] = true
            tiers[#tiers + 1] = lvl
        end
    end
    local slots = {}
    for _, r in ipairs(g.items) do
        local slot = SLOT_MERGE[r.equipSlot] or r.equipSlot or ""
        if slots[slot] then steps = true end
        slots[slot] = true
    end
    if not steps or #tiers < 2 or #tiers > MAX_TIERS then return nil end
    table.sort(tiers)
    local at = {}
    for i, lvl in ipairs(tiers) do at[lvl] = i end
    local list, bySlot = {}, {}
    for _, r in ipairs(g.items) do
        local slot = SLOT_MERGE[r.equipSlot] or r.equipSlot or ""
        local idx = at[r.iLevel or 0]
        local target
        for _, e in ipairs(bySlot[slot] or {}) do
            if not e.cells[idx] then
                target = e
                break
            end
        end
        if not target then
            target = { kind = "set", slot = slot, cells = {}, row = r }
            bySlot[slot] = bySlot[slot] or {}
            table.insert(bySlot[slot], target)
            list[#list + 1] = target
        end
        target.cells[idx] = r
    end
    return tiers, list
end
local FAMILY_DASH = " — "
local FAMILY_STEM = 6
local FAMILY_MIN = 4
local FAMILY_MAX = 4
local function cutLetters(word, n)
    local i, seen = 1, 0
    while i <= #word and seen < n do
        local c = word:byte(i)
        i = i + (c < 192 and 1 or (c < 224 and 2 or (c < 240 and 3 or 4)))
        seen = seen + 1
    end
    return word:sub(1, i - 1)
end
local function familyStem(word)
    return cutLetters(ns.Lower(word), FAMILY_STEM)
end
local function familyKeys(items)
    local spread, slots, nslots = {}, {}, 0
    for _, r in ipairs(items) do
        local slot = SLOT_MERGE[r.equipSlot] or r.equipSlot or ""
        if not ARMOR_SLOT[slot] then return nil end
        if not slots[slot] then
            slots[slot] = true
            nslots = nslots + 1
        end
        for w in (r.short or r.name or ""):gmatch("%S+") do
            local st = familyStem(w)
            local seen = spread[st]
            if not seen then
                seen = {}
                spread[st] = seen
            end
            seen[slot] = true
        end
    end
    if nslots < 2 then return nil end
    local shared = {}
    for st, seen in pairs(spread) do
        local n = 0
        for _ in pairs(seen) do n = n + 1 end
        if n >= 2 then shared[st] = true end
    end
    local keyOf, label, order, forms, top = {}, {}, {}, {}, {}
    for _, r in ipairs(items) do
        local parts, words = {}, {}
        for w in (r.short or r.name or ""):gmatch("%S+") do
            if shared[familyStem(w)] then
                parts[#parts + 1] = familyStem(w)
                words[#words + 1] = w
            end
        end
        if #parts == 0 then return nil end
        local key, text = table.concat(parts, " "), table.concat(words, " ")
        keyOf[r] = key
        if not forms[key] then
            forms[key] = {}
            order[#order + 1] = key
        end
        local seen = (forms[key][text] or 0) + 1
        forms[key][text] = seen
        if seen > (top[key] or 0) then
            top[key], label[key] = seen, text
        end
    end
    if #order < 2 or #order > FAMILY_MAX then return nil end
    local mix = {}
    for _, r in ipairs(items) do
        local slot = SLOT_MERGE[r.equipSlot] or r.equipSlot
        local at = mix[slot]
        if at and at ~= keyOf[r] then return keyOf, label, order end
        mix[slot] = keyOf[r]
    end
    return nil
end
function Groups.Family(items)
    if #items < FAMILY_MIN then return nil end
    return familyKeys(items)
end
local function splitFamilies(groups)
    local out = {}
    for _, g in ipairs(groups) do
        local keyOf, label, order
        if g.key:sub(1, 2) ~= "s:" then keyOf, label, order = Groups.Family(g.items) end
        if not keyOf then
            out[#out + 1] = g
        else
            for i, key in ipairs(order) do
                local items = {}
                for _, r in ipairs(g.items) do
                    if keyOf[r] == key then items[#items + 1] = r end
                end
                table.sort(items, function(a, b)
                    local sa = SLOT_RANK[SLOT_MERGE[a.equipSlot] or a.equipSlot] or 99
                    local sb = SLOT_RANK[SLOT_MERGE[b.equipSlot] or b.equipSlot] or 99
                    if sa ~= sb then return sa < sb end
                    return (a.name or "") < (b.name or "")
                end)
                out[#out + 1] = {
                    key = g.key .. "#" .. key, label = g.label .. FAMILY_DASH .. label[key],
                    items = items, rank = g.rank, tier = g.tier, fresh = g.fresh, prio = g.prio,
                    divBy = nil, subs = nil, viaText = false, family = true,
                }
            end
        end
    end
    return out
end
function Groups.Build(rows, collapsed, out, pair)
    out = out or {}
    wipe(out)
    for _, r in ipairs(rows) do r.short = nil end
    Groups.Affix(rows)
    Groups.MarkMine(rows)
    Groups.MarkPay(rows)
    Groups.MarkStale(rows)
    local mode = Groups.Mode(rows)
    if mode == "plain" then
        if not withDiet(rows, out, pair) then Groups.Plain(rows, out, pair) end
        return out, mode
    end
    for _, g in ipairs(splitFamilies(Groups.Split(rows, mode == "set" and "sub" or mode))) do
        local shut = collapsed[g.key] and true or false
        local head = { kind = "head", key = g.key, label = g.label, count = #g.items,
            collapsed = shut, prio = g.prio }
        if g.family or g.key:sub(1, 2) == "s:" then
            head.role = groupRole(g.items)
            local tag = Groups.Tag(g.items)
            if tag then head.label = g.label .. FAMILY_DASH .. tag end
        end
        out[#out + 1] = head
        local tiers, matrix
        if g.key:sub(1, 2) == "s:" then tiers, matrix = setMatrix(g) end
        if shut then
            head.tiers = nil
        elseif matrix then
            head.tiers = tiers
            for _, e in ipairs(matrix) do out[#out + 1] = e end
        elseif g.divBy then
            local prev
            for _, r in ipairs(g.items) do
                local k = g.divBy == "kind" and kindOf(r) or slotOf(r)
                if k ~= prev then
                    local label = g.divBy == "kind" and kindLabel(k) or (_G[k] or k)
                    out[#out + 1] = { kind = "div", label = label }
                end
                emit(out, r, nil, pair)
                prev = k
            end
        elseif not (not g.subs and withDiet(g.items, out, pair)) then
            local prev, first = nil, true
            for _, r in ipairs(g.items) do
                local div = g.subs and not first and r.stat ~= prev
                emit(out, r, div, pair)
                prev, first = r.stat, false
            end
        end
    end
    return out, mode
end
local function gcd(a, b)
    while b > 0 do a, b = b, a % b end
    return a
end
local function blocks(seq, heightOf)
    local list, cur = {}, nil
    for i, e in ipairs(seq) do
        if e.kind == "head" or not cur then
            cur = { from = i, to = i, head = e.kind == "head" and e or nil, h = 0,
                prio = (e.kind == "head" and e.prio) or 2 }
            list[#list + 1] = cur
        else
            cur.to = i
        end
        cur.h = cur.h + heightOf(e)
    end
    return list
end
local function pack(seq, list, cols, limit, heightOf, res)
    wipe(res)
    local col, c, y = {}, 1, 0
    res[1] = col
    local function newCol()
        if c >= cols then return false end
        c = c + 1
        col, y = {}, 0
        res[c] = col
        return true
    end
    local function put(e, h)
        e.y, e.h = y, h
        col[#col + 1] = e
        y = y + h
    end
    local function whole(b)
        for i = b.from, b.to do put(seq[i], heightOf(seq[i])) end
    end
    local function cut(b)
        for i = b.from, b.to do
            local e = seq[i]
            local h = heightOf(e)
            local pend = 0
            if (e.kind == "head" or e.kind == "div") and i < b.to then pend = heightOf(seq[i + 1]) end
            if y > 0 and y + h + pend > limit then
                if not newCol() then return false end
                if e.kind ~= "head" and b.head then
                    local cont = { kind = "head", cont = true, key = b.head.key,
                        label = b.head.label, tiers = b.head.tiers, prio = b.head.prio }
                    put(cont, heightOf(cont))
                end
            end
            put(e, h)
        end
        return true
    end
    local done, left, at = {}, #list, 1
    while left > 0 do
        while done[at] do at = at + 1 end
        local b = list[at]
        if b.h > limit then
            if not cut(b) then return false end
            done[at], left = true, left - 1
        elseif y == 0 or y + b.h <= limit then
            whole(b)
            done[at], left = true, left - 1
        else
            local pick
            for j = at + 1, #list do
                if not done[j] and list[j].prio == b.prio and y + list[j].h <= limit then
                    pick = j
                    break
                end
            end
            if pick then
                whole(list[pick])
                done[pick], left = true, left - 1
            elseif not newCol() then
                return false
            end
        end
    end
    local maxH = 0
    for _, cc in ipairs(res) do
        local t = 0
        for _, e in ipairs(cc) do t = t + e.h end
        if t > maxH then maxH = t end
    end
    return true, maxH
end
function Groups.Flow(seq, cols, heightOf, res, room)
    res = res or {}
    cols = math.max(1, cols or 1)
    local total, unit = 0, 0
    for _, e in ipairs(seq) do
        local h = heightOf(e)
        total = total + h
        unit = gcd(unit, h)
    end
    if total == 0 then
        wipe(res)
        return res, 0
    end
    if unit < 1 then unit = 1 end
    local list = blocks(seq, heightOf)
    local limit = math.ceil(total / cols / unit) * unit
    if room and room > limit then limit = math.floor(room / unit) * unit end
    while true do
        local ok, maxH = pack(seq, list, cols, limit, heightOf, res)
        if ok then return res, maxH end
        limit = limit + unit
    end
end
