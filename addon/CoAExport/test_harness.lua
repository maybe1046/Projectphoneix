--[[ Mock WoW 3.3.5 API harness for CoAExport.

     Run in two modes:
       full     — every API present, sane values
       hostile  — most APIs missing or throwing, as CoA may well have left them

     The hostile run is the one that matters: it proves a stripped or rewritten
     client API surface degrades the dump instead of killing it.
]]

local MODE = MODE or "full"
local present = (MODE == "full")

unpack = unpack or table.unpack   -- harness runs on 5.5; WoW is 5.1

-- ------------------------------------------------------------- scaffolding

DEFAULT_CHAT_FRAME = { AddMessage = function(self, m) print("  " .. tostring(m)) end }

local frames = {}
function CreateFrame()
    local fr = { events = {}, scripts = {} }
    function fr:RegisterEvent(e) self.events[e] = true end
    function fr:SetScript(k, fn) self.scripts[k] = fn end
    frames[#frames + 1] = fr
    return fr
end

local clock = 0
function GetTime() return clock end
date = os.date
SlashCmdList = {}

-- Define an API only in full mode; in hostile mode half of them vanish and a
-- few actively throw, which is the more realistic failure shape.
local n = 0
local function api(name, fn)
    n = n + 1
    if present then
        _G[name] = fn
    elseif n % 3 == 0 then
        _G[name] = function() error(name .. " is not supported on this client") end
    else
        _G[name] = nil
    end
end

-- ------------------------------------------------------------ the mock API

api("UnitName",        function() return "Cruellbby" end)
api("GetRealmName",    function() return "Vol'jin - Conquest of Azeroth" end)
api("UnitLevel",       function() return 60 end)
api("UnitClass",       function() return "Arcanist", "ARCANIST" end)
api("UnitRace",        function() return "Troll", "Troll" end)
api("UnitSex",         function() return 2 end)
api("UnitFactionGroup",function() return "Horde" end)
api("GetGuildInfo",    function() return "Last Days", "Member" end)
api("GetMoney",        function() return 123456789 end)
api("UnitXP",          function() return 5000 end)
api("UnitXPMax",       function() return 10000 end)
api("GetRealZoneText", function() return "Orgrimmar" end)
api("GetSubZoneText",  function() return "The Drag" end)
api("GetPlayerMapPosition", function() return 0.51, 0.62 end)
api("GetRestState",    function() return 1 end)

api("UnitHealthMax",   function() return 12000 end)
api("UnitManaMax",     function() return 8000 end)
api("UnitStat",        function(_, i) return 100 + i, 200 + i end)
api("UnitArmor",       function() return 1000, 2500 end)
api("UnitAttackPower", function() return 800, 150, 0 end)
api("GetCritChance",   function() return 22.5 end)
api("GetSpellCritChance", function() return 18.25 end)
api("GetCombatRatingBonus", function() return 9.1 end)
api("UnitDefense",     function() return 400 end)
api("GetCombatRating", function() return 55 end)

local slotIDs = {}
api("GetInventorySlotInfo", function(name)
    slotIDs[name] = slotIDs[name] or (#slotIDs + 1)
    return slotIDs[name]
end)
api("GetInventoryItemLink", function(_, id)
    if not id then error("nil slot") end
    if id > 12 then return nil end
    return ("|cffa335ee|Hitem:4%04d:3820:41285:0:0:0:%d:1234567:60|h[Mock Item %d]|h|r"):format(id, -217, id)
end)
api("GetInventoryItemID", function(_, id) return 40000 + id end)
api("GetInventoryItemDurability", function() return 95, 100 end)

api("GetContainerNumSlots", function(bag)
    if bag == 0 then return 16 elseif bag >= 1 and bag <= 4 then return 20
    elseif bag == -1 then return 28 elseif bag >= 5 and bag <= 11 then return 0
    else return 0 end
end)
api("GetContainerItemLink", function(bag, s)
    if s % 3 == 0 then return nil end
    return ("|cff0070dd|Hitem:3%04d:0:0:0:0:0:0:0:60|h[Bag %d Slot %d]|h|r"):format(bag * 100 + s, bag, s)
end)
api("GetContainerItemInfo", function() return "tex", 5, false, 3, false end)
api("ContainerIDToInventoryID", function(b) return 19 + b end)

api("GetNumSpellTabs", function() return 2 end)
api("GetSpellTabInfo", function(t)
    if t == 1 then return "General", "tex", 0, 12 else return "Arcanist", "tex", 12, 30 end
end)
api("GetSpellName", function(i) return "Mock Spell " .. i, "Rank " .. (i % 5 + 1) end)
api("GetSpellLink", function(i) return "|cff71d5ff|Hspell:" .. (1000 + i) .. "|h[Mock Spell " .. i .. "]|h|r" end)

api("UnitCharacterPoints", function() return 3 end)
api("GetNumTalentTabs", function() return 3 end)
api("GetTalentTabInfo", function(t) return "Tree " .. t, "tex", t * 10 end)
api("GetNumTalents", function() return 28 end)
api("GetTalentInfo", function(tab, i)
    return "Talent " .. tab .. "-" .. i, "tex", math.ceil(i / 4), (i % 4) + 1, i % 3, 3
end)

local skillExpanded = false
api("GetNumSkillLines", function() return skillExpanded and 14 or 6 end)
api("GetSkillLineInfo", function(i)
    if i <= 2 then return "Header " .. i, true, skillExpanded, 0, 0, 0, 0 end
    return "Skill " .. i, false, false, 300 + i, 0, 5, 450
end)
api("ExpandSkillHeader", function() skillExpanded = true end)

local factionExpanded = false
api("GetNumFactions", function() return factionExpanded and 20 or 4 end)
api("GetFactionInfo", function(i)
    if i == 1 then return "Header", "d", 4, 0, 3000, 1500, false, false, true, not factionExpanded end
    return "Faction " .. i, "desc", 5, 0, 6000, 2400, false, false, false, false
end)
api("ExpandFactionHeader", function() factionExpanded = true end)

api("GetQuestsCompleted", function(t) for i = 1, 500 do t[8000 + i] = true end end)

api("GetCategoryList", function() return { 92, 96, 97 } end)
api("GetCategoryNumAchievements", function() return 40 end)
api("GetAchievementInfo", function(cat, i)
    return cat * 1000 + i, "Ach " .. cat .. "-" .. i, 10, (i % 2 == 0), 9, 4, 26
end)

api("GetCurrencyListSize", function() return 6 end)
api("GetCurrencyListInfo", function(i)
    if i == 1 then return "Header", true, true, false, false, 0 end
    return "Currency " .. i, false, true, false, false, i * 100
end)

api("GetNumCompanions", function(k) return k == "MOUNT" and 25 or 40 end)
api("GetCompanionInfo", function(k, i) return 5000 + i, k .. " " .. i, 6000 + i, "tex", false end)

api("GetGlyphSocketInfo", function(i) return i <= 4, 1, 1, 7000 + i, "tex" end)

api("GetNumEquipmentSets", function() return 3 end)
api("GetEquipmentSetInfo", function(i) return "Outfit " .. i, "icon" .. i end)
api("GetEquipmentSetItemIDs", function() return { [1] = 40001, [3] = 40003, [5] = 40005 } end)
api("GetEquipmentSetLocations", function() return { [1] = 1234, [3] = 5678 } end)

api("GetNumAddOns", function() return 5 end)
api("GetAddOnInfo", function(i) return "Addon" .. i, "Title " .. i, "notes", (i % 2 == 0), true end)
api("IsAddOnLoaded", function(i) return i % 2 == 0 end)

api("GetBuildInfo", function() return "3.3.5", "12340", "Mar 17 2026", 30300 end)
api("GetLocale", function() return "enUS" end)
api("GetCVar", function(k)
    if k == "realmList" then return "51.210.230.10" end
    return "1"
end)
api("RequestTimePlayed", function() end)

-- ------------------------------------------------- custom globals to sweep
-- Shapes the sweep must survive: normal data, a cycle, a fake widget, a very
-- wide table, and deep nesting past the depth cap.

Ascension_SkillCard_RDB = {
    ["Vol'jin - Conquest of Azeroth"] = {
        massRevealStats = { rewardItemIDs = { 246190, 97399, 778998 }, boostersRevealed = 41 },
        Init = function() end,
        collection = {},
    },
}
for i = 1, 5000 do Ascension_SkillCard_RDB["Vol'jin - Conquest of Azeroth"].collection[i] = { id = i, qty = i % 4 } end

CoATalentFooterLayoutDB = { importY = 1.75, buildY = -34, version = 4 }

AscensionTransmogFrame = { GetObjectType = function() return "Frame" end, GetParent = function() end, huge = {} }

MysticEnchantData = { rolls = { { id = 1, seed = 99 }, { id = 2, seed = 12 } } }

local cyc = { name = "cycle-root" }
cyc.self = cyc
cyc.child = { parent = cyc }
AscensionCyclicThing = cyc

local deep = {}
local cur = deep
for i = 1, 12 do cur.next = { level = i }; cur = cur.next end
HandOfFateDeepNest = deep

function AscensionGetDraftState() return {} end
ASCENSION_WILDCARD_MAX = 7

-- Credential-shaped bait. None of these values may appear in the output.
AscensionAuthToken = { token = "hunter2-the-actual-token", issued = 123 }
AscensionAccountState = {
    password    = "correct-horse-battery-staple",
    email       = "someone@example.com",
    sessionKey  = "DEADBEEFCAFEBABE0123456789ABCDEF0123456789ABCDEF",
    displayName = "Cruellbby",             -- innocent, must survive
    innocent    = { nested = "keep me" },
}
AscensionMysticRolls = {
    srpProof = "a3f1c2",
    loginName = "player@mail.com",
    buried = { deeper = { authSecret = "should-not-survive" } },
    seed = 4242,                            -- innocent, must survive
}

-- ------------------------------------------------------------------- run

print(("=== MODE: %s ==="):format(MODE))

local chunk = assert(loadfile("CoAExport.lua"))
chunk()

for _, fr in ipairs(frames) do
    if fr.scripts.OnEvent then
        fr.scripts.OnEvent(fr, "PLAYER_LOGIN")
        fr.scripts.OnEvent(fr, "TIME_PLAYED_MSG", 987654, 4321)
    end
end

print("-- running export --")
SlashCmdList["COAEXPORT"]()

-- ------------------------------------------------------------- assertions

local key = "Vol'jin - Conquest of Azeroth - Cruellbby"
local c = CoAExportDB.characters and (CoAExportDB.characters[key]
          or select(2, next(CoAExportDB.characters)))
assert(c, "no character record produced")

local function count(t) local n = 0 for _ in pairs(t or {}) do n = n + 1 end return n end

print("-- results --")
print("  identity.name    ", c.identity and c.identity.name)
print("  money            ", c.identity and c.identity.money)
print("  timePlayed.total ", c.timePlayed and c.timePlayed.total)
print("  equipment slots  ", count(c.equipment))
print("  bags             ", #(c.bags or {}))
print("  bank             ", #(c.bank or {}))
print("  spell tabs       ", #(c.spells or {}))
print("  skills           ", #(c.skills or {}))
print("  reputations      ", #(c.reputations or {}))
print("  quests           ", #(c.questsCompleted or {}))
print("  achievements     ", #(c.achievements or {}))
print("  currencies       ", #(c.currencies or {}))
print("  equipmentSets    ", #(c.equipmentSets or {}))
print("  custom API names ", #((c.custom or {}).apiSurface or {}))
print("  custom state keys", count((c.custom or {}).state))

-- The sweep must be safe, not merely populated.
local st = (c.custom or {}).state or {}
assert(st.AscensionTransmogFrame == nil or st.AscensionTransmogFrame == "<widget>",
       "widget was serialised instead of refused")
local cyclic = st.AscensionCyclicThing
if cyclic then
    assert(cyclic.self == "<already-seen>", "cycle not broken: " .. tostring(cyclic.self))
end
local nest = st.HandOfFateDeepNest
if nest then
    local cur, d = nest, 0
    while type(cur) == "table" and cur.next do cur = cur.next; d = d + 1 end
    assert(type(cur) == "string" or d <= 6, "depth cap not applied, depth=" .. d)
end
local coll = st.Ascension_SkillCard_RDB
if coll then print("  wide table handled") end

-- No function or userdata may survive into SavedVariables.
local bad = 0
local function scan(t, depth)
    if depth > 8 or type(t) ~= "table" then return end
    for k, v in pairs(t) do
        local vt = type(v)
        if vt == "function" or vt == "userdata" or vt == "thread" then bad = bad + 1 end
        if vt == "table" then scan(v, depth + 1) end
    end
end
scan(CoAExportDB, 0)
assert(bad == 0, bad .. " non-serialisable values left in the DB")

-- No secret may survive anywhere in the DB, at any depth, under any key.
local FORBIDDEN = {
    "hunter2%-the%-actual%-token",
    "correct%-horse%-battery%-staple",
    "someone@example%.com",
    "player@mail%.com",
    "DEADBEEFCAFEBABE",
    "should%-not%-survive",
}
local leaks, kept = {}, {}
local function hunt(t, path, depth)
    if depth > 10 or type(t) ~= "table" then return end
    for k, v in pairs(t) do
        local p = path .. "." .. tostring(k)
        if type(v) == "string" then
            for _, pat in ipairs(FORBIDDEN) do
                if string.find(v, pat) then leaks[#leaks + 1] = p .. " = " .. v end
            end
        elseif type(v) == "table" then
            hunt(v, p, depth + 1)
        end
    end
end
hunt(CoAExportDB, "db", 0)

if #leaks > 0 then
    print("!! LEAKED SECRETS:")
    for _, l in ipairs(leaks) do print("     " .. l) end
    error("redaction failed")
end
print("  no secrets leaked   ", "OK")

-- Redaction must not be so eager that it eats the actual data.
local ms = st.AscensionMysticRolls
if ms then
    assert(ms.seed == 4242, "innocent numeric value was destroyed")
    print("  innocent data kept  ", "seed=" .. tostring(ms.seed))
end
local as = st.AscensionAccountState
if as then
    assert(as.displayName == "Cruellbby", "innocent string was destroyed")
    assert(type(as.innocent) == "table" and as.innocent.nested == "keep me",
           "innocent nested table was destroyed")
end
-- Item links must survive the hex-blob heuristic untouched.
local eq = c.equipment or {}
for slot, item in pairs(eq) do
    assert(string.find(item.link, "|Hitem:"), "item link was mangled in " .. slot)
end
if next(eq) then print("  item links intact   ", "OK") end

print(("-- %s mode PASSED --"):format(MODE))
