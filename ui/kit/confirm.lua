local ADDON, ns = ...
local NAME = "HTP_VendorConfirm"
local PAD = 12
local WIDTH = 280
local TITLE_H = 20
local BIG = 36
local CELL = 24
local CELL_GAP = 4
local PER_ROW = 8
local MAX_CELLS = 32
local LINE_H = 20
local BTN_H = 20
local BTN_W = 72
local NODE = 30
local SEP_W = 8
local SEP_GAP = 4
local QTY_W = 44
local QTY_INSET = 6
local JUNK_W = 340
local JUNK_MAX = 12
local JUNK_ROW = 14
local JUNK_COST_W = 90
local panel
local cells = {}
local nodes = {}
local ladder = {}
local plan = {}
local rows = {}
local function T(...) return ns.T(...) end
local function build(parent)
    panel = CreateFrame("Frame", NAME, parent)
    panel:SetWidth(WIDTH)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    ns.Theme.Panel(panel)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    panel.title:SetWidth(WIDTH - PAD * 2)
    panel.title:SetJustifyH("LEFT")
    panel.item = ns.MakeItem(panel, "tile")
    panel.item:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -(PAD + TITLE_H))
    panel.math = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.math:SetPoint("LEFT", panel.item, "RIGHT", 10, 0)
    panel.stacks = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.stacks:SetJustifyH("LEFT")
    panel.stacks:SetWidth(WIDTH - PAD * 2)
    panel.total = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.total:SetJustifyH("LEFT")
    panel.price = ns.MakePrice(panel)
    panel.sum = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.sum:SetJustifyH("RIGHT")
    panel.sum:Hide()
    panel.ok = ns.Theme.Chip(panel, OKAY)
    panel.ok:SetHeight(BTN_H)
    panel.ok:SetWidth(BTN_W)
    panel.ok:SetScript("OnClick", function()
        if panel.run then
            panel.run()
            return
        end
        local fn, index, n = panel.onOk, panel.index, panel.purchases
        panel:Hide()
        if fn then fn(index, n) end
    end)
    panel.cancel = ns.Theme.Chip(panel, CANCEL)
    panel.cancel:SetHeight(BTN_H)
    panel.cancel:SetWidth(BTN_W)
    panel.cancel:SetScript("OnClick", function() panel:Hide() end)
    panel:SetScript("OnHide", function(self)
        self.onOk, self.index, self.purchases, self.run = nil, nil, nil, nil
        if self.qty then self.qty:ClearFocus() end
        ns.Chain.Halt()
    end)
    tinsert(UISpecialFrames, NAME)
    panel:Hide()
end
local function getCell(i)
    local c = cells[i]
    if not c then
        c = ns.MakeItem(panel, "row")
        cells[i] = c
    end
    return c
end
function ns.ConfirmBuy(parent, data, purchases, onOk)
    if not panel then build(parent) end
    panel.onOk, panel.index, panel.purchases, panel.run = onOk, data.index, purchases, nil
    for i = 1, #nodes do
        nodes[i]:Hide()
        nodes[i].sep:Hide()
    end
    if panel.qty then panel.qty:Hide() end
    for i = 1, #rows do
        rows[i].name:Hide()
        rows[i].cost:Hide()
    end
    panel.sum:Hide()
    panel:SetWidth(WIDTH)
    panel.title:SetWidth(WIDTH - PAD * 2)
    panel.total:SetWidth(WIDTH - PAD * 2)
    panel.ok:SetText(OKAY)
    panel.ok:Enable()
    panel.item:Show()
    panel.math:Show()
    panel.price:Show()
    local r, g, b = 1, 1, 1
    if data.quality then r, g, b = GetItemQualityColor(data.quality) end
    panel.title:SetText(data.name or "")
    panel.title:SetTextColor(r, g, b)
    local qty = data.quantity or 1
    if qty < 1 then qty = 1 end
    local total = purchases * qty
    ns.ItemSet(panel.item, data.tex, { count = qty > 1 and qty or nil })
    panel.math:SetText(T("confirmMath", purchases, qty))
    local stack = data.link and select(8, GetItemInfo(data.link)) or 1
    if not stack or stack < 1 then stack = 1 end
    local full = math.floor(total / stack)
    local rem = total - full * stack
    local n = full + (rem > 0 and 1 or 0)
    local y = -(PAD + TITLE_H + BIG + 10)
    if n <= MAX_CELLS then
        panel.stacks:Hide()
        for i = 1, n do
            local c = getCell(i)
            local col, row = (i - 1) % PER_ROW, math.floor((i - 1) / PER_ROW)
            c:ClearAllPoints()
            c:SetPoint("TOPLEFT", panel, "TOPLEFT",
                PAD + col * (CELL + CELL_GAP), y - row * (CELL + CELL_GAP))
            ns.ItemSet(c, data.tex, { count = (i <= full) and stack or rem })
            c:Show()
        end
        for i = n + 1, #cells do cells[i]:Hide() end
        y = y - math.ceil(n / PER_ROW) * (CELL + CELL_GAP)
    else
        for i = 1, #cells do cells[i]:Hide() end
        panel.stacks:ClearAllPoints()
        panel.stacks:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
        panel.stacks:SetText(T("confirmStacks", full, stack, rem))
        panel.stacks:Show()
        y = y - 14
    end
    y = y - 6
    panel.total:ClearAllPoints()
    panel.total:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    panel.total:SetHeight(LINE_H)
    panel.total:SetText(T("confirmTotal", total))
    panel.total:Show()
    ns.PriceSet(panel.price, data, { mult = purchases })
    panel.price:ClearAllPoints()
    panel.price:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
    y = y - LINE_H - 8
    panel.ok:ClearAllPoints()
    panel.ok:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
    panel.cancel:ClearAllPoints()
    panel.cancel:SetPoint("RIGHT", panel.ok, "LEFT", -8, 0)
    y = y - BTN_H
    panel:SetHeight(-y + PAD)
    panel:ClearAllPoints()
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    panel:Show()
end
local draw
local function nodeTip(self)
    if not self.link then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(self.link)
    local have, need = GetItemCount(self.link) or 0, self.need or 0
    if need > 0 then
        local ok = have >= need
        GameTooltip:AddLine(T("costHave", have, need), ok and 0.6 or 1, ok and 1 or 0.4, ok and 0.6 or 0.4)
    end
    GameTooltip:Show()
