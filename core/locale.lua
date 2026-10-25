local ADDON, ns = ...
ns.locales = ns.locales or {}
local DEFAULT = "ruRU"
local FALLBACK = "enUS"
local MISSING = "??"
function ns.CurrentLocale()
    local db = ns.DB and ns.DB()
    local forced = db and db.lang
    if forced and ns.locales[forced] then return forced end
    local code = GetLocale()
    if ns.locales[code] then return code end
    return ns.locales[FALLBACK] and FALLBACK or DEFAULT
end
function ns.Has(key)
    local canon = ns.locales[DEFAULT]
    return (canon and canon[key]) ~= nil
end
function ns.T(key, ...)
    local dict = ns.locales[ns.CurrentLocale()]
    local s = dict and dict[key]
    if s == nil then
        local canon = ns.locales[DEFAULT]
        if not canon or canon[key] == nil then return "[" .. tostring(key) .. "]" end
        return MISSING
    end
    if select("#", ...) > 0 then return s:format(...) end
    return s
end
