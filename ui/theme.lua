local ADDON, ns = ...
local Theme = {}
ns.Theme = Theme
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BORDER = "Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
local TITLE_BG = "Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
local MARBLE = "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1"
local TAB_ON = "Interface\\PaperDollInfoFrame\\UI-Character-ActiveTab"
local TIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local SLOT = "Interface\\Buttons\\UI-Quickslot2"
local HILITE = "Interface\\QuestFrame\\UI-QuestTitleHighlight"
local PRESSED = "Interface\\Buttons\\UI-Quickslot-Depress"
local BTN_HILITE = "Interface\\Buttons\\ButtonHilight-Square"
local HAVE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local GLOW = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SCALE, GLOW_ALPHA = 1.8, 0.5
local DARK_LUM, LIFT = 0.5, 0.35
local HAVE_SCALE = 0.45
local PLUS = "Interface\\Buttons\\UI-PlusButton-Up"
local MINUS = "Interface\\Buttons\\UI-MinusButton-Up"
local K = 1.25
local CORNER = 64
local PIECES = {
    tl = { 0.501953125, 0.625 }, tr = { 0.625, 0.75 }, t = { 0.25, 0.369140625 },
    bl = { 0.751953125, 0.875 }, br = { 0.875, 1 }, b = { 0.376953125, 0.498046875 },
    l = { 0.001953125, 0.125 }, r = { 0.1171875, 0.2421875 },
}
local MARBLE_COORD = { 0.255, 1, 0.29, 1 }
local TAB_CAP, TAB_H = 20, 32
local TAB_L, TAB_R = 0.15625, 0.84375
local SLOT_COORD = { 0.1875, 0.796875 }
local BOTTOM_TAB_H = 26
local TAB_RAISE = 5
local SKINS = { vanilla = true, flat = true }
local widgets = {}
function Theme.Name()
    local db = ns.DB and ns.DB()
    local t = db and db.theme
    return SKINS[t] and t or "vanilla"
end
function Theme.Known(name)
    return SKINS[name] and true or false
end
local function vanilla()
    return Theme.Name() == "vanilla"
end
local function register(fn, obj)
    widgets[#widgets + 1] = { fn = fn, obj = obj }
    fn(obj)
end
function Theme.Apply()
    for _, w in ipairs(widgets) do w.fn(w.obj) end
end
local function skinChrome(frame)
    local c = frame.chrome
    if vanilla() then
        frame:SetBackdrop(nil)
        for key, tex in pairs(c.pieces) do
            tex:Show()
            tex:SetTexture(BORDER)
            tex:SetTexCoord(PIECES[key][1], PIECES[key][2], 0, 1)
        end
        c.band:Show()
        c.band:SetTexture(TITLE_BG)
        c.bg:Show()
        c.bg:SetTexture(MARBLE)
        c.bg:SetTexCoord(MARBLE_COORD[1], MARBLE_COORD[2], MARBLE_COORD[3], MARBLE_COORD[4])
        c.tabL:Show()
        c.tabR:Show()
        c.tabL:SetTexture(TAB_ON)
        c.tabL:SetTexCoord(0, TAB_L, 1, 0)
        c.tabM:SetTexture(TAB_ON)
        c.tabM:SetTexCoord(TAB_L, TAB_R, 1, 0)
        c.tabM:SetVertexColor(1, 1, 1, 1)
        c.tabR:SetTexture(TAB_ON)
        c.tabR:SetTexCoord(TAB_R, 1, 1, 0)
    else
        frame:SetBackdrop({
            bgFile = WHITE, edgeFile = TIP_EDGE, tile = false, edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 },
        })
        frame:SetBackdropColor(0.07, 0.07, 0.09, 1)
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5)
        for _, tex in pairs(c.pieces) do tex:Hide() end
        c.band:Hide()
        c.bg:Hide()
        c.tabL:Hide()
        c.tabR:Hide()
        c.tabM:SetTexture(WHITE)
        c.tabM:SetTexCoord(0, 1, 0, 1)
        c.tabM:SetVertexColor(0.07, 0.07, 0.09, 1)
    end
