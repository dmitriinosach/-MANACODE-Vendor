local ADDON, ns = ...
local PAD = 4
local ICON_GAP = 6
local TEXT_GAP = 10
local PRICE_MIN, PRICE_MAX = 38, 190
local WIDE_MIN = 220
local LINE = 13
local NAME_TOP = 4
local TALL = 40
local HEIRLOOM = 7
local LEVEL_FROM = 3
local GLOW_QUALITY = { [2] = true, [3] = true, [4] = true, [5] = true, [7] = true }
local GOLD = { 1, 0.82, 0 }
local SUB_BOTTOM = 3
local SUB_MIN = 46
local WHITE = "Interface\\Buttons\\WHITE8X8"
local GREY = "|cffb0b0b0"
local SKY = "|cff9dd0ff"
local WARN = "|cffd06a6a"
local MINE = "|cff8fc47c"
local RIDE = {
    [75] = { 60, false }, [150] = { 100, false },
    [225] = { 150, true }, [300] = { 280, true },
}
local function T(...) return ns.T(...) end
local function mountLine(data)
    local misc = ns.Groups.Misc()
    if not misc or not data.subType or data.subType ~= misc.mount then return nil end
    local r = data.skill and RIDE[data.skill]
    if not r then return nil end
    return T(r[2] and "mountFly" or "mountGround", r[1])
end
function ns.MakeGoods(parent, bind)
    local g = CreateFrame("Button", nil, parent)
    g:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    g:RegisterForDrag("LeftButton")
    ns.Theme.Host(g, false)
    g.item = ns.MakeItem(g, 24)
    g.item:SetPoint("LEFT", g, "LEFT", PAD, 0)
    g.divTex = g:CreateTexture(nil, "OVERLAY")
    g.divTex:SetTexture(WHITE)
    g.divTex:SetVertexColor(1, 0.82, 0.35, 0.30)
    g.divTex:SetHeight(1)
    g.divTex:SetPoint("TOPLEFT", g, "TOPLEFT", 2, 0)
    g.divTex:SetPoint("TOPRIGHT", g, "TOPRIGHT", -2, 0)
    g.divTex:Hide()
    g.name = g:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    g.name:SetJustifyH("LEFT")
    g.name:SetJustifyV("TOP")
    g.sub = g:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    g.sub:SetHeight(11)
    g.sub:SetJustifyH("LEFT")
    g.sub:SetTextColor(0.6, 0.6, 0.6)
    g.priceBox = ns.MakePrice(g, g)
    if bind then bind(g) end
    return g
end
function ns.GoodsQty(g, on)
    if not g or not g.sub then return end
    if on then
        g.sub:Hide()
        if g.narrow then g.priceBox:Hide() end
    else
        g.sub:Show()
        g.priceBox:Show()
    end
