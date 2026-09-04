# Extract and inventory the MPQ contents

Type: task
Status: open
Blocked by: none

## Question

Unpack the patch-A..patch-CX MPQs (~10 GB of custom content) plus patch-D.MPQ from
Data/area-52, and produce an inventory: DBC/DB2 files and their schemas, Lua and XML from
the Ascension addons, custom models, maps, and anything else CoA added over stock 3.3.5.

Pure offline work — the MPQs are on disk and are not going anywhere — so this must not
consume window hours. It is here because the DBCs are a large part of the eventual server's
data foundation, and because the Ascension addon Lua reveals custom system semantics and
the client-side API surface without any disassembly at all.

D:\mpqeditor is already installed. Note that on-disk Interface/AddOns/*.pub files are
encrypted; the readable Lua, if any, is inside the MPQs.
