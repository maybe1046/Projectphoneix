# Session context — 2026-09-04

Full state of the Conquest of Azeroth preservation effort as of 2026-09-04 ~15:40 local
(UTC+8). Written as a handover: everything a fresh session needs to continue without
re-deriving anything.

---

## 1. The situation

**Shutdown: 2026-09-05 10:00 Beijing** = 2026-09-04 19:00 PT = 2026-09-05 02:00 UTC.
At time of writing: **~18 hours left**.

Ascension's Conquest of Azeroth (WoW 3.3.5a build 12340, heavily modified private server)
is closing after a Blizzard cease-and-desist issued June 2026. The goal is an **archive
plus a specification**, not a running emulator — see `.scratch/coa-preservation/map.md`.

**Servers were still up and answering** at last check (15:40): logon `51.210.230.10:3724`
and world `51.254.7.227:8100`.

---

## 2. Where everything lives

| Path | What | In git? |
|---|---|---|
| `D:\Projects\projectphoneix` | the repo | yes |
| `D:\Program Files\Ascension\resources\client` | live client, 39.1 GB | no |
| `D:\Program Files\Ascension\resources\client_backup` | **verified complete backup** | no |
| `D:\coa-extract\` | 1,585 files pulled from the MPQs, 1.0 GB | no (gitignored) |
| `D:\coa-capture\` | pcapng + memory dump + sessions.txt | no (gitignored) |
| `C:\temp\mpqlist\` | per-archive MPQ listfiles | no |
| `D:\Projects\projectphoneix\dist\` | distribution package (guides + addon zip) | yes |

**Remote:** `https://github.com/maybe1046/Projectphoneix` — **private**, 9 commits.
Note this is *not* `ttma1046/Projectphoneix` as originally requested; `gh` on this machine
is authenticated as `maybe1046` and cannot create repos under another user. Transfer in
GitHub settings if the other account is wanted.

---

## 3. What is running right now

**A packet capture is live.** Minimised console window titled `CoA capture - DO NOT CLOSE`.

```
dumpcap -f "host 51.254.7.227 or host 51.210.230.10" -i 9 -i 5 \
        -b filesize:100000 -b files:200 -w D:\coa-capture\coa.pcapng
```

Restart with `D:\coa-capture\start-capture.bat` if it dies.
Interface 9 = Clash tunnel, interface 5 = WiFi.

---

## 4. Completed work

- **Client backup verified** — 69 MPQs, 38.2 GB, byte-count identical, nothing missing.
- **Opcode table** — 2,517 opcodes from `Extensions.dll` (pre-existing, from 2026-09-01).
- **MPQ extraction** — 1,585 non-art files: 349 DBC, 823 Lua, 313 XML, 97 TOC. Verified
  complete against listfiles, zero missing.
- **CoAExport addon** — written, tested (mock client, full + hostile API modes), installed
  to the live client, packaged, checksummed.
- **Capture guide** — English + Chinese, three skill tiers, safety at the top of each.
- **Live capture** — one login session captured and mined.
- **Memory dump** — 1.68 GB, taken while logged in, preserved.
- **Emailed** to chandlerfang@gmail.com: addon zip + both guides + KOOK announcement
  (message id `1a06bcb3cfa9f6dc`).

---

## 5. The four findings that matter

### 5.1 The addon Lua inside the MPQs is not encrypted

The map hoped this might be true; it is. **338,882 lines of plaintext**, the client half of
every custom system. From it: **753 functions across 60 `C_*` namespaces** —
`C_CharacterAdvancement` (118), `C_BuildEditor`/`BuildCreator`/`BuildDraft` (74),
`C_Wildcard` (55), `C_MysticEnchant` (23), `C_SkillCard` (29).
→ `research/mpq-extraction-findings.md`, `research/custom-api-surface.txt`

### 5.2 Packet **bodies** are plaintext — only headers are encrypted

WoW 3.3.5 applies RC4 to the per-message header, never the body. **32% of the
server-to-client payload is printable ASCII.** 1,222 distinct strings came out of a capture
with **no session key and no memory dump**.

This overturned the project's working assumption that a passive pcap is useless without a
recovered key. It is not. The key buys *framing* (which opcode, where messages start), not
content.
→ `research/login-capture-findings.md`

### 5.3 The server config table is recoverable

**281 server-authored settings** decoded out of a login — Ascension's live ruleset, which
exists nowhere on disk. Wire format is `uint32 keyLength | key | value`, **no type tag**,
value is 1 *or* 4 bytes. Width must be inferred by trying both and keeping whichever leaves
the stream on a valid next record.

Self-validating: all 51 one-byte values decode to 0 or 1. A fixed 4-byte read produces
confident nonsense (`CONFIG_BUILD_DRAFT_ENABLED` as 5889).
→ `research/server-config.csv`, `research/decode_server_config.py`

### 5.4 `SMSG_PATCH_*` — 228 opcodes that mirror the DBC tables

