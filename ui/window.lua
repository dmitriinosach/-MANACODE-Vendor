local ADDON, ns = ...
local NAME = "HTP_VendorFrame"
local PAD = 10
local ROW_H = 30
local HEAD_H, DIV_H, PAIR_H = 30, 20, 48
local UNIT = 6
local DIV_X = 8
local TILE_GAP = 12
local COL_DEF = 318
local COL_GAP = 8
local SCROLL_W = 18
local LIST_TOP = 36
local FOOT_ROW = 26
local FOOT_ONE = 44
local FOOT_TWO = FOOT_ONE + FOOT_ROW
local footH = FOOT_ONE
local MAX_COLS = 4
local MIN_ROWS, MAX_ROWS = 10, 30
local FIT_ROWS = 14
local FIT_COLS = 3
local SCREEN_TALL = 2 / 3
local SCREEN_WIDE = 0.98
local TEXT_X = 34
local TEXT_GAP = 10
local ICON = 24
local CHIP_ICON = 14
local BTN = 22
local FOOT_Y = 12
local FOOT_X = 16
local FOOT_GAP = 7
local TAB_MIN_W = 96
local TAB_LIFT = 10
local RETRY_MAX = 8
local RETRY_AFTER = 0.5
local QTY = { 5, 20, 100 }
local BULK_SLOT = { INVTYPE_AMMO = true, INVTYPE_THROWN = true }
local JUNK_TIP_MAX = 12
local CELL_W = 100
local CELL_MIN = 58
local CELL_TIGHT = 78
local NAME_MIN = 150
local NAME_HARD = 70
local CELL_MAX = 150
local CELL_SLACK = 8
local CELL_PAD = 7
local NAME_FIT = 210
local SET_X = 10
local CELL_H = 28
local CELL_GAP = 8
local EXP_ROOM = 24
local MAX_TIERS = 4
local MAX_CHIPS = 8
local WHITE = "Interface\\Buttons\\WHITE8X8"
local REPAIR_ICONS = "Interface\\MerchantFrame\\UI-Merchant-RepairIcons"
local COIN_ICON = "Interface\\Icons\\INV_Misc_Coin_02"
local GRIP = "Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up"
local NO_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local PAGE_PREV = "Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up"
local PAGE_NEXT = "Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up"
local PLUS = "Interface\\Buttons\\UI-PlusButton-Up"
local MINUS = "Interface\\Buttons\\UI-MinusButton-Up"
local BTN_HILITE = "Interface\\Buttons\\ButtonHilight-Square"
local frame, listArea, scroll, search, searchHint, emptyText, moneyText, moneyBtn
local filterGlyph, viewGlyph
local hammerBtn, repairBtn, guildBtn, repairText, junkBtn, junkText, grip, qbar
local colMore, colLess, footLine, ruler
local tabs = {}
local TAB_ORDER = { "goods", "buyback" }
local rowPool, canvas, flowScratch = nil, nil, {}
local goodsPool
local chips = {}
local walletList = {}
local costLines = {}
local colLines = {}
local state = {
    tab = "goods",
    query = "",
    filtered = {},
    shown = {},
    seq = {},
    collapsed = {},
    cols = 2,
    rows = 12,
    lines = 0,
    backpackWasOpen = nil,
    retryLeft = 0,
    retryAt = nil,
    rightAnchor = nil,
    wide = false,
    mode = "plain",
}
local function T(...) return ns.T(...) end
local Refresh
local applyLayout, rememberSize, placeList, placeFoot, updateView
local function entryH(e)
    if e.kind == "pair" then return PAIR_H end
    if e.kind == "div" then return DIV_H end
    return ROW_H
end
local function needRows(seq, cols)
    local _, h = ns.Groups.Flow(seq, cols, entryH, flowScratch)
    return math.ceil(h / ROW_H)
end
function ns.MerchantOpen()
    return frame ~= nil and frame:IsShown()
end
function ns.SellingTab()
    return ns.MerchantOpen() and state.tab == "goods"
end
hooksecurefunc("ContainerFrameItemButton_OnEnter", function(self)
    if not ns.SellingTab() or InRepairMode() or IsModifiedClick("DRESSUP") then return end
    ShowContainerSellCursor(self:GetParent():GetID(), self:GetID())
end)
local function listWidth(cols)
    return cols * COL_DEF + (cols - 1) * COL_GAP
end
local function frameWidth(cols)
    return PAD * 2 + listWidth(cols) + SCROLL_W
end
local function frameHeight(n)
    return LIST_TOP + n * ROW_H + footH
end
local function curScale()
    local v = ns.DB and ns.DB() and ns.DB().scale
    return (v and v > 0) and v or 1
end
local function roomRows()
    local room = GetScreenHeight() * SCREEN_TALL / curScale()
    local n = math.floor((room - LIST_TOP - footH) / ROW_H)
    if n > MAX_ROWS then n = MAX_ROWS end
    if n < MIN_ROWS then n = MIN_ROWS end
    return n
end
local function roomCols()
    local room = GetScreenWidth() * SCREEN_WIDE / curScale()
    local n = math.floor((room - PAD * 2 - SCROLL_W + COL_GAP) / (COL_DEF + COL_GAP))
    if n > MAX_COLS then n = MAX_COLS end
    if n < 1 then n = 1 end
    return n
end
local function tipShow(self, title, text)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if text then GameTooltip:AddLine(text, nil, nil, nil, true) end
    GameTooltip:Show()
end
local function tipHide()
    GameTooltip:Hide()
end
local function mouseInside(f)
    if not f or not f:IsShown() then return false end
    local left, right = f:GetLeft(), f:GetRight()
    local top, bottom = f:GetTop(), f:GetBottom()
    if not left then return false end
    local scale = f:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    return x >= left and x <= right and y >= bottom and y <= top
end
local function updateMoney()
    moneyText:SetText(ns.List.Purse(GetMoney()))
    moneyBtn:SetWidth(math.max(60, math.ceil(moneyText:GetStringWidth()) + 6))
    moneyBtn:SetWidth(math.ceil(moneyText:GetStringWidth()) + 2)
end
local function moneyEnter(self)
    local list = state.wallet
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T("wallet"), 1, 1, 1)
    GameTooltip:AddDoubleLine(ns.Icon(COIN_ICON, 14) .. " " .. T("walletMoney"),
        GetCoinTextureString(GetMoney()), 1, 1, 1, 1, 1, 1)
    for _, d in ipairs(list or {}) do
        local n = d.count or 0
        local r, g, b = 1, 1, 1
        if n == 0 then r, g, b = 0.5, 0.5, 0.5 end
        GameTooltip:AddDoubleLine(ns.Icon(d.tex, 14) .. " " .. (d.title or ""), n, r, g, b, r, g, b)
    end
    GameTooltip:Show()
end
local function updateTitle()
    ns.Theme.SetTitle(frame, state.who or T("title"), state.npcTitle, frameWidth(state.cols))
end
local function chipEnter(self)
    local d = self.data
    if not d then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if d.link then
        GameTooltip:SetHyperlink(d.link)
    else
        GameTooltip:SetText(d.title or "", 1, 1, 1)
    end
    local key = d.hint or (d.id and ("cur" .. d.id))
    if key and ns.Has(key) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(T(key), 0.6, 0.8, 1, true)
    end
    GameTooltip:Show()
end
local function getChip(i)
    local chip = chips[i]
    if chip then return chip end
    chip = CreateFrame("Button", nil, frame)
    chip:SetHeight(22)
    chip.icon = chip:CreateTexture(nil, "ARTWORK")
    chip.icon:SetWidth(CHIP_ICON)
    chip.icon:SetHeight(CHIP_ICON)
    chip.icon:SetPoint("RIGHT", chip, "RIGHT", 0, 0)
    chip.text = chip:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    chip.text:SetPoint("RIGHT", chip.icon, "LEFT", -3, 0)
    chip:SetScript("OnEnter", chipEnter)
    chip:SetScript("OnLeave", tipHide)
    chips[i] = chip
    return chip
end
local function footLeftWidth()
    local w = FOOT_X
    if hammerBtn and hammerBtn:IsShown() then
        w = w + BTN * 2 + FOOT_GAP * 2 + (guildBtn:IsShown() and (BTN + FOOT_GAP) or 0)
            + FOOT_GAP + math.ceil(repairText:GetStringWidth()) + FOOT_GAP * 2
    end
    if junkBtn and junkBtn:IsShown() then
        w = w + BTN + FOOT_GAP + math.ceil(junkText:GetStringWidth()) + FOOT_GAP * 2
    end
    return w
