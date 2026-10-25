local ADDON, ns = ...
local Options = {}
ns.Options = Options
local NAME = "HTP_VendorOptions"
local PAD, LINE, INDENT = 16, 26, 16
local panel
local checks = {}
local function T(...) return ns.T(...) end
local ITEMS = {
    { key = "enabled", label = "optEnabled", tip = "optEnabledTip",
      get = function() return ns.DB().enabled ~= false end,
      set = function(on) ns.SetEnabled(on) end },
    { key = "tiles", label = "optTiles", tip = "optTilesTip",
      get = function() return ns.DB().tiles ~= false end,
      set = function(on) ns.DB().tiles = on; if ns.RefitWindow then ns.RefitWindow() end end },
    { key = "flat", label = "optFlat", tip = "optFlatTip",
      get = function() return ns.Theme.Name() == "flat" end,
      set = function(on) ns.SetTheme(on and "flat" or "vanilla") end },
    { key = "autoRepair", label = "optAutoRepair", tip = "optAutoRepairTip",
      get = function() return ns.DB().autoRepair == true end,
      set = function(on) ns.DB().autoRepair = on end },
    { key = "autoJunk", label = "optAutoJunk", tip = "optAutoJunkTip",
      get = function() return ns.DB().autoJunk == true end,
      set = function(on) ns.DB().autoJunk = on end },
    { key = "warnSold", label = "optWarnSold", tip = "optWarnSoldTip",
      get = function() return ns.DB().warnSold ~= false end,
      set = function(on) ns.DB().warnSold = on end },
    { key = "bagMarks", label = "optBagMarks", tip = "optBagMarksTip",
      get = function() return ns.DB().bagMarks ~= false end,
      set = function(on) ns.DB().bagMarks = on; if ns.RefreshBagMarks then ns.RefreshBagMarks() end end },
}
local function refresh()
    for _, cb in ipairs(checks) do cb:SetChecked(cb.item.get()) end
end
local function makeCheck(i, item, y)
    local cb = CreateFrame("CheckButton", NAME .. "Check" .. i, panel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, y)
    cb.item = item
    _G[cb:GetName() .. "Text"]:SetText(T(item.label))
    if item.tip then cb.tooltipText = T(item.tip) end
    cb:SetScript("OnClick", function(self)
        local on = self:GetChecked() and true or false
        PlaySound(on and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        self.item.set(on)
        refresh()
    end)
    checks[i] = cb
    return cb
end
local function makeButton(label, x, y, onClick)
    local b = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    b:SetWidth(160)
    b:SetHeight(22)
    b:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    b:SetText(T(label))
    b:SetScript("OnClick", onClick)
    return b
end
local function build()
    panel = CreateFrame("Frame", NAME, UIParent)
    panel.name = "ManaCode Vendor"
    panel.refresh = refresh
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -PAD)
    title:SetText("ManaCode Vendor " .. (ns.VERSION or ""))
    local info = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    info:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
    info:SetWidth(520)
    info:SetJustifyH("LEFT")
    info:SetText(T("optInfo"))
    local y = -PAD - 56
    for i, item in ipairs(ITEMS) do
        makeCheck(i, item, y)
        y = y - LINE
    end
    y = y - 10
    makeButton("optIntro", PAD + INDENT, y, function() ns.Intro.Show(nil) end)
    makeButton("optReset", PAD + INDENT + 170, y, function()
        if ns.ResetWindowSize then ns.ResetWindowSize() end
        ns.say(T("chatReset"))
    end)
    y = y - 32
    local cmd = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    cmd:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD + INDENT, y)
    cmd:SetWidth(520)
    cmd:SetJustifyH("LEFT")
    cmd:SetText(T("chatHelp"))
    InterfaceOptions_AddCategory(panel)
end
function Options.Open()
    if not panel then build() end
    InterfaceOptionsFrame_OpenToCategory(panel)
    InterfaceOptionsFrame_OpenToCategory(panel)
end
ns.OnReady(build)
