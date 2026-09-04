# Map: Conquest of Azeroth preservation

## Destination

A complete archive of everything about Ascension's Conquest of Azeroth that cannot be
recovered after the servers stop on **5 September 2026**, plus a specification precise
enough that a compatible server emulator could be built from it later — by us, or by
anyone else.

Reaching the destination does NOT mean a running emulator. It means nothing further is
lost to time, and the remaining work is ordinary engineering against a written spec.

## Notes

**Domain.** World of Warcraft 3.3.5a (build 12340) private-server emulation. The client
at `D:\Program Files\Ascension\resources\client` is the primary specimen. AzerothCore
(https://github.com/azerothcore/azerothcore-wotlk) is the reference implementation of the
*stock* 3.3.5 protocol and server model — a baseline to diff against, never a drop-in.

**The hard deadline.** Shutdown is **2026-09-04 19:00 PT** = 2026-09-05 02:00 UTC =
2026-09-05 ~10:00 UTC+8. Charted 2026-08-31. Budget ~10 hours/day until then.

**Teardown has already begun.** As of 2026-08-31, `db.ascension.gg` and
`cdn2.ascension-patch.gg` no longer resolve. Services are dying ahead of the announced
date, so readiness beats optimality: a crude capture that exists outranks a good plan that
arrives late.

**Why it is shutting down.** A Blizzard cease-and-desist and lawsuit issued June 2026, over
copyright infringement and donation monetization. Ascension is moving to a non-Blizzard
project, so a source or data release should not be planned for. This is also why public
distribution stays firmly out of scope: it walks into live, demonstrated legal machinery.

**Network constraint.** This machine sits behind GFW-style filtering. `archive.org`,
`archive.ph`, memento, and Claude's own `WebFetch` all fail; `WebSearch` works. Clash for
Windows is installed at `D:\Clash for Windows` and must be enabled for archive lookups and
GitHub tool downloads.

**The organising principle.** The hours before shutdown buy *only* things that require a
living server. Anything derivable from files already on disk (Extensions.dll, the MPQs,
`Data/Content/*.json`) is free forever and must not consume the window — with one
exception: work that measurably *multiplies* capture coverage earns its place inside the
window. Opcode-table extraction qualifies; spec writing does not.

**Execution override.** Wayfinder is normally planning-only. This map deliberately
carries execution, because half the destination — the archive — is manual work that
expires. `task` tickets here really do the thing.

**Risk posture.** Aggressive capture accepted, including interception the anticheat
(`DivxTac.dll`, `CMSG_ANTICHEAT_ALERT`) may flag. Prefer a secondary account for
interception where one is available; keep one account clean as a fallback capture vehicle.

**Skills to consult**: `research` for AFK investigation, `grilling` + `domain-modeling`
for decisions, `prototype` where a rough artifact beats an argument.

## Established facts

From the client, verified 2026-08-31:

- Base is stock WotLK **build 12340**. Logon `51.210.230.10:3724` (GRUNT, token-based,
  `g_accountUsesToken "1"`); realm `Vol'jin - Conquest of Azeroth` at `51.254.7.227:8100`.
- `Extensions.dll` (12.6 MB) contains **2,123 opcode name strings** vs ~1,300 in stock
  3.3.5. Custom families: `*_DRAFT_HAND_OF_FATE_*`, `*_SKILL_CARD*`, `*_RANDOM_ENCHANT_*`,
  `*_MYSTIC_*`, `*_TRANSMOG_*`, `*_WILDCARD_*`, `*_ASCENSION_*`, plus a non-stock in-world
  `CMSG_AUTH_SRP6_BEGIN/PROOF/RECODE` handshake. Live traffic confirms opcodes 1862 and
  2304, far above stock WotLK's range.
- **~50 MB of server-authored content is already on disk** as plaintext JSON in
  `Data/Content/` (CharacterAdvancement 7.8 MB, SkillCard 2.4 MB, SpellRank, ItemVariation,
  TradeSkillRecipe, HandOfFateQuest, the Spell/Enchantment suggestion matrices) plus
  `Localization/{Item,Spell,Unit}`. The three `Transmogrification*.json` are 0 bytes —
  that data is server-side only.
- `MMgr64.exe` / MemoryBridge hosts 6 large tables out-of-process for the 32-bit client;
  largest is 563,598 records x 64 B.
- **`Cache/WDB/*.wdb` are 32-byte headers — client-side caching is disabled.** Creature,
  item, quest, gameobject and NPC data is re-sent every session and never persisted.
  This is the wound: most of the game world is observable only while the server lives.
- ~10 GB of custom content in `patch-A` .. `patch-CX` MPQs, dated 2026-08-31 04:50 — very
  likely the final build. With the patch CDN gone these are **irreplaceable**, not merely
  safe.
- CoA's headline feature is **21 custom classes, three specializations each** — a different
  shape from classic Ascension's classless system.
- Machine: 65 GB free on D:, 52 GB on C:. Has Python 3.12, Node, git, PostgreSQL,
  `D:\mpqeditor`. Lacks Ghidra, IDA, x64dbg, Wireshark, 7-Zip, .NET SDK.

## Decisions so far

- **Destination is archive + spec, not a running server** — building the emulator is a
  multi-month project with no deadline; the archive has a deadline of five days. Settled
  in charting, 2026-08-31.
- **Aggressive capture from day one**, accepting ban risk, rather than staging risk to the
  final day. User's call against a recommendation to stage. Settled in charting.
- **Budget is ~10 hours/day**, not 10 hours total. Settled in charting.
- **db.ascension.gg is already gone** — NXDOMAIN as of 2026-08-31, confirmed against a
  public resolver. No scrape is possible; only archived mirrors remain, if any.
  See [Is db.ascension.gg scrapeable in the window?](issues/03-db-ascension-gg-scrapeability.md).
- **Capture readiness now outranks capture quality**, because teardown started early and
  the world server may go without warning.
  See [Get a crude capture running immediately](issues/16-crude-capture-now.md).

## Not yet specified

Fog toward the destination — real, in scope, not yet sharp enough to ticket:

- **Per-system wire format.** Once the opcode table and captures exist, each custom system
  (draft, skill cards, mystic enchants, wildcard, transmog, rulesets) needs its packet
  structures documented. Likely one ticket per system, but the split depends on what the
  captures actually cover.
- **World reconstruction strategy.** With the WDB cache disabled and no server DB, how do
  creature/gameobject/quest/spawn data get rebuilt? Options range from stock-WotLK
  baseline + observed diffs, to scraped `db.ascension.gg`, to accepting loss. Cannot be
  scoped until we know what the scrape yields.
- **Classless advancement data model.** How `CharacterAdvancementData.json` and the
  MemoryBridge tables relate to spell learning, Ascension points, and the talent
  replacement. Suspected to be largely client-side and therefore recoverable offline.
- **MemoryBridge table provenance.** Whether the 6 tables are built from files on disk
  (recoverable) or pushed by the server (not). Determines how much of the custom DB we
  already have.
- **Auth and account model.** The token logon and in-world SRP6 handshake need specifying
  before anything can log in. Blocked on captures of the login sequence.
- **Definition of a playable milestone.** If someone later builds from this spec, what is
  the first thing that should work? Deferred until the spec's scope is known.

## Out of scope

- **Building the emulator.** The destination is the spec; implementation is a separate
  effort against it.
- **Public or multiplayer hosting.** Not a goal, and it changes the legal and operational
  picture entirely.
- **Client or asset modification.** The MPQs are safe on disk; nothing needs changing.
- **Anything requiring Ascension's cooperation.** No assumption of a data release, source
  drop, or official blessing. Now near-certain given the C&D. Upside, never a plan.
- **Scraping db.ascension.gg.** The target no longer exists.
  See [Scrape db.ascension.gg](issues/09-scrape-db-ascension-gg.md), closed unstarted.
