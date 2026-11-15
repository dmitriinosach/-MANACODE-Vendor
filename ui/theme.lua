local ADDON, ns = ...
local Theme = {}
ns.Theme = Theme
local WHITE = "Interface\\Buttons\\WHITE8X8"
local BORDER = "Interface\\PaperDollInfoFrame\\UI-GearManager-Border"
local TITLE_BG = "Interface\\PaperDollInfoFrame\\UI-GearManager-Title-Background"
local MARBLE = "Interface\\PaperDollInfoFrame\\UI-Character-CharacterTab-L1"
local TIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local HILITE = "Interface\\QuestFrame\\UI-QuestTitleHighlight"
local PRESSED = "Interface\\Buttons\\UI-Quickslot-Depress"
local BTN_HILITE = "Interface\\Buttons\\ButtonHilight-Square"
local HAVE = "Interface\\RaidFrame\\ReadyCheck-Ready"
local GLOW = "Interface\\Buttons\\UI-ActionButton-Border"
local GLOW_SCALE, GLOW_ALPHA = 1.8, 0.5
local DARK_LUM, LIFT = 0.5, 0.35
local HAVE_SCALE = 0.45
local ART = "Interface\\AddOns\\" .. ADDON .. "\\art\\"
local K = 1.25
local CORNER = 64
local PIECES = {
    tl = { 0.501953125, 0.625 }, tr = { 0.625, 0.75 }, t = { 0.25, 0.369140625 },
    bl = { 0.751953125, 0.875 }, br = { 0.875, 1 }, b = { 0.376953125, 0.498046875 },
    l = { 0.001953125, 0.125 }, r = { 0.1171875, 0.2421875 },
}
local MARBLE_COORD = { 0.255, 1, 0.29, 1 }
local BAND_Y, BAND_H = 7 * K, 17 * K
local BAND_MID = BAND_Y + BAND_H / 2
local TITLE_H = 14
local TITLE_SIDE = 44
local PORTRAIT, PORTRAIT_X, PORTRAIT_EDGE, PORTRAIT_CROP = 16, 12, 1, 0.08
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
    c.band:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -BAND_Y)
    c.band:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -BAND_Y)
    c.band:SetHeight(BAND_H)
    c.bg = frame:CreateTexture(nil, "BORDER")
    c.bg:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -24 * K)
    c.bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 8)
    c.portraitBack = frame:CreateTexture(nil, "ARTWORK")
    c.portraitBack:SetTexture(WHITE)
    c.portraitBack:SetVertexColor(0, 0, 0, 0.85)
    c.portraitBack:SetWidth(PORTRAIT + PORTRAIT_EDGE * 2)
    c.portraitBack:SetHeight(PORTRAIT + PORTRAIT_EDGE * 2)
    c.portraitBack:SetPoint("LEFT", frame, "TOPLEFT", PORTRAIT_X, -BAND_MID)
    c.portrait = frame:CreateTexture(nil, "OVERLAY")
    c.portrait:SetWidth(PORTRAIT); c.portrait:SetHeight(PORTRAIT)
    c.portrait:SetPoint("CENTER", c.portraitBack, "CENTER", 0, 0)
    c.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    c.title:SetPoint("TOP", frame, "TOP", 0, -(BAND_MID - TITLE_H / 2))
    c.title:SetHeight(TITLE_H)
    c.title:SetJustifyH("CENTER")
    frame.chrome = c
    register(skinChrome, frame)
    return c
end
function Theme.SetTitle(frame, name, sub, maxWidth)
    local c = frame.chrome
    c.title:SetText(sub and (name .. "  |cffffffff" .. sub .. "|r") or name)
    c.title:SetWidth(math.max(40, maxWidth - TITLE_SIDE * 2))
