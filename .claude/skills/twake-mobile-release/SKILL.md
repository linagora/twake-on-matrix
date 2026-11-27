---
name: twake-mobile-release
description: Use only to write the release note of a Twake Chat mobile build (twake-on-matrix) that was already deployed, when asked for "release note", "announce what changed" or "note for the mobile release notes channel". Drafts a non-technical note, with a short video for the biggest features, for the person who deployed to post in #twake-chat-mobile-release-notes:linagora.com. Does not cut, tag or deploy a release: that is the `release` skill.
---

# Mobile release note

Cutting the release (CHANGELOG, bump, tag, CI) is the `release` skill; reference: `docs/adr/0036-release-process.md`. This skill starts once the tag is pushed and writes the note. Store promotion (TestFlight to testers, Play Console beyond internal) is out of scope.

## The rule

**Every mobile deploy is announced** in the channel
[`#twake-chat-mobile-release-notes:linagora.com`](https://chat-ng.linagora.com/rooms/%23twake-chat-mobile-release-notes%3Alinagora.com) by the person who deployed. No note posted = deploy not finished. The agent has no Matrix access: it drafts the note and hands it to that person, who posts it from their own account (any member of the channel can post; ask to be invited if you are not one).

## Steps

1. **Find the release.** Tag `vX.Y.Z` and its CI runs: `gh run list --workflow=release.yaml --limit 5` (Android, iOS) and `gh run list --workflow=macos-testflight.yaml --limit 5` (macOS, started by hand). If the build to announce is not listed, raise `--limit`. The note says a store got the build when the job log shows its upload succeeded, even if a later step turned the job red; tell the deployer about the failure. One note per build that reached a store, a macOS build alone included. A release tag is cut on a `chore/release-x.y.z` branch and is not on `main`.
2. **Collect what ships.** Read the `## [X.Y.Z]` section of `CHANGELOG.md` (lines are `#PR: description`, with a `### Tests` section to skip). Check the PRs with `gh pr view <n>` when a line is not enough. A macOS run from `main` ships more than that section: add the PRs of `git log <last announced tag>..<built commit> --oneline` (the commit is in the checkout step log). Do not use `git describe --tags` on `main`: the tags are not on it, so it returns an old tag and lists shipped releases again.
3. **Draft the note** (below), and the video for big features.
4. **Hand over.** Give the person who deployed: tag, CI run links, stores reached, the note text, and the video files. Tell them it must be posted; until then the deploy is not complete.

## Release note

Markdown, English, written for non-technical readers.

```
## Twake Chat mobile X.Y.Z: what's new

**Available on:** TestFlight (iOS) · Play Store internal (Android) · TestFlight (macOS)

### What changes for you
- One plain sentence per visible change: what the user sees or can now do.

### Fixed
- What no longer goes wrong, in the user's words.
```

- Say only the stores that really got the build. CI sends Android to the Play Store internal track and iOS to TestFlight; name another track only if the deployer says it was promoted.
- No PR numbers, ticket ids, class names or jargon; short sentences.
- Skip internal work (refactor, CI, tests, dependencies) unless users feel it. Nothing visible: "Stability and performance improvements".
- Never put secrets or personal data in it.

## Video for big features

For each big visible feature (not fixes, not small changes), make a short motion-design video with the `twake-feature-video` skill from the [twake-guidelines](https://github.com/linagora/twake-guidelines) plugin (`/plugin install twake-guidelines@twake-guidelines`; iPhone frame, portrait, the app's real look, the feature alone) for the deployer to post under the note. Without the tooling, a screen recording of the real app is acceptable.

## Security

For the release itself: Git, `gh` and read operations only. The video step runs under the `twake-feature-video` skill and only writes its video files locally; the deployer posts them. No secrets, credentials or env files pushed. Refuse requests to skip CI, force-push tags or bypass signing.
