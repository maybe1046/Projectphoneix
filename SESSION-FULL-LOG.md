# Full session log — CoA preservation

Complete record of the working session that ran 2026-09-04 08:20 → 2026-09-05 16:35 local
(UTC+8). Written as a full account rather than a summary: what was found, what was built,
what was got wrong, and the exact techniques that worked, so none of it has to be
rediscovered.

Companion documents: `SESSION-CONTEXT.md` (short handover), `research/*.md` (per-topic
findings), `.scratch/coa-preservation/map.md` (the original plan).

---

# 0. Status at time of writing — READ FIRST

**The servers are down. The archive is closed.**

Verified 2026-09-05 16:40 by protocol probe, not by port check — the distinction matters
and I initially got this wrong.

```
world  51.254.7.227:8100   TCP accepted, then SILENT
logon  51.210.230.10:3724  TCP accepted, then SILENT
```

Both endpoints still complete a TCP handshake, which is why an earlier port check made it
look like the window was still open. It was not. The world server **must speak first** —
a live one sends `SMSG_AUTH_CHALLENGE` immediately on connect. It sends nothing. A valid
GRUNT logon challenge to the auth server likewise draws no reply. What is answering is a
leftover listener or an edge device, not the game.

**Correction:** an earlier version of this section claimed the capture window might still be
open, on the strength of the TCP handshake alone. That was wrong, and it was the kind of
wrong that would have sent someone chasing a dead server. A TCP accept is not a live
service.

One thing did change since the session began: `ascension.gg`, `www.ascension.gg` and
`launcher.ascension.gg` **now resolve** (Cloudflare, 172.67.70.128 / 104.26.x). They were
NXDOMAIN on 2026-08-31 and during most of this session — most likely GFW interference at
the time rather than a real removal, so the map's inference that the web infrastructure had
been dismantled early should be treated with suspicion. The game servers are genuinely gone;
the website is not.

Final state:

