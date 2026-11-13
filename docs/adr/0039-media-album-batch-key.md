# 39. Media album batch key

Date: 2026-11-06

## Status

Proposed

## Context

Matrix has no album concept: several images sent together are N separate
`m.image` events. The Twake web client (linagora/twake-space-chat) groups them
into one album by a plain string in the event content, `app.twake.chat.batch`
(src/domain/extensions.ts, written in src/adapters/matrix/matrixAttachments.ts).
MSC4274 (`m.gallery`) is still open and unsupported by clients that do not know it.

## Decision

- Mobile sends and reads the same key: `app.twake.chat.batch`, a UUID string,
  identical on every file of one confirmed send. No other key, no index or count.
- Each file stays its own `m.image`/`m.video` event. Nothing changes for clients
  that ignore the key.
- Grouping is display only and follows the web rule: adjacent events, same
  sender, same batch, at most a minute apart and on the same day, up to 10,
  decrypted, and a new album starts at the first unread event. A reply may sit
  only on the first file; a caption only on the last. On mobile a deleted
  event of the same sender between two images does not end the album.
- Differences with web: images without the key never group on mobile (web
  also groups them when they are a minute apart, which can merge two sends);
  images still being sent stay in the album on mobile, so it does not break
  apart while uploading (web groups only sent images).
- Forwarding drops the key; a forward of 2+ images stamps one fresh id.
- Spec basis (Matrix client-server API v1.19): a client may put its own keys in
  event content under a reverse-domain namespace
  (https://spec.matrix.org/v1.19/appendices/#common-namespaced-identifier-grammar);
  the reply (`m.relates_to`) may sit on any one event of the send
  (https://spec.matrix.org/v1.19/client-server-api/#rich-replies); in an
  encrypted room the whole content is inside the encrypted payload
  (https://spec.matrix.org/v1.19/client-server-api/#end-to-end-encryption).
- MSC4274: https://github.com/matrix-org/matrix-spec-proposals/pull/4274

## Consequences

- Albums look the same on web and mobile, except for the two differences
  above.
- Mobile treats an album as one message, as Telegram does: the long-press
  menu acts on the whole album. Reply and pin go to the first image; copy
  and edit to the caption (last image), shown only when there is one, and
  copy takes the caption as text, not an image file (copying a single image
  copies the file itself);
  forward (one fresh batch id), save to gallery, report and delete (one
  confirmation) to every image. Select picks the pressed image, Select all
  every image.
- An album shows one list of reactions: the chips merge the reactions of
  every image, and a new reaction goes to the first image.
- A deleted image between two images of an album is hidden and the album
  reflows. Matrix strips the content of a deleted event, batch key included
  (https://spec.matrix.org/v1.19/client-server-api/#redactions), so deleted
  messages of one sender sent within a minute collapse into one "Deleted
  message"; deleted texts sent together collapse too.
- These are differences with web, which keeps actions and reactions per
  image and splits an album at a deleted image.
- The key is a Twake convention outside the Matrix spec. It is not secret; in
  E2EE rooms it is inside the encrypted payload.
- Moving the reply to the first file changes today's mobile behaviour.
- If MSC4274 is merged and adopted, a later ADR can replace this one.
