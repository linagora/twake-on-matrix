# Contributing to Twake Chat

Thanks for wanting to contribute to the project!

The simplest way to help is to report the problems you see while using the app, by [creating an issue](https://github.com/linagora/twake-on-matrix/issues/new/choose). If you want to submit a change, please open an issue or comment on an existing one first, so we can discuss it before you start.

## Issue tracking

Every issue has a **type** and a few **labels**. The type says what the issue is, the labels say how bad it is, when we want it, and which part of the app it touches.

### Issue type

Exactly one per issue. It is set by the issue template.

| Type | Use it for |
|---|---|
| Bug | Something does not behave as expected |
| Feature | A request, an idea or a new functionality. Large features are split into sub-issues |
| Task | A specific piece of work: refactoring, tests, CI, documentation, dependency upgrade |

### Labels

Labels are grouped in families. The family is the prefix before `::`.

<details open>
<summary>Severity (bugs only)</summary>

How much the bug hurts users. Exactly one per bug, set by QA during triage.

- `severity::critical`: the app is unusable, or data or security is at risk.
- `severity::major`: an important feature is unusable, with no workaround.
- `severity::medium`: a feature is degraded, or a workaround exists.
- `severity::minor`: inconvenience or visual defect, usage is not impacted.

</details>
<details>
<summary>Priority</summary>

When we want to do it. Optional: an issue without a priority has a normal priority.

- `priority::urgent`: we want to do this as soon as possible.
- `priority::high`: we want to do this soon.
- `priority::low`: not time-sensitive, will be done later.

</details>
<details>
<summary>Platform</summary>

Only when the issue is specific to a platform. An issue without a platform label concerns all of them.

- `platform::web`
- `platform::android`
- `platform::ios`
- `platform::desktop`: macOS, Linux, Windows.

</details>
<details>
<summary>Area</summary>

The part of the app the issue touches. One per issue, two at most.

- `area::auth`: login, SSO, homeserver discovery, onboarding, multi-account.
- `area::rooms`: chat list, groups, members, permissions.
- `area::timeline`: message list: bubbles, scroll, replies, reactions, edit, delete.
- `area::composer`: message input: typing, paste, mentions, emoji.
- `area::media`: files, images, video, audio: upload, download, preview.
- `area::search`: search in chats, contacts and messages.
- `area::contacts`: contacts, address book sync, invitations.
- `area::notifications`: push notifications, unread counters and badges.
- `area::e2ee`: encryption, key backup, device verification.
- `area::perf`: performance, memory, battery, frame rate.
- `area::tests`: unit, integration and end-to-end tests.
- `area::build`: build, CI/CD, release, stores.

</details>
<details>
<summary>Triage state</summary>

What the issue is waiting for before someone can work on it.

- `needs::triage`: new issue, not triaged yet. Set by the issue templates, removed once the issue has its labels.
- `needs::info`: more context is required from the reporter.
- `needs::repro`: could not be reproduced yet.
- `needs::design`: waiting for a design or a design review.
- `needs::decision`: a product or technical decision is required before going further.

</details>
<details>
<summary>Other labels</summary>

- `regression`: worked in a previous release.
- `qa-failed`: the fix did not pass QA.
- `security`: security risk for users.
- `blocked-externally`: blocked by a server or a library we depend on.
- `good first issue`: well explained and requires little project knowledge.

</details>

### What is not a label

- Duplicates and issues we will not fix are closed with the matching close reason.
- Work in progress is shown by the assignee and the linked pull request.
- Large features are tracked with sub-issues, not with an "epic" label.

### Adding a label

Open a pull request on this file. A new area needs at least five issues to justify it.
