local ADDON, ns = ...
local GAP = 6
local TEXT_GAP = 2
local RED = { 1, 0.3, 0.3 }
local WHITE = { 1, 1, 1 }
local lines = {}
local function chipEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if self.link then
        GameTooltip:SetHyperlink(self.link)
    else
        GameTooltip:SetText(self.name or "", 1, 1, 1)
    end
    local have, need = self.have or 0, self.need or 0
    local ok = have >= need
    GameTooltip:AddLine(ns.T("costHave", have, need), ok and 0.6 or 1, ok and 1 or 0.4, ok and 0.6 or 0.4)
    GameTooltip:Show()
end
local function chipLeave()
    GameTooltip:Hide()
end
local function chipClick(self, button)
    local host = self:GetParent().host
    local fn = host and host:GetScript("OnClick")
    if fn then fn(host, button) end
end
local function makeCurrency(p)
    local c = CreateFrame("Button", nil, p)
    c:SetHeight(20)
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    c:SetScript("OnEnter", chipEnter)
    c:SetScript("OnLeave", chipLeave)
    c:SetScript("OnClick", chipClick)
    if p.host then ns.Theme.Highlight(c, p.host) end
    c.icon = c:CreateTexture(nil, "ARTWORK")
    c.icon:SetWidth(ns.IconSize)
    c.icon:SetHeight(ns.IconSize)
    c.icon:SetPoint("RIGHT", c, "RIGHT", 0, -1)
    c.text = c:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    c.text:SetPoint("RIGHT", c.icon, "LEFT", -TEXT_GAP, 0)
    return c
end
function ns.CurrencySet(c, line, mult)
    local need, have = line.need * (mult or 1), line.have or 0
    c.icon:SetTexture(line.tex)
    c.need, c.have, c.name, c.link = need, have, line.name, line.link
    local label = need > 1 and tostring(need) or ""
    c.text:SetText(label)
    local col = (have or 0) < need and RED or WHITE
    c.text:SetTextColor(col[1], col[2], col[3])
    local w = ns.IconSize
    if label ~= "" then w = w + TEXT_GAP + math.ceil(c.text:GetStringWidth()) end
    c:SetWidth(w)
    return w
end
function ns.MakePrice(parent, host)
    local p = CreateFrame("Frame", nil, parent)
    p.host = host
    p:SetHeight(20)
    p.gold = p:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    p.gold:SetJustifyH("RIGHT")
    p.parts = {}
    return p
end
local function part(p, i)
    local c = p.parts[i]
    if not c then
        c = makeCurrency(p)
        p.parts[i] = c
    end
    return c
end
function ns.PriceSet(p, row, opts)
    opts = opts or {}
    local mult = opts.mult or 1
    local used, width = 0, 0
    local anchor, edge = p, "RIGHT"
    local cost = ns.List.CostLines(row, lines)
    for i = #cost, 1, -1 do
        local c = cost[i]
        if not (opts.noGear and ns.List.Wearable(c.link)) then
            used = used + 1
            local cur = part(p, used)
            local w = ns.CurrencySet(cur, c, mult)
            cur:ClearAllPoints()
            cur:SetPoint("RIGHT", anchor, edge, width > 0 and -GAP or 0, 0)
            cur:Show()
            anchor, edge = cur, "LEFT"
            width = width + w + (width > 0 and GAP or 0)
        end
    end
    for i = used + 1, #p.parts do p.parts[i]:Hide() end
    if row.price > 0 then
        p.gold:SetText(ns.List.Coin(row.price * mult))
        local col = row.price * mult > GetMoney() and RED or WHITE
        p.gold:SetTextColor(col[1], col[2], col[3])
        p.gold:ClearAllPoints()
        p.gold:SetPoint("RIGHT", anchor, edge, width > 0 and -GAP or 0, 0)
        p.gold:Show()
        width = width + math.ceil(p.gold:GetStringWidth()) + (width > 0 and GAP or 0)
    else
        p.gold:Hide()
    end
    p:SetWidth(math.max(width, 1))
    return width
end
