local ADDON, ns = ...
local Intro = {}
ns.Intro = Intro
local NAME = "HTP_VendorIntro"
local WIDTH, PAD = 360, 14
local panel
local function T(...) return ns.T(...) end
local function build()
    panel = CreateFrame("Frame", NAME, UIParent)
    panel:SetWidth(WIDTH)
    panel:SetFrameStrata("DIALOG")
    panel:SetToplevel(true)
    panel:EnableMouse(true)
    ns.Theme.Panel(panel)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    panel.title:SetText(T("introTitle"))
    panel.text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    panel.text:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD - 26)
    panel.text:SetWidth(WIDTH - PAD * 2)
    panel.text:SetJustifyH("LEFT")
    panel.text:SetSpacing(4)
    panel.text:SetText(T("introText"))
    panel.ok = ns.Theme.Chip(panel, T("introOk"), 22)
    panel.ok:SetWidth(110)
    panel.ok:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -PAD, PAD)
    panel.ok:SetScript("OnClick", function() panel:Hide() end)
    panel:SetScript("OnHide", function() ns.DB().introSeen = true end)
    panel:SetHeight(PAD * 2 + 26 + panel.text:GetStringHeight() + 12 + 22)
    tinsert(UISpecialFrames, NAME)
    panel:Hide()
end
function Intro.Show(parent)
    if not panel then build() end
    panel:ClearAllPoints()
    if parent and parent:IsShown() then
        panel:SetPoint("CENTER", parent, "CENTER", 0, 0)
    else
        panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
    panel:Show()
end
function Intro.Hide()
    if panel then panel:Hide() end
end
