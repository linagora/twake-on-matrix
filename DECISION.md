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

## D9. Public groups in the search of the chat list (proposed by Johann, 2026-11-05)

From two typed letters (spaces around them ignored), the search also asks the
directory of the user's homeserver for the text, as twake-space-chat does:
one request, filtered by the server (`generic_search_term`), at most 20
rooms. Shown only when the well-known enables public groups.

- The rooms come under « Groups you can join », after the chats and contacts
  and before the messages (decided by Johann, 2026-11-06). Here the messages
  page in endlessly as the list scrolls, unlike twake-space-chat where they
  stop at 20 and the public rooms come last. The same rooms as D5: groups and
  feeds the user has neither joined nor been invited to, with the same rows
  and badges.
- The request leaves 300 ms after the typing stops, like the other searches.
  Nothing shows while it runs, when it fails or when it finds nothing.
- A tap behaves as on the page of D5: joins and opens the room, or sends the
  request and says so, or says the join failed.

## D10. A room address opens a preview of the room (proposed by Johann, 2026-11-05)

A link to a room address (`https://matrix.to/#/#name:server`) or ID that the
user has neither joined nor been invited to opens a preview, as Twake Space
Chat does (D491 and D581 there):

- The room's name, topic and avatar, with « Join · n members », or « Ask to
  join · n members » when it needs an approval. Once asked, the button gives
  way to « Request sent ».
- A user banned from the room is told so, with no button.
- A room nobody can preview (unknown, or invite only) says the group is
  unavailable and offers « Try to join ».
- A failed join or request is said in the preview, under the button.
- A room the user is already in under another address opens directly.

The preview reads the room summary (MSC3266) only, with no search of a public
directory, as Twake Space Chat does since its D581: it also says whether the
user is banned or has already asked, and it describes a room that no directory
lists. A failure of the summary shows the group as unavailable, with « Try to
join », as there, unless the app already knows the user is banned from it: the
preview then says so, with no button. The `via` servers of the link route the
summary, the join and the request. A joined room still opens directly, at the
linked message; one this device has not synced yet opens once it arrives, or
shows « Try to join » after 30 seconds.

Hand-typed addresses becoming links is left to a later change.

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

## D13. A message reached by a jump is tinted until the next touch, as in Twake Space Chat (proposed by Johann, 2026-11-06)

