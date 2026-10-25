local ADDON, ns = ...
local Sold = {}
ns.Sold = Sold
local QUEST_CLASS = 12
local POOR = 0
local open = false
local seen = {}
local warned = {}
local function idOf(link)
    return link and tonumber(link:match("item:(%d+)")) or nil
end
local function readBuyback()
    local stacks, links = {}, {}
    for i = 1, GetNumBuybackItems() or 0 do
        local link = GetBuybackItemLink(i)
        local id = idOf(link)
        if id then
            stacks[id] = (stacks[id] or 0) + 1
            links[id] = link
        end
    end
    return stacks, links
end
function Sold.Reason(id, link)
    local mark = ns.Marks and ns.Marks.Get(id) or nil
    if mark == "spare" then return nil end
    if mark == "keep" then return ns.T("soldKeep") end
    local name, _, quality, _, _, itemType = GetItemInfo(link)
    if not name or quality == POOR then return nil end
    for _, u in ipairs(ns.Prof.Uses(id) or {}) do
        if not u.who then return ns.T("useProfMany", u.prof, u.n) end
    end
    local spell = ns.Scan.MyReagents()[ns.Lower(name)]
    if type(spell) == "string" then return ns.T("useSpell", spell) end
    local quest = ns.Groups.Types().classes[QUEST_CLASS]
    if quest and itemType == quest then return ns.T("soldQuest") end
    return nil
end
local function check()
    if ns.DB().warnSold == false then return end
    local stacks, links = readBuyback()
    for id, n in pairs(stacks) do
        if n > (seen[id] or 0) and not warned[id] then
            local why = Sold.Reason(id, links[id])
            if why then
                warned[id] = true
                ns.say(ns.T("soldWarn", links[id], why))
                UIErrorsFrame:AddMessage(ns.T("soldWarn", links[id], why), 1, 0.82, 0)
            end
        end
    end
    seen = stacks
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("MERCHANT_SHOW")
watcher:RegisterEvent("MERCHANT_CLOSED")
watcher:RegisterEvent("MERCHANT_UPDATE")
watcher:SetScript("OnEvent", function(self, event)
    if event == "MERCHANT_SHOW" then
        open = true
        seen = readBuyback()
        wipe(warned)
    elseif event == "MERCHANT_CLOSED" then
        open = false
    elseif open then
        check()
    end
end)
