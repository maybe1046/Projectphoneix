# Which emulator base does the spec target?

Type: grilling
Status: open
Blocked by: 08

## Question

The spec has to be written against something. AzerothCore, TrinityCore, a leaked Ascension
core if one surfaces, or a deliberately implementation-neutral specification.

The trade-off is real in both directions. Targeting AzerothCore makes the spec concrete and
immediately actionable, and inherits a large working stock-3.3.5 implementation — but bakes
in that project's architecture, and CoA diverges from stock enough that the fit may be poor
in exactly the places that matter most. A neutral spec ages better and constrains nobody,
but risks describing a server no one ever builds.

Deferred until after capture, because how far CoA departs from stock 3.3.5 is the main
input to the decision, and guessing at it now would settle the question on the wrong
evidence.
