local ADDON, ns = ...
local Have = {}
ns.Have = Have
local FIRST_SLOT, LAST_SLOT = 1, 19
local worn = {}
local ready = false
local tokens = {}
local tokensReady = false
local function idOf(link)
    return link and link:match("item:(%d+)") or nil
end
function Have.Forget()
    ready = false
    tokensReady = false
end
local function loadTokens()
    if tokensReady then return end
    wipe(tokens)
    for i = 1, GetCurrencyListSize() or 0 do
        local _, isHeader, _, _, _, _, _, _, itemID = GetCurrencyListInfo(i)
        if not isHeader and itemID then tokens[itemID] = true end
    end
    tokensReady = true
end
function Have.Token(id)
    if not id then return false end
    loadTokens()
    return tokens[tonumber(id)] and true or false
end
local function loadWorn()
    if ready then return end
    wipe(worn)
    for slot = FIRST_SLOT, LAST_SLOT do
        local id = idOf(GetInventoryItemLink("player", slot))
        if id then worn[id] = true end
    end
    ready = true
end
function Have.Count(link)
    if not link then return 0 end
    loadWorn()
    local n = GetItemCount(link, true) or 0
    local id = idOf(link)
    if id and worn[id] then n = n + 1 end
    return n
end
function Have.Mark(row)
    if not row or not row.link then return false, 0 end
    local n = Have.Count(row.link)
    if n <= 0 then return false, 0 end
    if row.swap or Have.Token(row.id) then return false, n end
    local stack = select(8, GetItemInfo(row.link)) or 1
    if stack > 1 then return false, n end
    return true, n
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UNIT_INVENTORY_CHANGED")
watcher:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
watcher:SetScript("OnEvent", function(self, event, unit)
    if event == "CURRENCY_DISPLAY_UPDATE" then
        tokensReady = false
    elseif unit == "player" then
        Have.Forget()
    end
end)
