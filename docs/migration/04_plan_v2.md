# Migration plan v2 — finishing the migration

> **Status**: Draft
> **Last updated**: 2026-10-20
> **Rules**: [ADR 0037](../adr/0037-riverpod-migration-rules.md)
> **Progress**: [MIGRATION_STATUS.md](../../MIGRATION_STATUS.md)

This plan replaces the phases and the timeline of
[01_migration_plan.md](./01_migration_plan.md). Its conventions (§6) still
apply where ADR 0037 does not change them.

## What changes

v1 rewrote each module through every layer, in a fixed order, by one part-time
developer: 6 to 10 months. v2 splits the work:

- **Mechanical rewrites** (one pattern over many files) are done by agents in
  bulk: `Matrix.of(context).client`, `getIt.get<X>()`.
- **Module migrations** (use cases, controllers, states) stay one module per
  pull request, behind Patrol scenarios written first.
- **A CI ratchet** stops legacy code from growing, so the remaining work only
  shrinks.

Every pull request is written by an agent, reviewed by the `zeus` and
`migration-reviewer` agents, and approved by one person.

## Step 0 — Rules and guardrails

- [ ] ADR 0037 accepted
- [ ] `scripts/migration_status.sh` and the `Riverpod migration` workflow
- [ ] `MIGRATION_STATUS.md`
- [ ] `migration-reviewer` agent and `migrate-module` skill in `.claude/`
- [ ] `riverpod_lint`, which checks the rules of [Riverpod's
      DO/DON'T][do-dont]
- [ ] Fix its 6 findings on existing code (public notifier getters, a scoped
      override without dependencies), then run it in CI

## Step 1 — The Matrix client in Riverpod

- [ ] Contacts migration (#3459) merged; it brings `activeMatrixClientProvider`
- [ ] The app's `ProviderContainer`, created in `main` with automatic retry
      off ([Automatic retry][retry]) and given to the tree with
      `UncontrolledProviderScope`
- [ ] `matrixClientProvider`: the active, non-null `Client` for screens
      behind login, read from `activeMatrixClientProvider`, which
      `MatrixState` feeds: the tolerated exception until Step 4
      (ADR 0037 §3, §4 Q1)
- [ ] One bridge provider per GetIt registration, generated next to each
      implementation
- [ ] Patrol scenario: log in, add a second account, switch, log out

## Step 2 — Mechanical sweep

One pull request per area, one pattern each, areas that nobody is changing.
The sweep covers `lib/pages`, `lib/widgets` and `lib/presentation`, where a
`ref` is at hand:

| Area | `Matrix.of` | `getIt` |
|---|---:|---:|
| `pages/settings_dashboard` | 53 | 23 |
| `pages/chat` | 37 | 42 |
| `pages/chat_list` | 24 | 5 |
| `presentation/mixins` | 13 | 24 |
| Other `pages/`, `widgets/`, `presentation/` | 155 | 124 |

The `getIt` lookups in `lib/data`, `lib/domain` and `lib/utils` (about 125)
are fields of repositories, datasources and interactors: they need
constructor injection and move with their module in Step 3.

- `Matrix.of(context).client` → `ref.watch(matrixClientProvider)` in
  `build()`, `ref.read(matrixClientProvider)` in callbacks and `initState`
- `getIt.get<X>()` → `ref.read(xProvider)`
- Every other `MatrixState` member read by the UI (`shareContent`,
  `showToMBootstrap`, `loginType`, `accountBundles`…) → its own
  provider, one small pull request each
- Rename the existing `ViewModel`s to `Controller`s

Measured on 2026-10-20 with `scripts/migration_status.sh`'s patterns; the
totals are in `MIGRATION_STATUS.md`.

## Step 3 — Module migrations

For each module:

1. Patrol scenarios (mobile and web files) for its flows, merged first.
2. Interactors → `Future<T>` use cases with typed exceptions.
3. Controller + `@freezed` state; the screen becomes a Consumer widget.
4. Delete its `app_state/` files, mixins and GetIt registrations.

| Wave | Modules |
|---|---|
| 1 | app_grid, capabilities, preview_url, settings, reactions |
| 2 | invitation, recovery, user_info, search, device_settings |
| 3 | chat_draft (#3392), new_group, new_private_chat, forward |
| 4 | room (messages, members, media, settings), chat, chat_list |

## Step 4 — Removing the legacy

- [ ] Client creation, the choice of the active account and login move to
      `keepAlive` providers; their owner feeds `matrixClientProvider`, so no
      widget initializes a provider any more
      ([DO/DON'T: avoid initializing providers in a widget][do-dont])
- [ ] The `Matrix` widget is deleted
- [ ] `get_it`, `dartz` and `lib/domain/app_state/` are deleted
- [ ] Full Patrol run, mobile and web, before the next release

## Risks

- **Flaky end-to-end tests**: a red suite nobody trusts is no safety net. The
  unread scenarios and the Android nightly are fixed during Step 0–1.
- **Conflicts with feature work**: the sweep skips areas with open pull
  requests and announces each area before it starts.
- **Room and chat**: smaller pull requests there, even if slower.
- **Paused listeners**: Riverpod 3 pauses the listeners of hidden widgets
  ([Listeners inside widgets that are not visible are now paused][pause]).
  Unread badges and the chat list are checked with the screen hidden.
- **Review throughput**: about 40 pull requests; one approval a day keeps the
  pace.

## References

- [What's new in Riverpod 3.0](https://riverpod.dev/docs/whats_new)
- [Riverpod — DO/DON'T][do-dont]
- [Riverpod — About code generation](https://riverpod.dev/docs/concepts/about_code_generation)

[do-dont]: https://riverpod.dev/docs/root/do_dont
[retry]: https://riverpod.dev/docs/whats_new#automatic-retry
[pause]: https://riverpod.dev/docs/whats_new#listeners-inside-widgets-that-are-not-visible-are-now-paused
