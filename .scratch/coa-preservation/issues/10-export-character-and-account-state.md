# Export character and account state

Type: task
Status: open
Blocked by: none

## Question

Preserve the user's own characters as data: gear, learned spells, Ascension points and
advancement, bags and bank, gold, professions and recipes, achievements, collections,
transmog appearances, saved outfits, reputations, completed quests.

This is separate from preserving the game. The game might be rebuilt from a spec; these
characters cannot be rebuilt from anything.

An addon dumping to SavedVariables via the client Lua API is the cheap path — minutes per
character once written, and it runs on any account, including friends' accounts if they are
willing. Write it early: it is one of the few tickets whose value scales directly with how
many people run it before the fifth.

Note the 0-byte Transmogrification*.json files: appearance and outfit data is server-side
only, so it is captured here or not at all.
