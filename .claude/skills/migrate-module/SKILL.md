---
name: migrate-module
description: >
  Twake-on-Matrix Riverpod migration recipe. Use whenever the user wants to
  migrate a module, a screen or an area to Riverpod, remove `Matrix.of` or
  `getIt` calls, rewrite interactors to `Future<T>`, or prepare a migration
  pull request. Trigger on: "migrate to Riverpod", "Riverpod migration",
  "remove getIt", "remove Matrix.of", "sweep", "migrate module",
  "controller", "MIGRATION_STATUS".
metadata:
  author: twake-team
  version: "1.0.0"
---

# Riverpod migration

Rules: `docs/adr/0037-riverpod-migration-rules.md`.
Plan and module order: `docs/migration/04_plan_v2.md`.
Progress: `MIGRATION_STATUS.md`, `scripts/migration_status.sh`.

## 1. Pick the kind of pull request

| Kind | Content | Size |
|---|---|---|
| End-to-end | Patrol scenarios for a module, nothing else | any |
| Mechanical | One rewrite pattern over one area | any |
| Module | One module through its layers | ≤ ~500 lines, generated files excluded |

Never mix two kinds. Check open pull requests on the area first
(`gh pr list --search <path>`); skip an area someone is changing.

## 2. End-to-end first

A module is migrated only when its flows have Patrol scenarios on `main`.

- Mobile and web scenarios in separate files; no `kIsWeb` or platform switch
  inside a test.
- Robot pattern, as in `integration_test/robots/` and
  `integration_test/scenarios/`.
- Run the web suite locally on the new files before opening the pull request.

## 3. Mechanical recipes

### `Matrix.of(context).client`

Once `matrixClientProvider` exists:

- In `build()`: `ref.watch(matrixClientProvider)`.
- In `initState`, `dispose`, callbacks and methods:
  `ref.read(matrixClientProvider)`.
- `StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`;
  `StatelessWidget` → `ConsumerWidget`. Change nothing else in the class.
- A mixin on `State` that needs `ref` is constrained on `ConsumerState`.

Before it exists, leave these calls alone; a new controller takes the
`Client` as a provider parameter, as `BootstrapViewModel` does.

### `getIt.get<X>()`

- Find or add the provider of `X` in `<implementation of X>.provider.dart`.
  While `X` has legacy consumers it returns `getIt.get<X>()`, with a comment
  naming them.
- Rewrite the call site to `ref.read(xProvider)` (`ref.watch` in `build()`).

### Imports

A file that imports `package:provider` imports Riverpod with `show`:
`import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerState, ConsumerStatefulWidget;`

## 4. Module recipe

In this order, one commit per step:

1. **Data**: datasource interface + implementation (`package:matrix` only
   here), repository implementation mapping SDK types to domain entities.
   Providers in `<implementation>.provider.dart`.
2. **Use cases**: `Future<T>` + typed exceptions in `domain/exceptions/`.
   Rewrite the interactor in place if all its consumers move in this pull
   request; otherwise add a use case next to it.
3. **Controller**: `@riverpod class XxxController extends _$XxxController`;
   `build()` returns `T`, `Future<T>` or `Stream<T>` like its source
   (GUIDELINES.md §2.5.0bis). State `XxxState` with `@freezed`. After every
   `await`, `if (!ref.mounted) return;` before touching `state`
   ([`Ref.mounted`][mounted]). No side effect in `build()`
   ([DO/DON'T][do-dont]).
4. **Screen**: Consumer widget; `ref.watch` the state, `ref.read(...notifier)`
   in callbacks; no business logic. Ephemeral UI state (text controllers,
   selection, animations, form fields) stays in the widget
   ([DO/DON'T][do-dont]).
5. **Tests**: controller tests with `ProviderContainer.test(overrides: …)`
   ([`ProviderContainer.test`][container-test]); use case tests; existing
   tests still pass.
6. **Cleanup**: delete the module's `app_state` files, mixins, unused
   interactors and their GetIt registrations.
7. Update the module row in `MIGRATION_STATUS.md` and run
   `scripts/migration_status.sh --write`.

## 5. Before opening the pull request

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
dart run custom_lint
flutter test
git add -N . && scripts/migration_status.sh --check origin/main
```

Never run `build_runner` with `--build-filter` and
`--delete-conflicting-outputs` together: it deletes every generated file and
rebuilds only the filtered ones.

Then run the `zeus` agent (GUIDELINES.md) and the `migration-reviewer` agent
on the branch, fix their findings, and put both summaries in the pull request
description.

Commit and pull request title: `type(TW-XXXX): Short subject`, no body.
For a sweep: `refactor(TW-XXXX): Read the Matrix client from Riverpod in settings`.

## Riverpod references

- [What's new in Riverpod 3.0](https://riverpod.dev/docs/whats_new): retry,
  `Ref.mounted`, paused listeners, test utilities.
- [DO/DON'T][do-dont]: ephemeral state, initialization, side effects.
- [About code generation](https://riverpod.dev/docs/concepts/about_code_generation)

[mounted]: https://riverpod.dev/docs/whats_new#refmounted
[container-test]: https://riverpod.dev/docs/whats_new#providercontainertest
[do-dont]: https://riverpod.dev/docs/root/do_dont
