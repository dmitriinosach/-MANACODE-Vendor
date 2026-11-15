local ADDON, ns = ...
local NO_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local SIZE = { row = 24, cell = 24, tile = 30 }
function ns.ItemStyle(f, kind)
    if f.kind == kind then return end
    f.kind = kind
    local s = type(kind) == "number" and kind or SIZE[kind] or SIZE.row
    f:SetWidth(s)
    f:SetHeight(s)
    f.icon:SetWidth(s)
    f.icon:SetHeight(s)
    ns.Theme.IconSize(f, s)
end
function ns.MakeItem(parent, kind)
    local f = CreateFrame("Frame", nil, parent)
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("CENTER", f, "CENTER", 0, 0)
    f.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    f.icon:SetWidth(SIZE.row)
    f.icon:SetHeight(SIZE.row)
    ns.Theme.Icon(f, f.icon, SIZE.row)
    f.count = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    f.count:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -1, 1)
    f.count:Hide()
    f.stock = f:CreateFontString(nil, "OVERLAY", "NumberFontNormalSmall")
    f.stock:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    f.stock:Hide()
    ns.ItemStyle(f, kind or "row")
    return f
end
function ns.ItemSet(f, tex, opts)
    opts = opts or {}
    f.icon:SetTexture(tex or NO_ICON)
    if opts.dim then
        if not f.icon:SetDesaturated(true) then f.icon:SetVertexColor(0.5, 0.5, 0.5) end
    else
        f.icon:SetDesaturated(false)
        if opts.tint then
            f.icon:SetVertexColor(1, 0.4, 0.4)
        else
            f.icon:SetVertexColor(1, 1, 1)
        end
    end
    if opts.have then f.haveTex:Show() else f.haveTex:Hide() end
    if opts.quality and (opts.frame or opts.glow) then
        local r, g, b = GetItemQualityColor(opts.quality)
        ns.Theme.IconTint(f, r, g, b, opts.frame, opts.glow)
    else
        ns.Theme.IconTint(f, nil)
    end
    if opts.count then
        f.count:SetText("x" .. opts.count)
        if f.count:GetStringWidth() > f:GetWidth() - 2 then f.count:SetText(opts.count) end
        f.count:Show()
    else
        f.count:Hide()
    end
    if opts.stock then
        f.stock:SetText("(" .. opts.stock .. ")")
        f.stock:Show()
    else
        f.stock:Hide()
    end
    ns.Theme.ShowIcon(f)
    f.icon:Show()
end
function ns.ItemReset(f)
    f.icon:SetTexture(nil)
    ns.Theme.IconTint(f, nil)
    f.haveTex:Hide()
    f.count:Hide()
    f.stock:Hide()
end