end
local function footRightWidth()
    return FOOT_X + 14 + math.ceil(moneyText:GetStringWidth()) + 18
end
local function chipsWidth(k)
    local w = 0
    for i = 1, k do w = w + chips[i]:GetWidth() + 12 end
    return w
end
local function showChips(avail)
    local k = 0
    for i = 1, state.chipsAll or 0 do
        if chipsWidth(i) > avail then break end
        k = i
    end
    for i = 1, state.chipsAll or 0 do
        if i <= k then chips[i]:Show() else chips[i]:Hide() end
    end
    state.chips = k
end
local function footLeftTail()
    if junkBtn and junkBtn:IsShown() then return junkText end
    if repairText and repairText:IsShown() then return repairText end
    if hammerBtn and hammerBtn:IsShown() then return hammerBtn end
    return nil
end
local function placeChips(two)
    local anchor = moneyBtn
    for i = 1, state.chips or 0 do
        local chip = chips[i]
        chip:ClearAllPoints()
        if two then
            chip:SetPoint("LEFT", anchor, "RIGHT", FOOT_GAP * 2, 0)
        else
            chip:SetPoint("RIGHT", anchor, "LEFT", -FOOT_GAP * 2, 0)
        end
        anchor = chip
    end
    return anchor
end
placeFoot = function()
    if not moneyBtn then return end
    local room = frameWidth(state.cols)
    local left = footLeftWidth()
    local two = left + footRightWidth() > room
    local want = two and FOOT_TWO or FOOT_ONE
    if want ~= footH then
        footH = want
        frame:SetHeight(frameHeight(state.rows))
        frame:SetMinResize(frameWidth(1), frameHeight(MIN_ROWS))
        frame:SetMaxResize(frameWidth(roomCols()), frameHeight(roomRows()))
    end
    local topY = two and (FOOT_Y + FOOT_ROW) or FOOT_Y
    footLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", PAD, footH - 2)
    footLine:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD, footH - 2)
    hammerBtn:ClearAllPoints()
    hammerBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", FOOT_X, topY + 1)
    junkBtn:ClearAllPoints()
    if repairText:IsShown() then
        junkBtn:SetPoint("LEFT", repairText, "RIGHT", FOOT_GAP * 2, 0)
    else
        junkBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", FOOT_X, topY + 1)
    end
    moneyBtn:ClearAllPoints()
    if two then
        moneyText:SetJustifyH("LEFT")
        moneyBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", FOOT_X, FOOT_Y)
        showChips(room - FOOT_X * 2 - moneyBtn:GetWidth())
        placeChips(true)
        return
    end
    moneyText:SetJustifyH("RIGHT")
    moneyBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -FOOT_X - 14, FOOT_Y)
    showChips(room - left - footRightWidth())
    state.rightAnchor = placeChips(false)
end
function ns.RefreshFilterButton()
    if not filterGlyph then return end
    ns.Theme.GlyphTint(filterGlyph, ns.Filter.Count() > 0)
end
local function updateWallet(src)
    local list = src and ns.List.Wallet(src, walletList) or {}
    state.wallet = list
    local made = 0
    for _, d in ipairs(list) do
        if made < MAX_CHIPS then
            made = made + 1
            local chip = getChip(made)
            chip.data = d
            chip.icon:SetTexture(d.tex)
            chip.text:SetText(d.count or 0)
            local have = (d.count or 0) > 0
            chip.text:SetTextColor(1, 1, 1, have and 1 or 0.5)
            if have then
                chip.icon:SetDesaturated(false)
                chip.icon:SetVertexColor(1, 1, 1)
            elseif not chip.icon:SetDesaturated(true) then
                chip.icon:SetVertexColor(0.5, 0.5, 0.5)
            end
            chip:SetWidth(math.ceil(chip.text:GetStringWidth()) + CHIP_ICON + 8)
        end
    end
    for i = made + 1, #chips do chips[i]:Hide() end
    state.chipsAll = made
    placeFoot()
end
local function guildRepairLeft()
    local limit = GetGuildBankWithdrawMoney()
    local bank = GetGuildBankMoney() or 0
    if not limit or limit < 0 then return bank end
    if limit < bank then return limit end
    return bank
end
local function guildEnter(self)
    local cost = select(2, ns.List.RepairInfo())
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T("repairGuild"), 1, 1, 1)
    GameTooltip:AddLine(T("tipRepairGuild"), nil, nil, nil, true)
    if cost > 0 then
        GameTooltip:AddDoubleLine(T("repairAll"), GetCoinTextureString(cost), 0.62, 0.62, 0.62, 1, 1, 1)
    end
    local left = guildRepairLeft()
    if left > 0 then
        local short = cost > 0 and left < cost
        GameTooltip:AddDoubleLine(T("repairGuildLeftTip"), GetCoinTextureString(left),
            0.62, 0.62, 0.62, 1, short and 0.2 or 1, short and 0.2 or 1)
    else
        GameTooltip:AddLine(T("repairGuildBlind"), 0.6, 0.8, 1, true)
    end
    GameTooltip:Show()
end
local guildWired
local function updateRepair()
    local can, cost, canPay, guild = ns.List.RepairInfo()
    if not can then
        hammerBtn:Hide()
        repairBtn:Hide()
        guildBtn:Hide()
        repairText:Hide()
        placeFoot()
        return
    end
    hammerBtn:Show()
    repairBtn:Show()
    local broken = canPay and cost > 0
    local rich = broken and GetMoney() >= cost
    ns.Theme.SetIconEnabled(hammerBtn, broken or InRepairMode())
    ns.Theme.SetIconEnabled(repairBtn, rich)
    local text = cost > 0 and ns.List.Coin(cost) or ""
    local plain = true
    if guild then
        guildBtn:Show()
        ns.Theme.SetIconEnabled(guildBtn, broken)
        if not guildWired then
            guildWired = true
            guildBtn:SetScript("OnEnter", guildEnter)
        end
        local left = guildRepairLeft()
        if left > 0 then
            local part = T("repairGuildLeft", ns.List.Purse(left))
            text = text ~= "" and (text .. "  " .. part) or part
            plain = false
        end
    else
        guildBtn:Hide()
    end
    repairText:ClearAllPoints()
    repairText:SetPoint("LEFT", guild and guildBtn or repairBtn, "RIGHT", 6, 0)
    repairText:SetText(text)
    if plain and broken and not rich then
        repairText:SetTextColor(1, 0.2, 0.2)
    else
        repairText:SetTextColor(1, 1, 1)
    end
    repairText:Show()
    placeFoot()
end
local updateJunk
local function askJunk()
    if ns.Junk.Busy() then return end
    local list, total = ns.Junk.Scan()
    if #list == 0 then return end
    ns.ConfirmJunk(frame, list, total, function()
        ns.Junk.Sell()
        updateJunk()
    end)