end
function Theme.Chrome(frame)
    local c = { pieces = {} }
    for key in pairs(PIECES) do c.pieces[key] = frame:CreateTexture(nil, "OVERLAY") end
    local p = c.pieces
    local big = CORNER * K
    p.tl:SetWidth(big); p.tl:SetHeight(big); p.tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    p.tr:SetWidth(big); p.tr:SetHeight(big); p.tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    p.t:SetHeight(big)
    p.t:SetPoint("TOPLEFT", p.tl, "TOPRIGHT", 0, 0)
    p.t:SetPoint("TOPRIGHT", p.tr, "TOPLEFT", 0, 0)
    p.bl:SetWidth(big); p.bl:SetHeight(big); p.bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    p.br:SetWidth(big); p.br:SetHeight(big); p.br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    p.b:SetHeight(big)
    p.b:SetPoint("BOTTOMLEFT", p.bl, "BOTTOMRIGHT", 0, 0)
    p.b:SetPoint("BOTTOMRIGHT", p.br, "BOTTOMLEFT", 0, 0)
    p.l:SetWidth(big)
    p.l:SetPoint("TOPLEFT", p.tl, "BOTTOMLEFT", 0, 0)
    p.l:SetPoint("BOTTOMLEFT", p.bl, "TOPLEFT", 0, 0)
    p.r:SetWidth(big)
    p.r:SetPoint("TOPRIGHT", p.tr, "BOTTOMRIGHT", 0, 0)
    p.r:SetPoint("BOTTOMRIGHT", p.br, "TOPRIGHT", 0, 0)
    c.band = frame:CreateTexture(nil, "BORDER")
    c.band:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -7 * K)
    c.band:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -7 * K)
    c.band:SetHeight(17 * K)
    c.bg = frame:CreateTexture(nil, "BORDER")
    c.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -24 * K)
    c.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 8)
    c.tabL = frame:CreateTexture(nil, "BACKGROUND")
    c.tabL:SetWidth(TAB_CAP); c.tabL:SetHeight(TAB_H)
    c.tabL:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 14, -8)
    c.tabM = frame:CreateTexture(nil, "BACKGROUND")
    c.tabM:SetHeight(TAB_H)
    c.tabM:SetPoint("LEFT", c.tabL, "RIGHT", 0, 0)
    c.tabR = frame:CreateTexture(nil, "BACKGROUND")
    c.tabR:SetWidth(TAB_CAP); c.tabR:SetHeight(TAB_H)
    c.tabR:SetPoint("LEFT", c.tabM, "RIGHT", 0, 0)
    c.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    c.title:SetPoint("BOTTOMLEFT", c.tabL, "BOTTOMRIGHT", 0, 13)
    c.title:SetHeight(14)
    c.title:SetJustifyH("LEFT")
    frame.chrome = c
    register(skinChrome, frame)
    return c
end
function Theme.SetTitle(frame, name, sub, maxWidth)
    local c = frame.chrome
    c.title:SetWidth(0)
    c.title:SetText(name .. (sub and ("  |cff9a9a9a" .. sub .. "|r") or ""))
    local w = math.ceil(c.title:GetStringWidth()) + 6
    local cap = maxWidth - TAB_CAP * 2 - 14
    if w > cap then w = cap end
    if w < 40 then w = 40 end
    c.title:SetWidth(w)
    c.tabM:SetWidth(w)
end
local TAB_PARTS = { "Left", "Middle", "Right", "LeftDisabled", "MiddleDisabled", "RightDisabled" }
local function skinTab(btn)
    local name = btn:GetName()
    if vanilla() then
        btn:SetBackdrop(nil)
        for _, part in ipairs(TAB_PARTS) do
            local tex = _G[name .. part]
            local up = strfind(part, "Disabled", 1, true) and TAB_RAISE or 0
            tex:SetHeight(BOTTOM_TAB_H + up)
            tex:SetAlpha(1)
        end
    else
        for _, part in ipairs(TAB_PARTS) do _G[name .. part]:SetAlpha(0) end
        btn:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
        btn:SetBackdropBorderColor(0.13, 0.06, 0.06, 1)
        if btn.selected then
            btn:SetBackdropColor(0.48, 0.12, 0.12, 1)
        else
            btn:SetBackdropColor(0.30, 0.08, 0.08, 1)
        end
    end
    btn:SetHeight(BOTTOM_TAB_H)
end
function Theme.Tab(btn)
    register(skinTab, btn)
end
function Theme.RefreshTab(btn)
    skinTab(btn)
