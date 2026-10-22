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
| Module | One module through its layers | ≤ ~500 lines added in `lib/`, tests and generated files excluded |

Never mix two kinds. Check which open pull requests change files in the area
first, and skip an area someone is changing:

```bash
gh pr list --limit 100 --json number,title,files \
  --jq '.[] | select(any(.files[]; .path | startswith("<path>/"))) | "#\(.number) \(.title)"'
```

## 2. End-to-end first

A module is migrated only when its flows have Patrol scenarios on `main`.

- Mobile and web scenarios in separate files; no `kIsWeb` or platform switch
  inside a test.
- Robot pattern, as in `integration_test/robots/` and
  `integration_test/scenarios/`.
- Run the web suite locally on the new files before opening the pull request.

## 3. Mechanical recipes

End state: no `package:matrix` import in `lib/pages`, `lib/widgets` or
`lib/presentation`; only datasource implementations import the SDK. The sweep
is a step towards it, and the ratchet stops new UI imports. Keep the client's
type inferred (`final client = ref.watch(...)`) so the sweep adds none.

### `Matrix.of(context).client`

Once `matrixClientProvider` exists:

- In `build()`: `ref.watch(matrixClientProvider)`.
- In `initState`, `dispose`, callbacks and methods:
  `ref.read(matrixClientProvider)`.
- `StatefulWidget` → `ConsumerStatefulWidget`, `State` → `ConsumerState`.
- `StatelessWidget` → `ConsumerWidget`, and its
  `Widget build(BuildContext context)` becomes
  `Widget build(BuildContext context, WidgetRef ref)`.
- Change nothing else in the class.
- A mixin on `State` that needs `ref` is constrained on `ConsumerState`.

Before it exists, leave these calls alone. A controller never takes the
`Client`: it calls use cases, so a module migration waits for Step 1.

`getIt` is not swept: it goes with its module (§4).

### Imports

A file that imports `package:provider` imports Riverpod with `show`:
`import 'package:flutter_riverpod/flutter_riverpod.dart' show ConsumerState, ConsumerStatefulWidget, ConsumerWidget, WidgetRef;`,
keeping only the names the file uses.

## 4. Module recipe

In this order, one commit per step:

1. **Data**: datasource interface + implementation (`package:matrix` only
   here), repository implementation mapping SDK types to domain entities.
   Providers in `<implementation>.provider.dart`, typed with the interface,
   built natively (`XImpl(ref.watch(...))`); every `getIt` field of the
   module becomes a constructor parameter. Only a singleton whose state
   legacy code shares (`ContactsManager`, `HiveCollectionToMDatabase`,
   `UploadManager`…) gets a bridge returning `getIt.get<X>()`, with a
   `// TODO: [transitional]` comment naming its legacy consumers.
2. **Use cases**: in `lib/domain/<feature>/usecases/`, `Future<T>` + typed
   exceptions in `domain/exceptions/`. Move and rewrite the interactor from
   `lib/domain/usecase/<feature>/` if all its consumers move in this pull
   request; otherwise add a use case in the new folder and delete the
   interactor with its last consumer.
3. **Controller**: `@riverpod class XxxController extends _$XxxController`;
   `build()` returns `T`, `Future<T>` or `Stream<T>` like its source
   ([GUIDELINES.md][guidelines] §2.5.0bis). State `XxxState` with
   `@freezed`. After every `await`, `if (!ref.mounted) return;` before
   touching `state` or `ref` ([`Ref.mounted`][mounted]). No side effect in `build()`
   ([DO/DON'T][do-dont]).
4. **Screen**: Consumer widget; `ref.watch` the state, `ref.read(...notifier)`
   in callbacks; no business logic. Ephemeral UI state (text controllers,
   selection, animations, form fields) stays in the widget
   ([DO/DON'T][do-dont]).
5. **Tests**: controller tests with
   `ProviderContainer.test(retry: (_, _) => null, overrides: …)`, since a
   test container does not inherit the app's retry setting
   ([`ProviderContainer.test`][container-test]); use case tests; existing
   tests still pass.
6. **Cleanup**: delete the module's `app_state` files, mixins, unused
   interactors and their GetIt registrations.
7. Update the module row in the Modules table of `MIGRATION_STATUS.md`.
   Leave the metrics: they are refreshed on `main`.

## 5. Before opening the pull request

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
git add -N <new files>
scripts/migration_status.sh --check origin/main
```

Never run `build_runner` with `--build-filter` and
`--delete-conflicting-outputs` together: it deletes every generated file and
rebuilds only the filtered ones.

Then run the `zeus` agent ([GUIDELINES.md][guidelines]) and the
`migration-reviewer` agent on the branch, fix their findings, and put both
summaries in the pull request description.

Commit message: `type(TW-XXXX): Short subject`, no body. The pull request
takes the same title; its description holds the two agent summaries.
For a sweep: `refactor(TW-XXXX): Read the Matrix client from Riverpod in settings`.

## Riverpod references

- [What's new in Riverpod 3.0](https://riverpod.dev/docs/whats_new): retry,
  `Ref.mounted`, paused listeners, test utilities.
- [DO/DON'T][do-dont]: ephemeral state, initialization, side effects.
- [About code generation](https://riverpod.dev/docs/concepts/about_code_generation)

[mounted]: https://riverpod.dev/docs/whats_new#refmounted
[container-test]: https://riverpod.dev/docs/whats_new#providercontainertest
[do-dont]: https://riverpod.dev/docs/root/do_dont
[guidelines]: https://github.com/linagora/twake-flutter-guidelines/blob/main/GUIDELINES.md
