# Extract the opcode name-to-value table from Extensions.dll

Type: task
Status: open
Blocked by: none

## Question

Extensions.dll contains all 2,123 opcode name strings. It almost certainly also contains
the name-to-value mapping — as parallel arrays, a table of {name, id} structs, or a
dispatch switch. Recover that mapping.

At a 10-hour total budget this was post-mortem work. At 10 hours/day it moves inside the
window, because it is a capture multiplier: knowing which opcodes exist, and their numeric
ids, tells us which systems to go exercise in-game, and lets us measure live coverage
against a known denominator instead of guessing.

Start with the cheap approach — a Python byte-pattern search around the string table,
looking for pointer-adjacent integers — before reaching for Ghidra. Verify against the two
opcodes observed live: 1862 (0x746, player polls) and 2304 (0x900, unhandled).

Output: a machine-readable opcode table (name, id, direction) committed to the repo, plus a
diff against AzerothCore's stock 3.3.5 enum showing exactly what CoA added.