end
function Theme.SetPortrait(frame, unit)
    local c = frame.chrome
    if UnitExists(unit) then
        SetPortraitTexture(c.portrait, unit)
    else
        c.portrait:SetTexture("Interface\\Icons\\INV_Misc_Coin_01")
    end
    c.portrait:SetTexCoord(PORTRAIT_CROP, 1 - PORTRAIT_CROP, PORTRAIT_CROP, 1 - PORTRAIT_CROP)
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
local SLOT_BACK = { 0, 0, 0, 0.85 }
local SLOT_EDGE = { 0.32, 0.30, 0.26 }
local SLOT_OUT = 2
local function skinRow(row)
    row.slotBack:Show()
    row.slotEdge:Show()
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
    if row.glowTex then
        row.glowTex:SetWidth(math.floor(size * GLOW_SCALE))
        row.glowTex:SetHeight(math.floor(size * GLOW_SCALE))
    end
    if row.haveTex then
        row.haveTex:SetWidth(math.floor(size * HAVE_SCALE))
        row.haveTex:SetHeight(math.floor(size * HAVE_SCALE))
    end
end
local function slotUnder(owner, icon)
    local back = owner:CreateTexture(nil, "BACKGROUND")
    back:SetTexture(WHITE)
    back:SetVertexColor(SLOT_BACK[1], SLOT_BACK[2], SLOT_BACK[3], SLOT_BACK[4])
    back:SetPoint("TOPLEFT", icon, "TOPLEFT", -SLOT_OUT, SLOT_OUT)
    back:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", SLOT_OUT, -SLOT_OUT)
    local edge = owner:CreateTexture(nil, "BORDER")
    edge:SetTexture(WHITE)
    edge:SetVertexColor(SLOT_EDGE[1], SLOT_EDGE[2], SLOT_EDGE[3], 1)
    edge:SetPoint("TOPLEFT", icon, "TOPLEFT", -1, 1)
    edge:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 1, -1)
    return back, edge
end
function Theme.Icon(row, icon, size)
    row.slotBack, row.slotEdge = slotUnder(row, icon)
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
    if not (r and frame) then
        row.slotEdge:SetVertexColor(SLOT_EDGE[1], SLOT_EDGE[2], SLOT_EDGE[3], 1)
        return
    end
    if 0.3 * r + 0.59 * g + 0.11 * b < DARK_LUM then
        r, g, b = r + (1 - r) * LIFT, g + (1 - g) * LIFT, b + (1 - b) * LIFT
    end
    row.slotEdge:SetVertexColor(r, g, b, 1)
end
function Theme.Row(row, icon, odd)
    Theme.Host(row, odd)
    Theme.Icon(row, icon)
end
function Theme.Track(bar, arrow)
    local back = bar:CreateTexture(nil, "BACKGROUND")
    back:SetTexture(WHITE)
    back:SetVertexColor(SLOT_BACK[1], SLOT_BACK[2], SLOT_BACK[3], 0.45)
    back:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, arrow + 1)
    back:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -arrow - 1)
end
function Theme.HideIcon(row)
    row.slotBack:Hide()
    row.slotEdge:Hide()
    row.glowTex:Hide()
    row.haveTex:Hide()
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
local EXP_TINT = { 1, 0.82, 0.35 }
local EXP_LIT = { 1, 0.93, 0.62 }
local function expGrow(btn, on)
    local tex = btn.glyph
    local d = on and EXP_GROW or 0
    tex:ClearAllPoints()
    tex:SetPoint("TOPLEFT", btn, "TOPLEFT", -d, d)
    tex:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", d, -d)
    local c = on and EXP_LIT or EXP_TINT
    tex:SetVertexColor(c[1], c[2], c[3])
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
    row.exp.glyph = row.exp:CreateTexture(nil, "ARTWORK")
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
    local kind = collapsed and "shut" or "open"
    if row.exp.kind ~= kind then
        row.exp.kind = kind
        row.exp.glyph:SetTexture(ART .. kind .. ".tga")
    end
    expGrow(row.exp, false)
