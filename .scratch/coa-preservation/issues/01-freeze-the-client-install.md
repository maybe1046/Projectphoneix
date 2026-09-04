# Freeze the client install

Type: task
Status: open
Blocked by: none

## Question

Make a verified, checksummed second copy of the client directory so that the ~38 GB of
client — including the ~10 GB of patch-A..patch-CX custom MPQs and the ~50 MB of
Data/Content JSON — cannot be lost to a reinstall, a drive failure, or a careless cleanup
in six months.

Decide and record: where the master copy lives (second physical drive, external media, or
cloud), and whether 65 GB free on D: is enough or new media is needed.

This is the cheapest insurance in the project: hours of wall-clock, near-zero attention,
protecting against a failure mode that is stupid, permanent, and entirely avoidable. Run
it in the background while other tickets proceed.

Produce a manifest (path, size, SHA-256) so future-you can prove the archive is intact.
