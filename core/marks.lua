local ADDON, ns = ...
local Marks = {}
ns.Marks = Marks
local KEEP, SPARE = "keep", "spare"
Marks.KEEP, Marks.SPARE = KEEP, SPARE
local function store()
    local db = ns.DB()
    if type(db.marks) ~= "table" then db.marks = {} end
    return db.marks
end
function Marks.IdOf(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
function Marks.Get(id)
    if not id then return nil end
    local m = store()[id]
    if m == KEEP or m == SPARE then return m end
    return nil
end
function Marks.Set(id, mark)
    if not id then return end
    store()[id] = mark
    if ns.RefreshBagMarks then ns.RefreshBagMarks() end
    if ns.RefreshWindow then ns.RefreshWindow() end
end
function Marks.Cycle(id)
    local m = Marks.Get(id)
    local nxt
    if m == nil then nxt = KEEP elseif m == KEEP then nxt = SPARE else nxt = nil end
    Marks.Set(id, nxt)
    return nxt
end
function Marks.Label(mark)
    if mark == KEEP then return ns.T("markKeep") end
    if mark == SPARE then return ns.T("markSpare") end
    return nil
end