end
local FRAME_GOLD = { 0.9, 0.74, 0.32 }
local FRAME_OUT = 2
local function edgeFor(size)
    return math.max(5, math.floor(size / 4))
end
local function skinRow(row)
    row.slotTex:Hide()
    row.iconEdge:Hide()
    row.qualFrame:Show()
end
function Theme.Host(row, odd)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(WHITE)
    bg:SetVertexColor(1, 1, 1, 0.035)
    bg:SetAllPoints(row)
    if not odd then bg:Hide() end
    row.oddTex = bg
    row.hlTex = Theme.Highlight(row, row)
end
function Theme.Highlight(frame, over)
    local hl = frame:CreateTexture(nil, "HIGHLIGHT")
    hl:SetTexture(HILITE)
    hl:SetBlendMode("ADD")
    hl:SetAllPoints(over)
    return hl
end
function Theme.IconSize(row, size)
    row.slotTex:SetWidth(size + 6)
    row.slotTex:SetHeight(size + 6)
    if row.glowTex then
        row.glowTex:SetWidth(math.floor(size * GLOW_SCALE))
        row.glowTex:SetHeight(math.floor(size * GLOW_SCALE))
    end
    if row.haveTex then
        row.haveTex:SetWidth(math.floor(size * HAVE_SCALE))
        row.haveTex:SetHeight(math.floor(size * HAVE_SCALE))
    end
    if row.qualFrame then
        row.qualFrame:SetBackdrop({ edgeFile = TIP_EDGE, edgeSize = edgeFor(size) })
        local c = row.qualColor or FRAME_GOLD
        row.qualFrame:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    end
end
function Theme.Icon(row, icon, size)
    row.iconEdge = row:CreateTexture(nil, "BORDER")
    row.iconEdge:SetTexture(WHITE)
    row.iconEdge:SetVertexColor(0, 0, 0, 1)
    row.iconEdge:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    row.iconEdge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    row.glowTex = row:CreateTexture(nil, "OVERLAY")
    row.glowTex:SetTexture(GLOW)
    row.glowTex:SetBlendMode("ADD")
    row.glowTex:SetAlpha(GLOW_ALPHA)
    row.glowTex:SetPoint("CENTER", icon, "CENTER", 0, 0)
    row.glowTex:Hide()
    row.haveTex = row:CreateTexture(nil, "OVERLAY")
    row.haveTex:SetTexture(HAVE)
    row.haveTex:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 3, 3)
    row.haveTex:Hide()
    row.slotTex = row:CreateTexture(nil, "OVERLAY")
    row.slotTex:SetTexture(SLOT)
    row.slotTex:SetTexCoord(SLOT_COORD[1], SLOT_COORD[2], SLOT_COORD[1], SLOT_COORD[2])
    row.slotTex:SetPoint("CENTER", icon, "CENTER", 0, 0)
    row.slotTex:SetAlpha(0.8)
    row.qualFrame = CreateFrame("Frame", nil, row)
    row.qualFrame:SetFrameLevel(row:GetFrameLevel() + 2)
    row.qualFrame:SetPoint("TOPLEFT", icon, "TOPLEFT", -FRAME_OUT, FRAME_OUT)
    row.qualFrame:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", FRAME_OUT, -FRAME_OUT)
    Theme.IconSize(row, size or icon:GetWidth())
    row.qualFrame:Hide()
    row.haveTex:SetParent(row.qualFrame)
    Theme.IconSize(row, size or icon:GetWidth())
    register(skinRow, row)
end
function Theme.IconTint(row, r, g, b, frame, glow)
    if r and glow then
        row.glowTex:SetVertexColor(r, g, b)
        row.glowTex:Show()
    else
        row.glowTex:Hide()
    end
    row.qualColor = (r and frame) and { r, g, b } or nil
    local c = row.qualColor or FRAME_GOLD
    local fr, fg, fb = c[1], c[2], c[3]
    if row.qualColor and 0.3 * fr + 0.59 * fg + 0.11 * fb < DARK_LUM then
        fr, fg, fb = fr + (1 - fr) * LIFT, fg + (1 - fg) * LIFT, fb + (1 - fb) * LIFT
    end
    row.qualFrame:SetBackdropBorderColor(fr, fg, fb, 1)
