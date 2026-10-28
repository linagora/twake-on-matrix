# 37. Riverpod migration rules

Date: 2026-10-20

## Status

Proposed

## Context

The Riverpod migration plan (`docs/migration/01_migration_plan.md`) has been a
draft since March. Its open questions were never settled, so the code drifted:

- Notifiers are named `ViewModel` on `main` and `Controller` on
  `contacts/migration`, while [GUIDELINES.md][guidelines] §3.2 says
  `Controller`.
- Providers live either in `lib/pages/<feature>/providers/` or next to their
  implementation in `*.provider.dart`.
- States are `@freezed` or hand-written sealed classes.
- `MatrixState`, a widget, pushes values into providers
  (`loginHomeserverSummaryProvider` on `main`, `activeMatrixClientProvider`
  in #3459), although the plan only allows Riverpod to read from GetIt.

Meanwhile the legacy did not shrink: `Matrix.of` and `Matrix.read` calls were
288 when the plan was written and are 288 today, with a peak at 295 in June.
Nothing stops new legacy code from being added.

The plan was also written before Riverpod 3.0, which retries failing
providers, pauses hidden listeners and throws on disposed refs
([What's new in Riverpod 3.0][whats-new]).

## Decision

### 1. Naming, placement and state

- Providers use code generation (`@riverpod`), the way the Riverpod
  documentation recommends ([About code generation][codegen]).
- A Notifier is a `XxxController`; its state is a `XxxState`
  ([GUIDELINES.md][guidelines] §3.2). Existing `ViewModel`s are renamed as
  their module is migrated.
- States are `@freezed`; a state with several shapes is a `@freezed` sealed
  union ([GUIDELINES.md][guidelines] §9.3). Riverpod 3 notifies listeners
  only when the new state is not `==` to the old one, which `@freezed`
  implements
  ([All `updateShouldNotify` now use `==`][whats-new-equality]).
- A dependency provider (datasource, repository, use case, service) lives in
  `<implementation>.provider.dart`, next to its implementation
  ([GUIDELINES.md][guidelines] §2.7), and its type is the interface, not the
  `*Impl`. App-wide state with no implementation file (the accounts, the
  active client) lives in `lib/providers/`, like
  `login_homeserver_summary_provider.dart`. A controller lives next to its
  screen.
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
- **Tests** create their container with
  `ProviderContainer.test(retry: (_, _) => null)`: a test container does not
  inherit the app's retry setting
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
- GetIt goes module by module, not in a sweep. A module migration gives each
  dependency it needs a native provider (`XImpl(ref.watch(...))`) and
  deletes the module's `getIt` lookups and registrations. Legacy code keeps
  its GetIt registration until its last consumer migrates; a stateless
  dependency can be built by both meanwhile.
- A bridge, a provider that returns `getIt.get<X>()`, is only for a
  singleton whose state is shared with legacy consumers (`ContactsManager`,
  `HiveCollectionToMDatabase`, `UploadManager`…): a second instance would
  hold a second state. It lives in `<implementation of X>.provider.dart`,
  names the legacy consumers in a comment, and the pull request that creates
  it moves at least one existing `getIt.get<X>()` lookup onto it. The
  ratchet counts it like any other `getIt` use, so a bridge added without
  that move fails the check on purpose, and no file name can hide a lookup.
- A value still owned by legacy code is pushed into its provider by its
  owner. Providers are not initialized from widgets ([DO/DON'T: avoid
  initializing providers in a widget][do-dont]). The two pushes `MatrixState`
  does today (the active client, the homeserver summary) are tolerated until
  they are removed; any new push from a widget, `MatrixState` included, is
  not.
- Every bridge carries a `// TODO: [transitional]` comment, the marker the
  code already uses, so `git grep "TODO: \[transitional\]"` lists them.

### 4. Open questions of the plan

- **Q1**: code reads the active `Client` from `matrixClientProvider`, which
  is never null and serves screens behind login. During the migration it
  reads the nullable `activeMatrixClientProvider` (#3459), fed by
  `MatrixState` and later derived from the account state (#3466–#3476);
  nothing else reads `activeMatrixClientProvider`. At the end only
  `matrixClientProvider` remains, reading the active account directly; "no
  account" is the account state's and the router's concern, not the
  client's.
- **Q2**: new use cases go in `lib/domain/<feature>/usecases/`, one class
  per use case with `execute()` ([GUIDELINES.md][guidelines] §2.3.4), as
  #3459 does. Legacy interactors stay in `lib/domain/usecase/<feature>/`. An
  interactor moves to the new folder, rewritten to `Future<T>` + typed
  exceptions, when all its consumers migrate in the same pull request.
  Otherwise a use case is added in the new folder for the migrated
  consumers, and the interactor is deleted with its last consumer. The
  folder tells migrated code from legacy; nothing is renamed in bulk.
- **Q3**: no move to `features/` folders during the migration.
- **Q4**: the migration is done when every legacy metric of
  `scripts/migration_status.sh` is zero and the `Matrix` widget is gone.

### 5. Scope per module

A service is created only when it orchestrates several use cases or holds
state ([GUIDELINES.md][guidelines] §2.3.5). A module with one use case goes
controller → use case → repository → datasource.

### 6. Guardrails

- The `Riverpod migration` workflow fails a pull request that increases a
  legacy metric: `Matrix.of`, `getIt` uses (bridges included), GetIt
  registrations, `Stream<Either>`, `dartz` imports,
  `lib/domain/app_state/` files, UI files importing `package:matrix`.
- The workflow compares a pull request with `main` as it is when the check
  runs. Two pull requests that each add one use and are checked before either
  merges both pass, and the growth stays. The next pull request starts from
  the higher number; the reviewer agents catch the additions, and
  `MIGRATION_STATUS.md` shows the drift.
- `riverpod_lint` checks the rules the Riverpod documentation recommends
  ([DO/DON'T][do-dont], [riverpod_lint][riverpod-lint]). Version 3.0.x runs
  as a legacy analyzer plugin through `custom_lint`, which `flutter analyze`
  reports as deprecated since Dart 3.13. Version 3.1.x uses the new plugin
  system but needs Riverpod 3.4 and analyzer 13: it comes in its own pull
  request with that upgrade.

### 7. Pull requests

- A mechanical pull request applies one pattern; its size does not matter.
- A module pull request adds under about 500 lines in `lib/`; tests,
  generated files and deleted lines do not count.
- A module is covered by Patrol scenarios (mobile only; the web suite is
  disabled in CI), merged before its migration.
- Every migration pull request runs the `zeus` and `migration-reviewer` agents
  and quotes their summaries.

## Consequences

- The plan's 6 to 10 months shrink: in `lib/pages`, `lib/widgets` and
  `lib/presentation`, most `Matrix.of` calls (152 of them only read
  `.client`) can be rewritten mechanically.
- `getIt` shrinks only as modules migrate, and is gone after the last wave
  (room, chat, chat_list) and Step 4. In exchange there are few bridges:
  only shared-state singletons, listed by
  `git grep "TODO: \[transitional\]"`.
- Six existing `ViewModel`s and their tests are renamed.
- `MatrixState` keeps its two pushes into providers until they are removed,
  against the Riverpod recommendation.
- Turning retry off changes how today's providers react to errors; their
  tests run with it off.

## References

- [What's new in Riverpod 3.0][whats-new]
- [Riverpod — DO/DON'T][do-dont]
- [Riverpod — About code generation][codegen]
- [riverpod_lint][riverpod-lint]
- [GUIDELINES.md][guidelines], in `linagora/twake-flutter-guidelines`

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
[guidelines]: https://github.com/linagora/twake-flutter-guidelines/blob/main/GUIDELINES.md
