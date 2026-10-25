local _, ns = ...
local About = {}
ns.About = About
About.DATA = {
    release = "https://github.com/dmitriinosach/-MANACODE-Vendor/releases",
    discord = "https://discord.gg/CYnxS6R9qY",
    site = "https://wow-addons.manacode.su",
}
About.DATA.updater = "https://github.com/dmitriinosach/-MANACODE-Update/releases/latest"
local NAME = "HTP_VendorAbout"
local WIDTH, PAD, GAP = 500, 16, 8
local TILE_W, TILE_H = 222, 100
local frame, content, scroll
local labels, tiles, links = {}, {}, {}
local function T(key, ...) return ns.T(key, ...) end
local function text(parent, value, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, -y)
    label:SetWidth(WIDTH - PAD * 2 - 16)
    label:SetJustifyH("LEFT")
    label:SetText(value)
    return label
end
local function linkField(parent, url, width)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetWidth(width)
    edit:SetHeight(22)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlightSmall)
    edit:SetTextInsets(4, 50, 0, 0)
    edit:SetText(url)
    edit:SetCursorPosition(0)
    edit.url = url
    edit:SetScript("OnTextChanged", function(self)
        if self:GetText() ~= url then self:SetText(url) end
    end)
    edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
    edit:SetScript("OnMouseUp", function(self) self:HighlightText() end)
    edit:SetScript("OnEditFocusLost", function(self)
        self:HighlightText(0, 0)
        self:SetCursorPosition(0)
    end)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(T("aboutCopyTip"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    edit:SetScript("OnLeave", function() GameTooltip:Hide() end)
    local key = edit:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    key:SetPoint("RIGHT", edit, "RIGHT", -5, 0)
    key:SetText("Ctrl+C")
    links[#links + 1] = edit
    return edit
end
local function copyRow(key, label, url, y)
    local caption = text(content, label, y + 5, "GameFontNormalSmall")
    caption:SetWidth(96)
    local edit = linkField(content, url, WIDTH - PAD * 2 - 126)
    edit:SetPoint("TOPLEFT", content, "TOPLEFT", 110, -y)
    frame.rows[key] = edit
    return y + 30
end
function About.Installed(folder)
    local name, _, _, _, _, reason = GetAddOnInfo(folder)
    return name ~= nil and reason ~= "MISSING"
end
local function makeTile(addon, index, y)
    local tile = CreateFrame("Frame", nil, content)
    tile:SetWidth(TILE_W)
    tile:SetHeight(TILE_H)
    tile:SetPoint("TOPLEFT", content, "TOPLEFT",
        ((index - 1) % 2) * (TILE_W + GAP), -y - math.floor((index - 1) / 2) * (TILE_H + GAP))
    ns.Theme.Panel(tile)
    local name = text(tile, addon.name, 8, "GameFontNormalSmall")
    name:ClearAllPoints()
    name:SetPoint("TOPLEFT", tile, "TOPLEFT", 8, -8)
    name:SetWidth(TILE_W - 16)
    local desc = text(tile, addon[ns.CurrentLocale()] or addon.enUS, 27)
    desc:ClearAllPoints()
    desc:SetPoint("TOPLEFT", tile, "TOPLEFT", 8, -27)
    desc:SetWidth(TILE_W - 16)
    desc:SetHeight(28)
    local installed = text(tile, "", 57)
    installed:ClearAllPoints()
    installed:SetPoint("TOPLEFT", tile, "TOPLEFT", 8, -57)
    installed:SetWidth(TILE_W - 16)
    local edit = linkField(tile, addon.url, TILE_W - 20)
    edit:SetPoint("BOTTOMLEFT", tile, "BOTTOMLEFT", 10, 5)
    tiles[#tiles + 1] = { addon = addon, state = installed, frame = tile }
end
local function build()
    frame = CreateFrame("Frame", NAME, UIParent)
    frame.rows = {}
    frame:SetWidth(WIDTH)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    ns.Theme.Panel(frame)
    local title = text(frame, T("aboutTitle"), 16, "GameFontNormalLarge")
    title:ClearAllPoints()
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -16)
    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    scroll = CreateFrame("ScrollFrame", NAME .. "Scroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -46)
    scroll:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -32, PAD)
    scroll:SetWidth(WIDTH - PAD - 32)
    content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(WIDTH - PAD - 32)
    scroll:SetScrollChild(content)
    local intro = text(content, T("aboutInfo"), 0)
    local y = intro:GetStringHeight() + 12
    labels.version = text(content, "", y, "GameFontNormal")
    y = y + 26
    y = copyRow("release", T("aboutDownload"), About.DATA.release, y)
    if About.DATA.updater then
        y = copyRow("updater", T("aboutUpdate"), About.DATA.updater, y)
        local info = text(content, T("aboutUpdateInfo"), y)
        y = y + info:GetStringHeight() + 12
    end
    y = copyRow("discord", "Discord", About.DATA.discord, y)
    local locale = GetLocale() == "ruRU" and "/" or "/en/"
    y = copyRow("site", T("aboutSite"), About.DATA.site .. locale, y)
    text(content, T("aboutOthers"), y + 4, "GameFontNormal")
    y = y + 28
    for i, addon in ipairs(ns.otherAddons) do makeTile(addon, i, y) end
    y = y + math.ceil(#ns.otherAddons / 2) * (TILE_H + GAP) + 6
    text(content, T("aboutAuthor"), y, "GameFontNormal")
    y = y + 22
    text(content, "|cffffffffFutex|r  |cfff58cbaSyncpool|r", y)
    content:SetHeight(y + 24)
    frame:SetScript("OnHide", function()
        for _, edit in ipairs(links) do edit:ClearFocus() end
    end)
    tinsert(UISpecialFrames, NAME)
    frame:Hide()
end
function About.Frame() return frame end
function About.Show()
    if not frame then build() end
    labels.version:SetText(T("aboutVersion", ns.VERSION))
    for _, tile in ipairs(tiles) do
        local installed = About.Installed(tile.addon.folder)
        tile.state:SetText(T(installed and "aboutInstalled" or "aboutMissing"))
        tile.state:SetTextColor(installed and 0.5 or 0.6, installed and 1 or 0.6, 0.6)
    end
    local scale = math.min(1, (GetScreenWidth() - 24) / WIDTH)
    frame:SetScale(scale)
    frame:SetHeight(math.min(content:GetHeight() + 62, math.max(200, (GetScreenHeight() - 60) / scale)))
    scroll:SetVerticalScroll(0)
    frame:Show()
end
function About.Toggle()
    if frame and frame:IsShown() then frame:Hide() else About.Show() end
end