All server-to-client, no `CMSG` counterpart. **212 match an extracted DBC name for name**;
the other 16 differ only by singular/plural. Ascension patches the client's data tables at
runtime from the server, so the on-disk DBCs are a baseline and the authoritative values
are pushed down the wire.
→ `research/patch-opcodes-finding.md`

---

## 6. Things I got wrong and corrected — do not re-adopt them

**"A pcap without a memory dump is an unreadable blob."** False. Bodies are plaintext
(5.2). Memory dumps went from mandatory to optional, which matters a lot because a dump can
carry the account password and was being requested from strangers. Guide corrected.

**"Volume of logins beats depth of play."** Withdrawn. Written assuming every login carries
the whole database. A login is 494 KB — far too small for the 228-table set, so the patch
stream is most likely version-gated and an up-to-date client receives only a slice. Depth of
play is the better use of the window. Guide corrected.

**`dumpcap -f` placement.** `-f` binds only to the interface named by the **preceding**
`-i`. Writing `-i 9 -i 5 -f "..."` filtered WiFi only and left the Clash tunnel recording
**unfiltered** — it captured ~2 hours of unrelated traffic before I noticed. Those files
were deleted. The filter must come **before** the first `-i`. Verified: 0 packets idle,
game IPs only when active.

**MPQEditor `/fp`** is broken in build 3.6.0.866 — it flattens output and collides every
addon's `core.lua`. Extraction is grouped per directory instead.

---

## 7. Open questions

**Did `SMSG_PATCH_*` actually fire on the captured login?** Unresolved. Needs header
framing → needs the RC4 state → needs deeper RE than the window allowed.

**RC4 recovery failed.** The dump contains both stock HMAC seeds (`cc98ae04…` at
`0x0078573e`, `c2b3723c…` at `0x0078574e`), each exactly once, confirming **stock 3.3.5
crypto, no custom scheme**. But: a byte-scan found 188 permutation candidates, nearly all
AES T-tables; the client does **not** use OpenSSL's `RC4_KEY` layout (256×uint32); and the
dump holds mid-stream state anyway, so decryption needs the initial state or the 40-byte
session key plus a known offset. **Deferred, not lost** — the dump and pcap are preserved
together and this can be done offline after shutdown.

---

## 8. Capture coverage — measured, not guessed

Run `python research/harvest_capture.py` to re-measure. As of 14:45:

| System | Evidence | Status |
|---|---:|---|
| Hand of Fate | **0** | nothing captured |
| Mail | **0** | nothing captured |
| Transmog | **2** | **most urgent** — ships as 0-byte files on disk, server-side only |
| Collections | 6 | thin |
| Manastorm | 6 | thin |
| Auction house | 12 | thin |
| Professions | 12 | thin |
| Skill cards | 30 | adequate |
| Wildcard | 58 | good |
| Challenge/mythic | 119 | good |
| Mystic enchant | 232 | well covered |

Payload has grown 534 KB → 5.5 MB; JSON objects 91 → 1,295; strings 1,222 → 3,227.

---

## 9. What to do next, in priority order

1. **Post the guide to the community.** Package is finished, checksummed and emailed. This
   is the only item with a hard deadline — every hour costs other people's capture time.
   The KOOK link in the guide is a channel URL that outsiders cannot open, so the build tag
   and SHA-256 should also be pinned somewhere publicly readable.
2. **Play the coverage gaps** with the capture running: transmog first, then Hand of Fate
   and mail.
3. **Re-run** `harvest_capture.py` after each batch to confirm data actually landed.
4. **After shutdown**, offline and unhurried: RC4/session-key recovery from the dump, then
   header framing, then per-system wire formats.

---

## 10. Verification anchors

```
CoAExport.zip  SHA-256  162760ec90dcb4cb1273a018292393e1a0d854d83f68845f75ec60081dfe100a
Build tag               2026-09-04a
```

Any edit to the addon invalidates the checksum, so **packaging must be the last step**
before publishing. Regenerate the zip, the hash and the guide together.

---

## 11. Deliberately excluded from git

- `research/capture-strings.txt` and `research/capture-json.json` — 3,227 strings from live
  traffic including other players' public LFM chat and the user's 3 character names. Mild,
  but it is other people's traffic. Everything derived from them is committed, so no
  analysis is lost.
- All `.pcapng` and `.dmp` files — too large, and dumps can contain credentials.

---

## 12. Machine notes

- Python 3.12 with `lupa` (Lua 5.5, used to test the addon) and `numpy` installed this
  session.
- Wireshark 4.6.8 + Npcap installed this session. **No reboot was needed.**
- Clash for Windows runs in TUN mode; **all game traffic routes through the tunnel adapter**
  (`198.18.0.1`), not WiFi. This is why the guide tells everyone to select every adapter —
  Chinese players overwhelmingly use accelerators (UU加速器, 迅游, Clash) and would
  otherwise capture nothing.
- `gh` authenticated as `maybe1046`. Git identity is Chandler / chandlerfang@gmail.com.
