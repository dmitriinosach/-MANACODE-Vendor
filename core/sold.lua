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
    local list = {}
    for i = 1, GetNumBuybackItems() or 0 do
        list[i] = GetBuybackItemLink(i) or ""
    end
    return list
end
local function soldFrom(old, new)
    if #new > #old then return #old + 1 end
    if #new < #old or #new < 2 then return #new + 1 end
    local same = true
    for i = 1, #new - 1 do
        if new[i] ~= old[i + 1] then return #new + 1 end
        if new[i] ~= new[i + 1] then same = false end
    end
    return same and #new + 1 or #new
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
local TOAST_W, TOAST_PAD, ICON = 300, 10, 32
local TOAST_GAP, TOAST_TEXT = 4, TOAST_W - TOAST_PAD * 2 - ICON - 8
local TOAST_LIFE, TOAST_FADE = 10, 1
local SOUND = "MapPing"
local toast
local function buybackIndex(id, link)
    local same
    for i = GetNumBuybackItems() or 0, 1, -1 do
        local at = GetBuybackItemLink(i)
        if link and at == link then return i end
        if not same and idOf(at) == id then same = i end
    end
    return same
end
local function buildToast()
    toast = CreateFrame("Frame", "HTP_VendorSoldToast", UIParent)
    toast:SetWidth(TOAST_W)
    toast:SetFrameStrata("DIALOG")
    toast:EnableMouse(true)
    toast:SetClampedToScreen(true)
    ns.Theme.Panel(toast)
    toast.icon = toast:CreateTexture(nil, "ARTWORK")
    toast.icon:SetWidth(ICON)
    toast.icon:SetHeight(ICON)
    toast.icon:SetPoint("TOPLEFT", toast, "TOPLEFT", TOAST_PAD, -TOAST_PAD)
    toast.title = toast:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    toast.title:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 8, 0)
    toast.title:SetWidth(TOAST_TEXT - 16)
    toast.title:SetJustifyH("LEFT")
    toast.title:SetText(ns.T("soldTitle"))
    toast.item = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toast.item:SetPoint("TOPLEFT", toast.title, "BOTTOMLEFT", 0, -3)
    toast.item:SetWidth(TOAST_TEXT)
    toast.item:SetJustifyH("LEFT")
    toast.why = toast:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    toast.why:SetPoint("TOPLEFT", toast.item, "BOTTOMLEFT", 0, -3)
    toast.why:SetWidth(TOAST_TEXT)
    toast.why:SetJustifyH("LEFT")
    local close = CreateFrame("Button", nil, toast, "UIPanelCloseButton")
    close:SetWidth(22)
    close:SetHeight(22)
    close:SetPoint("TOPRIGHT", toast, "TOPRIGHT", -2, -2)
    toast.back = ns.Theme.Chip(toast, ns.T("soldBack"), 20)
    toast.back:SetWidth(100)
    toast.back:SetPoint("BOTTOMRIGHT", toast, "BOTTOMRIGHT", -TOAST_PAD, TOAST_PAD)
    toast.back:SetScript("OnClick", function()
        local i = toast.id and buybackIndex(toast.id, toast.link)
        if i then BuybackItem(i) else ns.say(ns.T("soldGone", toast.link or "")) end
        toast:Hide()
    end)
    toast:SetScript("OnEnter", function(self)
        if not self.link then return end
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end)
    toast:SetScript("OnLeave", function() GameTooltip:Hide() end)
    toast:SetScript("OnUpdate", function(self, elapsed)
        if MouseIsOver(self) then
            self.left = TOAST_LIFE
            self:SetAlpha(1)
            return
        end
        self.left = self.left - elapsed
        if self.left <= 0 then
            self:Hide()
        elseif self.left < TOAST_FADE then
            self:SetAlpha(self.left / TOAST_FADE)
        end
    end)
    toast:Hide()
end
local function showToast(id, link, why)
    if not toast then buildToast() end
    local anchor = _G.HTP_VendorFrame
    if not (anchor and anchor:IsShown()) then anchor = MerchantFrame end
    toast:ClearAllPoints()
    toast:SetPoint("TOPLEFT", anchor, "TOPRIGHT", TOAST_GAP, 0)
    toast.id, toast.link = id, link
    toast.icon:SetTexture(GetItemIcon(id))
    toast.item:SetText(link)
    toast.why:SetText(why)
    toast:SetHeight(TOAST_PAD * 2 + 14 + toast.item:GetStringHeight() + toast.why:GetStringHeight() + 6 + 20 + 4)
    toast.left = TOAST_LIFE
    toast:SetAlpha(1)
    toast:Show()
    PlaySound(SOUND)
end
local function check()
    local list = readBuyback()
    local from = soldFrom(seen, list)
    seen = list
    if ns.DB().warnSold == false then return end
    for i = from, #list do
        local link = list[i]
        local id = idOf(link)
        if id and not warned[id] then
            local why = Sold.Reason(id, link)
            if why then
                warned[id] = true
                ns.say(ns.T("soldWarn", link, why))
                showToast(id, link, why)
            end
        end
    end
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
        if toast then toast:Hide() end
    elseif open then
        check()
    end
end)
