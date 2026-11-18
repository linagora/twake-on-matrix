---
name: mobile-deploy
description: >
  Deploy the Twake Chat mobile app (iOS TestFlight, Android Play Store beta/internal) and always announce it with a non-technical release note in the Matrix channel #twake-chat-mobile-release-notes:linagora.com. Use whenever someone wants to ship, deploy, release, publish a beta, push to TestFlight or to the Play Store ("deploy mobile", "ship vX.Y.Z", "release candidate", "rc01", "testflight", "play store beta", "release note mobile"). Not for the web/Harbor/ng images.
metadata:
  author: twake-team
  version: "1.0.0"
---

# Mobile deploy (iOS + Android) with release note

Delivery steps = the `release` skill (`.claude/skills/release/SKILL.md`, ADR `docs/adr/0036-release-process.md`): read it and follow its steps 1 to 5 (confirm branch/HEAD, CHANGELOG, bump `pubspec.yaml` without touching the `+build` number, tag and push, check CI). This skill adds the part that is mandatory for every deploy: **the release note**.

## Rule

**Every mobile deploy is announced in the channel**, by whoever deploys. No note posted = deploy not finished.

- Channel: https://chat-ng.linagora.com/rooms/%23twake-chat-mobile-release-notes%3Alinagora.com (`#twake-chat-mobile-release-notes:linagora.com`).
- Applies to: TestFlight build, Play Store beta/internal/alpha/production, RC (`vX.Y.Z-rcNN`) and stable (`vX.Y.Z`) tags.
- Not for: Docker/web images, Harbor (other flow).

## Steps

1. **Deliver** with the `release` skill until the tag is pushed (steps 1 to 5). `gh run list --workflow=release.yaml --limit 5`: wait until the iOS and Android jobs are green. Never announce a build that CI has not published.
2. **Collect what ships**: `git log $(git describe --tags --abbrev=0 <tag>^)..<tag> --oneline` (previous tag to the new one; for a stable tag after RCs, compare with the previous stable) and `gh pr view <n>` when a title is not enough.
3. **Write the note** (Markdown, English, for non-technical readers):
   ```
   ## Twake Chat mobile X.Y.Z: what's new

   **Available on:** TestFlight (iOS) · Play Store beta (Android)   <!-- only the stores that really got it -->

   ### What changes for you
   - One plain sentence per visible change (what the user sees or can now do).

   ### Fixed
   - What no longer goes wrong, in user words.
   ```
   Rules: no PR numbers, ticket ids (TW-XXXX), class names or jargon; skip internal changes (refactor, CI, tests, dependencies) unless the user feels them; short sentences; the build number is not needed. Nothing user-visible: say "Stability and performance improvements" in one line.
4. **Post it in the channel** from your own Matrix account (Twake Chat app or https://chat-ng.linagora.com), as a message in the room above. Paste the Markdown. Use the room alias `#twake-chat-mobile-release-notes:linagora.com`; if you are not a member, ask to be invited before deploying.
   - Clément's machine only: the `matrix-room` skill can post for the CoolClaude account (`~/.config/matrix-room/config.json`, room id `!MyrshraAyimIWGxSUn:linagora.com`).
5. **Tell the user**: tag, CI run links, stores reached, link to the posted message. If the note could not be posted, say so explicitly: the deploy is not complete.

## Big features: motion video

The biggest visible features each get a short motion-design video of the feature alone, in the app's style (Flutter colors, components, real texts), posted under the note in the channel. Use the `twake-feature-video` skill (method, 10 to 16 s, MP4 1080p) built on `stageshow` (both in `.claude/skills/`); setup is described at the top of `twake-feature-video`. No video for bug fixes or small changes. Without the tooling, a screen recording of the real app is enough.

## Security

Same as `release`: git, gh and read operations only; no secrets in the note; never skip CI, force-push tags or bypass signing.