end
function Theme.Row(row, icon, odd)
    Theme.Host(row, odd)
    Theme.Icon(row, icon)
end
function Theme.ShowIcon(row)
    skinRow(row)
end
local ROLES = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"
local ROLE_COORD = {
    heal = { 0.25, 0.5, 0, 0.25 },
    tank = { 0, 0.25, 0.25, 0.5 },
    dps = { 0.25, 0.5, 0.25, 0.5 },
}
function Theme.SetRole(row, role)
    local c = role and ROLE_COORD[role]
    if not c then
        row.roleTex:Hide()
        return
    end
    row.roleTex:SetTexture(ROLES)
    row.roleTex:SetTexCoord(c[1], c[2], c[3], c[4])
    row.roleTex:Show()
end
local function skinHead(row)
    if vanilla() then
        row.headBg:SetTexture(TITLE_BG)
        row.headBg:SetVertexColor(1, 1, 1, 1)
    else
        row.headBg:SetTexture(WHITE)
        row.headBg:SetVertexColor(1, 1, 1, 0.09)
    end
end
local EXP_SIZE = 16
local EXP_GROW = 2
local function expGrow(btn, on)
    local tex = btn:GetNormalTexture()
    if not tex then return end
    tex:ClearAllPoints()
    local d = on and EXP_GROW or 0
    tex:SetPoint("TOPLEFT", btn, "TOPLEFT", -d, d)
    tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", d, -d)
    tex:SetVertexColor(1, on and 0.92 or 1, on and 0.6 or 1)
end
local HEAD_BAR = 24
function Theme.HeadBar(row, lineH)
    local inset = math.max(2, math.floor((lineH - HEAD_BAR) / 2))
    row.headBg:ClearAllPoints()
    row.headBg:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -inset)
    row.headBg:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, inset)
end
function Theme.Head(row)
    row.headBg = row:CreateTexture(nil, "BACKGROUND")
    Theme.HeadBar(row, row:GetHeight())
    row.exp = CreateFrame("Button", nil, row)
    row.exp:SetWidth(EXP_SIZE)
    row.exp:SetHeight(EXP_SIZE)
    row.exp:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.exp:SetHighlightTexture(BTN_HILITE, "ADD")
    row.exp:SetScript("OnEnter", function(self) expGrow(self, true) end)
    row.exp:SetScript("OnLeave", function(self) expGrow(self, false) end)
    row.roleTex = row:CreateTexture(nil, "ARTWORK")
    row.roleTex:SetWidth(18)
    row.roleTex:SetHeight(18)
    row.roleTex:SetPoint("LEFT", row, "LEFT", 8, 0)
    row.roleTex:Hide()
    register(skinHead, row)
end
function Theme.SetExpander(row, collapsed)
    row.exp:SetNormalTexture(collapsed and PLUS or MINUS)
    expGrow(row.exp, false)
end
function Theme.Divider(row, textX)
    row.divText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.divText:SetPoint("LEFT", row, "LEFT", textX, 0)
    row.divText:SetJustifyH("LEFT")
    row.divLine = row:CreateTexture(nil, "ARTWORK")
    row.divLine:SetTexture(WHITE)
    row.divLine:SetVertexColor(1, 1, 1, 0.14)
    row.divLine:SetHeight(1)
    row.divLine:SetPoint("LEFT", row.divText, "RIGHT", 8, 0)
    row.divLine:SetPoint("RIGHT", row, "RIGHT", -6, 0)
end
local function skinIconButton(btn)
    if vanilla() then
        btn.ring:Show()
        btn.edge:Hide()
    else
        btn.ring:Hide()
        btn.edge:Show()
    end
end
local function skinPanel(frame)
    frame:SetBackdrop({
        bgFile = WHITE, edgeFile = TIP_EDGE, tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 },
    })
    if vanilla() then
        frame:SetBackdropColor(0.10, 0.09, 0.07, 0.97)
        frame:SetBackdropBorderColor(0.85, 0.72, 0.35)
    else
        frame:SetBackdropColor(0.07, 0.07, 0.09, 0.97)
        frame:SetBackdropBorderColor(0.5, 0.5, 0.5)
    end
end
function Theme.Panel(frame)
    register(skinPanel, frame)
    return frame