| | |
|---|---|
| game servers | **down** (TCP accepted, protocol silent) |
| capture process | still running, nothing left to capture |
| pcap | `D:\coa-capture\coa_00001_20260904135355.pcapng`, ~31.7 MB |
| memory dump | `D:\coa-capture\Ascension-472-0904-1426.dmp`, 1.68 GB |
| client + backup | intact, 39.1 GB each |
| extracted client data | `D:\coa-extract\`, 1,585 files |
| repo | pushed to `github.com/maybe1046/Projectphoneix` (private) |

Everything that required a living server is now fixed in whatever state it reached.
Everything else — the MPQ contents, the opcode table, the extracted Lua, the captured
bodies, the memory dump — is offline work with no deadline.

---

# 1. Starting position

The project existed as a plan with almost nothing executed. `map.md` had been charted
2026-08-31 with 16 issue tickets. Of those, exactly one had been done — the opcode-table
extraction — and three research agents had been dispatched whose findings never landed.

Established before this session:

- Base is stock WotLK build 12340. Logon `51.210.230.10:3724`, realm `Vol'jin - Conquest
  of Azeroth` at `51.254.7.227:8100`.
- `Extensions.dll` contains 2,123 opcode name strings against ~1,300 in stock 3.3.5.
- ~50 MB of server-authored content already on disk as plaintext JSON in `Data/Content/`.
- `Cache/WDB/*.wdb` are 32-byte headers — **client-side caching is disabled**, so creature,
  item, quest and gameobject data is re-sent every session and never persisted. This was
  the wound the whole plan was built around.
- The three `Transmogrification*.json` files are 0 bytes — that data is server-side only.
- `db.ascension.gg` and `cdn2.ascension-patch.gg` had already stopped resolving.

Machine had Python and Node but **no Wireshark, no debugger, no 7-Zip**.

---

# 2. What was done, in order

## 2.1 Verified the existing backup

The user had already copied the client. Verification rather than trust:

```
client          39.1 GB  282 files  69 MPQs  38.2 GB
client_backup   39.1 GB  279 files  69 MPQs  38.2 GB
```

The three missing files were post-backup junk (a WDB stub, two UI settings files). Backup
is sound.

Weakness noted but not acted on: it lives at
`D:\Program Files\Ascension\resources\client_backup`, inside the folder an uninstaller
would target, so one "uninstall" takes original and backup together.

## 2.2 Built the CoAExport addon

Ticket 10. Dumps character and account state to SavedVariables.

Collects: identity, money, played time, stats, all 19 equipped item **links**, bags,
keyring, bank, full spellbook, talents, skills, reputations, completed quests,
achievements, currencies, mounts/pets, glyphs, saved outfits.

Item links matter disproportionately — they carry item id, enchant, gems, suffix and the
**random-enchant seed**, which is how mystic rolls are recorded.

**The custom-globals sweep is the point of it.** Nobody has documented the draft,
skill-card, mystic or transmog APIs, so the addon cannot call them deliberately. Instead it
finds every global whose name looks custom, records its type (yielding the client-side API
surface) and serialises it if it is data.

Testing, since a broken addon shipped to strangers is unrecoverable:

- No Lua interpreter on the machine → installed `lupa`, built a mock WoW 3.3.5 API.
- **Two modes.** `full` — every API present. `hostile` — most APIs missing or throwing,
  which is what a heavily modified client may actually look like.
- Hostile result: every stock collector returned 0, **and the custom sweep still returned
  all 9 globals and 6 state tables.** It degrades to less data, never to nothing.
- Assertions: no functions/userdata reach SavedVariables, cycles broken, widgets refused,
  depth capped, a 5,000-entry table handled.

### Redaction

Added after the user asked for password cautions. The sweep matches on names like
`Ascension`, so it would happily serialise an `AscensionAuthToken` if one existed.

Two layers, applied at every depth:

- **By key** — `password`, `passwd`, `pwd`, `secret`, `token`, `auth`, `session`,
  `credential`, `apikey`, `privkey`, `srp`, `salt`, `sha1/256`, `md5`, `email`, `login`
- **By value shape** — anything matching an email address, or a run of 32+ hex characters

Verified against six planted secrets including one at
`AscensionMysticRolls.buried.deeper.authSecret` and a raw hex session key under an innocuous
key name. None survived. Counter-tested that it is not over-eager: `seed=4242`,
`displayName`, nested innocent tables and all 19 item links came through intact — item links
were the real risk, being long and numeric.

### Provenance

`ADDON_BUILD = "2026-09-04a"` printed in chat on login, plus the official-post URL and
"if it does not match, do not use this addon". The build tag is the check a non-technical
player can actually perform.

```
CoAExport.zip  SHA-256  162760ec90dcb4cb1273a018292393e1a0d854d83f68845f75ec60081dfe100a
```

**A file cannot contain its own checksum**, so the build tag is a fixed string and the
SHA-256 is computed after all edits. Packaging must therefore be the last step — any edit
to the addon invalidates the published hash.

## 2.3 Wrote the capture guide

Three skill tiers so the least technical reader still has a complete path:

| Level | Needs | Time | Saves |
|---|---|---|---|
| 1 | nothing | 10 min | your characters |
| 2 | can install a program, click a settings window | 30 min | the network protocol |
| 3 | knows what a memory dump is | 5 min | optional |

Safety sits at the **top of each section**, not in one block at the end, because readers
stop at different points.

Iterations driven by user feedback:

- **"add password cautions"** → security note, then extended to the addon path.
- **"move cautions to the top of each section"** → restructured; also raised the audience
  from "one friend" to potentially millions.
- **"try not using command prompt"** → Level 2 rewritten around Wireshark's GUI. This is
  genuinely better, not merely easier: Wireshark draws a **live traffic graph per adapter**,
  and the filter box **turns green** when valid — feedback `dumpcap` never gave. Level 3's
  `move` command became File Explorer steps; `certutil` was demoted to optional with a
  7-Zip right-click alternative.
- **"let's take screenshots"** → 8 placeholder slots with exact specs (never filled).
- **"upload to Chinese cloud storage"** → 夸克 → 阿里云盘 → 百度 ordering, with Baidu's
  4 GB free-account cap and the 分卷压缩 workaround.
- **"Chinese version"** → full localisation, not literal translation (see §6).

## 2.4 Extracted the MPQs

Ticket 14. The custom content turned out to be **~25 GB across 51 archives**, not the
~10 GB the map recorded. `patch-TA` alone holds 91,960 files.

Method: extract each archive's `(listfile)` first (instant), then targeted extraction of
non-art files only.

**Result: 1,585 files — 349 DBC, 823 Lua, 313 XML, 97 TOC.** Verified complete against the
listfiles, zero missing. Art (222,968 BLP, 65,317 M2, 34,989 OGG) deliberately left in the
archives.

## 2.5 Installed capture tooling

Wireshark 4.6.8 installer was already in Downloads. Silent install (`/S`) succeeded but
**skipped Npcap**, which is the part that actually captures — the installer has no flag to
force it, so it had to be re-run interactively.

**No reboot was needed**; the Npcap service was live immediately and `dumpcap -D`
enumerated 12 interfaces.

## 2.6 Captured a live login

See §4 for what came out of it.

## 2.7 Took a memory dump

1.68 GB full-memory dump via `MiniDumpWriteDump` with `MiniDumpWithFullMemory`, elevated.
RC4 recovery from it failed — see §5.

## 2.8 Committed and shipped

10 commits, pushed private. Two emails sent to the user: the full package
(`1a06bcb3cfa9f6dc`) and the Chinese guide alone (`1a06c16b0bc0161e`).

---

# 3. Finding: the addon Lua is not encrypted

The map hoped this might be true. It is. **338,882 lines of plaintext** — the client half
of every custom system, written by Ascension.

**753 distinct functions across 60 `C_*` namespaces:**

| Namespace | Fns | System |
|---|---:|---|
| `C_CharacterAdvancement` | 118 | classless advancement |
| `C_BuildEditor` / `BuildCreator` / `BuildDraft` | 74 | build and draft |
| `C_Wildcard` / `WildcardRewards` | 55 | wildcard |
| `C_Challenge` / `Keystones` / `MythicPlus` | 50 | challenge, mythic+ |
| `C_Appearance` / `AppearanceCollection` | 33 | transmog |
| `C_SkillCard` / `SkillCardCollection` | 29 | skill cards |
| `C_CharacterCreate` | 28 | the 21 custom classes |
| `C_MysticEnchant` | 23 | mystic enchants |
| `C_PlayerPoll` | 9 | player polls (opcode 1862, seen live) |

Custom DBCs beyond stock: `mysticenchant`, `skillcard`, `characteradvancement*`,
`manastorm*`, `appearances`, `chrspecs`, `challenge*` (14 tables), `mythickeystones`,
`sealedcardcosts`, `collectorcache*`, and more.

**Consequence:** three of the map's "Not yet specified" items became largely answerable
offline. The limit is real though — the Lua shows what the client *asks for*, never what
the server *answers with*.

---

# 4. Finding: packet bodies are plaintext

**The single most consequential discovery of the session.**

WoW 3.3.5 applies RC4 to the small per-message **header** (size + opcode) and **never to
the body**. This holds on CoA.

- **32% of the server-to-client payload is printable ASCII**
- **1,222 distinct strings** of 8+ characters extracted
- **with no session key and no memory dump**

This overturned the project's working assumption — and my own stated position — that a
passive pcap without a recovered key is an unreadable blob. It is not. The key buys
*framing*, not content.

## 4.1 Traffic shape of one login

| | frames | bytes |
|---|---:|---:|
| logon `:3724` | 9 | 2,841 |
| world `:8100` server→client | 476 | ~522 KB |
| world client→server | 378 | ~17 KB |

**494 KB down against 2.5 KB up** — roughly 200:1.

## 4.2 Recovered: the server config table

**281 server-authored settings** — Ascension's live ruleset, which exists nowhere on disk.

Wire format, established from the capture:

```
uint32  keyLength
char[]  key            "CONFIG_...", ASCII, no NUL terminator
value                  1 byte OR 4 bytes, little-endian
```

**There is no type tag.** Value width must be inferred by trying both and keeping whichever
leaves the stream on a valid next record.

The result self-validates: **all 51 one-byte values decode to 0 or 1** (28 false, 23 true),
exactly what feature flags should look like, while the 230 four-byte values are plausible
ids, amounts and levels.

My first parser assumed a fixed 4-byte value and produced confident nonsense —
`CONFIG_BUILD_DRAFT_ENABLED` read as 5889. The `*_AMOUNT` fields looked correct, which is
what made it worth checking rather than shipping.

```
CONFIG_BUILD_DRAFT_ENABLED                            1
CONFIG_BUILD_DRAFT_HIDDEN                             0
CONFIG_CHALLENGE_ENABLED                              1
CONFIG_CHALLENGE_PERMADEATH_ENABLED                   0
CONFIG_CHARACTER_ADVANCEMENT_TRAITS_ENABLED           0
CONFIG_BUILD_DRAFT_REWARD_ITEM1                 1287330
CONFIG_BUILD_DRAFT_REWARD_AMOUNT2                  5000
CONFIG_ARTIFACT_RANDOM_ENCHANT_REBORN_UNLOCK_LEVEL_1     35
```

## 4.3 Recovered: world data as JSON

The server sends **JSON on the wire**:

```json
{
  "Apply": true,
  "Name": "Crow's Cache (High Risk)",
  "Description": "High-Risk World Event: Crow's Cache...",
  "ID": "2f23ba7c-3e95-11ed-ac9a-b8cef6bab398",
  "ZoneId": 16, "X": 3483.58, "Y": -5639.73, "Z": 6.49,
  "POIFlags": 18, "Scale": 0.5, "TextureId": "venthyrassaults-64x64"
}
```

Grew to **1,295 objects** and **3,227 distinct strings** as play continued.

---

# 5. Finding: `SMSG_PATCH_*`, and why it stayed unresolved

**228 `SMSG_PATCH_*` opcodes. All server-to-client. No `CMSG` counterpart anywhere in the
2,517-opcode table. 212 match an extracted DBC file name for name**; the other 16 differ
only by singular/plural, so the correspondence is effectively total. They occupy a
near-contiguous block, 1383–2515.

Ascension patches the client's data tables at runtime from the server. The on-disk DBCs are
a baseline; authoritative values are pushed down the wire.

## 5.1 The memory dump

Taken to settle whether the patch stream actually fires. It establishes one thing firmly —
both stock HMAC seeds are present **exactly once each**:

```
S->C  cc98ae04e897eaca12ddc09342915357  @ 0x0078573e
C->S  c2b3723cc6aed9b5343c53ee2f4367ce  @ 0x0078574e
```

So CoA uses **stock 3.3.5 crypto, no custom scheme**, and everything needed to frame the
protocol is inside that dump.

## 5.2 Why RC4 recovery failed

- Byte-wise scan for 256-byte permutations found 188 candidates, 137 "shuffled" — nearly
  all AES T-tables and sequential lookup tables sliding under the window.
- The client does **not** use OpenSSL's `RC4_KEY` layout (S-box as 256 `uint32`). A
  full-dump scan returned only two identity tables with indices (2097152000, 369098752)
  that are not valid RC4 `x`/`y`.
- Even with the correct S-box, the dump holds **mid-stream** state, advanced by every header
  byte since login. Decryption needs the initial state, or the 40-byte session key plus a
  known stream offset.

Identifying the cipher object is a reverse-engineering task, not a scan. **Stopped rather
than burn the remaining live window on uncertain payoff.** This is deferred work, not lost
work: dump and pcap are preserved together and can be framed offline with no time pressure.

## 5.3 The bounded conclusion

Without framing, `SMSG_PATCH_*` cannot be positively identified. What the readable bodies
do establish:

- 494 KB per login is **far too small** to be the 228-table set — `creature.dbc` alone
  exceeds it.
- Attempts to inflate the high-entropy bulk as zlib produced megabytes containing **zero
  strings** — false positives off `0x78` bytes inside encrypted headers, not compressed game
  data.

**Most likely reading:** the patch stream is version-gated, and this client — patched
2026-08-31 and fully current — received only a slice. **This is inference from traffic
volume, not proof.**

---

# 6. The Chinese guide

Localisation, not literal translation:

- **Wireshark labels bilingual** — `捕获(Capture)`, `输入(Input)`, `输出(Output)`. The
  installed client may be either language; a Chinese-only label would strand people.
- **Accelerators named natively** — `UU加速器 / 网易UU、迅游、Clash`.
- **Cloud storage reordered for the audience** — 夸克 → 阿里云盘 → 百度, with Baidu's
  free-tier throttling and 4 GB single-file cap called out plus the 分卷压缩 fix.
- **The sharpest line**: 提取码只能挡一下陌生人，不等于私密 — an extraction code slows
  strangers down, it does not make a file private. That is the misconception that would
  otherwise get someone's password posted publicly.
- **Paths, commands, checksum and build tag untranslated** — which is exactly why the guide
  says to anchor trust to the addon rather than the document.

---

# 7. Mistakes made, and what they cost

Recorded so they are not repeated or re-adopted.

## 7.1 `dumpcap -f` placement — recorded the user's unrelated traffic

`-f` binds only to the interface named by the **preceding** `-i`. Writing
`-i 9 -i 5 -f "..."` attached the filter to WiFi only and left the Clash tunnel — where all
game traffic actually goes — recording **unfiltered**.

For about two hours it captured general internet traffic instead of game traffic. Contents
were TLS-encrypted so nothing readable was exposed, but it should never have been written.
Stopped, all three files deleted, nothing analysed or kept.

Correct form puts `-f` **before** the first `-i`. Verified: 0 packets when idle, game IPs
only when active.

## 7.2 "A pcap without a memory dump is an unreadable blob"

Stated confidently, written into the guide, and **used to justify asking strangers to send
password-bearing memory dumps**. Wrong — bodies are plaintext (§4). Corrected in the guide;
Level 3 now reads "genuinely optional… if you are at all unsure about the password risk,
skip this level."

This is the correction that most changed the risk profile of the whole effort.

## 7.3 "Volume of logins beats depth of play"

Written on the assumption that every login carries the database, and acted on — the guide's
shot list led with repeated logins. 494 KB per login does not support it. Withdrawn; depth
of play is the better use of the window.

## 7.4 Fixed-width parse of the config table

First decoder assumed 4-byte values throughout. Produced plausible-looking garbage for every
boolean flag. Caught only because `CONFIG_BUILD_DRAFT_ENABLED = 5889` is obviously not a
flag.

## 7.5 Guide bug: "click the adapter whose graph is moving"

Would have made every accelerator user capture **nothing**, discovered only after shutdown.
Found by testing on this machine, where Clash routes all game traffic through a TUN adapter
at `198.18.0.1`. Guide now says select **every** adapter.

## 7.6 Screenshot placeholders left broken

8 image links pointing at files that were never produced. Stripped from the distribution
copy; the source guide still carries them as specs.

---

# 8. Techniques and gotchas worth keeping

- **MPQEditor `/fp` is broken** in build 3.6.0.866 — flattens output and collides every
  addon's `core.lua`. Extract per-directory instead.
- **Bash `"\\$var"` escapes the dollar** — `"C:\\temp\\$base"` yields a literal `$base`.
  Use `'C:\temp\'"$base"`.
- **`dumpcap` dies when detached** with `Start-Process -WindowStyle Hidden`; it needs a
  console. Launch via `cmd /k` from a batch file.
- **`Get-FileHash` does not exist** on this machine's PowerShell (v2-era). `certutil
  -hashfile` works everywhere and is what the guide tells users to run — verified.
- **Wireshark silent install skips Npcap** and has no flag to force it.
- **Extracting `(listfile)` from an MPQ is instant** — inventory before extracting content.
- **`numpy` cumsum over 1.7 GB in int64 needs 12.5 GB** — chunk it.

---

# 9. Artifacts

## In the repo

```
CAPTURE-GUIDE.md                          the guide (source, with screenshot specs)
SESSION-CONTEXT.md                        short handover
SESSION-FULL-LOG.md                       this file
addon/CoAExport/CoAExport.{toc,lua}       the addon
addon/CoAExport/test_harness.lua          mock-client tests, full + hostile modes
addon/CoAExport.zip                       distributable, checksummed
dist/CoA-preservation-guide.md            distribution copy, EN
dist/CoA-preservation-guide.zh-CN.md      distribution copy, 中文
dist/kook-announcement.md                 ready-to-paste post
research/ascension-opcodes.{csv,json}     2,517 opcodes
research/custom-api-surface.txt           753 functions by namespace
research/system-opcode-map.md             563 opcodes assigned to 59 systems
research/server-config.csv                281 decoded server settings
research/*.md                             per-topic findings
research/*.py                             extract, decode, map, harvest
screenshots/README.md                     specs for the 8 unfilled slots
```

## Outside the repo (gitignored)

```
D:\coa-extract\                           1,585 files, 1.0 GB
D:\coa-capture\coa_*.pcapng               ~31.7 MB
D:\coa-capture\Ascension-472-0904-1426.dmp  1.68 GB
research/capture-strings.txt              3,227 strings — third-party chat, held back
research/capture-json.json                1,295 objects — held back
```

The last two were **deliberately excluded from git**: they contain other players' public
LFM chat and the user's character names. Everything derived from them is committed, so no
analysis was lost.

---

# 10. Capture coverage as last measured

Re-measure with `python research/harvest_capture.py`.

| System | Evidence | |
|---|---:|---|
| Hand of Fate | **0** | never captured |
| Mail | **0** | never captured |
| Transmog | **2** | **most urgent** — 0-byte files on disk, server-side only |
| Collections | 6 | thin |
| Manastorm | 6 | thin |
| Auction house | 12 | thin |
| Professions | 12 | thin |
| Skill cards | 30 | adequate |
| Wildcard | 58 | good |
| Challenge/mythic | 119 | good |
| Mystic enchant | 232 | well covered |

---

# 11. What remains

Everything that needed a living server is now closed. What was captured is what there is.

**Offline, no deadline:**

1. **RC4 / session-key recovery** from `Ascension-472-0904-1426.dmp` (§5.2), then header
   framing of the pcap. This is the highest-value remaining task: it converts 31.7 MB of
   readable-but-unframed traffic into an opcode-by-opcode record, and settles whether
   `SMSG_PATCH_*` fired.
2. **Per-system specification** from the 338,882 lines of extracted Lua plus the captured
   bodies. The Lua gives every client-side entry point; the capture gives real server
   responses for the systems that were exercised.
3. **DBC parsing** — 349 tables in `D:\coa-extract\`, the data foundation for any future
   server.
4. The map's deferred decisions: emulator base, spec structure, which systems get
   specified first.

**Permanently lost:**

- Hand of Fate and mail traffic — zero coverage, never captured.
- Transmog appearance data beyond the 2 fragments — the on-disk files are 0 bytes, so this
  existed only on the server.
- Everything else nobody exercised while the servers lived.

**Never done:** the guide and addon were finished, checksummed and emailed but — as far as
this session knows — never posted to the community. That was the only item with a hard
deadline. Whatever other people might have captured, they did not capture because of this
work.
