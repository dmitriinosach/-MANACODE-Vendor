local ADDON, ns = ...
local Prof = {}
ns.Prof = Prof
local DIFF = { optimal = 0, medium = 1, easy = 2, trivial = 3 }
local GREY = 3
local READ_DELAY = 0.3
local index
local mine
local function charKey()
    return (GetRealmName() or "") .. "-" .. (UnitName("player") or "")
end
local function chars()
    local db = ns.DB()
    if type(db.chars) ~= "table" then db.chars = {} end
    return db.chars
end
local function me()
    local all = chars()
    local key = charKey()
    local c = all[key]
    if type(c) ~= "table" then
        c = { profs = {} }
        all[key] = c
    end
    c.name = UnitName("player")
    c.faction = UnitFactionGroup("player")
    if type(c.profs) ~= "table" then c.profs = {} end
    return c
end
local function idOf(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
local function forget()
    index, mine = nil, nil
end
local function readWindow()
    if IsTradeSkillLinked and IsTradeSkillLinked() then return end
    local prof = GetTradeSkillLine()
    local n = GetNumTradeSkills() or 0
    if not prof or prof == "" or prof == "UNKNOWN" or n == 0 then return end
    local book = me().profs
    local list = book[prof]
    if type(list) ~= "table" then
        list = {}
        book[prof] = list
    end
    for i = 1, n do
        local name, kind = GetTradeSkillInfo(i)
        local d = DIFF[kind or ""]
        if name and d then
            local r = {}
            for j = 1, GetTradeSkillNumReagents(i) or 0 do
                local id = idOf(GetTradeSkillReagentItemLink(i, j))
                if id then r[#r + 1] = id end
            end
            if #r > 0 then list[name] = { d = d, r = r } end
        end
    end
    forget()
end
local function add(uses, id, who, prof, recipe, d)
    local list = uses[id]
    if not list then
        list = {}
        uses[id] = list
    end
    local u
    for _, x in ipairs(list) do
        if x.who == who and x.prof == prof then
            u = x
            break
        end
    end
    if not u then
        u = { who = who, prof = prof, n = 0, up = 0, ex = recipe, exUp = false }
        list[#list + 1] = u
    end
    u.n = u.n + 1
    local up = d < GREY
    if up then u.up = u.up + 1 end
    if up and not u.exUp then u.ex, u.exUp = recipe, true end
end
local function build()
    if index then return index end
    index, mine = {}, {}
    local key = charKey()
    local realm = GetRealmName() or ""
    local faction = UnitFactionGroup("player")
    for k, c in pairs(chars()) do
        local own = k == key
        local same = k:sub(1, #realm + 1) == realm .. "-" and c.faction == faction
        if type(c.profs) == "table" and (own or same) then
            for prof, list in pairs(c.profs) do
                for recipe, rec in pairs(list) do
                    for _, id in ipairs(rec.r or {}) do
                        add(index, id, not own and c.name or nil, prof, recipe, rec.d or GREY)
                        if own then mine[id] = true end
                    end
                end
            end
        end
    end
    for _, list in pairs(index) do
        table.sort(list, function(a, b)
            if (a.who == nil) ~= (b.who == nil) then return a.who == nil end
            if a.n ~= b.n then return a.n > b.n end
            return (a.who or "") .. a.prof < (b.who or "") .. b.prof
        end)
    end
    return index
end
function Prof.Uses(id)
    if not id then return nil end
    return build()[id]
end
function Prof.Mine(id)
    if not id then return false end
    build()
    return mine[id] and true or false
end
function Prof.Known()
    return next(me().profs) ~= nil
end
local pending = 0
local reader = CreateFrame("Frame")
reader:Hide()
reader:SetScript("OnUpdate", function(self, dt)
    pending = pending - dt
    if pending > 0 then return end
    self:Hide()
    readWindow()
end)
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("TRADE_SKILL_SHOW")
watcher:RegisterEvent("TRADE_SKILL_UPDATE")
watcher:RegisterEvent("PLAYER_LOGIN")
watcher:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        me()
        forget()
        return
    end
    pending = READ_DELAY
    reader:Show()
end)
