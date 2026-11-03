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

## D3. Video call links: the room must be on the configured Meet host (proposed by Johann, 2026-10-23)

A video call link is always `<livekit_base_url>/<slug>`, `livekit_base_url`
being the well-known value every client checks a received call link against.
When ToM creates the room on another host, Chat sends nothing and shows that
the call could not be started: a link on that host would not show as a call
in any client, and a link on the configured host would open a room that does
not exist.

## D4. Video call room creation: 422 falls back to a local link, like 404 (proposed by Johann, 2026-10-23)

When ToM answers 404 (no room creation on this server) or 422 (no room for
this user, who has no usable email), Chat sends a link it generates itself, as
before room creation existed. The call works, but its first participant may
not be able to open it without logging in to Meet. Any other failure sends
nothing and shows that the call could not be started.

## D6. Who can join a group, and the directory, are set from Edit (proposed by Johann, 2026-11-02)

The Edit screen of a group has a « Who can join » section, as in
twake-space-chat: « Invite only », « On request » or « Public », then « In
directory ». It is saved with the rest of Edit, the rule first, then the
listing, and Edit stays open after the save, as it does today.

- Choosing « Public » turns « In directory » on; it can still be turned off
  before saving. Otherwise the two are independent.
- Shown only when the well-known enables public groups, to someone allowed to
  change the join rule, never in a direct chat. A refusal of the server shows
  an error.
- An encrypted room is never offered « Public » nor the listing, unless it
  already has them, so it can be taken out.
- A room restricted to a space says so and offers no rule; the listing stays.
- While the public web page is on (`app.twake.chat.public_page`), only
  « Public » is offered and the listing is locked; the save refuses the rest.
- A group made « Public » from Edit stays on its server when it was created
  with `m.federate: false`, or when its server announces that it applies the
  server ACL (see D8). Otherwise, people from other servers can join it.
- A public room cannot be encrypted: the encryption switch of Edit is greyed
  out, with the reason, while the room is public, readable by anyone, or
  « Public » is chosen.

## D7. Group creation: public and encryption exclude each other (proposed by Johann, 2026-11-03)

When the server enables public groups, the group creation screen always shows
"Enable end-to-end encryption" then "Make chat public", both off. While one is
on, the other is greyed out and its subtitle says why, so a group can never be
created both public and encrypted. Turning it off makes the other available
again. "Limit to users of <server>" still appears under "Make chat public"
when the group is public.

When the server does not enable public groups, only the encryption toggle is
shown, as before.