end
local junkWired
updateJunk = function()
    local list, total = ns.Junk.Scan()
    if #list == 0 then
        junkBtn:Hide()
        junkText:Hide()
        return
    end
    if not junkWired then
        junkWired = true
        junkBtn:SetScript("OnClick", askJunk)
    end
    junkBtn:Show()
    junkText:Show()
    junkText:SetText(T("junkLine", #list, ns.List.Purse(total)))
    ns.Theme.SetIconEnabled(junkBtn, not ns.Junk.Busy())
end
local function junkEnter(self)
    local list = ns.Junk.Scan()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T("junk"), 1, 1, 1)
    for i = 1, math.min(#list, JUNK_TIP_MAX) do
        local it = list[i]
        local label = (it.name or "?") .. (it.count > 1 and (" x" .. it.count) or "")
        GameTooltip:AddDoubleLine(label, GetCoinTextureString(it.value), 0.62, 0.62, 0.62, 1, 1, 1)
    end
    if #list > JUNK_TIP_MAX then
        GameTooltip:AddLine(T("junkMore", #list - JUNK_TIP_MAX), 0.5, 0.5, 0.5)
    end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(T("tipJunk"), 0.6, 0.8, 1, true)
    GameTooltip:Show()
end
local function askBuy(data, count)
    if not data then return end
    local list = ns.Chain.For(ns.List.Scan(), data)
    if #list > 0 then
        ns.ConfirmChain(frame, data, list, count)
        return
    end
    local afford = ns.List.CanAfford(data)
    if count > afford then count = afford end
    if count <= 0 then return end
    ns.ConfirmBuy(frame, data, count, ns.List.BuyMany)
end
local function buy(btn, count)
    count = count or 1
    if count <= 0 then return end
    if btn.extendedCost then
        MerchantFrame_ConfirmExtendedItemCost(btn, count)
    elseif btn.price and btn.price >= (MERCHANT_HIGH_PRICE_COST or 1500000) then
        MerchantFrame_ConfirmHighCostItem(btn, count)
    else
        BuyMerchantItem(btn:GetID(), count)
    end
end
local function rowModifiedClick(self)
    if state.tab == "buyback" then
        HandleModifiedItemClick(GetBuybackItemLink(self:GetID()))
        return
    end
    if HandleModifiedItemClick(GetMerchantItemLink(self:GetID())) then return end
    if IsModifiedClick("SPLITSTACK") or (IsControlKeyDown() and not ns.List.Wearable(self.link)) then
        local maxStack = GetMerchantItemMaxStack(self:GetID())
        if maxStack > 1 and self.price and self.price > 0 then
            local canAfford = math.floor(GetMoney() / self.price)
            if canAfford < maxStack then maxStack = canAfford end
        end
        if maxStack > 1 then
            OpenStackSplitFrame(maxStack, self, "BOTTOMLEFT", "TOPLEFT")
        end
    end
end
local function rowClick(self, button)
    if self.head then
        state.collapsed[self.head.key] = not state.collapsed[self.head.key] or nil
        Refresh()
        return
    end
    if not self.data then return end
    if IsModifiedClick() then
        rowModifiedClick(self)
        return
    end
    if state.tab == "buyback" then
        BuybackItem(self:GetID())
        return
    end
    MerchantFrame.extendedCost = nil
    if button == "LeftButton" then
        if MerchantFrame.refundItem
            and ContainerFrame_GetExtendedPriceString(MerchantFrame.refundItem, MerchantFrame.refundItemEquipped) then
            return
        end
        PickupMerchantItem(self:GetID())
        if self.extendedCost then MerchantFrame.extendedCost = self end
    elseif ns.List.CanAfford(self.data) > 0 or (self.data.reach or 0) <= 0 then
        buy(self, 1)
    else
        askBuy(self.data, 1)
    end
end
local function compareWanted()
    return IsShiftKeyDown()
        or IsModifiedClick("COMPAREITEMS")
        or (GetCVarBool and GetCVarBool("alwaysCompareItems"))
        or false
end
local function hideCompare()
    if GameTooltip.shoppingTooltips then
        for _, f in pairs(GameTooltip.shoppingTooltips) do f:Hide() end
    end
    GameTooltip.comparing = false
end
local function showQty(row)
    if not qbar then return end
    if state.tab ~= "goods" or not row or not row.data or row.noQty then
        qbar:Hide()
        return
    end
    local slot = row.data.equipSlot
    if slot and slot ~= "" and not BULK_SLOT[slot] then
        qbar:Hide()
        return
    end
    local afford = ns.List.CanAfford(row.data)
    if (row.data.reach or 0) > afford then afford = row.data.reach end
    local x, any = 0, false
    for i, n in ipairs(QTY) do
        local b = qbar.buttons[i]
        if n <= afford then
            b:ClearAllPoints()
            b:SetPoint("LEFT", qbar, "LEFT", x, 0)
            b:Show()
            x = x + b:GetWidth() + 3
            any = true
        else
            b:Hide()
        end
    end
    if not any then
        qbar:Hide()
        return
    end
    if qbar.row and qbar.row ~= row then ns.GoodsQty(qbar.row, false) end
    qbar.row = row
    ns.GoodsQty(row, true)
    qbar:SetWidth(x)
    qbar:ClearAllPoints()
    qbar:SetPoint("TOPLEFT", row, "TOPLEFT", row.qtyX or TEXT_X, row.qtyY or -15)
    qbar:SetFrameLevel(row:GetFrameLevel() + 4)
    qbar:Show()
end
local function rowEnter(self)
    if not self.data then return end
    showQty(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if state.tab == "goods" then
        GameTooltip:SetMerchantItem(self:GetID())
        if self.narrow then GameTooltip:AddLine(T("priceLine", ns.List.PriceText(self.data)), 1, 1, 1) end
        local have = ns.Have.Count(self.data.link)
        if have > 0 then GameTooltip:AddLine(T("haveCount", have), 1, 0.82, 0) end
        local cost = ns.List.CostLines(self.data, costLines)
        if #cost > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(T("costTitle"), 1, 0.82, 0)
            for _, c in ipairs(cost) do
                local enough = c.have >= c.need
                GameTooltip:AddLine(T("costLine", c.need, c.name or UNKNOWN, c.have),
                    enough and 0.6 or 1, enough and 1 or 0.4, enough and 0.6 or 0.4)
            end
        end
        GameTooltip:AddLine(T("tipBuy"), 0.6, 0.8, 1)
        GameTooltip:Show()
        if not CursorHasItem() then
            SetCursor(ns.List.CanAfford(self.data) > 0 and "BUY_CURSOR" or "BUY_ERROR_CURSOR")
        end
        if compareWanted() then
            GameTooltip_ShowCompareItem(GameTooltip)
        else
            hideCompare()
        end
    else
        GameTooltip:SetBuybackItem(self:GetID())
        GameTooltip:AddLine(T("tipBuyback"), 0.6, 0.8, 1)
        GameTooltip:Show()
        if IsModifiedClick("DRESSUP") then
            ShowInspectCursor()
        else
            ShowBuybackSellCursor(self:GetID())
        end
    end
end
local function rowLeave()
    GameTooltip:Hide()
    ResetCursor()
end
local function sellCursorItem(index)
    if CursorHasItem() then PickupMerchantItem(index or 0) end
end
local function bindGoods(g)
    g.SplitStack = function(btn, split)
        if split and split > 0 then buy(btn, split) end
    end
    g.UpdateTooltip = rowEnter
    g:SetScript("OnClick", rowClick)
    g:SetScript("OnDragStart", function(self)
        if self.data and state.tab == "goods" then PickupMerchantItem(self:GetID()) end
    end)
    g:SetScript("OnReceiveDrag", function(self)
        sellCursorItem(self.data and state.tab == "goods" and self:GetID() or 0)
    end)
    g:SetScript("OnEnter", rowEnter)
    g:SetScript("OnLeave", rowLeave)
end
local function maxTiers(seq)
    local n = 0
    for _, e in ipairs(seq) do
        if e.kind == "head" and e.tiers and #e.tiers > n then n = #e.tiers end
    end
    return n
end
local function matrixCols(total, tiers)
    local need = SET_X + NAME_MIN + TEXT_GAP + tiers * CELL_W
    local k = math.floor((total + COL_GAP) / (need + COL_GAP))
    return k > 1 and k or 1
end
local cellWs, uniformWs = {}, {}
local function spanOf(ws, from, to)
    local w = 0
    for i = from, to do w = w + ws[i] end
    return w
end
local function cellWidths(rowW, n)
    if state.cellWs then return state.cellWs end
    wipe(uniformWs)
    local w = CELL_W
    if n >= 1 then
        w = math.floor((rowW - SET_X - TEXT_GAP - NAME_MIN) / n)
        if w > CELL_W then w = CELL_W end
        if w < CELL_MIN then w = CELL_MIN end
    end
    for i = 1, n do uniformWs[i] = w end
    return uniformWs
end
local function priceWidth(text)
    local plain, icons = text:gsub("|T.-|t", "")
    ruler:SetText(plain)
    return math.ceil(ruler:GetStringWidth()) + icons * ns.IconSize
end
local cellParts = {}
local function cellPrice(data, avail)
    local parts = ns.List.PriceParts(data, 1, ns.Filter.Get("hideGear"), cellParts)
    local text = ""
    for i, part in ipairs(parts) do
        local more = i == 1 and part or (text .. ns.List.PriceSep .. part)
        if i > 1 and priceWidth(more) > avail then break end
        text = more
    end
    return text
end
local function cellFit(seq, n, rowW)
    if n < 1 or not ruler then return nil end
    local noGear = ns.Filter.Get("hideGear")
    wipe(cellWs)
    for i = 1, n do cellWs[i] = 0 end
    for _, e in ipairs(seq) do
        if e.kind == "set" and e.cells then
            for i = 1, n do
                local d = e.cells[i]
                if d then
                    local w = priceWidth(ns.List.PriceText(d, 1, noGear))
                    if w > cellWs[i] then cellWs[i] = w end
                end
            end
        end
    end
    local sum = 0
    for i = 1, n do
        local need = ICON + CELL_PAD + cellWs[i] + CELL_SLACK + CELL_GAP
        if need > CELL_MAX then need = CELL_MAX end
        if need < CELL_MIN then need = CELL_MIN end
        cellWs[i] = need
        sum = sum + need
    end
    local room = rowW - SET_X - TEXT_GAP - NAME_HARD
    if sum > room then
        for i = 1, n do
            cellWs[i] = math.max(CELL_MIN, math.floor(cellWs[i] * room / sum))
        end
    end
    return cellWs
end
local function makeCell(row, i)
    local cell = CreateFrame("Button", nil, row)
    cell:SetWidth(CELL_W)
    cell:SetHeight(CELL_H)
    cell.tier = i
    cell:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    cell:RegisterForDrag("LeftButton")
    cell.noQty = true
    cell.icon = cell:CreateTexture(nil, "ARTWORK")
    cell.icon:SetWidth(ICON)
    cell.icon:SetHeight(ICON)
    cell.icon:SetPoint("LEFT", cell, "LEFT", 2, 0)
    cell.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ns.Theme.Row(cell, cell.icon, false)
    cell.priceText = cell:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cell.priceText:SetPoint("LEFT", cell.icon, "RIGHT", 3, 0)
    cell.priceText:SetPoint("RIGHT", cell, "RIGHT", -2, 0)
    cell.priceText:SetJustifyH("RIGHT")
    cell.SplitStack = function(btn, split)
        if split and split > 0 then buy(btn, split) end
    end
    cell.UpdateTooltip = rowEnter
    cell:SetScript("OnClick", rowClick)
    cell:SetScript("OnDragStart", function(self)
        if self.data and state.tab == "goods" then PickupMerchantItem(self:GetID()) end
    end)
    cell:SetScript("OnReceiveDrag", function(self)
        sellCursorItem(self.data and state.tab == "goods" and self:GetID() or 0)
    end)
    cell:SetScript("OnEnter", rowEnter)
    cell:SetScript("OnLeave", rowLeave)
    cell:Hide()
    return cell
end
local function getCell(row, i)
    row.cells = row.cells or {}
    local cell = row.cells[i]
    if not cell then
        cell = makeCell(row, i)
        row.cells[i] = cell
    end
    return cell
end
local function getCap(row, i)
    row.caps = row.caps or {}
    local cap = row.caps[i]
    if not cap then
        cap = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        cap:SetWidth(CELL_W - 8)
        cap:SetJustifyH("LEFT")
        row.caps[i] = cap
    end
    return cap
end
local function makeRow()
    local row = CreateFrame("Button", nil, canvas)
    row:SetWidth(COL_DEF)
    row:SetHeight(ROW_H)
    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    row:RegisterForDrag("LeftButton")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(ICON)
    row.icon:SetHeight(ICON)
    row.icon:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    ns.Theme.Row(row, row.icon, false)
    ns.Theme.Head(row)
    row.exp:SetScript("OnClick", function(self) rowClick(self:GetParent()) end)
    ns.Theme.Divider(row, DIV_X)
    row.divTex = row:CreateTexture(nil, "OVERLAY")
    row.divTex:SetTexture(WHITE)
    row.divTex:SetVertexColor(1, 0.82, 0.35, 0.30)
    row.divTex:SetHeight(1)
    row.divTex:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
    row.divTex:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, 0)
    row.divTex:Hide()
    row.headText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.headText:SetPoint("RIGHT", row, "RIGHT", -40, 0)
    row.headText:SetJustifyH("LEFT")
    row.headText:Hide()
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", TEXT_X, -4)
    row.name:SetHeight(12)
    row.name:SetJustifyH("LEFT")
    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", TEXT_X, -17)
    row.sub:SetHeight(11)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetTextColor(0.6, 0.6, 0.6)
    row.priceText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.priceText:SetPoint("RIGHT", row, "RIGHT", -8, 0)
    row.priceText:SetHeight(20)
    row.priceText:SetJustifyH("RIGHT")
    row.SplitStack = function(btn, split)
        if split and split > 0 then buy(btn, split) end
    end
    row.UpdateTooltip = rowEnter
    row:SetScript("OnClick", rowClick)
    row:SetScript("OnDragStart", function(self)
        if self.data and state.tab == "goods" then PickupMerchantItem(self:GetID()) end
    end)
    row:SetScript("OnReceiveDrag", function(self)
        sellCursorItem(self.data and state.tab == "goods" and self:GetID() or 0)
    end)
    row:SetScript("OnEnter", rowEnter)
    row:SetScript("OnLeave", rowLeave)
    row:Hide()
    return row
end
local function resetRow(row)
    row.head = nil
    row.data = nil
end
local function clearRow(row)
    row.head = nil
    row.data = nil
    row:EnableMouse(true)
    row.hlTex:Hide()
    row.divTex:Hide()
    row:SetID(0)
    row.icon:Hide()
    row.slotTex:Hide()
    row.iconEdge:Hide()
    row.qualFrame:Hide()
    row.haveTex:Hide()
    row.name:Hide()
    row.sub:Hide()
    row.priceText:SetText("")
    row.headBg:Hide()
    row.exp:Hide()
    row.roleTex:Hide()
    row.headText:Hide()
    row.divText:Hide()
    row.divLine:Hide()
    for _, cell in ipairs(row.cells or {}) do
        cell.data = nil
        cell.haveTex:Hide()
        cell:Hide()
    end
    for _, cap in ipairs(row.caps or {}) do cap:Hide() end
end
local function fillHead(row, entry)
    clearRow(row)
    row.head = entry
    row.headBg:Show()
    row.headText:Show()
    row.headText:SetText(entry.label)
    ns.Theme.SetRole(row, not entry.cont and entry.role or nil)
    row.headText:ClearAllPoints()
    if row.roleTex:IsShown() then
        row.headText:SetPoint("LEFT", row.roleTex, "RIGHT", 6, 0)
    else
        row.headText:SetPoint("LEFT", row, "LEFT", 8, 0)
    end
    ns.Theme.SetExpander(row, entry.collapsed)
    if entry.cont then
        row.exp:Hide()
        row.headBg:SetAlpha(1)
        row.headText:SetAlpha(1)
        return
    end
    row.exp:Show()
    row.headBg:SetAlpha(1)
    row.headText:SetAlpha(1)
    ns.Theme.HeadBar(row, HEAD_H)
    local n = entry.tiers and #entry.tiers or 0
    local caps = n > 0
    if caps then
        local ws = cellWidths(row:GetWidth(), n)
        local all = spanOf(ws, 1, n)
        local startX = (row.roleTex:IsShown() and 32 or 8)
        caps = math.ceil(row.headText:GetStringWidth()) <= row:GetWidth() - startX - all
        if caps then
            for i, lvl in ipairs(entry.tiers) do
                local cap = getCap(row, i)
                cap:ClearAllPoints()
                cap:SetPoint("LEFT", row, "RIGHT", -spanOf(ws, i, n) + 4, 0)
                cap:SetWidth(ws[i] - 8)
                local tag = ns.Groups.TierTag(lvl)
                cap:SetText(tag or (ws[i] < CELL_TIGHT and tostring(lvl) or T("ilvl", lvl)))
                cap:Show()
            end
        end
        row.headText:SetPoint("RIGHT", row, "RIGHT", caps and -all or -EXP_ROOM, 0)
    else
        row.headText:SetPoint("RIGHT", row, "RIGHT", -(EXP_ROOM + 18), 0)
    end
end
local function fillCell(cell, data)
    cell.data = data
    cell:SetID(data.index)
    cell.link = data.link
    cell.texture = data.tex
    cell.price = data.price
    cell.count = data.quantity
    cell.extendedCost = data.cost and true or nil
    cell.icon:SetTexture(data.tex or NO_ICON)
    if ns.Have.Count(data.link) > 0 then cell.haveTex:Show() else cell.haveTex:Hide() end
    if data.stock == 0 then
        if not cell.icon:SetDesaturated(true) then cell.icon:SetVertexColor(0.5, 0.5, 0.5) end
    else
        cell.icon:SetDesaturated(false)
        cell.icon:SetVertexColor(1, 1, 1)
    end
    ns.Theme.ShowIcon(cell)
    cell.priceText:SetText(cellPrice(data, cell:GetWidth() - ICON - CELL_PAD))
    if ns.List.CanAfford(data) > 0 then
        cell.priceText:SetTextColor(1, 1, 1)
    else
        cell.priceText:SetTextColor(1, 0.3, 0.3)
    end
    cell:Show()
end
local function fillSet(row, entry, tiers)
    clearRow(row)
    row:EnableMouse(false)
    local base = entry.row
    local n = tiers and #tiers or 0
    local ws = cellWidths(row:GetWidth(), n)
    local textW = row:GetWidth() - SET_X - spanOf(ws, 1, n) - TEXT_GAP
    row.name:Show()
    row.name:ClearAllPoints()
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", SET_X, -4)
    row.name:SetText(_G[entry.slot] or "")
    row.name:SetTextColor(1, 1, 1)
    row.name:SetWidth(textW)
    local r, g, b = 1, 1, 1
    if base.quality then r, g, b = GetItemQualityColor(base.quality) end
    row.sub:SetText(base.name or "")
    row.sub:ClearAllPoints()
    row.sub:SetPoint("TOPLEFT", row, "TOPLEFT", SET_X, -17)
    row.sub:SetTextColor(r, g, b)
    row.sub:SetWidth(textW)
    row.sub:Show()
    for i = 1, n do
        local data = entry.cells[i]
        local cell = getCell(row, i)
        cell:ClearAllPoints()
        cell:SetWidth(ws[i] - CELL_GAP)
        cell:SetPoint("RIGHT", row, "RIGHT", -spanOf(ws, i + 1, n), 0)
        if data then fillCell(cell, data) else cell:Hide() end
    end
end
local function fillDiv(row, entry)
    clearRow(row)
    row:EnableMouse(false)
    row.divText:Show()
    row.divText:SetText(entry.label or "")
    row.divLine:Show()
end
local function placeGoods(data, x, y, w, h, odd, div, look)
    local g = goodsPool:Acquire()
    g:SetWidth(w)
    g:SetHeight(h)
    g:ClearAllPoints()
    g:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, y)
    ns.GoodsSet(g, data, {
        odd = odd,
        div = div,
        level = look.level,
        qualityName = look.qualityName,
        qualityFrame = look.qualityFrame,
        qualityGlow = look.qualityGlow,
        repCaption = look.repCaption,
        subHidden = qbar and qbar:IsShown() and qbar.row == g,
    })
end
local function scrollToTop()
    FauxScrollFrame_SetOffset(scroll, 0)
    _G[NAME .. "ScrollScrollBar"]:SetValue(0)
end
local function setTab(tab)
    state.tab = tab
    for key, btn in pairs(tabs) do
        btn.selected = key == tab
        if btn.selected then PanelTemplates_SelectTab(btn) else PanelTemplates_DeselectTab(btn) end
        ns.Theme.RefreshTab(btn)
    end
    scrollToTop()
    Refresh()
end
local function sizeTab(btn, text)
    btn:SetText(text)
    local w = math.ceil(_G[btn:GetName() .. "Text"]:GetStringWidth()) + 40
    if w < TAB_MIN_W then w = TAB_MIN_W end
    PanelTemplates_TabResize(btn, 0, w)
    ns.Theme.RefreshTab(btn)
end
local function doRefresh()
    local src, missing
    if state.tab == "goods" then
        src, missing = ns.List.Scan()
        ns.Chain.Mark(src)
        updateWallet(src)
    else
        src = ns.List.Buyback()
        updateWallet(nil)
    end
    local usableOnly = state.tab == "goods" and ns.DB().usableOnly
    local list = ns.List.Filter(src, state.query, usableOnly, state.filtered)
    if state.tab == "goods" then
        ns.Groups.MarkMine(list)
        list = ns.Filter.Apply(list, state.shown)
    end
    local cols = state.cols
    local seq = state.seq
    local mode = "plain"
    if state.tab == "goods" then
        mode = select(2, ns.Groups.Build(list, state.collapsed, seq, state.tiles))
    else
        wipe(seq)
        ns.Groups.Plain(list, seq, state.tiles)
    end
    local tiers = maxTiers(seq)
    local wide = tiers > 0
    state.wide = wide
    state.mode = mode
    local flowCols, rowW = cols, COL_DEF
    state.cellWs = nil
    if wide then
        local total = listWidth(cols)
        flowCols = matrixCols(total, tiers)
        rowW = math.floor((total - (flowCols - 1) * COL_GAP) / flowCols)
        state.cellWs = cellFit(seq, tiers, rowW)
    end
    for i, line in ipairs(colLines) do
        if i < flowCols then
            line:ClearAllPoints()
            line:SetPoint("TOP", listArea, "TOPLEFT", i * (rowW + COL_GAP) - COL_GAP / 2, 0)
            line:SetPoint("BOTTOM", listArea, "BOTTOMLEFT", i * (rowW + COL_GAP) - COL_GAP / 2, 0)
            line:Show()
        else
            line:Hide()
        end
    end
    local listH = state.rows * ROW_H
    local columns, flowH = ns.Groups.Flow(seq, flowCols, entryH, state.flow, listH)
    state.flow = columns
    state.lines = math.ceil(flowH / ROW_H)
    FauxScrollFrame_Update(scroll, math.ceil(flowH / UNIT), math.floor(listH / UNIT), UNIT)
    placeList()
    local offset = (FauxScrollFrame_GetOffset(scroll) or 0) * UNIT
    rowPool:Reset()
    goodsPool:Reset()
    local look = {
        level = not ns.Filter.Get("hideLevel"),
        qualityName = ns.Filter.Get("qualityName"),
        qualityFrame = ns.Filter.Get("qualityFrame"),
        qualityGlow = ns.Filter.Get("qualityGlow"),
        repCaption = mode ~= "rep",
    }
    for c, column in ipairs(columns) do
        local x = (c - 1) * (rowW + COL_GAP)
        local tiers, n = nil, 0
        for _, entry in ipairs(column) do
            if entry.kind == "head" then tiers = entry.tiers end
            local top = entry.y - offset
            local visible = top + entry.h > 0 and top < listH
            if entry.kind == "item" or entry.kind == "pair" then
                n = n + 1
                if visible then
                    local tile = entry.kind == "pair"
                    local w = tile and math.floor((rowW - TILE_GAP) / 2) or rowW
                    placeGoods(entry.row or entry.a, x, -top, w, entry.h, n % 2 == 1, entry.div, look)
                    if tile and entry.b then
                        placeGoods(entry.b, x + w + TILE_GAP, -top, w, entry.h, n % 2 == 1, entry.div, look)
                    end
                end
            elseif visible then
                local row = rowPool:Acquire()
                row:SetWidth(rowW)
                row:SetHeight(entry.h)
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", canvas, "TOPLEFT", x, -top)
                if entry.kind == "head" then
                    fillHead(row, entry)
                elseif entry.kind == "div" then
                    fillDiv(row, entry)
                else
                    n = n + 1
                    fillSet(row, entry, tiers)
                    if n % 2 == 1 then row.oddTex:Show() else row.oddTex:Hide() end
                end
            end
        end
    end
    rowPool:HideExtras()
    goodsPool:HideExtras()
    if #seq == 0 then
        if state.tab == "buyback" then
            emptyText:SetText(T("emptyBuyback"))
        elseif #src == 0 then
            emptyText:SetText(T("emptyGoods"))
        elseif state.query == "" and ns.Filter.Count() > 0 then
            emptyText:SetText(T("emptyFilter"))
        else
            emptyText:SetText(T("emptySearch"))
        end
        emptyText:Show()
    else
        emptyText:Hide()
    end
    local nBuyback = GetNumBuybackItems() or 0
    sizeTab(tabs.buyback, T("tabBuyback") .. (nBuyback > 0 and (" " .. nBuyback) or ""))
    updateMoney()
    updateRepair()
    updateJunk()
    ns.RefreshFilterButton()
    if missing and state.retryLeft > 0 then
        state.retryLeft = state.retryLeft - 1
        state.retryAt = GetTime() + RETRY_AFTER
    end
end
Refresh = function()
    if not frame or not frame:IsShown() then return end
    local ok, err = pcall(doRefresh)
    if not ok and err ~= state.lastError then
        state.lastError = err
        ns.say(err)
    end
end
function ns.RefreshWindow()
    Refresh()
end
function ns.DiagMode()
    if frame then
        ns.say(("frame shown=%s w=%d h=%d scale=%.2f left=%s top=%s"):format(
            tostring(frame:IsShown()), frame:GetWidth(), frame:GetHeight(), frame:GetScale(),
            tostring(frame:GetLeft()), tostring(frame:GetTop())))
    end
    if frame and frame.chrome then
        local c = frame.chrome
        ns.say(("head: screen=%d frameTop=%s tabTop=%s tabW=%d title=%s"):format(
            math.floor(GetScreenHeight()), tostring(frame:GetTop()), tostring(c.tabL:GetTop()),
            c.tabM:GetWidth(), tostring(c.title:GetText())))
        ns.say(("search left=%s w=%d | tools right=%s"):format(
            tostring(search:GetLeft()), search:GetWidth(), tostring(colMore and colMore:GetRight())))
    end
    if state.lastError then ns.say("ERR: " .. tostring(state.lastError)) end
    if not frame or not frame:IsShown() then
        ns.say(T("diagNoMerchant"))
        return
    end
    local list = ns.List.Scan()
    ns.Groups.MarkMine(list)
    ns.Groups.MarkPay(list)
    local worn = ns.Groups.MarkStale(list)
    local c = ns.Groups.Counts(list)
    ns.say(T("diagMode", ns.Groups.Mode(list), c.n, c.set, c.recipe, c.gear, c.mine, c.noInfo))
    ns.say(T("diagMode2", tostring(c.topType), c.topCount, c.topSubs, c.prod, c.desc, c.named, c.bodies))
    ns.say(T("diagWorn", worn and math.floor(worn) or -1, c.stale))
    for i = 1, math.min(3, #list) do
        local r = list[i]
        local p = r.prod
        ns.say(("%d. %s | %s / %s / %s | prod=%s%s | desc=%s | swap=%s | diet=%s"):format(
            i, tostring(r.name), tostring(r.itemType), tostring(r.subType), tostring(r.equipSlot),
            tostring(r.prodName),
            p and (" -> " .. tostring(p.itemType) .. " / " .. tostring(p.subType)) or "",
            tostring(r.desc), tostring(r.swap), tostring(r.diet)))
    end
end
function ns.DiagDump()
    if not frame or not frame:IsShown() then
        ns.say(T("diagNoMerchant"))
        return
    end
    local list = ns.List.Scan()
    ns.Groups.MarkMine(list)
    ns.Groups.MarkPay(list)
    local worn = ns.Groups.MarkStale(list)
    local c = ns.Groups.Counts(list)
    local mode = ns.Groups.Mode(list)
    local dump = { who = state.who, title = state.npcTitle, mode = mode, worn = worn,
        zone = GetRealZoneText(), sub = GetSubZoneText(), when = date("%Y-%m-%d %H:%M"),
        player = UnitName("player"), class = select(2, UnitClass("player")),
        level = UnitLevel("player"), build = ns.VERSION,
        counts = {}, rows = {}, groups = {} }
    for k, v in pairs(c) do
        if type(v) ~= "table" then dump.counts[k] = v end
    end
    for i, r in ipairs(list) do
        local cost
        if r.cost then
            cost = { honor = r.cost.honor > 0 and r.cost.honor or nil,
                arena = r.cost.arena > 0 and r.cost.arena or nil, items = {} }
            for _, it in ipairs(r.cost.items) do
                cost.items[#cost.items + 1] = { n = it.n,
                    name = it.link and GetItemInfo(it.link) or nil,
                    id = it.link and tonumber(it.link:match("item:(%d+)")) or nil }
            end
        end
        dump.rows[i] = { id = r.id, name = r.name, type = r.itemType, sub = r.subType,
            slot = r.equipSlot, q = r.quality, ilvl = r.iLevel, minLevel = r.minLevel,
            set = r.set, enchant = r.enchant or nil, mine = r.mine or nil, known = r.known or nil,
            rep = r.repRank, faction = r.repFaction,
            prod = r.prodName, desc = r.desc, stat = r.stat, diet = r.diet, skill = r.skill,
            classes = r.classes, req = r.req, stale = r.stale or nil, swap = r.swap or nil,
            price = r.price, qty = r.quantity, stock = r.stock,
            usable = r.usable or nil, stack = GetMerchantItemMaxStack(r.index),
            cost = cost,
            tip = ns.Scan.Dump(r.index) }
    end
    if mode ~= "plain" then
        for _, g in ipairs(ns.Groups.Split(list, mode == "set" and "sub" or mode)) do
            local names = {}
            for _, r in ipairs(g.items) do names[#names + 1] = r.short or r.name end
            dump.groups[#dump.groups + 1] = { key = g.key, label = g.label, n = #g.items, items = names }
        end
    end
    local db = ns.DB()
    if type(db.dumps) ~= "table" then db.dumps = {} end
    local key = (dump.who or "?") .. (dump.title and (" / " .. dump.title) or "")
    local fresh = db.dumps[key] == nil
    db.dumps[key] = dump
    db.dump = dump
    local n = 0
    for _ in pairs(db.dumps) do n = n + 1 end
    ns.say(T(fresh and "chatDump" or "chatDumpAgain", #list, mode, n))
end
function ns.DiagDumpClear()
    local db = ns.DB()
    local n = 0
    if type(db.dumps) == "table" then
        for _ in pairs(db.dumps) do n = n + 1 end
    end
    db.dumps = {}
    db.dump = nil
    ns.say(T("chatDumpClear", n))
end
local function setToolEnabled(b, on)
    if on then b:Enable() else b:Disable() end
end
applyLayout = function(cols, nrows)
    local maxCols, maxRows = roomCols(), roomRows()
    local least = 1
    state.cols = math.max(least, math.min(maxCols, cols or state.cols))
    state.rows = math.max(MIN_ROWS, math.min(maxRows, nrows or state.rows))
    frame:SetMinResize(frameWidth(least), frameHeight(MIN_ROWS))
    frame:SetMaxResize(frameWidth(maxCols), frameHeight(maxRows))
    frame:SetWidth(frameWidth(state.cols))
    frame:SetHeight(frameHeight(state.rows))
    listArea:SetWidth(listWidth(state.cols))
    listArea:SetHeight(state.rows * ROW_H)
    if canvas then
        canvas:SetWidth(listArea:GetWidth())
        canvas:SetHeight(listArea:GetHeight())
    end
    if qbar then qbar:Hide() end
    if colMore then
        setToolEnabled(colMore, state.cols < maxCols)
        setToolEnabled(colLess, state.cols > least)
    end
    updateTitle()
    scrollToTop()
    Refresh()
end
local function applyScale(v)
    v = math.max(0.7, math.min(1.4, v))
    ns.DB().scale = v
    frame:SetScale(v)
    applyLayout(state.cols, state.rows)
end
rememberSize = function()
    local db = ns.DB()
    db.cols, db.rows = state.cols, state.rows
    if state.vendor and db.sizes then
        db.sizes[state.vendor] = { cols = state.cols, rows = state.rows }
    end
end
local function snapSize()
    local w, h = frame:GetWidth(), frame:GetHeight()
    local cols = math.floor((w - PAD * 2 - SCROLL_W + COL_GAP) / (COL_DEF + COL_GAP) + 0.5)
    local nrows = math.floor((h - LIST_TOP - footH) / ROW_H + 0.5)
    applyLayout(cols, nrows)
    rememberSize()
end
local function autoFit()
    local list = ns.List.Filter(ns.List.Scan(), nil, ns.DB().usableOnly, state.filtered)
    local scratch = {}
    local _, mode = ns.Groups.Build(list, state.collapsed, scratch, state.tiles)
    if maxTiers(scratch) > 0 then
        local tiers = maxTiers(scratch)
        local want = SET_X + NAME_FIT + TEXT_GAP + tiers * CELL_W
        local room = roomCols()
        local cols = 1
        while cols < room and listWidth(cols) < want do cols = cols + 1 end
        local need = needRows(scratch, matrixCols(listWidth(cols), tiers))
        while cols < room and need > FIT_ROWS do
            cols = cols + 1
            ns.Groups.Build(list, state.collapsed, scratch, state.tiles)
            need = needRows(scratch, matrixCols(listWidth(cols), tiers))
        end
        return cols, math.max(MIN_ROWS, math.min(roomRows(), need))
    end
    for cols = 1, FIT_COLS do
        ns.Groups.Build(list, state.collapsed, scratch, state.tiles)
        local need = needRows(scratch, cols)
        if need <= FIT_ROWS or cols == FIT_COLS then
            return cols, math.max(MIN_ROWS, math.min(roomRows(), need))
        end
    end
    return state.cols, state.rows
end
local function layoutForVendor()
    local db = ns.DB()
    local saved = state.vendor and db.sizes and db.sizes[state.vendor]
    if saved then
        applyLayout(saved.cols, saved.rows)
        return
    end
    local ok, cols, nrows = pcall(autoFit)
    if ok and cols then
        applyLayout(cols, nrows)
    else
        applyLayout(db.cols, db.rows)
    end
    rememberSize()
end
local function makeTab(i, key)
    local btn = CreateFrame("Button", NAME .. "Tab" .. i, frame, "CharacterFrameTabButtonTemplate")
    btn:SetID(i)
    btn:SetFrameStrata("LOW")
    btn:SetScript("OnShow", nil)
    btn:SetScript("OnClick", function() setTab(key) end)
    if i == 1 then
        btn:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 12, TAB_LIFT)
    else
        btn:SetPoint("LEFT", tabs[TAB_ORDER[i - 1]], "RIGHT", -8, 0)
    end
    ns.Theme.Tab(btn)
    tabs[key] = btn
    return btn
end
local function makeRepairButton(left, right, tipTitle, tipText, onClick)
    local btn = ns.Theme.IconButton(frame, BTN)
    btn.icon:SetTexture(REPAIR_ICONS)
    btn.icon:SetTexCoord(left, right, 0, 0.5625)
    btn:SetScript("OnClick", onClick)
    btn:SetScript("OnEnter", function(self) tipShow(self, T(tipTitle), T(tipText)) end)
    btn:SetScript("OnLeave", tipHide)
    return btn
end
local HEAD_X, HEAD_Y, HEAD_GAP = 18, 12, 4
local function makeGlyph(kind, titleKey, tipKey, onClick)
    local b = CreateFrame("Button", nil, frame)
    b:SetWidth(14)
    b:SetHeight(14)
    b:SetHighlightTexture(BTN_HILITE, "ADD")
    b:RegisterForClicks("LeftButtonUp")
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self) tipShow(self, T(titleKey), T(tipKey)) end)
    b:SetScript("OnLeave", tipHide)
    ns.Theme.Glyph(b, kind)
    return b
end
local function makeTool(tex, dx, tipKey, onClick)
    local b = CreateFrame("Button", nil, frame)
    b:SetWidth(16)
    b:SetHeight(16)
    b:SetPoint("TOPRIGHT", frame, "TOPRIGHT", dx, -11)
    b:SetNormalTexture(tex)
    b:SetDisabledTexture(tex)
    b:GetDisabledTexture():SetDesaturated(true)
    b:GetDisabledTexture():SetVertexColor(0.5, 0.5, 0.5)
    b:SetHighlightTexture(BTN_HILITE, "ADD")
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", onClick)
    b:SetScript("OnEnter", function(self) tipShow(self, T(tipKey)) end)
    b:SetScript("OnLeave", tipHide)
    return b
end
local function buildQty()
    qbar = CreateFrame("Frame", nil, canvas)
    qbar:SetHeight(14)
    qbar:EnableMouse(true)
    qbar:Hide()
    qbar.buttons = {}
    for i, n in ipairs(QTY) do
        local b = ns.Theme.Chip(qbar, "x" .. n)
        b:SetScript("OnClick", function()
            local row = qbar.row
            qbar:Hide()
            if row then askBuy(row.data, n) end
        end)
        qbar.buttons[i] = b
    end
    qbar:SetScript("OnUpdate", function(self)
        if not self.row or not (mouseInside(self) or mouseInside(self.row)) then
            self:Hide()
        end
    end)
    qbar:SetScript("OnHide", function(self)
        ns.GoodsQty(self.row, false)
        self.row = nil
    end)
    goodsPool = ns.NewPool(function() return ns.MakeGoods(canvas, bindGoods) end, ns.GoodsReset)
end
updateView = function()
    if not viewGlyph then return end
    ns.Theme.Glyph(viewGlyph, state.tiles and "tiles" or "rows")
end
local function buildChrome()
    frame = CreateFrame("Frame", NAME, UIParent)
    frame:SetWidth(frameWidth(state.cols))
    frame:SetHeight(frameHeight(state.rows))
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
    frame:EnableMouse(true)
    frame:SetToplevel(true)
    frame:SetResizable(true)
    frame:SetMinResize(frameWidth(1), frameHeight(MIN_ROWS))
    frame:SetMaxResize(frameWidth(roomCols()), frameHeight(roomRows()))
    frame:Hide()
    UIPanelWindows[NAME] = { area = "left", pushable = 0 }
    ns.Theme.Chrome(frame)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    makeTool(PLUS, -44, "tipScale", function(self, button)
        if button == "RightButton" then applyScale(1) else applyScale((ns.DB().scale or 1) + 0.05) end
    end)
    makeTool(MINUS, -62, "tipScale", function(self, button)
        if button == "RightButton" then applyScale(1) else applyScale((ns.DB().scale or 1) - 0.05) end
    end)
    colMore = makeTool(PAGE_NEXT, -86, "tipCols", function()
        applyLayout(state.cols + 1, state.rows)
        rememberSize()
    end)
    colLess = makeTool(PAGE_PREV, -104, "tipCols", function()
        applyLayout(state.cols - 1, state.rows)
        rememberSize()
    end)
    filterGlyph = makeGlyph("filter", "filterBtn", "tipFilter", function(self)
        ns.Filters.Toggle(frame, self)
    end)
    filterGlyph:SetPoint("TOPLEFT", frame, "TOPLEFT", HEAD_X, -HEAD_Y)
    viewGlyph = makeGlyph("rows", "viewHead", "tipView", function()
        local db = ns.DB()
        db.tiles = not state.tiles
        state.tiles = db.tiles
        updateView()
        applyLayout(state.cols, state.rows)
        Refresh()
    end)
    viewGlyph:SetPoint("LEFT", filterGlyph, "RIGHT", HEAD_GAP, 0)
    colLess:ClearAllPoints()
    colLess:SetPoint("LEFT", viewGlyph, "RIGHT", HEAD_GAP * 2, 0)
    colLess:SetWidth(14)
    colLess:SetHeight(14)
    colMore:ClearAllPoints()
    colMore:SetPoint("LEFT", colLess, "RIGHT", 1, 0)
    colMore:SetWidth(14)
    colMore:SetHeight(14)
    search = CreateFrame("EditBox", NAME .. "Search", frame, "InputBoxTemplate")
    search:SetWidth(140)
    search:SetHeight(20)
    search:SetPoint("LEFT", colMore, "RIGHT", HEAD_GAP * 2, 0)
    search:SetAutoFocus(false)
    search:SetMaxLetters(60)
    searchHint = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchHint:SetPoint("LEFT", search, "LEFT", 2, 0)
    local function hintUpdate()
        if search:GetText() == "" and not search:HasFocus() then searchHint:Show() else searchHint:Hide() end
    end
    search:SetScript("OnTextChanged", function(self)
        state.query = self:GetText() or ""
        hintUpdate()
        scrollToTop()
        Refresh()
    end)
    search:SetScript("OnEditFocusGained", hintUpdate)
    search:SetScript("OnEditFocusLost", hintUpdate)
    search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
end
placeList = function()
    if not listArea then return end
    local bar = _G[NAME .. "ScrollScrollBar"]
    local free = (bar and bar:IsShown()) and 0 or math.floor(SCROLL_W / 2)
    listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD + free, -LIST_TOP)
end
local function buildList()
    listArea = CreateFrame("Frame", nil, frame)
    listArea:SetWidth(listWidth(state.cols))
    listArea:SetHeight(state.rows * ROW_H)
    if canvas then
        canvas:SetWidth(listArea:GetWidth())
        canvas:SetHeight(listArea:GetHeight())
    end
    listArea:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -LIST_TOP)
    scroll = CreateFrame("ScrollFrame", NAME .. "Scroll", listArea, "FauxScrollFrameTemplate")
    scroll:SetAllPoints(listArea)
    scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, UNIT, Refresh)
    end)
    local clip = CreateFrame("ScrollFrame", nil, listArea)
    clip:SetAllPoints(listArea)
    canvas = CreateFrame("Frame", nil, clip)
    canvas:SetWidth(listArea:GetWidth())
    canvas:SetHeight(listArea:GetHeight())
    clip:SetScrollChild(canvas)
    rowPool = ns.NewPool(makeRow, resetRow)
    local bar = _G[NAME .. "ScrollScrollBar"]
    bar:ClearAllPoints()
    bar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 2, -16)
    bar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", 2, 16)
    for i = 1, MAX_COLS - 1 do
        local line = listArea:CreateTexture(nil, "ARTWORK")
        line:SetTexture(WHITE)
        line:SetVertexColor(1, 1, 1, 0.10)
        line:SetWidth(1)
        line:SetPoint("TOP", listArea, "TOPLEFT", i * (COL_DEF + COL_GAP) - COL_GAP / 2, 0)
        line:SetPoint("BOTTOM", listArea, "BOTTOMLEFT", i * (COL_DEF + COL_GAP) - COL_GAP / 2, 0)
        line:Hide()
        colLines[i] = line
    end
    ruler = listArea:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    ruler:SetPoint("TOPLEFT", listArea, "TOPLEFT", 0, 0)
    ruler:SetAlpha(0)
    emptyText = listArea:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    emptyText:SetPoint("CENTER", listArea, "CENTER", 0, 0)
    emptyText:Hide()
    buildQty()
