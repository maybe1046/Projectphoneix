# Scrape db.ascension.gg

Type: task
Status: closed — out of scope
Blocked by: 03

## Question

Execute the scrape plan from ticket 03 and pull down everything db.ascension.gg exposes.

Mostly unattended — a Python script against the documented endpoints, rate-limited to stay
under whatever protection is in place, checkpointing so it can resume after an
interruption. Attention cost should be near zero, which makes it excellent value against a
budget measured in attention rather than wall-clock.

Store raw responses verbatim as well as any parsed form. We do not yet know which fields
matter, and re-fetching will be impossible.

## Closed: out of scope

The scrape target no longer exists. `db.ascension.gg` stopped resolving before we reached
this ticket (see ticket 03). There is nothing to execute against.

Salvage of archived copies is folded into ticket 03's redirected research, not reopened
here.