end
local sub = {}
local function subLine(data, opts, haveN)
    wipe(sub)
    if data.quality == HEIRLOOM then
        sub[#sub + 1] = GREY .. (ITEM_QUALITY7_DESC or "") .. "|r"
    elseif opts.level ~= false and (data.quality or 0) >= LEVEL_FROM
        and data.equipSlot and data.equipSlot ~= "" and data.iLevel and data.iLevel > 0 then
        sub[#sub + 1] = GREY .. T("ilvl", data.iLevel) .. "|r"
    end
    local mount = mountLine(data)
    if mount then sub[#sub + 1] = SKY .. mount .. "|r" end
    if data.known then sub[#sub + 1] = ITEM_SPELL_KNOWN end
    if haveN and haveN > 0 then sub[#sub + 1] = MINE .. T("haveN", haveN) .. "|r" end
    if opts.repCaption and data.repRank and not data.req then
        sub[#sub + 1] = GREY .. (_G["FACTION_STANDING_LABEL" .. data.repRank] or "") .. "|r"
    end
    if data.req then
        sub[#sub + 1] = WARN .. data.req .. "|r"
    elseif not data.usable then
        sub[#sub + 1] = WARN .. T("notUsable") .. "|r"
    end
    return table.concat(sub, "  ")
end
local function layout(g, pw)
    local w, h = g:GetWidth(), g:GetHeight()
    local icon = h >= TALL and 30 or 24
    ns.ItemStyle(g.item, icon)
    local textX = PAD + icon + ICON_GAP
    g.narrow = w < WIDE_MIN
    g.name:ClearAllPoints()
    g.name:SetPoint("TOPLEFT", g, "TOPLEFT", textX, -NAME_TOP)
    g.sub:ClearAllPoints()
    g.priceBox:ClearAllPoints()
    if not g.narrow then
        if pw < PRICE_MIN then pw = PRICE_MIN end
        if pw > PRICE_MAX then pw = PRICE_MAX end
        local textW = w - textX - pw - TEXT_GAP
        g.name:SetHeight(LINE)
        g.name:SetWidth(textW)
        g.sub:SetPoint("TOPLEFT", g, "TOPLEFT", textX, -(NAME_TOP + LINE))
        g.sub:SetWidth(textW)
        g.priceBox:SetPoint("RIGHT", g, "RIGHT", -8, 0)
        g.qtyX, g.qtyY = textX, -(NAME_TOP + LINE - 2)
        return
    end
    local nameW = w - textX - PAD
    g.name:SetWidth(nameW)
    local lines = (h >= TALL and g.name:GetStringWidth() > nameW) and 2 or 1
    g.name:SetHeight(lines * LINE)
    g.sub:SetPoint("BOTTOMLEFT", g, "BOTTOMLEFT", textX, SUB_BOTTOM)
    local subW = w - textX - pw - PAD * 2
    if subW < SUB_MIN then
        g.sub:SetText("")
        subW = SUB_MIN
    end
    g.sub:SetWidth(subW)
    g.priceBox:SetPoint("BOTTOMRIGHT", g, "BOTTOMRIGHT", -PAD, SUB_BOTTOM - 5)
    g.qtyX, g.qtyY = textX, -(h - SUB_BOTTOM - 13)
end
function ns.GoodsSet(g, data, opts)
    opts = opts or {}
    g.data = data
    g:SetID(data.index)
    g.link = data.link
    g.texture = data.tex
    g.price = data.price
    g.count = data.quantity
    g.extendedCost = data.cost and true or nil
    if opts.odd then g.oddTex:Show() else g.oddTex:Hide() end
    if opts.div then g.divTex:Show() else g.divTex:Hide() end
    local mine, haveN = ns.Have.Mark(data)
    ns.ItemSet(g.item, data.tex, {
        dim = data.stock == 0,
        tint = not data.usable,
        have = mine,
        count = data.quantity > 1 and data.quantity or nil,
        stock = data.stock >= 0 and data.stock or nil,
        quality = GLOW_QUALITY[data.quality or 0] and data.quality or nil,
        frame = opts.qualityFrame,
        glow = opts.qualityGlow,
    })
    local r, b, c = GOLD[1], GOLD[2], GOLD[3]
    if opts.qualityName and data.quality then r, b, c = GetItemQualityColor(data.quality) end
    if data.stock == 0 or data.known then r, b, c = 0.5, 0.5, 0.5 end
    g.name:SetText(data.short or data.name or "")
    g.name:SetTextColor(r, b, c)
    g.name:Show()
    g.sub:SetText(subLine(data, opts, not mine and haveN or nil))
    local pw = ns.PriceSet(g.priceBox, data, { noGear = opts.noGear }) + 4
    layout(g, pw)
    ns.GoodsQty(g, opts.subHidden)
end
function ns.GoodsReset(g)
    g.data = nil
    g:SetID(0)
    g:EnableMouse(true)
    g.hlTex:Show()
    ns.ItemReset(g.item)
end