end
local function buildFoot()
    footLine = frame:CreateTexture(nil, "ARTWORK")
    footLine:SetTexture(WHITE)
    footLine:SetVertexColor(1, 1, 1, 0.10)
    footLine:SetHeight(1)
    moneyBtn = CreateFrame("Button", nil, frame)
    moneyBtn:SetHeight(20)
    moneyBtn:SetWidth(80)
    moneyBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -PAD - 14, FOOT_Y)
    moneyBtn:SetScript("OnEnter", moneyEnter)
    moneyBtn:SetScript("OnLeave", tipHide)
    moneyText = moneyBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    moneyText:SetAllPoints(moneyBtn)
    moneyText:SetJustifyH("RIGHT")
    hammerBtn = makeRepairButton(0, 0.28125, "repairItem", "tipRepairItem", function()
        if InRepairMode() then HideRepairCursor() else ShowRepairCursor() end
    end)
    repairBtn = makeRepairButton(0.5625, 0.84375, "repairAll", "tipRepairAll", function()
        RepairAllItems()
        PlaySound("ITEM_REPAIR")
    end)
    repairBtn:SetPoint("LEFT", hammerBtn, "RIGHT", FOOT_GAP, 0)
    guildBtn = makeRepairButton(0.28125, 0.5625, "repairGuild", "tipRepairGuild", function()
        RepairAllItems(1)
        PlaySound("ITEM_REPAIR")
    end)
    guildBtn:SetPoint("LEFT", repairBtn, "RIGHT", FOOT_GAP, 0)
    repairText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    repairText:SetPoint("LEFT", guildBtn, "RIGHT", FOOT_GAP, 0)
    junkBtn = ns.Theme.IconButton(frame, BTN)
    junkBtn.icon:SetTexture(COIN_ICON)
    junkBtn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    junkBtn:SetScript("OnClick", function()
        ns.Junk.Sell()
        updateJunk()
    end)
    junkBtn:SetScript("OnEnter", junkEnter)
    junkBtn:SetScript("OnLeave", tipHide)
    junkBtn:Hide()
    junkText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    junkText:SetPoint("LEFT", junkBtn, "RIGHT", FOOT_GAP, 0)
    junkText:Hide()
    grip = CreateFrame("Button", nil, frame)
    grip:SetWidth(16)
    grip:SetHeight(16)
    grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -4, 4)
    local gripTex = grip:CreateTexture(nil, "OVERLAY")
    gripTex:SetAllPoints(grip)
    gripTex:SetTexture(GRIP)
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        snapSize()
    end)
    grip:SetScript("OnEnter", function(self)
        gripTex:SetVertexColor(1, 0.9, 0.5)
        tipShow(self, T("tipGrip"))
    end)
    grip:SetScript("OnLeave", function()
        gripTex:SetVertexColor(1, 1, 1)
        tipHide()
    end)
    placeFoot()