A tap on the quote of a reply, a pinned message, a search result or a link
scrolls the chat to its message and highlights it (#3281). The highlight
follows Twake Space Chat (its D138 and D263): the whole row of the message,
with a soft tint of the design system warning colour at 12 %, after a short
stronger flash when the message is reached. It stays until the next touch in
the conversation, scrolling included, instead of a strong blue block that
went away after three seconds. A selected message shows its selection colour
instead.

## D14. In-app calls use the MatrixRTC format of Twake Space Chat, not the voip of the Dart SDK (proposed by Johann, 2026-11-05)

A call in a room is a MatrixRTC session with a LiveKit focus, written exactly
as Twake Space Chat (matrix-js-sdk 43) writes it, so that both apps meet in
the same call:

- one `org.matrix.msc3401.call.member` state event per device, state key
  `_<user>_<device>_m.call` (no leading `_` on the MSC3757/MSC3779 room
  versions), `membershipID` `<user>:<device>`, `focus_active` LiveKit
  `oldest_membership`, `foci_preferred` the token service of the well-known;
- the token comes from `POST <token service>/sfu/get` (MSC4195) with an
  OpenID token; the token service is `livekit_service_url` of the
  `org.matrix.msc4143.rtc_foci` LiveKit focus (D15), over https only
  (http on this machine, for local servers);
- the membership lasts 4 hours (`expires`) and grows by 4 hours before it
  lapses; a delayed leave (MSC4140) of 8 seconds, restarted every 5, ends it
  on the server when the app vanishes;
- at join, a membership this device left from an earlier run is ended first;
- a call is encrypted when its room is;
- a call in a direct chat ends when the other person leaves it.

The calls of `package:matrix` (`GroupCallSession`, `LiveKitBackend`) are not
used: they write `com.famedly.call.member`, which Twake Space Chat and Element
Call do not read (still so in matrix 15.0.0).

In an encrypted call each device encrypts its media with its own random key
and sends it to the other devices of the call over Olm
(`io.element.call.encryption_keys`). When a device leaves, the key changes;
a device that joins gets the current key while it is under 10 seconds old,
else everyone gets a new one. LiveKit only sees ciphertext.
A call that started in the clear ends if encryption is turned on in its room
during the call, as its media would stay in the clear.

## D15. The call button of a chat: in-app call or Meet link (proposed, 2026-11-05)

The call button in the header of a chat starts an in-app call (D14) when the
`org.matrix.msc4143.rtc_foci` LiveKit focus of the well-known has a
`livekit_service_url`. Without one, it keeps sending the Meet link of
`livekit_base_url`, as before. A base url alone is not taken as a token
service: on `meet.twake.app` (the production well-known on 2026-11-05) it is
Meet, and `POST /sfu/get` answers 405.

The first call screen is audio only, as the calls of Twake Space Chat start
with the camera off:

- the button opens the screen before the call; « Start Call » joins it;
- in the call: one tile per device, with its avatar, its name, « Microphone
  off » and a ring while it speaks; a microphone button and « Leave the call »;
- leaving the screen leaves the call: no call keeps running without a screen
  that shows it.

Not yet: the camera and the videos, the speaker and device choice, a call
that goes on in a small window, the number of people already in a call on
the button.

Joining a call writes the state event `org.matrix.msc3401.call.member`
(decided by Johann, 2026-11-10):

- a group created by Twake Chat gives it to every member (level 0), as Twake
  Space Chat does;
- in an older room, a member who may not write it sees no in-app call button,
  only the Meet link when the well-known has one;
- the join still checks this right before anything goes out.

On web an encrypted room keeps the Meet link: the web build does not ship the
LiveKit E2EE worker, and the Flutter web client is retired.

## D16. Reactions under a message: most used first, then oldest first (proposed by Johann, 2026-11-09)

The row shows up to three reactions, the most used first; among equal
counts, the user's own reaction comes first, then the others in the order of
their first reaction, oldest first. Reactions beyond three are summed up in
`+N`; in a group it opens the full list (a direct chat shows no counts and no
list, as before). A later reaction from someone else does not push out one
already shown at the same count; the user's own one does, so their tap shows.

## D17. Copying an image or video copies the file itself (proposed by Johann, 2026-11-10)

Copy on an image or a video message puts the file itself on the clipboard,
on mobile, ready to paste in another app or in the composer (#962). An
encrypted file is downloaded and decrypted first. A format the clipboard
cannot hold (WebM, BMP…) copies the text, as before. This replaces, for one
selected message, the "image itself on the web" of D11.

## D18. Add members closes at once and invites in the background (proposed by Johann, 2026-11-10)

Inviting a user from another server waits for that server, which can take
minutes (#3262). The Add members screen now closes as soon as the selection is
sent, and the invite goes on in the background. The result comes later on the
page underneath: the usual « Contact has been invited to the chat » snackbar,
or the « couldn't be added » dialog when it fails.

There is no « Inviting… » feedback while an invite is pending, for now. There
is no client-side timeout either: the server keeps going after the client
gives up, so a timeout could report a failure for an invite that still lands.

## D19. On one column, the title, search and filters of the chat list scroll away with the list (decided by Clément, 2026-11-16)

On one column (a window narrower than 905 px: a phone, and a narrow web or
desktop window too), scrolling the chat list down hides the whole top block:
the title bar, the search field and the filter chips (All, Unread, Broadcast,
Direct…). Scrolling back up, even a little, brings it back at once; it is
always shown at the top of the list. The block is the first sliver of the list
(floating, snap), so the viewport keeps its size: an app bar that changed
height would move the scroll position and could flip the block back and forth.

The block stays pinned while a selection is active, so its actions never
disappear. Wide layouts, an empty list and the loading skeleton keep the fixed
app bar as before.

On one column the app bar of the block no longer takes the lavender
"scrolled under" tint when the list scrolls (it is the same fill at the top, after
a scroll and in selection); wide layouts keep it.

With the block hidden, a fixed strip as tall as the status bar, in the fill of
the block, covers the top of the screen: no room row shows behind the clock and
the battery.

Choices made without Clément: the audio mini-player and the connection status
bar are part of the block, so they hide with it. A message playing keeps
playing: its state lives in `MatrixState` (`audioPlayer`), the widget only shows
it, and the player comes back on the next scroll up.

Not checked on a device: the snap gesture, the real iOS rendering, and the
audio player appearing while the block is hidden. The layout was checked with
widget renders at 390 x 844 and a 47 px status bar inset, compared with the
fixed app bar of before.

## D20. iOS notifications: a preview for clear rooms, a label for encrypted ones (decided by Clément, 2026-11-20)

On iOS the notification of a message shows what the room allows:

- a clear room: the sender, the room, the text and the avatar;
- an encrypted room: always « You have a new encrypted message », never the
  content, even when the device could decrypt it. A clear event sent into an
  encrypted room (a bot, a bridge) counts as encrypted;
- a room whose encryption cannot be read, or a push the notification
  extension cannot handle (phone locked since a reboot, offline, app not
  reopened after an update): the neutral « You have a new message ». This
  trade-off is accepted.

A room set to notify without sound stays silent; a mention of the user
always rings.

The dedicated notification device, the second SSO sign-in that gave the
decrypted previews, is removed by the app on its own at startup, and its
setting is gone.

This replaces the generic text by default (2026-10-29) for clear rooms, and
the decrypted preview of encrypted rooms (2026-10-24), both decided before
this file. Android is unchanged.

## D21. Who a call rings, and how it rings in the app (proposed by Clément, 2026-11-23; who rings decided by Johann, 2026-11-23)

When someone joins a call that nobody else is in, Twake Chat sends a MatrixRTC
ring (MSC4075) in the room. Another device of the same account in the call
counts as someone: only the first to join rings.

- The whole room rings, direct chats and groups alike, as Twake Space Chat
  rings it: `notification_type: ring`, a lifetime of 60 s (decided by Johann,
  2026-11-23: mobile behaves as the web).
- Unlike matrix-js-sdk 43, the ring mentions nobody (`m.mentions: {}`, D29).
  A ring that names other people only does not ring.
- The ring is sent in the clear, also in an encrypted room: the push gateway
  and the other devices read it without the keys of the room. It holds no
  message content.
- The ring sound of the push comes from two underride push rules of the
  account, one for the ring and one for the legacy `call.notify`, added only
  when absent, once the account has synced its push rules, at each start of
  the app. An override would sound over the mute of a room.
- With the app open, a ring shows over the app: « Pierre is calling you » for
  a direct chat, « Clément · is calling you in General » for a group, with
  « Decline » and « Answer » (the words of Twake Space Chat, its D134). It
  rings, in a loop, two rising triplets every two seconds (the notes of Twake
  Space Chat), until it is answered, declined, its ring lapses (60 s, at most
  120 s for other clients) or another device of the account joins or
  declines. During another call it shows without its sound; « Answer » leaves
  that call.
- « Answer » joins at once, audio only, and opens the call. « Decline » sends
  the decline of MSC4310 in the clear; in a direct chat the caller leaves the
  call and reads « Call declined ». A group call goes on.
- Calls start audio only (decided by Johann, 2026-11-23).

Not yet: a ring with the app in the background or closed, the system call
screen (CallKit), the missed calls and the call history.

Completes D12, which left the ring push rules for later.

## D22. Threads are on for everyone on mobile (decided by Clément, 2026-11-20)

The threads of Twake Space Chat (#993, P1) ship on, for every user, when
#3606 reaches main: `threadsEnabled` is `true`. They cover sending to a
thread, the thread screen and its card in the chat, Start a thread, thread
counts in the badges, the chat list and the room list, threads opened from
notifications, links and search, per-thread unread and threaded read
receipts, the Activity tab (unread rooms and followed threads), and the iOS
icon badge.

Known limit, still open: while the app is killed, the iOS icon badge counts
the replies of threads the user does not follow (#3635).

## D23. A chat with unread messages opens on the first unread one, without scrolling (proposed by Johann, 2026-11-19)

Opening a chat with unread messages shows the "Unread messages" divider at the
top of the screen, with the first unread message right under it, from the first
frame: no scroll animation (#2720, as the designer asked in
https://github.com/linagora/twake-on-matrix/issues/2720#issuecomment-3579815019).
When all the unread messages fit on the screen, the chat opens at the bottom,
as before.

When the read marker is older than the loaded messages, the chat loads more
history first (up to three pages of 100 events), behind the loading skeleton.
If the marker is still not found, the chat opens at the bottom.

Opening the chat only marks as read the messages shown on the screen. The
unread count drops to the messages below, and the room is read once the user
reaches the bottom, as before.

## D25. A presence dot on people, and their presence under their name (decided by Johann, 2026-11-20, following Twake Space Chat D466 and D54)

A person's avatar carries a dot at its bottom right: green when online
(Matrix presence `online`, or `currently_active`), amber when away (presence
`unavailable`), none when offline or unknown (Matrix presence:
https://spec.matrix.org/v1.16/client-server-api/#presence)
(`LinagoraPresenceBadge` of the design system: 10 up to a 40 avatar, 12
above, a 2 ring in the colour behind the avatar). The dot sits on the circle
at 45°, so it stays on the edge of large avatars; Twake Space Chat pins it to
the corner of the avatar box, which only differs on large avatars.

This change shows the dot in the header of a direct chat, on the avatar of
its details and on a member's profile (on the round avatar, not on the
enlarged picture). The text under the name is `status · presence`, the
presence alone without a status: « Online », « online 5m ago » up to « a
while ago », or « Offline » when no activity is known. Only the online state
says « Online »; an away person shows when they were last active.

Opening a screen shows the cached presence at once, then asks the server once
(`GET /presence/{userId}/status`); after that the `/sync` the app already
runs keeps it current (no polling, unlike Twake Space Chat, whose sliding sync
carries none). The chat list, members,
contacts and the avatars of messages get the dot in the next changes.

## D26. Calls start audio-only; the camera and the speaker are buttons (decided by Johann, 2026-11-23)

A call on mobile starts with the camera off, as D15 decided. Twake Space
Chat no longer does: since its D778 (2026-11-21) its calls start with the
camera on, so the « as the calls of Twake Space Chat » of D15 is out of date,
not its rule. The call screen has a camera button and a speaker button, next
to the microphone.

- The camera shows the own video in the own tile, and the others see it in
  theirs. A tile without a video keeps the avatar.
- An audio call plays on the earpiece, or on the headset (wired or Bluetooth)
  when one is connected.
- Until the user taps the speaker button, the speaker follows the camera: on
  with the camera, off without it. A headset still takes the audio then.
- The speaker button turns the speaker on even over a headset. Off, the audio
  goes back to the headset, else to the earpiece.

Not yet: a list of the audio outputs to pick a Bluetooth device by name, and
the switch between the front and the back camera.

Completes D15, which left the camera and the speaker for later.

## D27. Chat list: floating bottom bar, pen capsule and pill chips ahead of the design system (decided by Johann, 2026-11-24)

On a phone (and a tablet, which shares the bottom bar), the tab bar is a
near-white capsule floating above the content: it hugs its four tabs (Contacts,
Chats, Activity, Settings, in that order), every tab has the width of the
widest label, and the selected tab sits in a light grey pill, its icon and label
in the primary colour. The unread badges of Chats and Activity are unchanged.
The capsule ignores the system text size, like the old bar; a label that does
not fit shrinks instead of being cut. Lists behind the bar end with a spacer as
tall as the bar, so their last row can be reached.

The header keeps the centred title. The new chat pen moves into a small
floating capsule of the same style, outside the app bar so its shadow is not
clipped; it is hidden in selection. The title bar, search and filters share one
white background from the status bar down, with no divider, at rest and
scrolled.

The filter chips become pills on one row: the selected one filled in the
primary colour without a check mark, the others light grey without a border.
They scroll sideways under an edge fade instead of the arrow buttons, and a
long press opens the menu of a folder (the ⋮ button of the selected chip is
gone on a phone). Wide layouts keep the design system chips and the arrows.

These three components are local to the app, built from the design system
tokens: the design runs ahead of the design system, and they are specific to
Chat. They move to linagora-design-flutter once the designers adopt them.

## D28. The folder screens follow one layout (proposed by Johann, 2026-11-18)

Status: proposed, pending the designer's review.

The Folders settings and the folder form share one edge: 16 dp on both sides,
for every row, header and field. Each section opens with the design system's
section header, in upper case, and its help text is small and tertiary.

In the folder form, the kinds of chats are ticked with checkboxes, not
switches: nothing applies before Save. A kind row is 56 dp high and a chat row
64 dp, with the checkbox on the same right edge. Save stays pinned at the
bottom, whatever the number of chats. The emoji is picked from the start of
the name field. It opens a sheet with a handle, a title, 16 dp margins and a
Clear action once an emoji is set. The colours are one row of nine swatches:
the first one, crossed, means no colour.

In the Folders list, a folder's colour shows as a tint behind its emoji, under
a « Your folders » header. Each folder keeps its own delete button.

## D29. Rings carry no mention (decided by Johann, 2026-11-26)

A ring of Twake Chat (MSC4075) sends `m.mentions: {}`, where matrix-js-sdk 43,
and so Twake Space Chat, sends `room: true`.

With `room: true`, Synapse's default override `.m.rule.is_room_mention` takes
the push of any caller allowed to mention the room (power level 50 or more)
before the ring rule of D21, an underride: the push is highlighted but plays no
ring sound, and a room set to « mentions only » is still notified. With no
mention, the ring rule takes every ring: the push plays the ring sound whoever
calls, and a room set to « mentions only » stays silent. Seen on Synapse 1.162,
2026-11-25. Twake Space Chat rings without reading the mentions of a ring.

Trade-off, accepted: a client that rings only when a ring mentions it or the
room does not ring for these calls. Twake Chat builds before this one do so,
through `shouldNotifyUser` of the Dart SDK; the review of #3760 reports the same
for Element X.

## D30. Voice messages play one after the other (proposed by Johann, 2026-11-24)

When a voice message plays to its end, the next message of the chat plays at
once if it is a voice message too (#2796). The run stops:

- at the first message that is not a voice message: a text, an image, or an
  audio file that was not recorded as a voice message;
- after the last message the chat has loaded on screen; a message no longer
  on screen goes on with the messages stored on the device, up to the last one;
- when the user closes the player, or starts another audio;
- when the user leaves the chat or covers it (a thread, a dialog, a bottom
  sheet): the next one does not start. On mobile the voice message that is playing goes on to its end,
  as before; on desktop, leaving the chat stops it, as before.

Events the chat does not show (reactions, edits) do not stop the run. On the
thread screen, the run plays the replies of that thread only, from its root
too; in the chat, it skips the thread replies, as the chat does.

## D34. A reply shows its quote above the message bubble (decided by Clément, 2026-11-27)

The quoted message moves out of the message bubble. From top to bottom, a reply
shows:

- a caption, "Reply to {name}", naming the author of the quoted message;
- the quoted message in a pale bubble;
- the message bubble, which overlaps the quoted bubble by 12, with a 2px gap
  cut out of the quoted bubble around it.

When the quoted message is not loaded, the caption is "Reply", with no name.

The gap shows what is behind the message: the chat background, or the colour of
a selected or highlighted row.
