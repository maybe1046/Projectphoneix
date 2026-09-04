--[[--------------------------------------------------------------------------
  CoA Export — dumps character and account state to SavedVariables.

  Usage:  /coaexport      then  /reload      (the /reload is what writes the file)

  Output lands in:
    <client>\WTF\Account\<ACCOUNT>\SavedVariables\CoAExport.lua

  Everything is wrapped in pcall. Conquest of Azeroth removes and replaces large
  parts of the stock 3.3.5 API, so any individual collector failing is expected
  and must never take the rest of the dump down with it.

  This file is meant to be handed to someone else, so it redacts anything
  credential-shaped on the way out — see "redaction" below. Character names,
  gear, gold and playtime ARE recorded; that is the point. Passwords, tokens,
  session keys and email addresses are not.
----------------------------------------------------------------------------]]

local ADDON_VERSION = 1

-- Provenance. Players are told to compare this build tag against the official
-- post before trusting the addon. A tampered copy either shows a stale tag or
-- a tag that does not match the post.
--
local ADDON_BUILD  = "2026-09-04a"
local OFFICIAL_URL = "https://www.kookapp.cn/app/channels/8766670179908841/3538459662568933"

CoAExportDB = CoAExportDB or {}

-- ---------------------------------------------------------------- utilities

-- Call a possibly-missing, possibly-broken API. Returns nil on any failure.
local function safecall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local r = { pcall(fn, ...) }
    if not r[1] then return nil end
    return unpack(r, 2)
end

-- Frames and other widgets are tables, but serialising one would recurse through
-- the entire UI. Anything answering to a widget method is refused.
local function isWidget(t)
    local ok, res = pcall(function()
        return t.GetObjectType ~= nil or t.IsForbidden ~= nil or t.GetParent ~= nil
    end)
    return ok and res == true
end

local MAX_DEPTH   = 4
local MAX_ENTRIES = 3000      -- per table
local MAX_VALUES  = 250000    -- across one whole copy() call

-- ------------------------------------------------------------- redaction
--
-- This file gets sent to someone else, so nothing resembling a credential may
-- reach it. The global sweep below matches on names like "Ascension", which
-- would happily serialise an AscensionAuthToken if one existed. Two defences:
-- refuse values under credential-shaped keys, and refuse credential-shaped
-- values wherever they appear.

local SENSITIVE_KEYS = {
    "password", "passwd", "pwd", "secret", "token", "auth", "session",
    "credential", "apikey", "api_key", "privkey", "privatekey",
    "srp", "salt", "sha1", "sha256", "md5", "email", "login",
}

local function isSensitiveKey(k)
    if type(k) ~= "string" then return false end
    local lower = string.lower(k)
    for _, p in ipairs(SENSITIVE_KEYS) do
        if string.find(lower, p, 1, true) then return true end
    end
    return false
end

-- Catch credentials that sit under an innocent key name.
local function sanitizeString(s)
    if string.find(s, "^%S+@%S+%.%S+$") then return "<redacted-email>" end
    -- A long unbroken hex run is a key, a hash or a token; game data is not
    -- shaped like this (item links carry ':' separators and short numbers).
    if #s >= 32 and string.find(s, "^%x+$") then return "<redacted-hex-blob>" end
    return s
end

-- Deep-copy into something the SavedVariables writer can serialise: no
-- functions, no userdata, no cycles, bounded depth and bounded size.
local function copy(v, depth, seen, budget)
    local t = type(v)
    if t == "string" then return sanitizeString(v) end
    if t == "number" or t == "boolean" then return v end
    if t ~= "table" then return "<" .. t .. ">" end
    if depth <= 0 then return "<max-depth>" end

    budget.n = budget.n + 1
    if budget.n > MAX_VALUES then return "<budget-exhausted>" end

    if seen[v] then return "<already-seen>" end
    if isWidget(v) then return "<widget>" end
    seen[v] = true

    local out, n = {}, 0
    pcall(function()
        for k, val in pairs(v) do
            local kt = type(k)
            if kt == "string" or kt == "number" then
                n = n + 1
                if n > MAX_ENTRIES then
                    out["<truncated>"] = true
                    break
                end
                if isSensitiveKey(k) then
                    out[k] = "<redacted>"
                else
                    out[k] = copy(val, depth - 1, seen, budget)
                end
            end
        end
    end)
    return out
