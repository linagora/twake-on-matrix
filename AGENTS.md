# Twake Chat mobile

Instructions for coding agents. The skills of `.claude/skills/` hold the details.

## Releases

- Every build that reaches a store (TestFlight for iOS or macOS, Play Store) is announced in [`#twake-chat-mobile-release-notes:linagora.com`](https://chat-ng.linagora.com/rooms/%23twake-chat-mobile-release-notes%3Alinagora.com). This covers a tag pushed for `release.yaml` and a run of `macos-testflight.yaml` started by hand, a rebuild or a CI test included. Draft the note with the `twake-mobile-release` skill and hand it to the person who deployed. Until it is posted, the deploy is not finished.
- Never move or push again a release tag that already built: cut the next version (`2.28.0` → `2.28.1`) with the `release` skill. A moved tag ships new code under a version the testers already have, and its note is wrong.