end
function Theme.IconButton(parent, size)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetWidth(size)
    btn:SetHeight(size)
    btn.edge = btn:CreateTexture(nil, "BACKGROUND")
    btn.edge:SetTexture(WHITE)
    btn.edge:SetVertexColor(0, 0, 0, 1)
    btn.edge:SetPoint("TOPLEFT", btn, "TOPLEFT", -1, 1)
    btn.edge:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 1, -1)
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints(btn)
    btn.ring = btn:CreateTexture(nil, "OVERLAY")
    btn.ring:SetTexture(SLOT)
    btn.ring:SetTexCoord(SLOT_COORD[1], SLOT_COORD[2], SLOT_COORD[1], SLOT_COORD[2])
    btn.ring:SetWidth(size + 6)
    btn.ring:SetHeight(size + 6)
    btn.ring:SetPoint("CENTER", btn, "CENTER", 0, 0)
    btn:SetPushedTexture(PRESSED)
    btn:SetHighlightTexture(BTN_HILITE, "ADD")
    register(skinIconButton, btn)
    return btn
end
function Theme.SetIconEnabled(btn, on)
    if on then
        btn:Enable()
        if not btn.icon:SetDesaturated(false) then btn.icon:SetVertexColor(1, 1, 1) end
    else
        btn:Disable()
        if not btn.icon:SetDesaturated(true) then btn.icon:SetVertexColor(0.5, 0.5, 0.5) end
    end
end
local GLYPH_BARS = { filter = { 10, 6, 2 }, rows = { 10, 10, 10 } }
local BAR_H, BAR_GAP = 2, 2
local TILE_SIDE, TILE_GAP = 4, 2
function Theme.GlyphTint(btn, on)
    btn.lit = on and true or false
    for _, bar in ipairs(btn.bars or {}) do
        if on then
            bar:SetVertexColor(1, 0.82, 0.35, 0.9)
        else
            bar:SetVertexColor(0.62, 0.62, 0.62, 0.8)
        end
    end
end
function Theme.Glyph(btn, kind)
    btn.bars = btn.bars or {}
    local box = math.floor(btn:GetWidth() or 0)
    if box < 1 then box = 14 end
    local n = 0
    local function bar(w, h, x, y)
        n = n + 1
        local t = btn.bars[n]
        if not t then
            t = btn:CreateTexture(nil, "ARTWORK")
            t:SetTexture(WHITE)
            btn.bars[n] = t
        end
        t:SetWidth(w)
        t:SetHeight(h)
        t:ClearAllPoints()
        t:SetPoint("TOPLEFT", btn, "TOPLEFT", x, -y)
        t:Show()
    end
    if kind == "tiles" then
        local side = TILE_SIDE * 2 + TILE_GAP
        local at = math.floor((box - side) / 2)
        for row = 0, 1 do
            for col = 0, 1 do
                bar(TILE_SIDE, TILE_SIDE,
                    at + col * (TILE_SIDE + TILE_GAP), at + row * (TILE_SIDE + TILE_GAP))
            end
        end
    else
        local list = GLYPH_BARS[kind] or GLYPH_BARS.rows
        local total = #list * BAR_H + (#list - 1) * BAR_GAP
        local y = math.floor((box - total) / 2)
        for _, w in ipairs(list) do
            bar(w, BAR_H, math.floor((box - w) / 2), y)
            y = y + BAR_H + BAR_GAP
        end
    end
    for i = n + 1, #btn.bars do btn.bars[i]:Hide() end
    Theme.GlyphTint(btn, btn.lit ~= false)
end
function Theme.Chip(parent, text)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(14)
    b:SetBackdrop({ bgFile = WHITE, edgeFile = WHITE, edgeSize = 1 })
    b:SetBackdropColor(0, 0, 0, 0.55)
    b:SetBackdropBorderColor(1, 0.82, 0, 0.45)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetFontString(fs)
    b:SetNormalFontObject(GameFontNormalSmall)
    b:SetHighlightFontObject(GameFontHighlightSmall)
    b:SetDisabledFontObject(GameFontDisableSmall)
    b:SetText(text)
    b:SetWidth(math.ceil(fs:GetStringWidth()) + 10)
    b:SetScript("OnEnter", function(self) self:SetBackdropColor(1, 0.82, 0, 0.25) end)
    b:SetScript("OnLeave", function(self) self:SetBackdropColor(0, 0, 0, 0.55) end)
    return b
end
