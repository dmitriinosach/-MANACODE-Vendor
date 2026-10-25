local ADDON, ns = ...
ns.ADDON = ADDON
ns.VERSION = "1.0.0"
local DEFAULTS = {
    enabled = true,
    usableOnly = false,
    scale = 1,
    theme = "vanilla",
    autoRepair = false,
    autoJunk = false,
    warnSold = true,
    bagMarks = true,
    introSeen = false,
}
local readyCallbacks = {}
function ns.OnReady(fn)
    readyCallbacks[#readyCallbacks + 1] = fn
end
function ns.say(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33cc44" .. ns.T("chatPrefix") .. "|r: " .. tostring(msg))
end
function ns.DB()
    return HTP_VendorDB
end
function ns.CharKey()
    return (GetRealmName() or "") .. "-" .. (UnitName("player") or "")
end
function ns.CharDB()
    local db = ns.DB()
    if type(db.chars) ~= "table" then db.chars = {} end
    local key = ns.CharKey()
    local c = db.chars[key]
    if type(c) ~= "table" then
        c = { profs = {} }
        db.chars[key] = c
    end
    return c
end
local function loadDB()
    if type(HTP_VendorDB) ~= "table" then HTP_VendorDB = {} end
    for k, v in pairs(DEFAULTS) do
        if HTP_VendorDB[k] == nil then HTP_VendorDB[k] = v end
    end
    HTP_VendorDB.sizes, HTP_VendorDB.cols, HTP_VendorDB.rows = nil, nil, nil
end
function ns.ApplyTakeover()
    if ns.Enabled() then
        MerchantFrame:UnregisterEvent("MERCHANT_SHOW")
    else
        MerchantFrame:RegisterEvent("MERCHANT_SHOW")
    end
end
function ns.SetTheme(name)
    if not ns.Theme.Known(name) then
        ns.say(ns.T("chatTheme", ns.Theme.Name()))
        return
    end
    HTP_VendorDB.theme = name
    ns.Theme.Apply()
    if ns.RefreshWindow then ns.RefreshWindow() end
    ns.say(ns.T("chatTheme", name))
end
function ns.SetEnabled(on)
    HTP_VendorDB.enabled = on and true or false
    ns.ApplyTakeover()
    ns.say(ns.T(on and "chatOn" or "chatOff"))
end
local PARTS = { "Theme", "Scan", "Prof", "Uses", "Groups", "List", "Have", "Junk", "Sold", "Filter", "Filters",
    "Sizer", "About", "Marks", "BagMarks", "Intro", "Options", "Rep" }
local broken = false
function ns.Enabled()
    return (not broken) and HTP_VendorDB and HTP_VendorDB.enabled and true or false
end
local function partsMissing()
    local gone
    for _, name in ipairs(PARTS) do
        if ns[name] == nil then
            gone = gone or {}
            gone[#gone + 1] = name
        end
    end
    return gone
end
local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON then return end
    self:UnregisterEvent("ADDON_LOADED")
    loadDB()
    local gone = partsMissing()
    if gone then
        broken = true
        ns.say(ns.T("chatRestart", table.concat(gone, ", ")))
        ns.ApplyTakeover()
        return
    end
    local ok = true
    for _, fn in ipairs(readyCallbacks) do
        local good, err = pcall(fn)
        if not good then
            ok = false
            ns.say("ERR: " .. tostring(err))
        end
    end
    if not ok then broken = true end
    ns.ApplyTakeover()
end)
SLASH_HTPVENDOR1 = "/vendor"
SLASH_HTPVENDOR2 = "/lavka"
SlashCmdList.HTPVENDOR = function(msg)
    local cmd = (msg or ""):lower():match("^%s*(%S*)")
    if cmd == "on" then
        ns.SetEnabled(true)
    elseif cmd == "off" then
        ns.SetEnabled(false)
    elseif cmd == "reset" then
        if ns.ResetWindowSize then ns.ResetWindowSize() end
        ns.say(ns.T("chatReset"))
    elseif cmd == "about" then
        if ns.About then ns.About.Show() else ns.say(ns.T("aboutRestart")) end
    elseif cmd == "options" or cmd == "config" then
        if ns.Options then ns.Options.Open() else ns.say(ns.T("aboutRestart")) end
    elseif cmd == "refund" then
        if ns.ShowRefund then ns.ShowRefund() end
    elseif cmd == "intro" then
        if ns.Intro then ns.Intro.Show(nil) else ns.say(ns.T("aboutRestart")) end
    elseif cmd == "lang" then
        local code = (msg or ""):match("^%s*%S+%s+(%S+)")
        local db = ns.DB()
        if code and ns.locales[code] then
            db.lang = code
        elseif code then
            ns.say(ns.T("chatLangBad", code))
            return
        else
            db.lang = nil
        end
        ReloadUI()
    elseif cmd == "theme" then
        ns.SetTheme((msg or ""):lower():match("^%s*%S+%s+(%S+)") or "")
    elseif cmd == "mode" then
        ns.DiagMode()
    elseif cmd == "dump" then
        if (msg or ""):lower():match("^%s*%S+%s+(%S+)") == "clear" then
            ns.DiagDumpClear()
        else
            ns.DiagDump()
        end
    elseif cmd == "tip" then
        local index = tonumber((msg or ""):match("^%s*%S+%s+(%d+)")) or 1
        for i, l in ipairs(ns.Scan.Dump(index)) do ns.say(i .. ": " .. l:gsub("|", "||")) end
    elseif cmd == "types" then
        local t = ns.Groups.Types()
        ns.say(ns.T("diagTypes"))
        for i, name in ipairs(t.classes) do ns.say(i .. ": " .. name) end
        ns.say(ns.T("diagPick", tostring(t.recipe)))
        for c = 1, 2 do
            local subs = {}
            for i, name in ipairs({ GetAuctionItemSubClasses(c) }) do subs[#subs + 1] = i .. " " .. name end
            ns.say((t.classes[c] or c) .. ": " .. table.concat(subs, ", "))
        end
    else
        ns.say(ns.T(ns.Enabled() and "chatOn" or "chatOff"))
        ns.say(ns.T("chatHelp"))
    end
end
