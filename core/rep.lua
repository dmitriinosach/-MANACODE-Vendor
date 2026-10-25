local ADDON, ns = ...
local Rep = {}
ns.Rep = Rep
local cache = {}
local cacheAt = 0
local CACHE_FOR = 2
local QUIET = 0.5
local scanning = false
local function onEvent(self, event)
    if event == "UPDATE_FACTION" and (scanning or GetTime() - cacheAt < QUIET) then return end
    wipe(cache)
    cacheAt = 0
end
local function scan()
    scanning = true
    wipe(cache)
    local opened = {}
    local i = 1
    while i <= (GetNumFactions() or 0) do
        local name, _, standing, barMin, barMax, barValue, _, _, isHeader, isCollapsed = GetFactionInfo(i)
        if not name then break end
        if isHeader and isCollapsed then
            ExpandFactionHeader(i)
            opened[#opened + 1] = i
        elseif not isHeader then
            cache[name] = { rank = standing or 0, label = _G["FACTION_STANDING_LABEL" .. (standing or 0)] or "",
                value = (barValue or 0) - (barMin or 0), max = (barMax or 0) - (barMin or 0) }
        end
        i = i + 1
    end
    for j = #opened, 1, -1 do CollapseFactionHeader(opened[j]) end
    cacheAt = GetTime()
    scanning = false
end
function Rep.Standing(name)
    if not name then return nil end
    if GetTime() - cacheAt > CACHE_FOR then scan() end
    return cache[name]
end
function Rep.Needed(rows, out)
    out = out or {}
    wipe(out)
    for _, r in ipairs(rows) do
        if r.repFaction and r.repRank then
            local need = out[r.repFaction]
            if not need then
                need = { rank = 0, n = 0 }
                out[r.repFaction] = need
            end
            need.n = need.n + 1
            if r.repRank > need.rank then need.rank = r.repRank end
        end
    end
    return out
end
local watcher = CreateFrame("Frame")
watcher:RegisterEvent("UPDATE_FACTION")
watcher:RegisterEvent("MERCHANT_SHOW")
watcher:SetScript("OnEvent", onEvent)
