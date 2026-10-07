local ADDON, ns = ...
local Junk = {}
ns.Junk = Junk
local POOR = 0
local STEP = 0.1
local BAGS = NUM_BAG_SLOTS or 4
local list = {}
local total = 0
local queue = {}
local sold, soldValue, elapsed = 0, 0, 0
function Junk.Scan()
    wipe(list)
    total = 0
    for bag = 0, BAGS do
        for slot = 1, GetContainerNumSlots(bag) or 0 do
            local _, count, locked = GetContainerItemInfo(bag, slot)
            local link = GetContainerItemLink(bag, slot)
            if link and not locked then
                local name, _, quality, _, _, _, _, _, _, _, price = GetItemInfo(link)
                if quality == POOR and price and price > 0 then
                    local value = price * (count or 1)
                    list[#list + 1] = { bag = bag, slot = slot, link = link, name = name,
                        count = count or 1, value = value }
                    total = total + value
                end
            end
        end
    end
    return list, total
end
local seller = CreateFrame("Frame")
seller:Hide()
seller:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < STEP then return end
    elapsed = 0
    local it = table.remove(queue, 1)
    if not it or not (ns.MerchantOpen and ns.MerchantOpen()) then
        self:Hide()
        wipe(queue)
        if sold > 0 then ns.say(ns.T("junkSold", sold, GetCoinTextureString(soldValue))) end
        return
    end
    if GetContainerItemLink(it.bag, it.slot) == it.link then
        UseContainerItem(it.bag, it.slot)
        sold = sold + 1
        soldValue = soldValue + it.value
    end
end)
function Junk.Sell()
    if seller:IsShown() then return end
    Junk.Scan()
    if #list == 0 then return end
    wipe(queue)
    for i, it in ipairs(list) do queue[i] = it end
    sold, soldValue, elapsed = 0, 0, STEP
    seller:Show()
end
function Junk.Busy()
    return seller:IsShown()
end
