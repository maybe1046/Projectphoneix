# What shape is the specification?

Type: grilling
Status: open
Blocked by: 08

## Question

Settle the form of the deliverable: which parts are prose, which are machine-readable, and
how they are organised.

Working assumption from charting: machine-readable where the data is mechanical (opcode
tables, packet structures, DB schemas, the Data/Content JSON formats), prose where
semantics need explaining (how the draft works, what an Ascension point does, how mystic
enchants roll). Codegen-ability is the test for the mechanical parts — if an implementer
has to retype it, it is in the wrong format.

Also decide how the spec references the archive, so a reader can get from a claim in the
prose to the packets that justify it.

Deferred until after capture: the spec's structure should follow the shape of what we
actually recovered, not a guess made before we had it.