end
function Theme.ExpanderHover(row, on)
    if row.exp:IsShown() then expGrow(row.exp, on) end
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
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints(btn)
    btn.slotBack, btn.edge = slotUnder(btn, btn.icon)
    btn:SetPushedTexture(PRESSED)
    btn:SetHighlightTexture(BTN_HILITE, "ADD")
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
Theme.CTRL = 20
Theme.CHIP = 18
local PLATE = {
    bgFile = WHITE, edgeFile = ART .. "rim.tga", tile = false, edgeSize = 5,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}
local LOOK = {
    fill = { 0, 0, 0, 0.55 }, rim = { 1, 0.82, 0, 0.45 }, glyph = { 1, 0.82, 0.35 },
    fillLit = { 0.40, 0.31, 0.05, 0.75 }, rimLit = { 1, 0.82, 0, 0.9 }, glyphLit = { 1, 0.93, 0.62 },
    fillOff = { 0, 0, 0, 0.35 }, rimOff = { 0.5, 0.5, 0.5, 0.35 }, glyphOff = { 0.45, 0.45, 0.45 },
    hover = { 1, 0.82, 0, 0.18 },
    rimWarn = { 1, 0.3, 0.3, 0.6 },
    field = { 0, 0, 0, 0.5 }, rimField = { 0.62, 0.56, 0.44, 0.55 }, rimFocus = { 1, 0.82, 0, 0.9 },
}
local GLYPH = 16
local HOVER_IN = 2
local function paintPlate(b)
    local fill, rim, glyph = LOOK.fill, LOOK.rim, LOOK.glyph
    if b.off then
        fill, rim, glyph = LOOK.fillOff, LOOK.rimOff, LOOK.glyphOff
    elseif b.lit then
        fill, rim, glyph = LOOK.fillLit, LOOK.rimLit, LOOK.glyphLit
    end
    b:SetBackdropColor(fill[1], fill[2], fill[3], fill[4])
    b:SetBackdropBorderColor(rim[1], rim[2], rim[3], rim[4])
    if b.glyph then b.glyph:SetVertexColor(glyph[1], glyph[2], glyph[3]) end
    if b.hover then
        b.hover:SetVertexColor(LOOK.hover[1], LOOK.hover[2], LOOK.hover[3], b.off and 0 or LOOK.hover[4])
    end
end
local function plate(b)
    b:SetBackdrop(PLATE)
    b.hover = b:CreateTexture(nil, "HIGHLIGHT")
    b.hover:SetTexture(WHITE)
    b.hover:SetBlendMode("ADD")
    b.hover:SetPoint("TOPLEFT", b, "TOPLEFT", HOVER_IN, -HOVER_IN)
    b.hover:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -HOVER_IN, HOVER_IN)
    paintPlate(b)
end
local function glyphDown(self)
    if not self.off then self.glyph:SetPoint("CENTER", self, "CENTER", 1, -1) end
end
local function glyphUp(self)
    self.glyph:SetPoint("CENTER", self, "CENTER", 0, 0)
