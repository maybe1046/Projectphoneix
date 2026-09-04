# First live capture: what a CoA login actually contains

Captured 2026-09-04 14:01 local, one login to `Vol'jin - Conquest of Azeroth`.
796 packets, 556 KB. Client behind Clash in TUN mode, so capture ran on the tunnel
adapter as well as WiFi.

## Headline: the packet bodies are not encrypted

WoW 3.3.5a applies RC4 to the small per-message **header** (size + opcode), never to the
body. That holds on CoA. **32% of the server-to-client payload is printable ASCII**, and
1,222 distinct strings of 8+ characters came straight out of the capture with **no session
key and no memory dump**.

This overturns the working assumption recorded earlier in the project - that a passive pcap
without a recovered session key is an unreadable blob. It is not. The content is readable
today. What the session key buys is the *framing*: which opcode each message is and where
message boundaries fall.

**Consequence:** memory dumps drop from mandatory to optional. Given a dump can carry the
account password in plain text and was being requested from strangers, this materially
lowers the risk of the whole capture effort. The guide has been corrected.

## Traffic shape

| | frames | bytes |
|---|---:|---:|
| logon `51.210.230.10:3724` | 9 | 2,841 |
| world `51.254.7.227:8100` (server -> client) | 476 | ~522 KB |
| world (client -> server) | 378 | ~17 KB |

**494 KB down against 2.5 KB up** - roughly 200:1. The login is overwhelmingly a
server-side data push, which is consistent with the `SMSG_PATCH_*` hypothesis, though it
does not confirm it (see open questions).

## Recovered: the server config table

**281 server-authored settings**, decoded and saved to `research/server-config.csv`.
This is Ascension's live ruleset. It exists nowhere on disk and dies with the server.

Wire format, established from the capture:

```
uint32  keyLength
char[]  key            "CONFIG_...", ASCII, no NUL
value                  1 byte OR 4 bytes, little-endian
```

There is no type tag. Value width has to be inferred by trying both and keeping whichever
leaves the stream on a valid next record - `research/decode_server_config.py` does this.
The result self-validates: **all 51 one-byte values are 0 or 1** (28 false, 23 true), which
is what feature flags should look like, while the 230 four-byte values are plausible ids,
amounts and levels. A fixed 4-byte read instead produces confident nonsense
(`CONFIG_BUILD_DRAFT_ENABLED` reads as 5889).

Sample:

```
CONFIG_BUILD_DRAFT_ENABLED                        1
CONFIG_BUILD_DRAFT_HIDDEN                         0
CONFIG_CHALLENGE_ENABLED                          1
CONFIG_CHALLENGE_PERMADEATH_ENABLED               0
CONFIG_CHARACTER_ADVANCEMENT_TRAITS_ENABLED       0
CONFIG_BUILD_DRAFT_REWARD_ITEM1             1287330
CONFIG_BUILD_DRAFT_REWARD_AMOUNT2              5000
CONFIG_ARTIFACT_RANDOM_ENCHANT_REBORN_UNLOCK_LEVEL_1  35
```

These answer questions the client files cannot: which systems were live at shutdown, what
the draft actually paid out, at what level each enchant tier unlocked.

## Recovered: world data as JSON

The server also sends **JSON objects on the wire**. 91 recovered, all parsing cleanly:

```json
{
  "Apply": true,
  "Name": "Crow's Cache (High Risk)",
  "Description": "High-Risk World Event: Crow's Cache\nDefend the location until...",
  "ID": "2f23ba7c-3e95-11ed-ac9a-b8cef6bab398",
  "ZoneId": 16, "X": 3483.58, "Y": -5639.73, "Z": 6.49,
  "POIFlags": 18, "Scale": 0.5, "TextureId": "venthyrassaults-64x64"
}
```

World event points of interest with coordinates, zone ids, GUIDs and player-facing text.
Also in the stream: the character list, quest text, and live chat.

## Open questions

**Did `SMSG_PATCH_*` fire?** Not established. 494 KB is far too small to be the full
228-table set - `creature.dbc` alone would exceed it - so either the patch stream is
version-gated and this up-to-date client (patched 2026-08-31) received little, or those
opcodes fire under conditions this login did not meet. Deciding this needs header decoding,
which needs a session key, which needs a memory dump.

**This is now the strongest remaining argument for a Level 3 dump** - not to read the data,
which is already readable, but to identify which opcodes carry it.

## Method note

The first capture attempt was wrong and produced nothing usable. `dumpcap`'s `-f` applies
only to the interface named by the *preceding* `-i`, so `-i 9 -i 5 -f "..."` filtered WiFi
only and left the tunnel adapter recording unfiltered. The filter must come **before** the
first `-i` to apply to all interfaces. Verified: 0 packets when idle, game-server IPs only
when active.


---

# Addendum, 14:30 — memory dump taken, RC4 not recovered

A full-memory dump of the running client was captured while logged in:
`D:\coa-capture\Ascension-472-0904-1426.dmp`, 1.68 GB, valid MDMP.

## What the dump establishes

Both stock WoW 3.3.5 header-encryption HMAC seeds are present, **exactly once each**:

```
S->C  cc 98 ae 04 e8 97 ea ca 12 dd c0 93 42 91 53 57   @ 0x0078573e
C->S  c2 b3 72 3c c6 ae d9 b5 34 3c 53 ee 2f 43 67 ce   @ 0x0078574e
```

CoA therefore uses the **stock 3.3.5 scheme**: RC4 over the per-message header, keyed by
HMAC-SHA1(seed, sessionKey). No custom crypto. Everything needed to frame the protocol is
inside this dump.

## What was not achieved, and why

Recovering the live RC4 state failed inside the window.

- A byte-wise scan for 256-byte permutations found 188 candidates, 137 of them
  "shuffled". Nearly all are AES T-tables and sequential lookup tables sliding under the
  window, not cipher state.
- The client does **not** use OpenSSL's `RC4_KEY` layout (S-box as 256 `uint32`). A
  full-dump scan for that structure returned only two identity tables, with indices
  (2097152000, 369098752) that are not valid RC4 `x`/`y`.
- Even given the correct S-box, the dump holds the state *mid-stream*, advanced by every
  header byte processed since login. Decryption needs the initial state or the 40-byte
  session key plus a known stream offset.

Identifying the cipher object is a reverse-engineering task, not a scan. It was stopped
rather than consume the remaining live window on uncertain payoff.

**This is deferred work, not lost work.** The dump and the pcap are preserved together and
the framing can be done offline after shutdown, with no time pressure.

## Consequence: the PATCH hypothesis is bounded, not confirmed

Without framing, `SMSG_PATCH_*` cannot be positively identified. What the readable bodies
do establish:

- The login is a **494 KB down / 2.5 KB up** push — consistent with a data-sync stream.
- **494 KB is far too small to be the 228-table set.** `creature.dbc` alone exceeds it.
- Attempts to inflate the high-entropy bulk as zlib produced megabytes containing **zero
  strings** — false positives off `0x78` bytes inside encrypted headers, not compressed
  game data. The bulk is encrypted headers plus bit-packed object fields.

**Most likely reading:** the patch stream is version-gated, and this client — patched
2026-08-31 and fully current — received only a slice. This is the case flagged as dangerous
in `patch-opcodes-finding.md`.

**Revision to earlier advice.** "Volume of logins beats depth of play" was written on the
assumption that every login carries the database. That assumption is not supported. For an
up-to-date client, logins yield the config table and world data — valuable, but not the
DBC set. Depth of play, which puts more readable bodies on the wire, is the better use of
the remaining window. This is inference from traffic volume, not proof.