end
local function nodeOut()
    GameTooltip:Hide()
end
local function makeNode(i)
    local n = nodes[i]
    if n then return n end
    n = ns.MakeItem(panel, "tile")
    n:EnableMouse(true)
    n:SetScript("OnEnter", nodeTip)
    n:SetScript("OnLeave", nodeOut)
    n.sep = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    n.sep:SetText(">")
    nodes[i] = n
    return n
end
local function fillNode(s, i, x, y)
    local n = makeNode(i)
    local tex, link, amount
    if i == 1 then
        local e = plan[s].edge
        tex, link, amount = e.payTex, e.payLink, plan[s].pay
    else
        local prev = plan[s - 1]
        tex, link = prev.edge.getTex, prev.edge.getLink
        amount = plan[s] and plan[s].pay or prev.get
    end
    ns.ItemSet(n, tex, { count = amount > 0 and amount or nil })
    n.link, n.need = link, amount
    n:ClearAllPoints()
    n:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    n:Show()
    if i > 1 then
        n.sep:ClearAllPoints()
        n.sep:SetPoint("RIGHT", n, "LEFT", -SEP_GAP, 0)
        n.sep:Show()
    else
        n.sep:Hide()
    end
end
local function runAll()
    if ns.Chain.Busy() then
        ns.Chain.Halt()
        return
    end
    ns.Chain.Run(plan, draw)
    draw()
end
local function setWant(n)
    if n < 1 then n = 1 end
    if (panel.reach or 0) > 0 and n > panel.reach then n = panel.reach end
    panel.want = n
    if panel.qty and panel.qty:GetText() ~= tostring(n) then
        panel.quiet = true
        panel.qty:SetText(tostring(n))
        panel.quiet = false
    end
    draw()
end
local function makeQty()
    if panel.qty then return panel.qty end
    local e = CreateFrame("EditBox", NAME .. "Qty", panel, "InputBoxTemplate")
    e:SetWidth(QTY_W)
    e:SetHeight(BTN_H)
    e:SetAutoFocus(false)
    e:SetNumeric(true)
    e:SetMaxLetters(4)
    e:SetJustifyH("CENTER")
    e:EnableMouseWheel(true)
    e:SetScript("OnTextChanged", function(self)
        if panel.quiet then return end
        local n = tonumber(self:GetText())
        if n then setWant(n) end
    end)
    e:SetScript("OnMouseWheel", function(self, d) setWant((panel.want or 1) + d) end)
    e:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        runAll()
    end)
    e:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    panel.qty = e
    return e
end
draw = function()
    if not panel then return end
    if not ns.Chain.Busy() then ns.Chain.Plan(ladder, panel.want, plan) end
    local from = plan.from or 1
    local count = #plan - from + 2
    local w = PAD * 2 + count * NODE + (count - 1) * (SEP_GAP * 2 + SEP_W)
    if w < WIDTH then w = WIDTH end
    panel:SetWidth(w)
    panel.title:SetWidth(w - PAD * 2)
    local y = -(PAD + TITLE_H)
    local x = PAD
    for i = 1, count do
        fillNode(from + i - 1, i, x, y)
        x = x + NODE + SEP_GAP * 2 + SEP_W
    end
    for i = count + 1, #nodes do
        nodes[i]:Hide()
        nodes[i].sep:Hide()
    end
    y = y - NODE - 10
    local qty = makeQty()
    qty:ClearAllPoints()
    qty:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + QTY_INSET, y)
    panel.total:ClearAllPoints()
    panel.total:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    panel.total:SetHeight(BTN_H)
    panel.total:SetWidth(w - PAD * 2 - BTN_W * 2 - 20)
    local step, of, done, need = ns.Chain.Progress()
    if step then
        qty:Hide()
        panel.total:SetText(T("chainBusy", step, of, done, need))
        panel.total:Show()
        panel.ok:SetText(T("chainStopBtn"))
        panel.ok:Enable()
    else
        panel.total:Hide()
        qty:Show()
        panel.ok:SetText(T("chainRun"))
        if (plan.buys or 0) > 0 then panel.ok:Enable() else panel.ok:Disable() end
    end
    panel.ok:ClearAllPoints()
    panel.ok:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
    panel.cancel:ClearAllPoints()
    panel.cancel:SetPoint("RIGHT", panel.ok, "LEFT", -8, 0)
    y = y - BTN_H
    panel:SetHeight(-y + PAD)
