# The `SMSG_PATCH_*` family: the server ships its database over the wire

Found 2026-09-04, by joining the extracted opcode table against the DBC files pulled out
of the MPQs. **This is the highest-value capture target identified so far, and it was not
on the map.**

## The finding

There are **228 `SMSG_PATCH_*` opcodes**. Every one is server-to-client; there is no
`CMSG_PATCH_*` anywhere in the 2,517-opcode table. **212 of them match, name for name, a
DBC file extracted from the client MPQs.** The remaining 16 are the same thing with
singular/plural naming drift (`SMSG_PATCH_CHALLENGE_CONDITION` against
`challengeconditions.dbc`), so the real correspondence is essentially total.

```
SMSG_PATCH_CREATURE        -> creature.dbc
SMSG_PATCH_QUEST           -> quest.dbc
SMSG_PATCH_MYSTIC_ENCHANT  -> mysticenchant.dbc
SMSG_PATCH_SKILL_CARD      -> skillcard.dbc
SMSG_PATCH_CHR_CLASSES_ROLES -> chrclassesroles.dbc
...212 of these
```

They occupy a near-contiguous block from 1383 (0x567) to 2515 (0x9D3) — allocated
deliberately as a family, not accreted.

## What it means

**Ascension patches the client's data tables at runtime, from the server.** The DBCs on
disk are a baseline; the authoritative values live server-side and are pushed down.

That reframes what a packet capture is worth. A capture is not only a record of protocol
mechanics — it carries **the server's own copy of ~228 game data tables**: creatures,
quests, items, spells, and every custom system's definitions.

This is the closest thing to a server database dump obtainable without the server's
cooperation, and it is available for exactly as long as the server answers logins.

## Consequences

**1. This partly answers "world reconstruction strategy",** listed as fog on the map. The
question was how to rebuild creature/gameobject/quest data with the WDB cache disabled and
no DB access. Answer: much of it comes down the wire as `SMSG_PATCH_*`, if the capture
catches it.

**2. It raises the value of the plainest possible session.** Logging in and doing nothing
may be worth more than an hour of deliberately exercising one custom system. The map's
instinct — that login and character-select gate everything — was right for a bigger reason
than it knew.

**3. It sharpens the "start the capture before you launch the game" rule** from good
practice into the single decisive instruction. If the patch stream fires during initial
data sync, a capture started thirty seconds late misses the entire game database.

## What is still unknown

**When the patch stream fires.** Three plausible behaviours, and they are not
distinguishable from files:

- at every login, in full — best case, any capture gets everything
- only when the client's data version differs from the server's — a client already
  up to date (ours is, patched 2026-08-31) may receive *nothing*
- lazily, per table, on first use

**The second case is the dangerous one.** If patches are version-gated, a normal login
captures nothing, and the tables would only appear to a client with stale or absent data.

This is testable in minutes with a live capture and cannot be answered any other way.
Being able to state the question precisely is the direct result of having both halves —
the opcode table and the DBCs — which is what the extraction bought.

## Immediate implication for capture

Whoever captures should do a plain login with the recorder running and check for traffic in
the 1383-2515 range. If it is there, the priority order changes: **volume of logins beats
depth of play**, and every additional person who logs in with a recorder running is
contributing a copy of the game database rather than a marginal packet sample.
