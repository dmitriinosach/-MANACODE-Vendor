local ADDON, ns = ...
local Filters = {}
ns.Filters = Filters
local NAME = "HTP_VendorFilterPanel"
local PAD = 12
local LINE_H = 22
local CHECK = 20
local INDENT = 18
local WIDTH = 250
local DOCK_GAP = 4
local SECTION_H = 22
local SECTION_GAP = 6
local FOOT_H = 30
local panel
local checks = {}
local sections = {}
local flat = {}
local function T(...) return ns.T(...) end
local function keyOf(key, suffix)
    return "f" .. key:sub(1, 1):upper() .. key:sub(2) .. (suffix or "")
end
local function flatten()
    wipe(flat)
    for _, node in ipairs(ns.Filter.Tree()) do
        if node.section then flat[#flat + 1] = { section = node.section } end
        flat[#flat + 1] = { key = node.key, depth = 0, branch = node.subs ~= nil, switch = node.switch }
        for _, leaf in ipairs(node.subs or {}) do
            flat[#flat + 1] = { key = leaf, depth = 1, parent = node }
        end
    end
    return flat
end
local function tipShow(self)
    local key = self.fkey
    if not key then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(T(keyOf(key)), 1, 1, 1)
    if ns.Has(keyOf(key, "Tip")) then
        GameTooltip:AddLine(T(keyOf(key, "Tip")), 0.6, 0.8, 1, true)
    end
    GameTooltip:Show()
end
local function tipHide()
    GameTooltip:Hide()
end
function Filters.Update()
    if not panel then return end
    for _, cb in ipairs(checks) do
        if cb.fkey then
            cb:SetChecked(ns.Filter.Get(cb.fkey))
            local off = cb.parent and cb.parent.switch and not ns.Filter.Get(cb.parent.key)
            local half = cb.branch and not cb.switch and not ns.Filter.Get(cb.fkey) and ns.Filter.Some(cb.fkey)
            if off then
                cb.label:SetTextColor(0.5, 0.5, 0.5)
                cb:SetAlpha(0.6)
            elseif half then
                cb.label:SetTextColor(1, 0.82, 0.35)
                cb:SetAlpha(1)
            else
                cb.label:SetTextColor(1, 1, 1)
                cb:SetAlpha(1)
            end
        end
    end
    local n = ns.Filter.Hidden()
    panel.foot:SetText(T("filterHidden", n))
    if n > 0 then panel.showAll:Show() else panel.showAll:Hide() end
end
local function apply()
    if ns.RefitWindow then ns.RefitWindow() elseif ns.RefreshWindow then ns.RefreshWindow() end
    if ns.RefreshFilterButton then ns.RefreshFilterButton() end
    Filters.Update()
end
local function onClick(self)
    local on = self:GetChecked() and true or false
    ns.Filter.Set(self.fkey, on)
    apply()
end
local function makeCheck(i, item, y)
    local cb = checks[i]
    if not cb then
        cb = CreateFrame("CheckButton", NAME .. "Check" .. i, panel, "UICheckButtonTemplate")
        cb:SetWidth(CHECK)
        cb:SetHeight(CHECK)
        cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
        cb.label:SetJustifyH("LEFT")
        cb:SetScript("OnClick", onClick)
        cb:SetScript("OnEnter", tipShow)
        cb:SetScript("OnLeave", tipHide)
        checks[i] = cb
    end
    cb.fkey = item.key
    cb.branch = item.branch
    cb.switch = item.switch
    cb.parent = item.parent
    cb.label:SetText(T(keyOf(item.key)))
    cb.label:SetFontObject(item.branch and GameFontNormal or GameFontHighlightSmall)
    local labelW = math.ceil(cb.label:GetStringWidth()) + 6
    cb:SetHitRectInsets(0, -labelW, 0, 0)
    cb:ClearAllPoints()
    cb:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + item.depth * INDENT, y)
    cb:Show()
    return cb
end
local function makeSection(i, key, y)
    local fs = sections[i]
    if not fs then
        fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(1, 0.82, 0)
        sections[i] = fs
    end
    fs:SetText(T(key))
    fs:ClearAllPoints()
    fs:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y - 4)
    fs:Show()
    return fs
end
local function build(parent)
    panel = CreateFrame("Frame", NAME, parent)
    panel:SetWidth(WIDTH)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    ns.Theme.Panel(panel)
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 2, 2)
    local list = flatten()
    local y = -PAD
    local nc, nsec = 0, 0
    for _, item in ipairs(list) do
        if item.section then
            nsec = nsec + 1
            if nsec > 1 then y = y - SECTION_GAP end
            makeSection(nsec, item.section, y)
            y = y - SECTION_H
        else
            nc = nc + 1
            makeCheck(nc, item, y)
            y = y - LINE_H
        end
    end
    for i = nc + 1, #checks do checks[i]:Hide() end
    panel.foot = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.foot:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", PAD, PAD)
    panel.foot:SetTextColor(0.7, 0.7, 0.7)
    panel.showAll = ns.Theme.Chip(panel, T("filterShowAll"), 20)
    panel.showAll:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PAD, PAD - 3)
    panel.showAll:SetScript("OnClick", function()
        ns.Filter.ShowAll()
        apply()
    end)
    panel:SetHeight(-y + FOOT_H + PAD)
    tinsert(UISpecialFrames, NAME)
    panel:SetScript("OnUpdate", function(self)
        if (IsMouseButtonDown("LeftButton") or IsMouseButtonDown("RightButton"))
            and not MouseIsOver(self) and not (self.anchor and MouseIsOver(self.anchor)) then
            self:Hide()
        end
    end)
    panel:Hide()
    return panel
end
function Filters.Toggle(parent, anchor)
    if not panel then build(parent) end
    if panel:IsShown() then
        panel:Hide()
        return
    end
    panel.anchor = anchor
    panel:ClearAllPoints()
    local k = parent:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local right = (parent:GetRight() or 0) + (WIDTH + DOCK_GAP) * k
    if right <= (UIParent:GetRight() or right) then
        panel:SetPoint("TOPLEFT", parent, "TOPRIGHT", DOCK_GAP, 0)
    else
        panel:SetPoint("TOPRIGHT", parent, "TOPLEFT", -DOCK_GAP, 0)
    end
    Filters.Update()
    panel:Show()
end
function Filters.Hide()
    if panel then panel:Hide() end
end
function Filters.Shown()
    return panel ~= nil and panel:IsShown()
end