end
function ns.ConfirmChain(parent, row, list, want)
    if not panel then build(parent) end
    panel.onOk, panel.index, panel.purchases = nil, nil, nil
    for i = 1, #cells do cells[i]:Hide() end
    panel.item:Hide()
    panel.math:Hide()
    panel.stacks:Hide()
    panel.price:Hide()
    for i = 1, #rows do
        rows[i].name:Hide()
        rows[i].cost:Hide()
    end
    panel.sum:Hide()
    local r, g, b = 1, 1, 1
    if row.quality then r, g, b = GetItemQualityColor(row.quality) end
    panel.title:SetText(row.name or "")
    panel.title:SetTextColor(r, g, b)
    wipe(ladder)
    for i, e in ipairs(list) do ladder[i] = e end
    panel.want, panel.reach = want, row.reach or 0
    panel.run = runAll
    makeQty()
    panel.quiet = true
    panel.qty:SetText(tostring(want or 1))
    panel.quiet = false
    draw()
    panel:ClearAllPoints()
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    panel:Show()
end
local function getRow(i)
    local r = rows[i]
    if not r then
        r = {}
        r.name = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.name:SetJustifyH("LEFT")
        r.cost = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        r.cost:SetJustifyH("RIGHT")
        rows[i] = r
    end
    return r
end
function ns.ConfirmJunk(parent, list, total, onOk)
    if not panel then build(parent) end
    panel.onOk, panel.index, panel.purchases, panel.run = onOk, nil, nil, nil
    for i = 1, #cells do cells[i]:Hide() end
    for i = 1, #nodes do
        nodes[i]:Hide()
        nodes[i].sep:Hide()
    end
    if panel.qty then panel.qty:Hide() end
    panel.item:Hide()
    panel.math:Hide()
    panel.stacks:Hide()
    panel.price:Hide()
    panel:SetWidth(JUNK_W)
    panel.title:SetWidth(JUNK_W - PAD * 2)
    panel.title:SetText(T("junk"))
    panel.title:SetTextColor(1, 0.82, 0)
    panel.ok:SetText(OKAY)
    panel.ok:Enable()
    local n = #list
    local shown = n > JUNK_MAX and JUNK_MAX or n
    local y = -(PAD + TITLE_H)
    for i = 1, shown do
        local it = list[i]
        local r = getRow(i)
        r.name:ClearAllPoints()
        r.name:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
        r.name:SetWidth(JUNK_W - PAD * 2 - JUNK_COST_W)
        r.name:SetHeight(JUNK_ROW)
        r.name:SetText((it.name or "?") .. (it.count > 1 and (" x" .. it.count) or ""))
        r.name:SetTextColor(0.62, 0.62, 0.62)
        r.name:Show()
        r.cost:ClearAllPoints()
        r.cost:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
        r.cost:SetWidth(JUNK_COST_W)
        r.cost:SetHeight(JUNK_ROW)
        r.cost:SetText(GetCoinTextureString(it.value))
        r.cost:Show()
        y = y - JUNK_ROW
    end
    for i = shown + 1, #rows do
        rows[i].name:Hide()
        rows[i].cost:Hide()
    end
    if n > shown then
        panel.stacks:ClearAllPoints()
        panel.stacks:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
        panel.stacks:SetText(T("junkMore", n - shown))
        panel.stacks:Show()
        y = y - JUNK_ROW
    end
    y = y - 6
    panel.total:ClearAllPoints()
    panel.total:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    panel.total:SetWidth(JUNK_W - PAD * 2 - JUNK_COST_W)
    panel.total:SetHeight(LINE_H)
    panel.total:SetText(T("junkTotal", n))
    panel.total:Show()
    panel.sum:ClearAllPoints()
    panel.sum:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
    panel.sum:SetWidth(JUNK_COST_W)
    panel.sum:SetHeight(LINE_H)
    panel.sum:SetText(GetCoinTextureString(total))
    panel.sum:Show()
    y = y - LINE_H - 8
    panel.ok:ClearAllPoints()
    panel.ok:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD, y)
    panel.cancel:ClearAllPoints()
    panel.cancel:SetPoint("RIGHT", panel.ok, "LEFT", -8, 0)
    y = y - BTN_H
    panel:SetHeight(-y + PAD)
    panel:ClearAllPoints()
    panel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    panel:Show()
end
function ns.ConfirmHide()
    if panel then panel:Hide() end
end
