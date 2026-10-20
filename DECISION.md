# Decisions

The product and design decisions of Twake Chat, the large ones, newest last.
A decision changes only by a new entry that says what it replaces.
Architecture and purely technical choices, the fundamental changes, are
records of `docs/adr/`, not entries here.

Status: **decided** (given by the product owner), **proposed** (to confirm),
**open**.

Every heading, `##` and `###`, carries the date of its decision, and of each
update, in its parentheses: `grep -nE '^#{2,3} .*2026-10-16' DECISION.md`
lists what one day decided or changed, for a review day by day. The workflow
`decisions.yaml` fails on a heading without a date.

---

## D1. A dated decision log (decided by Clément, 2026-10-16)

Decisions are written in this file, one `## Dnn` entry each, with the date in
the title: `(decided by <who>, YYYY-MM-DD; updates Dxx, YYYY-MM-DD)`. A
section found later, under an entry, is a `###` heading with its own date.

This file holds the large product and design decisions; `docs/adr/` keeps
architecture and purely technical choices, the fundamental changes.

## D2. Android navigation bar: one bottom inset for every page (proposed by Johann, 2026-10-20)

On Android with 3-button navigation, every page keeps its bottom content above
the system navigation bar, through one bottom inset at the app root (#3435).
The strip under the content is always the `surface` color, whatever the page
draws.

Accepted trade-offs:

- full-bleed dark screens (media viewer, image viewer) show a light strip at
  the bottom in the light theme;
- the barrier of a dialog or a bottom sheet stops above the strip instead of
  covering it.

The alternative, an inset on each page with bottom actions, renders these
screens right but has to be repeated on every new page; missing it is what
caused #3435.

Unchanged: iOS, web, desktop and Android gesture navigation. Only the bottom is
handled, since the app is locked to portrait.
