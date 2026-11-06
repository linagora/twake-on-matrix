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

## D5. Browse public groups on mobile (proposed by Johann, 2026-11-02)

A planet inside the search field of the chat list, at its right, opens a full
screen page of the public directory of the user's homeserver, as
twake-space-chat does. Shown only when the well-known enables public groups
(`app.twake.chat.public_groups.enabled`).

- The directory of the homeserver alone, read page after page up to 1,000
  rooms, minus the rooms the user has joined or is invited to, and the rooms
  nobody can join (`invite` or `private` rules). Groups and feeds only: no
  spaces.
  Each page shows as soon as it arrives, with a thin progress bar until the
  last one, where twake-space-chat waits for the whole directory.
- Each row: avatar, name, « Join · N members » or « Ask to join · N
  members » for a room on approval (`knock`), and the topic. A search field
  on top filters by name, ignoring case and accents.
- A tap joins and opens the room. On a room on approval it sends the request
  and says an administrator has to approve it; the page stays open. A failed
  join says so. Both messages are snackbars, where twake-space-chat shows an
  inline alert in its dialog.
- A room where the user's request is pending shows « Request sent · N
  members » and a tap does nothing, where twake-space-chat lets the user ask
  again. The row switches right after the request. The pending state is read
  through room_summary (MSC3266), because the SDK ignores the rooms in knock.
- The avatar carries the badge of the room kind, as the Figma « Avatar
  icon » component: a megaphone for a feed, a globe for a public room,
  people for any other room, none for a direct chat. A room whose join rule
  is unknown counts as not public.
- The room-kind badge is shown on every room avatar in the chat list, not
  behind the public-groups flag, read from each room's join rule (hence
  `m.room.join_rules` in the important state events), as twake-space-chat
  does.

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
  with `m.federate: false`, or when it is a room created on this server and
  the server applies the server ACL (see D8). On a server without the ACL, a
  group created private and then made « Public » from Edit can be joined from
  other servers. Edit offers « Public » either way.
- A public room cannot be encrypted: the encryption switch of Edit is greyed
  out, with the reason, while the room is public, readable by anyone, or
  « Public » is chosen.

## D7. Group creation: public and encryption exclude each other (proposed by Johann, 2026-11-03)

When the server enables public groups, the group creation screen always shows
"Enable end-to-end encryption" then "Make chat public", both off. While one is
on, the other is greyed out and its subtitle says why, so a group can never be
created both public and encrypted. Turning it off makes the other available
again. There is no "Limit to users of <server>" toggle under "Make chat
public" (see D8).

When the server does not enable public groups, only the encryption toggle is
shown, as before.

## D8. A public group stays on its server through a server ACL when the server says so (proposed by Johann, 2026-11-03)

A homeserver that keeps public rooms on itself sets an
[`m.room.server_acl`](https://spec.matrix.org/v1.16/client-server-api/#mroomserver_acl)
that allows only itself on a room whose join rule becomes public, and opens it
again when the room stops being public. If a room admin changes that ACL from
another client, the server module puts it back. The module acts only on rooms
created on its own server, and only when a local member has the power level to
send the ACL; otherwise it logs an error and the room stays public and open to
other servers. Such a server announces it in its well-known with
`app.twake.chat.public_groups.server_acl: true`.

When it does, the client creates a public group without `m.federate`. When the
key is false or missing, the client sets `m.federate: false` in the
`creation_content` of
[`createRoom`](https://spec.matrix.org/v1.16/client-server-api/#post_matrixclientv3createroom),
as before. That value of
[`m.room.create`](https://spec.matrix.org/v1.16/client-server-api/#mroomcreate)
is fixed forever, so the room can never be opened to other servers later. In
both cases the group creation screen offers no "Limit to users of <server>"
toggle.

A server whose well-known set `default_server_limited: false` used to create
public groups that federate by default. It now gets `m.federate: false` too,
unless it announces `server_acl: true`.

## D11. Copying several selected messages follows Twake Space Chat (proposed by Johann, 2026-11-06)

Copy, with several messages selected, puts them on the clipboard in timeline
order, as Twake Space Chat does (its D183): each message under a line
`Author, day time`, an empty line between two messages. The day and the time
are those of the conversation: "Today", "Yesterday" or the date of the day
separator, then `HH:mm`. A file, an image or a video with a caption is copied
with its caption, without one with its file name. Other messages (stickers,
locations, polls, encrypted, deleted) are left out.

With one message selected, Copy is unchanged: its text alone, or the image
itself on the web.

## D12. Call events in the timeline and the chat list follow Twake Space Chat (proposed by Johann, 2026-11-04)

Twake Chat reads call events as Twake Space Chat does, so that both clients
of the same room tell the same story:

- A MatrixRTC call shows only while it goes on. Its membership, its ring and
  the old call signalling (hangup, answer, candidates) never show in the
  timeline or the chat list, whatever the setting for unknown events.
- The message that opens the chat of a call (marked
  `app.twake.chat.call_thread`) reads « Meeting started at 14:32 », at the
  time of its event on the reader's clock, in the bubble and in the chat
  list. The body sent carries the caller's time, for the other clients.
- A legacy `m.call.invite` (the one-to-one call of Element) shows one line,
  « Call from an app Twake Chat does not support », with no answer button.
  It is not the chat-list preview, does not make the room unread on this
  device, and on Android its push shows no notification.

Known limits: the unread badge counts what the server counts. Synapse's
default rule for `m.call.invite` still adds 1 to the badge until the room is
read. On iOS the notification extension still shows its generic notification
for that push. The ring push rules, and the iOS extension, will be settled
with the in-app and the system ring.