end

local function snapshot(v, depth)
    return copy(v, depth or MAX_DEPTH, {}, { n = 0 })
end

local function say(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99CoAExport|r: " .. tostring(msg))
end

-- ------------------------------------------------------------- collectors

local function collectIdentity()
    local d = {}
    d.name                = safecall(UnitName, "player")
    d.realm               = safecall(GetRealmName)
    d.level               = safecall(UnitLevel, "player")
    d.class, d.classFile  = safecall(UnitClass, "player")
    d.race,  d.raceFile   = safecall(UnitRace, "player")
    d.sex                 = safecall(UnitSex, "player")
    d.faction             = safecall(UnitFactionGroup, "player")
    d.guild, d.guildRank  = safecall(GetGuildInfo, "player")
    d.money               = safecall(GetMoney)
    d.xp                  = safecall(UnitXP, "player")
    d.xpMax               = safecall(UnitXPMax, "player")
    d.zone                = safecall(GetRealZoneText)
    d.subZone             = safecall(GetSubZoneText)
    d.mapX, d.mapY        = safecall(GetPlayerMapPosition, "player")
    d.restState           = safecall(GetRestState)
    return d
end

local function collectStats()
    local d = {}
    d.healthMax = safecall(UnitHealthMax, "player")
    d.powerMax  = safecall(UnitManaMax, "player")
    for i = 1, 5 do
        local _, effective = safecall(UnitStat, "player", i)
        d["stat" .. i] = effective
    end
    local _, armor      = safecall(UnitArmor, "player")
    d.armor             = armor
    local base, posBuff = safecall(UnitAttackPower, "player")
    d.attackPower       = (base or 0) + (posBuff or 0)
    d.meleeCrit         = safecall(GetCritChance)
    d.spellCrit         = safecall(GetSpellCritChance, 2)
    d.haste             = safecall(GetCombatRatingBonus, 20)
    d.defense           = safecall(UnitDefense, "player")
    d.resilience        = safecall(GetCombatRating, 15)
    return d
end

local INV_SLOTS = {
    "HeadSlot", "NeckSlot", "ShoulderSlot", "ShirtSlot", "ChestSlot",
    "WaistSlot", "LegsSlot", "FeetSlot", "WristSlot", "HandsSlot",
    "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot",
    "BackSlot", "MainHandSlot", "SecondaryHandSlot", "RangedSlot", "TabardSlot",
}

-- Item links are the most valuable single thing in this dump: they carry the
-- item id, enchant, gems, suffix and the random-enchant seed, which is how
-- mystic/random enchant rolls are recorded.
local function collectEquipment()
    local out = {}
    for _, slotName in ipairs(INV_SLOTS) do
        local slotID = safecall(GetInventorySlotInfo, slotName)
        if slotID then
            local link = safecall(GetInventoryItemLink, "player", slotID)
            if link then
                out[slotName] = {
                    slotID    = slotID,
                    link      = link,
                    itemID    = safecall(GetInventoryItemID, "player", slotID),
                    durability = select(1, safecall(GetInventoryItemDurability, slotID)),
                }
            end
        end
    end
    return out
end

local function collectContainers(bags)
    local out = {}
    for _, bag in ipairs(bags) do
        local slots = safecall(GetContainerNumSlots, bag) or 0
        if slots > 0 then
            local b = { bag = bag, slots = slots, items = {} }
            b.bagLink = safecall(GetInventoryItemLink, "player",
                                 bag >= 1 and bag <= 4 and (ContainerIDToInventoryID and ContainerIDToInventoryID(bag)) or nil)
            for s = 1, slots do
                local link = safecall(GetContainerItemLink, bag, s)
                if link then
                    local _, count = safecall(GetContainerItemInfo, bag, s)
                    b.items[s] = { link = link, count = count }
                end
            end
            out[#out + 1] = b
        end
    end
    return out
end

local function collectSpells()
    local out = {}
    local numTabs = safecall(GetNumSpellTabs) or 0
    for t = 1, numTabs do
        local name, _, offset, numSpells = safecall(GetSpellTabInfo, t)
        local tab = { name = name, numSpells = numSpells, spells = {} }
        offset, numSpells = offset or 0, numSpells or 0
        for i = offset + 1, offset + numSpells do
            local sName, sRank = safecall(GetSpellName, i, "spell")
            if sName then
                tab.spells[#tab.spells + 1] = {
                    index = i,
                    name  = sName,
                    rank  = sRank,
                    link  = safecall(GetSpellLink, i, "spell"),
                }
            end
        end
        out[#out + 1] = tab
    end
    return out
end

-- CoA replaces the talent tree outright, so this may come back empty. That is
-- itself worth recording: the custom advancement state is picked up by the
-- global sweep below instead.
local function collectTalents()
    local out = { tabs = {} }
    out.unspentPoints = safecall(UnitCharacterPoints, "player")
    local numTabs = safecall(GetNumTalentTabs) or 0
    for t = 1, numTabs do
        local name, _, pointsSpent = safecall(GetTalentTabInfo, t)
        local tab = { name = name, pointsSpent = pointsSpent, talents = {} }
        local n = safecall(GetNumTalents, t) or 0
        for i = 1, n do
            local tName, _, tier, column, rank, maxRank = safecall(GetTalentInfo, t, i)
            if tName and rank and rank > 0 then
                tab.talents[#tab.talents + 1] = {
                    name = tName, tier = tier, column = column,
                    rank = rank, maxRank = maxRank,
                }
            end
        end
        out.tabs[#out.tabs + 1] = tab
    end
    return out
end

local function collectSkills()
    -- Headers must be expanded before their children are visible. Expanding
    -- shifts indices, so walk backwards.
    pcall(function()
        for i = GetNumSkillLines(), 1, -1 do
            local _, isHeader, isExpanded = GetSkillLineInfo(i)
            if isHeader and not isExpanded then ExpandSkillHeader(i) end
        end
    end)

    local out = {}
    local n = safecall(GetNumSkillLines) or 0
    for i = 1, n do
        local name, isHeader, _, rank, _, modifier, maxRank = safecall(GetSkillLineInfo, i)
        if name and not isHeader then
            out[#out + 1] = { name = name, rank = rank, maxRank = maxRank, modifier = modifier }
        end
    end
    return out
end

local function collectReputations()
    pcall(function()
        local i, guard = 1, 0
        while i <= GetNumFactions() and guard < 2000 do
            guard = guard + 1
            local _, _, _, _, _, _, _, _, isHeader, isCollapsed = GetFactionInfo(i)
            if isHeader and isCollapsed then
                ExpandFactionHeader(i)   -- list grew at i, do not advance
            else
                i = i + 1
            end
        end
    end)

    local out = {}
    local n = safecall(GetNumFactions) or 0
    for i = 1, n do
        local name, _, standing, barMin, barMax, barValue, _, _, isHeader = safecall(GetFactionInfo, i)
        if name and not isHeader then
            out[#out + 1] = {
                name = name, standing = standing,
                value = barValue, min = barMin, max = barMax,
            }
        end
    end
    return out
end

local function collectQuests()
    local t = {}
    if not pcall(GetQuestsCompleted, t) then return nil end
    local out = {}
    for id in pairs(t) do out[#out + 1] = id end
    table.sort(out)
    return out
end

local function collectAchievements()
    local out = {}
    local cats = safecall(GetCategoryList)
    if type(cats) ~= "table" then return out end
    for _, cat in ipairs(cats) do
        local n = safecall(GetCategoryNumAchievements, cat) or 0
        for i = 1, n do
            local id, name, points, completed, month, day, year = safecall(GetAchievementInfo, cat, i)
            if id and completed then
                out[#out + 1] = {
                    id = id, name = name, points = points,
                    date = year and string.format("%02d-%02d-%02d", year, month or 0, day or 0) or nil,
                }
            end
        end
    end
    return out
end

local function collectCurrencies()
    local out = {}
    local n = safecall(GetCurrencyListSize) or 0
    for i = 1, n do
        local name, isHeader, _, _, _, count = safecall(GetCurrencyListInfo, i)
        if name and not isHeader then
            out[#out + 1] = { name = name, count = count }
        end
    end
    return out
end

local function collectCompanions()
    local out = {}
    for _, kind in ipairs({ "MOUNT", "CRITTER" }) do
        local list = {}
        local n = safecall(GetNumCompanions, kind) or 0
        for i = 1, n do
            local creatureID, name, spellID = safecall(GetCompanionInfo, kind, i)
            if name then
                list[#list + 1] = { creatureID = creatureID, name = name, spellID = spellID }
            end
        end
        out[kind] = list
    end
    return out
end

local function collectGlyphs()
    local out = {}
    for i = 1, 6 do
        local enabled, glyphType, _, spellID = safecall(GetGlyphSocketInfo, i)
        out[i] = { enabled = enabled, glyphType = glyphType, spellID = spellID }
    end
    return out
end

-- Saved outfits matter disproportionately: the three Transmogrification*.json
-- files ship as 0 bytes, so appearance data is server-side only.
local function collectEquipmentSets()
    local out = {}
    local n = safecall(GetNumEquipmentSets) or 0
    for i = 1, n do
        local name, icon = safecall(GetEquipmentSetInfo, i)
        if name then
            out[#out + 1] = {
                name      = name,
                icon      = icon,
                itemIDs   = snapshot(safecall(GetEquipmentSetItemIDs, name), 2),
                locations = snapshot(safecall(GetEquipmentSetLocations, name), 2),
            }
        end
    end
    return out
end

local function collectAddOns()
    local out = {}
    local n = safecall(GetNumAddOns) or 0
    for i = 1, n do
        local name, title, _, enabled = safecall(GetAddOnInfo, i)
        out[#out + 1] = {
            name   = name,
            title  = title,
            enabled = enabled,
            loaded = safecall(IsAddOnLoaded, i) and true or false,
        }
    end
    return out
end

-- --------------------------------------------------- custom system sweep
--
-- The point of this addon. CoA's custom systems (draft, skill cards, mystic
-- enchants, wildcard, transmog, rulesets, advancement) have APIs nobody has
-- documented, so we cannot call them deliberately. Instead: find every global
-- whose name looks custom, record its type, and serialise it if it is data.
--
-- This captures both the client-side API surface and the live state of systems
-- we do not understand yet.

local CUSTOM_PATTERNS = {
    "Ascension", "ASCENSION", "CoA", "COA_",
    "SkillCard", "Skill_Card", "SKILL_CARD",
    "Transmog", "TRANSMOG",
    "Mystic", "MYSTIC",
    "Draft", "DRAFT",
    "HandOfFate", "Hand_Of_Fate", "HAND_OF_FATE",
    "Wildcard", "WILDCARD",
    "RandomEnchant", "RANDOM_ENCHANT",
    "Ruleset", "RULESET",
    "Advancement", "ADVANCEMENT",
    "Booster", "Reforge", "Rune",
}

local function looksCustom(name)
    for _, p in ipairs(CUSTOM_PATTERNS) do
        if string.find(name, p, 1, true) then return true end
    end
    return false
end

local function collectCustomGlobals()
    local api, data = {}, {}
    pcall(function()
        for k, v in pairs(_G) do
            if type(k) == "string" and looksCustom(k) then
                local vt = type(v)
                api[#api + 1] = k .. "  [" .. vt .. "]"
                if vt == "table" and not isWidget(v) then
                    -- The name still goes in apiSurface (knowing the API exists
                    -- is useful); only the contents are withheld.
                    if isSensitiveKey(k) then
                        data[k] = "<redacted-sensitive-name>"
                    else
                        data[k] = snapshot(v)
                    end
                end
            end
        end
    end)
    table.sort(api)
    return { apiSurface = api, state = data }
end

-- ------------------------------------------------------------ orchestration

local timePlayedTotal, timePlayedLevel

local function runExport(reason)
    local identity = collectIdentity()
    local realm    = identity.realm or "UnknownRealm"
    local name     = identity.name  or "UnknownChar"
    local key      = realm .. " - " .. name

    CoAExportDB.meta = {
        addonVersion = ADDON_VERSION,
        addonBuild   = ADDON_BUILD,   -- so a received file can be traced to a build
        exportedAt   = date and date("%Y-%m-%d %H:%M:%S") or nil,
        clientBuild  = select(2, safecall(GetBuildInfo)),
        clientVersion = select(1, safecall(GetBuildInfo)),
        locale       = safecall(GetLocale),
        realmList    = safecall(GetCVar, "realmList"),
        accountToken = safecall(GetCVar, "g_accountUsesToken"),
    }

    CoAExportDB.account = CoAExportDB.account or {}
    CoAExportDB.account.addons = collectAddOns()

    CoAExportDB.characters = CoAExportDB.characters or {}
    CoAExportDB.characters[key] = {
        reason         = reason,
        exportedAt     = CoAExportDB.meta.exportedAt,
        identity       = identity,
        timePlayed     = { total = timePlayedTotal, thisLevel = timePlayedLevel },
        stats          = collectStats(),
        equipment      = collectEquipment(),
        bags           = collectContainers({ 0, 1, 2, 3, 4 }),
        keyring        = collectContainers({ -2 }),
        bank           = collectContainers({ -1, 5, 6, 7, 8, 9, 10, 11 }),
        spells         = collectSpells(),
        talents        = collectTalents(),
        skills         = collectSkills(),
        reputations    = collectReputations(),
        questsCompleted = collectQuests(),
        achievements   = collectAchievements(),
        currencies     = collectCurrencies(),
        companions     = collectCompanions(),
        glyphs         = collectGlyphs(),
        equipmentSets  = collectEquipmentSets(),
        custom         = collectCustomGlobals(),
    }

    local c = CoAExportDB.characters[key]
    say("exported |cffffff00" .. key .. "|r")
    say(("  %d equipped, %d spells, %d skills, %d quests, %d achievements")
        :format(
            (function() local n = 0 for _ in pairs(c.equipment or {}) do n = n + 1 end return n end)(),
            (function() local n = 0 for _, t in ipairs(c.spells or {}) do n = n + #(t.spells or {}) end return n end)(),
            #(c.skills or {}), #(c.questsCompleted or {}), #(c.achievements or {})))
    say(("  %d custom globals found"):format(#((c.custom or {}).apiSurface or {})))
    if #(c.bank or {}) == 0 then
        say("  |cffff8800bank is empty - open your bank, then run /coaexport again|r")
    end
    say("now type |cffffff00/reload|r to write the file to disk")
end

-- ------------------------------------------------------------------ events

local f = CreateFrame("Frame", "CoAExportFrame", UIParent)
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("TIME_PLAYED_MSG")
f:RegisterEvent("BANKFRAME_OPENED")

local pending = nil

f:SetScript("OnEvent", function(self, event, arg1, arg2)
    if event == "PLAYER_LOGIN" then
        safecall(RequestTimePlayed)
        say(("v%d.0  build |cffffff00%s|r"):format(ADDON_VERSION, ADDON_BUILD))
        say("Check that build tag matches: " .. OFFICIAL_URL)
        say("If it does not match, |cffff0000do not use this addon|r.")
        say("loaded. Run |cffffff00/coaexport|r, then |cffffff00/reload|r.")
        say("Open your |cffffff00bank|r first if you can - bank contents need it.")
        pending = GetTime() + 15          -- run once unattended, in case nobody types anything

    elseif event == "TIME_PLAYED_MSG" then
        timePlayedTotal, timePlayedLevel = arg1, arg2

    elseif event == "BANKFRAME_OPENED" then
        pending = GetTime() + 1           -- bank is visible now, re-dump
    end
end)

f:SetScript("OnUpdate", function()
    if pending and GetTime() >= pending then
        pending = nil
        local ok, err = pcall(runExport, "auto")
        if not ok then say("|cffff0000export failed:|r " .. tostring(err)) end
    end
end)

SLASH_COAEXPORT1 = "/coaexport"
SLASH_COAEXPORT2 = "/coae"
SlashCmdList["COAEXPORT"] = function()
    local ok, err = pcall(runExport, "manual")
    if not ok then say("|cffff0000export failed:|r " .. tostring(err)) end
end
