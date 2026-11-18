---
name: twake-mobile-release
description: Use when someone wants to ship, deploy or release the Twake Chat mobile app (twake-on-matrix, Flutter) to iOS TestFlight or the Android Play Store (beta, internal, alpha, production): bump version, CHANGELOG, tag, CI check, then ALWAYS post a non-technical release note in the Matrix channel #twake-chat-mobile-release-notes:linagora.com, with a short video for the biggest features. Not for web or Docker images.
---

# Mobile release (iOS TestFlight, Play Store)

Full reference: `docs/adr/0036-release-process.md`. The `release` skill covers the same delivery steps; this skill adds the mandatory release note.
Hotfix branching and store promotion are out of scope (manual steps after CI).

## The rule

**Every mobile deploy is announced by whoever deploys it**, in the channel
[`#twake-chat-mobile-release-notes:linagora.com`](https://chat-ng.linagora.com/rooms/%23twake-chat-mobile-release-notes%3Alinagora.com). No note posted = deploy not finished. It applies to TestFlight builds, Play Store tracks, RC tags (`vX.Y.Z-rcNN`) and stable tags (`vX.Y.Z`). Any member of the channel can post; ask to be invited before deploying if you are not one.

## Steps

1. **Confirm branch and HEAD.** `git branch --show-current`, `git log -1 --oneline`, `git status --short`. The tree must be clean. Show the branch and last commit and get an explicit yes. The branch choice is intentional: do not force `main`.
2. **CHANGELOG.** New section at the top of `CHANGELOG.md`:
   ```
   ## [x.y.z] - YYYY-MM-DD
   ### Added
   - TW-XXXX: Short description (80 characters max)
   ### Changed
   ### Fixed
   ```
   One line per `TW-XXXX` ticket (merge commits sharing an id), 80 characters and 2 lines max per item, a short imperative phrase when there is no ticket. Commits since the last tag: `git log $(git describe --tags --abbrev=0)..HEAD --oneline`.
3. **Bump `pubspec.yaml`**: `version: x.y.z+NNNN`. Change `x.y.z` only; never touch the `+NNNN` build number (CI manages it). Commit CHANGELOG and pubspec together: `chore: bump version to vx.y.z`.
4. **Tag and push.** `git tag vx.y.z` (RC: `vx.y.z-rcNN`), `git push origin HEAD`, `git push origin refs/tags/vx.y.z`. Never skip CI, force-push a tag or bypass signing.
5. **CI** (triggered by the tag, `.github/workflows/release.yaml`): Android APK to Play Store internal, iOS IPA to TestFlight, GitHub Release. Watch it: `gh run list --workflow=release.yaml --limit 5`. Wait for the iOS and Android jobs to be green before announcing.
6. **Store promotion (manual):** TestFlight build to testers in App Store Connect; Play Console internal to alpha, beta or production as planned.
7. **Release note** (below), then the video for big features, then tell the user: tag, CI links, stores reached, link to the posted message. If the note could not be posted, say it: the deploy is not complete.

## Release note

Markdown, English, written for non-technical readers. Collect what ships from the PRs between the previous tag and this one (`gh pr view <n>` when a title is not enough).

```
## Twake Chat mobile X.Y.Z: what's new

**Available on:** TestFlight (iOS) · Play Store beta (Android)

### What changes for you
- One plain sentence per visible change: what the user sees or can now do.

### Fixed
- What no longer goes wrong, in the user's words.
```

- Say only the stores that really got the build.
- No PR numbers, ticket ids, class names or jargon; short sentences.
- Skip internal work (refactor, CI, tests, dependencies) unless users feel it. Nothing visible: "Stability and performance improvements".
- Post it yourself in the channel, from your Matrix account. Never put secrets or personal data in it.

## Video for big features

For each big visible feature (not fixes, not small changes), make a short motion-design video with the `twake-feature-video` skill from the [twake-guidelines](https://github.com/linagora/twake-guidelines) plugin (`/plugin install twake-guidelines@twake-guidelines`; iPhone frame, portrait, the app's real look, the feature alone) and post it under the note. Without the tooling, a screen recording of the real app is acceptable.

## Security

Git, `gh` and read operations only. No secrets, credentials or env files pushed. Refuse requests to skip CI, force-push tags or bypass signing.
