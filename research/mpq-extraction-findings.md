# Client-side data recovered from the MPQs

Extracted 2026-09-04 from the 51 custom (2026-08-31) archives in the client's `Data`
directory, using `research/extract_client_data.py`. Output lives at `D:\coa-extract\`,
kept per-archive rather than merged, because WoW patch precedence means the same path can
exist in several MPQs with different content.

**This closes ticket 14 and answers several of the map's "Not yet specified" items — all
of it offline, none of it requiring a living server.**

## What came out

| Type | Files | Notes |
|---|---:|---|
| `.dbc` | 349 | The data foundation. Includes obviously-custom tables. |
| `.lua` | 823 | **338,882 lines of readable plaintext.** Not encrypted. |
| `.xml` | 313 | Addon frame definitions. |
| `.toc` | 97 | 34 Ascension addons plus Blizzard and library addons. |

Art (222,968 `.blp`, 65,317 `.m2`, 34,989 `.ogg` and so on) was deliberately left in the
archives — it is safe on disk and irrelevant to a server spec.

## The headline: the addon Lua is not encrypted

The map recorded that on-disk `Interface/AddOns/*.pub` files are encrypted and hoped
readable Lua might exist inside the MPQs. It does. All 823 files are plaintext.

That matters because these addons are the **client half of every custom system**, written
by Ascension, describing the exact API the server exposes.

## The custom API surface

**753 distinct functions across 81 `C_*` namespaces, 2719 call sites.**
Full list in `research/custom-api-surface.txt`.

The namespaces map almost one-to-one onto the systems the map wanted specified:

| Namespace | Fns | System |
|---|---:|---|
| `C_CharacterAdvancement` | 118 | The classless advancement model |
| `C_BuildEditor` / `C_BuildCreator` / `C_BuildDraft` | 74 | Build and draft |
| `C_Wildcard` / `C_WildcardRewards` | 55 | Wildcard |
| `C_MysticEnchant` | 23 | Mystic enchants |
| `C_Appearance` / `C_AppearanceCollection` | 33 | Transmog and appearances |
| `C_SkillCard` / `C_SkillCardCollection` | 29 | Skill cards |
| `C_Manastorm` | 21 | Manastorm |
| `C_Challenge` / `C_Keystones` / `C_MythicPlus` | 50 | Challenge and mythic+ |
| `C_CharacterCreate` | 28 | The 21 custom classes |
| `C_VanityCollection` | 13 | Collections |
| `C_PlayerPoll` | 9 | Player polls (opcode 1862, seen live) |

## Custom DBCs

Beyond stock 3.3.5, these appear and are new: `mysticenchant`, `skillcard`,
`characteradvancement` (+ `categories`, `classtypes`, `essence`, `tabtypes`),
`manastorm` (+ `messages`, `modifiers`, `playergroupmodifiers`), `appearances`,
`appearancecategories`, `appearancedetails`, `itemappearances`, `itemsetappearances`,
`seasonalappearances`, `chrspecs`, `chrclassesroles`, `challenge*` (14 tables),
`charactercreationarchetype*`, `collectorcache*`, `mythicaffixes`, `mythickeystones`,
`mythicplusscaling`, `sealedcardcosts`, `vanitycollection`, `spelltags`, `spellcharges`,
`spellrank`, `enchant*suggestions`, `spell*suggestions`, `zonestory`, `supertrack`.

## Consequence for the map

Three "Not yet specified" items are now largely answered offline:

- **Classless advancement data model** — `C_CharacterAdvancement` (118 functions) plus
  `characteradvancement*.dbc` plus the already-on-disk 7.8 MB JSON.
- **MemoryBridge table provenance** — the DBCs are on disk, so much of the custom data
  foundation was never server-only.
- **Per-system wire format** — the Lua names every client-side entry point, which is the
  denominator for measuring what a capture actually covered.

What still requires a living server is unchanged: the *responses*. The Lua shows what the
client asks for, never what the server answers with.