end
local function onMerchantShow(self)
    if not ns.Enabled() then return end
    local db = ns.DB()
    state.tiles = db.tiles ~= false
    updateView()
    sizeTab(tabs.goods, T("tabGoods"))
    sizeTab(tabs.buyback, T("tabBuyback"))
    searchHint:SetText(T("search"))
    ns.Scan.Reset()
    ns.Have.Forget()
    wipe(state.collapsed)
    local who = UnitName("NPC")
    state.vendor = who
    state.who = who
    state.npcTitle = ns.Scan.NpcTitle()
    search:SetText("")
    state.query = ""
    state.retryLeft = RETRY_MAX
    do
        local scratch = {}
        local list = ns.List.Filter(ns.List.Scan(), nil, db.usableOnly, state.filtered)
        state.mode = select(2, ns.Groups.Build(list, state.collapsed, scratch, state.tiles))
    end
    ns.Theme.Apply()
    applyScale(db.scale or 1)
    layoutForVendor()
    ShowUIPanel(self)
    if not self:IsShown() then
        CloseMerchant()
        return
    end
    setTab("goods")
end
local function onEvent(self, event)
    if event == "MERCHANT_SHOW" then
        onMerchantShow(self)
    elseif event == "MERCHANT_UPDATE" then
        Refresh()
    elseif event == "MERCHANT_CLOSED" then
        HideUIPanel(self)
    elseif event == "PLAYER_MONEY" or event == "CURRENCY_DISPLAY_UPDATE" then
        Refresh()
    elseif event == "BAG_UPDATE" then
        if self:IsShown() then
            updateJunk()
            Refresh()
        end
    elseif event == "UNIT_INVENTORY_CHANGED" then
        Refresh()
    end
