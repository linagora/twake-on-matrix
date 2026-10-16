# Decisions

Product and architecture decisions for Twake Chat, newest last. A decision
changes only by a new entry that says what it replaces. The records of
`docs/adr/` stay as they are.

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
