# Get a crude capture running immediately

Type: task
Status: open
Blocked by: none

## Question

Start capturing *something* today, with whatever works in the first hour, without waiting
for the toolchain decision in ticket 04 or the coverage checklist in ticket 06.

The premise of the original sequencing was that we had until 5 September to prepare and
could afford to plan first. The disappearance of db.ascension.gg and the patch CDN before
the announced date breaks that premise: services are being dismantled now, and the world
server may go early or degrade without warning.

A crude capture that exists beats a well-planned capture that arrives too late. Even raw
encrypted pcap has option value if ticket 04 finds that session keys can be recovered
afterwards — and if it finds they cannot, we have lost only an hour.

Scope it deliberately small: get traffic to disk, confirm bytes are flowing, log in and
play normally. Do not tune it, do not aim for coverage, do not wait for a plan. Ticket 08
remains the real capture effort; this is insurance against ticket 08 never happening.

Deliberately duplicates work that tickets 07 and 08 will do properly. That duplication is
the point.
