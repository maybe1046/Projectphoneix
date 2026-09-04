# Is db.ascension.gg scrapeable in the window?

Type: research
Status: resolved
Blocked by: none

## Question

db.ascension.gg is Ascension's public game database, referenced from inside Extensions.dll.
It holds server-side item/spell/NPC/quest data that exists nowhere on the client — and with
the WDB cache disabled, nowhere else we control either. It probably dies with the rest of
the service.

Determine: what entity types it exposes and at what scale; whether a JSON/REST API sits
behind the UI (and its exact endpoints, parameters, pagination); how many requests and
hours a full dump costs at a polite rate; whether Cloudflare or auth blocks it; whether a
dump or Wayback mirror already exists; and — decisively — whether CoA content is
represented at all, or only the older Ascension realms.

A verified endpoint list converts a five-day scramble into an overnight script.

Agent dispatched 2026-08-31; findings land in research/db-ascension-gg.md.

## Answer

**Dead. Resolved by loss, not by research.** As of 2026-08-31, `db.ascension.gg` has no
A or AAAA record — confirmed against Cloudflare's public resolver (1.1.1.1), so this is a
real removal and not local DNS filtering. `cdn2.ascension-patch.gg`, the patch CDN
referenced from Extensions.dll, is likewise NXDOMAIN. `ascension.gg` itself is still up
behind Cloudflare.

The teardown began before the announced 5 September date. Everything db.ascension.gg held
that was not mirrored elsewhere is already gone; no scrape is possible.

Two consequences beyond the immediate loss:

1. The patch CDN being down means the client can no longer be re-downloaded or updated
   from any Ascension-controlled source. The on-disk MPQs (dated 2026-08-31 04:50, so
   almost certainly the final build) are now irreplaceable. See ticket 01.
2. The assumption that services survive until the 5th is unsafe. Infrastructure is being
   dismantled now, so capture readiness matters more than capture quality. See ticket 16.

The only remaining avenue is archived copies — Wayback, community mirrors, prior scrapes.
The dispatched research agent has been redirected to hunt for those; it is now a salvage
question rather than a scraping one.
