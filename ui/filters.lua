local ADDON, ns = ...
local Filters = {}
ns.Filters = Filters
local NAME = "HTP_VendorFilterPanel"
local PAD = 12
local LINE_H = 22
local INDENT = 18
local WIDTH = 250
local HEAD_GAP = 6
local panel
local checks = {}
local flat = {}
local function T(...) return ns.T(...) end
local function keyOf(key, suffix)
    return "f" .. key:sub(1, 1):upper() .. key:sub(2) .. (suffix or "")
end
local function flatten()
    wipe(flat)
    for _, node in ipairs(ns.Filter.Tree()) do
        flat[#flat + 1] = { key = node.key, depth = 0, branch = node.subs ~= nil }
        if node.subs then
            for _, leaf in ipairs(node.subs) do
                flat[#flat + 1] = { key = leaf, depth = 1 }
            end
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
            local half = cb.branch and not ns.Filter.Get(cb.fkey) and ns.Filter.Some(cb.fkey)
            if half then
                cb.label:SetTextColor(1, 0.82, 0.35)
            else
                cb.label:SetTextColor(1, 1, 1)
            end
        end
    end
end
local function onClick(self)
    local on = self:GetChecked() and true or false
    ns.Filter.Set(self.fkey, on)
    Filters.Update()
    if ns.RefreshWindow then ns.RefreshWindow() end
    if ns.RefreshFilterButton then ns.RefreshFilterButton() end
end
local function makeCheck(i, item, y)
    local cb = checks[i]
    if not cb then
        cb = CreateFrame("CheckButton", NAME .. "Check" .. i, panel, "UICheckButtonTemplate")
        cb:SetWidth(20)
        cb:SetHeight(20)
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
    cb.label:SetText(T(keyOf(item.key)))
    cb.label:SetFontObject(item.branch and GameFontNormal or GameFontHighlightSmall)
    cb:ClearAllPoints()
    cb:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + item.depth * INDENT, y)
    cb:Show()
    return cb
end
local function build(parent)
    panel = CreateFrame("Frame", NAME, parent)
    panel:SetWidth(WIDTH)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    ns.Theme.Panel(panel)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    panel.title:SetText(T("filterTitle"))
    local list = flatten()
    local y = -PAD - 14 - HEAD_GAP
    for i, item in ipairs(list) do
        makeCheck(i, item, y)
        y = y - LINE_H
    end
    for i = #list + 1, #checks do checks[i]:Hide() end
    panel:SetHeight(-y + PAD)
    tinsert(UISpecialFrames, NAME)
    panel:Hide()
    return panel
end
function Filters.Toggle(parent, anchor)
    if not panel then build(parent) end
    if panel:IsShown() then
        panel:Hide()
        return
    end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -8)
    Filters.Update()
    panel:Show()
end
function Filters.Hide()
    if panel then panel:Hide() end
end
function Filters.Shown()
    return panel ~= nil and panel:IsShown()
end
