local ADDON, ns = ...
local Chain = {}
ns.Chain = Chain
local MAX_STEPS = 8
local TICK = 0.1
local WAIT_MAX = 3
local GUARD = 600
local edges = {}
local byGet = {}
local ladder = {}
local marks = {}
local scratch = {}
local plan = {}
local job = {}
local function idOf(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
local function count(link)
    return link and GetItemCount(link) or 0
end
function Chain.Scan(rows)
    wipe(edges)
    wipe(byGet)
    for _, r in ipairs(rows) do
        local c = r.cost
        if c and r.id and c.honor == 0 and c.arena == 0 and #c.items == 1 then
            local it = c.items[1]
            local payId = idOf(it.link)
            if payId and payId ~= r.id and (it.n or 0) > 0
                and not ns.List.Wearable(it.link) and not ns.List.Wearable(r.link) then
                local e = {
                    index = r.index, name = r.name, gold = r.price or 0, stock = r.stock or -1,
                    payId = payId, payN = it.n, payLink = it.link, payTex = it.tex,
                    getId = r.id, getN = r.quantity or 1, getLink = r.link, getTex = r.tex,
                }
                edges[#edges + 1] = e
                local t = byGet[e.getId]
                if not t then
                    t = {}
                    byGet[e.getId] = t
                end
                t[#t + 1] = e
            end
        end
    end
    return edges
end
local function path(row, out)
    wipe(out)
    local node, tail = row.id, nil
    if not (node and byGet[node]) then
        local c = row.cost
        local it = (c and c.honor == 0 and c.arena == 0 and #c.items == 1) and c.items[1] or nil
        local payId = it and idOf(it.link) or nil
        if not (payId and byGet[payId] and row.id) then return out end
        tail = {
            index = row.index, name = row.name, gold = row.price or 0, stock = row.stock or -1,
            payId = payId, payN = it.n, payLink = it.link, payTex = it.tex,
            getId = row.id, getN = row.quantity or 1, getLink = row.link, getTex = row.tex,
        }
        node = payId
    end
    local seen = { [node] = true, [row.id] = true }
    while #out < MAX_STEPS do
        local pick
        for _, e in ipairs(byGet[node] or {}) do
            if not seen[e.payId] then
                pick = e
                break
            end
        end
        if not pick then break end
        seen[pick.payId] = true
        table.insert(out, 1, pick)
        node = pick.payId
    end
    if tail then out[#out + 1] = tail end
    return out
end
function Chain.For(rows, row, out)
    out = out or ladder
    wipe(out)
    if not row then return out end
    Chain.Scan(rows)
    return path(row, out)
end
function Chain.Mark(rows)
    Chain.Scan(rows)
    for _, r in ipairs(rows) do
        r.reach = nil
        if r.id or r.cost then
            local steps = path(r, marks)
            if #steps > 0 then
                local p = Chain.Plan(steps, nil, scratch)
                r.reach = p[#p] and p[#p].times or 0
            end
        end
    end
    return rows
end
function Chain.Cap(e)
    local n = math.floor(count(e.payLink) / e.payN)
    if e.stock >= 0 then
        local k = math.floor(e.stock / e.getN)
        if k < n then n = k end
    end
    if e.gold > 0 then
        local k = math.floor(GetMoney() / e.gold)
        if k < n then n = k end
    end
    return n > 0 and n or 0
end
function Chain.Plan(list, want, out)
    out = out or plan
    wipe(out)
    local pool, money, need = {}, GetMoney(), {}
    local function have(id, link)
        if pool[id] == nil then pool[id] = count(link) end
        return pool[id]
    end
    if want and want > 0 then
        local n = want
        for i = #list, 1, -1 do
            local e = list[i]
            need[i] = n
            local gap = n * e.payN - have(e.payId, e.payLink)
            if i > 1 then
                n = gap > 0 and math.ceil(gap / list[i - 1].getN) or 0
            end
        end
    end
    local buys, got = 0, 0
    for i = 1, #list do
        local e = list[i]
        local times = math.floor(have(e.payId, e.payLink) / e.payN)
        local cap = Chain.Cap(e)
        if need[i] and need[i] < times then times = need[i] end
        if e.stock >= 0 then
            local k = math.floor(e.stock / e.getN)
            if k < times then times = k end
        end
        if e.gold > 0 then
            local k = math.floor(money / e.gold)
            if k < times then times = k end
        end
        if times < 0 then times = 0 end
        local before = have(e.payId, e.payLink)
        have(e.getId, e.getLink)
        pool[e.payId] = before - times * e.payN
        pool[e.getId] = pool[e.getId] + times * e.getN
        money = money - times * e.gold
        buys = buys + times
        got = times * e.getN
        out[i] = { edge = e, times = times, cap = cap, pay = times * e.payN,
            get = times * e.getN, payHave = before, need = need[i],
            short = need[i] ~= nil and times < need[i] }
    end
    local from = 1
    while from < #list and (out[from].times or 0) <= 0 do from = from + 1 end
    out.from = from
    out.buys = buys
    out.got = got
    out.gold = GetMoney() - money
    return out
end
local runner = CreateFrame("Frame")
runner:Hide()
local function tell(key, ...)
    if key then ns.say(ns.T(key, ...)) end
end
function Chain.Stop(key, ...)
    local onChange = job.onChange
    runner:Hide()
    wipe(job)
    if onChange then onChange() end
    tell(key, ...)
end
function Chain.Busy()
    return job.list ~= nil
end
function Chain.Progress()
    if not job.list then return nil end
    return job.i, #job.list, job.done, job.done + job.left
end
runner:SetScript("OnUpdate", function(self, dt)
    job.clock = job.clock + dt
    if job.clock < TICK then return end
    job.clock = 0
    if not job.list or not ns.MerchantOpen() then
        return Chain.Stop("chainStop", job.bought or 0)
    end
    job.guard = job.guard + 1
    if job.guard > GUARD then
        return Chain.Stop("chainStop", job.bought)
    end
    while job.left <= 0 do
        job.i = job.i + 1
        local nxt = job.list[job.i]
        if not nxt then
            return Chain.Stop("chainDone", job.gotName or "", job.got or 0)
        end
        job.left, job.done, job.expect = nxt.times or 0, 0, nil
    end
    local e = job.list[job.i].edge
    local stack = GetMerchantItemMaxStack(e.index) or 1
    if stack < 1 then stack = 1 end
    local take = job.left < stack and job.left or stack
    local purse = count(e.payLink)
    if job.expect and purse > job.expect then
        job.wait = job.wait + TICK
        if job.wait <= WAIT_MAX then return end
    end
    local fit = math.floor(purse / e.payN)
    if fit < 1 then
        job.wait = job.wait + TICK
        if job.wait > WAIT_MAX then
            return Chain.Stop("chainShort", e.name or "")
        end
        return
    end
    job.wait = 0
    if fit < take then take = fit end
    BuyMerchantItem(e.index, take)
    job.expect = purse - take * e.payN
    job.left = job.left - take
    job.done = job.done + take
    job.bought = job.bought + take
    if job.step ~= job.i then
        job.step, job.got = job.i, 0
    end
    job.got = job.got + take * e.getN
    job.gotName = e.name
    if job.onChange then job.onChange() end
end)
function Chain.Run(list, onChange)
    if job.list or not list or #list == 0 then return false end
    local any = false
    for _, s in ipairs(list) do
        if (s.times or 0) > 0 then any = true end
    end
    if not any then return false end
    wipe(job)
    job.list, job.i, job.left, job.done = list, 0, 0, 0
    job.wait, job.clock, job.guard, job.bought, job.got = 0, TICK, 0, 0, 0
    job.onChange = onChange
    runner:Show()
    return true
end
function Chain.Halt()
    if job.list then Chain.Stop("chainStop", job.bought or 0) end
end
