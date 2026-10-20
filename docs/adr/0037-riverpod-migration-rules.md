# 37. Riverpod migration rules

Date: 2026-10-20

## Status

Proposed

## Context

The Riverpod migration plan (`docs/migration/01_migration_plan.md`) has been a
draft since March. Its open questions were never settled, so the code drifted:

- Notifiers are named `ViewModel` on `main` and `Controller` on
  `contacts/migration`, while GUIDELINES.md §3.2 says `Controller`.
- Providers live either in `lib/pages/<feature>/providers/` or next to their
  implementation in `*.provider.dart`.
- States are `@freezed` or hand-written sealed classes.
- `MatrixState`, a widget, pushes values into providers
  (`loginHomeserverSummaryProvider`, `activeMatrixClientProvider`), although
  the plan only allows Riverpod to read from GetIt.

Meanwhile `Matrix.of` calls grew from 246 to 288. Nothing stops new legacy
code from being added.

The plan was also written before Riverpod 3.0, which retries failing
providers, pauses hidden listeners and throws on disposed refs
([What's new in Riverpod 3.0][whats-new]).

## Decision

### 1. Naming, placement and state

- Providers use code generation (`@riverpod`), the way the Riverpod
  documentation recommends ([About code generation][codegen]).
- A Notifier is a `XxxController`; its state is a `XxxState`
  (GUIDELINES.md §3.2). Existing `ViewModel`s are renamed as their module is
  migrated.
- States are `@freezed`; a state with several shapes is a `@freezed` sealed
  union (GUIDELINES.md §9.3). Riverpod 3 notifies listeners only when the new
  state is not `==` to the old one, which `@freezed` implements
  ([All `updateShouldNotify` now use `==`][whats-new-equality]).
- A dependency provider (datasource, repository, use case, service) lives in
  `<implementation>.provider.dart`, next to its implementation
  (GUIDELINES.md §2.7). A controller lives next to its screen.
- Ephemeral UI state stays in the widget: text controllers, selection,
  animations, form fields ([DO/DON'T: avoid using providers for ephemeral
  state][do-dont]).

### 2. Riverpod 3 behaviours

- **Automatic retry is off.** The app's container passes
  `retry: (_, _) => null`; a provider that should retry declares its own
  `retry`. A failing provider shows its typed error instead of retrying
  silently ([Automatic retry][whats-new-retry]).
- **`ref.mounted` after every `await`** in a Notifier method, before touching
  `state` or `ref`: Riverpod 3 throws on a disposed ref
  ([`Ref.mounted`][whats-new-mounted]).
- **No experimental API**: no mutations, no offline persistence
  ([What's new in Riverpod 3.0][whats-new]).
- **No legacy providers**: no `StateProvider`, `StateNotifierProvider` or
  `ChangeNotifierProvider` ([discouraged and moved to a different
  import][whats-new-legacy]).
- **Tests** create their container with `ProviderContainer.test()`
  ([`ProviderContainer.test`][whats-new-test]).
- **Hidden widgets pause their listeners.** A provider read only by a hidden
  screen (an unread badge in another tab) stops updating until the screen is
  visible again ([Listeners inside widgets that are not visible are now
  paused][whats-new-pause]).

### 3. Bridges

- From Step 1, `main` creates the app's `ProviderContainer` and gives it to
  the tree with `UncontrolledProviderScope`. Code outside the widget tree
  (GetIt services, `background_push.dart`, `ClientManager`) reads and feeds
  providers through this container only. A background isolate has its own
  memory and does not see it.
- Riverpod may read from GetIt: a provider that returns `getIt.get<X>()` is
  allowed while `X` still has legacy consumers, with a comment naming them.
- A value still owned by legacy code is pushed into its provider by its
  owner. Providers are not initialized from widgets ([DO/DON'T: avoid
  initializing providers in a widget][do-dont]), with one tolerated exception:
  `MatrixState` keeps pushing the active client and the homeserver summary
  until Step 4, because it is where the active account is chosen today. Each
  push is marked as a bridge. No other widget pushes into a provider.

### 4. Open questions of the plan

- **Q1**: a single `matrixClientProvider` exposes the active `Client`. It is
  fed by `MatrixState` until the choice of the active account and client
  creation move to Riverpod (last step).
- **Q2**: an interactor is rewritten in place to `Future<T>` + typed
  exceptions when its consumers are migrated in the same pull request.
  Otherwise a `UseCase` is added next to it and the interactor is deleted with
  its last consumer.
- **Q3**: no move to `features/` folders during the migration.
- **Q4**: the migration is done when every legacy metric of
  `scripts/migration_status.sh` is zero and the `Matrix` widget is gone.

### 5. Scope per module

A service is created only when it orchestrates several use cases or holds
state (GUIDELINES.md §2.3.5). A module with one use case goes
controller → use case → repository → datasource.

### 6. Guardrails

- The `Riverpod migration` workflow fails a pull request that increases a
  legacy metric: `Matrix.of`, GetIt lookups outside providers, GetIt
  registrations, `Stream<Either>`, `dartz` imports,
  `lib/domain/app_state/` files.
- `riverpod_lint` checks the rules the Riverpod documentation recommends
  ([DO/DON'T][do-dont], [riverpod_lint][riverpod-lint]). Version 3.0.x runs
  through `custom_lint` (`dart run custom_lint`) and follows the `riverpod`
  version; 3.1.x needs Riverpod 3.4 and analyzer 13. It joins CI once the
  findings on existing code are fixed.

### 7. Pull requests

- A mechanical pull request applies one pattern; its size does not matter.
- A module pull request stays under about 500 lines of non-generated diff.
- A module is covered by Patrol scenarios, mobile and web, merged before its
  migration.
- Every migration pull request runs the `zeus` and `migration-reviewer` agents
  and quotes their summaries.

## Consequences

- The plan's 6 to 10 months shrink: most `Matrix.of` calls (152 of them only
  read `.client`) and every `getIt.get` call site can be rewritten
  mechanically.
- Six existing `ViewModel`s and their tests are renamed.
- Bridges exist until the last step; they are listed by the `getIt` lookups
  inside providers metric, by the writes through the app container and by
  `MatrixState`'s marked pushes.
- `MatrixState` stays a widget that initializes providers until Step 4,
  against the Riverpod recommendation; the exception ends with it.
- Turning retry off changes how today's providers react to errors; their
  tests run with it off.

## References

- [What's new in Riverpod 3.0][whats-new]
- [Riverpod — DO/DON'T][do-dont]
- [Riverpod — About code generation][codegen]
- [riverpod_lint][riverpod-lint]

[whats-new]: https://riverpod.dev/docs/whats_new
[whats-new-retry]: https://riverpod.dev/docs/whats_new#automatic-retry
[whats-new-mounted]: https://riverpod.dev/docs/whats_new#refmounted
[whats-new-equality]: https://riverpod.dev/docs/whats_new#all-updateshouldnotify-now-use-
[whats-new-legacy]: https://riverpod.dev/docs/whats_new#stateproviderstatenotifierprovider-and-changenotifierprovider-are-discouraged-and-moved-to-a-different-import
[whats-new-test]: https://riverpod.dev/docs/whats_new#providercontainertest
[whats-new-pause]: https://riverpod.dev/docs/whats_new#listeners-inside-widgets-that-are-not-visible-are-now-paused
[do-dont]: https://riverpod.dev/docs/root/do_dont
[codegen]: https://riverpod.dev/docs/concepts/about_code_generation
[riverpod-lint]: https://pub.dev/packages/riverpod_lint