end
function Theme.Button(parent, glyph, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(size or Theme.CTRL)
    b:SetHeight(size or Theme.CTRL)
    b.glyph = b:CreateTexture(nil, "ARTWORK")
    b.glyph:SetWidth(GLYPH)
    b.glyph:SetHeight(GLYPH)
    b.glyph:SetPoint("CENTER", b, "CENTER", 0, 0)
    plate(b)
    b:SetScript("OnMouseDown", glyphDown)
    b:SetScript("OnMouseUp", glyphUp)
    Theme.SetGlyph(b, glyph)
    return b
end
function Theme.SetGlyph(b, glyph)
    if b.glyphName == glyph then return end
    b.glyphName = glyph
    b.glyph:SetTexture(ART .. glyph .. ".tga")
end
function Theme.SetLit(b, on)
    on = on and true or false
    if (b.lit or false) == on then return end
    b.lit = on
    paintPlate(b)
end
function Theme.SetEnabled(b, on)
    local off = not on
    if (b.off or false) == off then return end
    b.off = off
    if on then b:Enable() else b:Disable() end
    glyphUp(b)
    paintPlate(b)
end
function Theme.Counter(b)
    b.count = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.count:SetPoint("LEFT", b, "RIGHT", 3, 0)
    b.count:SetTextColor(LOOK.glyph[1], LOOK.glyph[2], LOOK.glyph[3])
    b.count:SetText("99")
    local w = math.ceil(b.count:GetStringWidth() or 0)
    if w < 1 then w = 14 end
    b.count:SetText("")
    return w + 3
end
function Theme.SetCount(b, n)
    if b.countN == n then return end
    b.countN = n
    b.count:SetText(n > 0 and (n > 99 and "99+" or tostring(n)) or "")
end
function Theme.Field(edit, right)
    for _, region in ipairs({ edit:GetRegions() }) do
        if region:GetObjectType() == "Texture" and region:GetDrawLayer() == "BACKGROUND" then region:Hide() end
    end
    edit:SetBackdrop(PLATE)
    edit:SetBackdropColor(LOOK.field[1], LOOK.field[2], LOOK.field[3], LOOK.field[4])
    edit:SetBackdropBorderColor(LOOK.rimField[1], LOOK.rimField[2], LOOK.rimField[3], LOOK.rimField[4])
    edit:SetTextInsets(6, right or 6, 0, 0)
    edit:HookScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(LOOK.rimFocus[1], LOOK.rimFocus[2], LOOK.rimFocus[3], LOOK.rimFocus[4])
    end)
    edit:HookScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(LOOK.rimField[1], LOOK.rimField[2], LOOK.rimField[3], LOOK.rimField[4])
    end)
end
function Theme.Mark(parent, glyph, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetWidth(size)
    b:SetHeight(size)
    b.glyph = b:CreateTexture(nil, "ARTWORK")
    b.glyph:SetAllPoints(b)
    b.glyph:SetTexture(ART .. glyph .. ".tga")
    b.glyph:SetVertexColor(LOOK.rimField[1], LOOK.rimField[2], LOOK.rimField[3])
    b:SetScript("OnEnter", function(self)
        self.glyph:SetVertexColor(LOOK.glyphLit[1], LOOK.glyphLit[2], LOOK.glyphLit[3])
    end)
    b:SetScript("OnLeave", function(self)
        self.glyph:SetVertexColor(LOOK.rimField[1], LOOK.rimField[2], LOOK.rimField[3])
    end)
    return b
end
local GRIP_AT = { vanilla = { 8, 11 }, flat = { 6, 6 } }
local function skinGrip(grip)
    local at = GRIP_AT[Theme.Name()] or GRIP_AT.vanilla
    grip:ClearAllPoints()
    grip:SetPoint("BOTTOMRIGHT", grip:GetParent(), "BOTTOMRIGHT", -at[1], at[2])
end
function Theme.Grip(grip)
    register(skinGrip, grip)
end
function Theme.Chip(parent, text, height)
    local b = CreateFrame("Button", nil, parent)
    b:SetHeight(height or Theme.CHIP)
    plate(b)
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("CENTER", b, "CENTER", 0, 0)
    b:SetFontString(fs)
    b:SetNormalFontObject(GameFontNormalSmall)
    b:SetHighlightFontObject(GameFontHighlightSmall)
    b:SetDisabledFontObject(GameFontDisableSmall)
    b:SetText(text)
    b:SetWidth(math.ceil(fs:GetStringWidth()) + 14)
    return b
end
function Theme.ChipWarn(b, warn)
    if warn then
        b:SetNormalFontObject(GameFontRedSmall)
        b:SetHighlightFontObject(GameFontRedSmall)
        b:SetBackdropBorderColor(LOOK.rimWarn[1], LOOK.rimWarn[2], LOOK.rimWarn[3], LOOK.rimWarn[4])
    else
        b:SetNormalFontObject(GameFontNormalSmall)
        b:SetHighlightFontObject(GameFontHighlightSmall)
        b:SetBackdropBorderColor(LOOK.rim[1], LOOK.rim[2], LOOK.rim[3], LOOK.rim[4])
    end
end