end
local function buildEvents()
    frame:SetScript("OnReceiveDrag", function() sellCursorItem(0) end)
    frame:SetScript("OnShow", function()
        state.backpackWasOpen = OpenBackpack()
        PlaySound("igCharacterInfoOpen")
    end)
    frame:SetScript("OnHide", function()
        CloseMerchant()
        if not state.backpackWasOpen then CloseBackpack() end
        search:ClearFocus()
        ResetCursor()
        if InRepairMode() then HideRepairCursor() end
        StaticPopup_Hide("CONFIRM_PURCHASE_TOKEN_ITEM")
        StaticPopup_Hide("CONFIRM_HIGH_COST_ITEM")
        ns.ConfirmHide()
        ns.Filters.Hide()
        if qbar then qbar:Hide() end
        MerchantFrame.extendedCost = nil
        state.retryAt = nil
        PlaySound("igCharacterInfoClose")
    end)
    frame:SetScript("OnUpdate", function()
        if state.retryAt and GetTime() >= state.retryAt then
            state.retryAt = nil
            Refresh()
        end
    end)
    frame:RegisterEvent("MERCHANT_SHOW")
    frame:RegisterEvent("MERCHANT_UPDATE")
    frame:RegisterEvent("MERCHANT_CLOSED")
    frame:RegisterEvent("PLAYER_MONEY")
    frame:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
    frame:RegisterEvent("BAG_UPDATE")
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    frame:SetScript("OnEvent", function(self, event)
        local ok, err = pcall(onEvent, self, event)
        if not ok then
            state.lastError = err
            ns.say("ERR " .. event .. ": " .. tostring(err))
        end
    end)
end
local function build()
    buildChrome()
    buildList()
    buildFoot()
    for i, key in ipairs(TAB_ORDER) do makeTab(i, key) end
    buildEvents()
end
ns.OnReady(build)
