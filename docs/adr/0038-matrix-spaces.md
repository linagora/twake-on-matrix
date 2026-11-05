# 38. Matrix spaces and folders

Date: 2026-11-02

## Status

Proposed

## Context

Spaces were hidden from the room list and `SpaceView` could not be reached,
while Twake Chat React shows them as a tree, with a card in place of a
conversation and chips to filter the list. Both clients share one account, so
they must read and write the same data.

## Decision

The Flutter client follows the React client (`twake-space-chat`, decisions D2b,
D17, D42, D170, D237, D286, D348, D354, D483, D542):

- A space is no conversation: its row opens a card. A new one comes with an
  unencrypted `General` channel; a channel of a space is `restricted` to its members and
  goes away if the space refuses its `m.space.child`.
- The list keeps its own order, a space at the place of its most recent room.
  The hierarchy of the card follows the spec's order of children.
- Folders are the `app.twake.chat.folders` account data and `u.<name>` tags.

`Client.createSpace` is not used: it defaults to public with
`events_default: 100`.

## Differences with the React client

- Invitations stay as they are in Flutter; React joins them at once (D248).
- Search does not list spaces.
- The suggestions listener is not invited to new channels.
- A new room made here (space, channel or group) does not set
  `org.matrix.msc3401.call.member` and the bot command state types
  (`org.matrix.msc4332.commands`, `m.bot.commands`) to level 0, as React's
  `buildCreateRoomOptions` does. They stay at `state_default`: a member may not
  join a call there, and a bot may not announce its commands.
- « Recommended » offers the hidden built-ins, not one folder per kind.
- A row shows no globe for a public room: join rules are not in
  `importantStateEvents`, and adding them would hide the ones already stored
  in the `nonPreload` box until a cache reset.
- The chat picker of a folder names an unnamed group in English: the data
  layer has no locale.
- A parent a room names counts only if its sender may list children in that
  space, as the spec asks; React trusts it.

## Structure

- A space, a channel and a group are created through the same flow, contacts
  then details: `NewGroupKind` says what it creates, and the details add a
  description for a space and a parent space for a space or a group. Only a
  plain group or feed needs a contact.
- What the header, the list and the settings share lives in
  `lib/providers/room_list/`: entries, filter, folders, children of a space.
- The folded spaces are a preference of this device, with no business rule:
  their controller reads its datasource directly, without a use case.
- Exception to §2.4.5 of `GUIDELINES.md`: `FoldersController` shows a save at
  once, before the server answers, and goes back to what the server holds if
  it fails. A dragged folder must stay where it was dropped, and account data
  has no local echo before the sync. Saves run one at a time, in order.

## Spec

- [`m.space.child`](https://spec.matrix.org/v1.16/client-server-api/#mspacechild)
- [`m.space.parent`](https://spec.matrix.org/v1.16/client-server-api/#mspaceparent)
- [`/hierarchy`](https://spec.matrix.org/v1.16/client-server-api/#get_matrixclientv1roomsroomidhierarchy)
- [`restricted` joins](https://spec.matrix.org/v1.16/client-server-api/#restricted-rooms)

A public space follows D8 of `DECISION.md`, like a public group: no `m.federate`
when the server announces its ACL, `m.federate: false` otherwise.

## Consequences

- Chat list state added here lives in Riverpod; the rest of `chat_list` stays
  legacy until its wave.
- `/hierarchy` is read for each joined space shown in All and Spaces, again
  when the space lists something else or its home opens; React reads it every
  60 seconds. It is limited to 100 children, without pagination, as in React.
