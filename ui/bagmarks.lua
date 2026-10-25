local ADDON, ns = ...
local Bag = {}
ns.BagMarks = Bag
local WHITE = "Interface\\Buttons\\WHITE8X8"
local KEEP_TEX = "Interface\\RaidFrame\\ReadyCheck-Ready"
local SPARE_TEX = "Interface\\Buttons\\UI-GroupLoot-Coin-Up"
local SIZE = 14
local BACK_ALPHA = 0.7
local marks = setmetatable({}, { __mode = "k" })
local lastLink = setmetatable({}, { __mode = "k" })
local watched = setmetatable({}, { __mode = "k" })
local bagnonHooked = false
local function markOf(button)
    local m = marks[button]
    if m then return m end
    m = CreateFrame("Frame", nil, button)
    m:SetWidth(SIZE + 2)
    m:SetHeight(SIZE + 2)
    m:SetPoint("TOPLEFT", button, "TOPLEFT", -1, 1)
    m:SetFrameLevel(button:GetFrameLevel() + 2)
    m.back = m:CreateTexture(nil, "BACKGROUND")
    m.back:SetTexture(WHITE)
    m.back:SetVertexColor(0, 0, 0, BACK_ALPHA)
    m.back:SetAllPoints(m)
    m.icon = m:CreateTexture(nil, "ARTWORK")
    m.icon:SetWidth(SIZE)
    m.icon:SetHeight(SIZE)
    m.icon:SetPoint("CENTER", m, "CENTER", 0, 0)
    m:Hide()
    marks[button] = m
    return m
end
local function paint(button, link)
    lastLink[button] = link or false
    local shown = ns.DB().bagMarks ~= false and link ~= nil
    local mark = shown and ns.Marks.Get(ns.Marks.IdOf(link)) or nil
    if not mark then
        if marks[button] then marks[button]:Hide() end
        return
    end
    local m = markOf(button)
    m.icon:SetTexture(mark == ns.Marks.KEEP and KEEP_TEX or SPARE_TEX)
    m:Show()
end
function ns.RefreshBagMarks()
    for button, link in pairs(lastLink) do paint(button, link or nil) end
end
local function paintBag(frame)
    local id, name = frame:GetID(), frame:GetName()
    for i = 1, frame.size or 0 do
        local button = _G[name .. "Item" .. i]
        if button then paint(button, GetContainerItemLink(id, button:GetID())) end
    end
end
hooksecurefunc("ContainerFrame_Update", paintBag)
local function hookBagnon()
    if bagnonHooked then return end
    local slot = Bagnon and Bagnon.ItemSlot
    if not slot or type(slot.Update) ~= "function" then return end
    bagnonHooked = true
    hooksecurefunc(slot, "Update", function(self)
        if self:IsVisible() then
            local link = self.hasItem
            paint(self, type(link) == "string" and link or nil)
        end
    end)
end
local function linkOf(button)
    if button.hasItem and type(button.hasItem) == "string" then return button.hasItem end
    local parent = button:GetParent()
    if not parent or not parent.GetID then return nil end
    return GetContainerItemLink(parent:GetID(), button:GetID())
end
function Bag.Watch(button)
    if watched[button] then return end
    watched[button] = true
    button:HookScript("OnClick", function(self, key)
        if key ~= "LeftButton" or not IsAltKeyDown() or IsShiftKeyDown() or IsControlKeyDown() then return end
        local link = linkOf(self)
        local id = ns.Marks.IdOf(link)
        if not id then return end
        local mark = ns.Marks.Cycle(id)
        local label = ns.Marks.Label(mark)
        UIErrorsFrame:AddMessage(label and ns.T("markSet", link, label) or ns.T("markCleared", link), 1, 0.82, 0.35)
        paint(self, link)
        if GameTooltip:IsOwned(self) and self.UpdateTooltip then self.UpdateTooltip(self) end
    end)
end
hooksecurefunc("ContainerFrameItemButton_OnEnter", function(self)
    Bag.Watch(self)
end)
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", hookBagnon)
hookBagnon()
