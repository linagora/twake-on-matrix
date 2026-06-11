# Migration plan to Riverpod 3.0

> **Author**: Clement
> **Last updated**: 2026-03-27
> **Status**: Draft — pending decisions on open questions
> **Reference document**: [GUIDELINES.md](../../GUIDELINES.md)

---

## Table of contents

1. [Overview](#1-overview)
2. [Current architecture vs target architecture](#2-current-architecture-vs-target-architecture)
3. [Migration phases](#3-migration-phases)
4. [Detailed migration order](#4-detailed-migration-order)
5. [Coexistence strategy for old/new code](#5-coexistence-strategy-for-oldnew-code)
6. [Riverpod conventions](#6-riverpod-conventions)
7. [Module prioritization](#7-module-prioritization)
8. [Validation criteria per migrated module](#8-validation-criteria-per-migrated-module)
9. [Risks and mitigations](#9-risks-and-mitigations)
10. [Estimated timeline](#10-estimated-timeline)
11. [Open questions](./03_open_questions.md)

---

## 1. Overview

Progressive migration of the Twake on Matrix application from the current architecture (get_it + Interactors + Stream\<Either\<Failure, Success\>\> + presentation mixins) to the target architecture defined in GUIDELINES.md (Riverpod 3.0 + Feature First Clean Architecture + Future\<T\> + Controllers).

### Measured scope of the effort

| Metric | Value |
|---|---|
| Occurrences of `Matrix.of(context)` | **246** in 104 files |
| Occurrences of `getIt.get` | **349** in 163 files |
| Existing usecase modules | ~18 directories |
| Presentation pages | ~39 directories |
| Pilot module | Invitation |

This is not a refactoring. It is a progressive rewrite of the app's backbone.

---

## 2. Current architecture vs target architecture

### 2.1 Current architecture

```
Screen (StatefulWidget)
  ├── Matrix.of(context)         ← direct Matrix SDK coupling in the view
  ├── Mixin (ex: InvitationStatusMixin)
  │     └── getIt.get<XxxInteractor>()   ← DI via service locator
  │           └── Stream<Either<Failure, Success>>  ← custom pattern
  │                 └── Repository (I/Impl)
  │                       └── DataSource (I/Impl)
  │                             └── API Tom (Dio) / SDK Matrix / Hive
  └── ValueNotifier<Either<Failure, Success>>   ← ad-hoc state management
```

**Identified problems:**

- No Service layer: business orchestration is scattered across mixins and screens
- No dedicated Controller: UI state is managed via `ValueNotifier`s in mixins
- Direct coupling to the Matrix SDK from the presentation (246 occurrences)
- DI via service locator (get_it): invisible to the type system, impossible to override cleanly in tests
- `Stream<Either<Failure, Success>>` pattern with a custom hierarchy (`app_state/`) that duplicates `AsyncValue`
- Interactors know infrastructure types (`DioException`) — violation of Clean Architecture

### 2.2 Target architecture

```
Screen (ConsumerWidget)
  ├── ref.watch(xxxControllerProvider)        ← observes XxxState, rebuilds on change
  │     └── XxxState (@freezed)               ← immutable UI state
  └── ref.read(xxxControllerProvider.notifier).doAction()  ← action call in callback
        └── Controller (AsyncNotifier/Notifier)
              └── Service (business orchestration, pure Dart)
                    └── UseCase (single business action, pure Dart)
                          └── Repository Interface (domain/)
                                └── Repository Impl (data/)
                                      └── DataSource Interface (data/)
                                            └── DataSource Impl (data/)
                                                  └── API Tom (Dio) / SDK Matrix / Hive
```

**Fundamental changes:**

| Before | After |
|---|---|
| `getIt.get<T>()` | Riverpod provider (`ref.watch` / `ref.read`) |
| `Stream<Either<Failure, Success>>` | `Future<T>` + typed exceptions |
| `ValueNotifier` in mixin | `AsyncNotifier` / `Notifier` (Controller) |
| `Matrix.of(context)` | Matrix DataSource injected via Riverpod |
| `app_state/` hierarchy | Native Riverpod `AsyncValue<T>` |
| Presentation mixins | Controllers composed via `ref` |

---

## 3. Migration phases

The migration follows a strict coexistence approach: at no point should the application be in a non-functional state. Each phase produces code that compiles and passes tests.

### Phase 0 — Coexistence infrastructure (prerequisite)

Set up the get_it <-> Riverpod bridge so both systems can coexist.

- [ ] Create a global `ProviderContainer` accessible from get_it (or the reverse)
- [ ] Define the bridge strategy (see section 5)
- [ ] Migrate `Matrix.of(context)` to an injectable abstraction (top priority)

### Phase 1 — Service layer

Create services that centralize the business logic currently scattered across mixins and screens.

- [ ] Identify for each module the scattered orchestration logic
- [ ] Create `XxxService` in `domain/services/` (or `features/xxx/domain/services/`)
- [ ] Services call existing use cases (no interactor rewrite at this stage)
- [ ] Mixins progressively delegate to services

### Phase 2 — Missing abstraction layers

Add the missing layers per the target: Service -> UseCase -> Repository (I+Impl) -> DataSource (I+Impl) -> Endpoint.

- [ ] Abstract `Matrix.of(context)` calls behind injectable DataSources
- [ ] Migrate interactors from `Stream<Either<Failure, Success>>` to `Future<T>` + typed exceptions
- [ ] Remove infrastructure dependencies from domain (e.g. `DioException` in `GenerateInvitationLinkInteractor`)
- [ ] Map Matrix SDK types to domain entities in Repository Impl
- [ ] Progressively remove the `app_state/` hierarchy in favour of `AsyncValue`

### Phase 3 — Presentation migration

Migrate controllers/screens to Controller + Screen + State.

- [ ] Create `XxxController extends _$XxxController` (Riverpod codegen)
- [ ] Create `XxxState` with `@freezed`
- [ ] Migrate `StatefulWidget`s to `ConsumerWidget` / `ConsumerStatefulWidget`
- [ ] Replace `ValueNotifier`s with Riverpod providers
- [ ] Remove now-obsolete presentation mixins

---

## 4. Detailed migration order

For each module, the internal order is:

```
1. DataSource interfaces + impls (if missing, especially for Matrix SDK)
2. Repository interfaces + impls (map SDK types -> domain entities)
3. UseCase: migrate from Stream<Either> to Future<T>
4. Service: create the orchestration layer
5. Controller: create the Notifier/AsyncNotifier
6. State: create the @freezed state
7. Screen: migrate to ConsumerWidget
8. Tests: adapt existing + add new ones
9. Cleanup: remove mixin, app_state classes, get_it registrations
```

> **Original note**: "Create services that centralize the data" was step 1 in the initial notes. The order was adjusted: DataSources and Repositories must exist before Services, otherwise Services have nothing to orchestrate. Service creation comes after the lower layers are in place.

---

## 5. Coexistence strategy for old/new code

### 5.1 The central problem: get_it and Riverpod must coexist

During migration, some modules use get_it, others Riverpod. They must be able to call each other.

### 5.2 Recommended approach: unidirectional bridge

**Bridge direction: Riverpod reads from get_it, not the other way around.**

```dart
// Provider that exposes a legacy service registered in get_it
@riverpod
InvitationRepository invitationRepository(Ref ref) {
  return getIt.get<InvitationRepository>();
}

// The new Controller uses the provider normally
@riverpod
class InvitationController extends _$InvitationController {
  @override
  FutureOr<InvitationState> build() async {
    final repo = ref.watch(invitationRepositoryProvider);
    // ...
  }
}
```

As modules are migrated, the provider transitions from delegating to get_it to direct creation:

```dart
// After complete migration of the module
@riverpod
InvitationRepository invitationRepository(Ref ref) {
  final dataSource = ref.watch(invitationDataSourceProvider);
  return InvitationRepositoryImpl(dataSource);
}
```

### 5.3 Abstracting Matrix.of(context)

This is the most critical and most cross-cutting effort. 246 occurrences, 104 files.

**Fundamental constraint**: a `@riverpod` provider receives `Ref`, not `BuildContext`. It cannot call `Matrix.of(context)`. The migration does not consist of wrapping the InheritedWidget — the Matrix `Client` must live directly in Riverpod.

**Target approach: the `Client` lives in a `keepAlive` provider**

```dart
// lib/providers/matrix_client_provider.dart
@Riverpod(keepAlive: true)
Client matrixClient(Ref ref) {
  final client = Client('TwakeApp', databaseFactory: ...);
  ref.onDispose(() => client.dispose());
  return client;
}
```

The `ProviderScope` at the root of the app replaces the `Matrix` widget as the entry point:

```dart
// main.dart
runApp(ProviderScope(child: TwakeApp())); // no longer need the Matrix widget as InheritedWidget
```

DataSource Impl receive the `Client` via injection:

```dart
@riverpod
RoomDataSource roomDataSource(Ref ref) {
  return RoomDataSourceImpl(ref.watch(matrixClientProvider));
}
```

**3-step migration strategy:**

1. **Create `matrixClientProvider`** with the `Client` initialized inside (`keepAlive: true`)
2. **Create DataSource Impl** that receive the `Client` via injection
3. **Migrate file by file** the 246 occurrences of `Matrix.of(context)` to injected DataSources

### 5.4 Non-regression rule during coexistence

- Any non-migrated module continues to work via get_it without modification
- A migrated module must NEVER directly import `getIt`
- Cross-imports between migrated and non-migrated modules go through bridge providers

---

## 6. Riverpod conventions

> Official reference: https://riverpod.dev/docs/introduction/getting_started

These rules are mandatory from the first migrated module. Early divergence is costly to unify.

### 6.1 Naming

| Element | Convention | Example |
|---|---|---|
| Notifier (state + logic) | `Controller` suffix | `ChatController`, `InvitationController` |
| Generated provider | `Provider` suffix (auto via codegen) | `chatControllerProvider` |
| State (`@freezed`) | `State` suffix | `ChatState`, `InvitationState` |
| Screen | `Page` suffix | `ChatPage`, `InvitationPage` |

### 6.2 `ref.watch` vs `ref.read` vs `ref.listen` vs `ref.listenManual`

> Reference: https://docs-v2.riverpod.dev/docs/concepts/reading

| Method | Allowed in | Forbidden in | Effect |
|---|---|---|---|
| `ref.watch` | `build()`, `Notifier.build()` | Callbacks, methods, `initState` | Subscribes — rebuilds on every change |
| `ref.read` | Callbacks, methods, `initState` | `build()`, `Notifier.build()` | Reads once — no rebuild |
| `ref.listen` | `build()` | Outside `build()` | Subscribes — side effect without rebuild |
| `ref.listenManual` | `initState`, `didChangeDependencies` | — | Subscribes — returns a `ProviderSubscription` to `cancel()` in `dispose()` |

```dart
// ✅ Correct — ConsumerWidget
class ChatPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(chatControllerProvider(roomId)); // rebuilds on change
    return ElevatedButton(
      onPressed: () => ref.read(chatControllerProvider(roomId).notifier).send(),
    );
  }
}

// ✅ Correct — ConsumerStatefulWidget: one-time read in initState
class ChatPageState extends ConsumerState<ChatPage> {
  @override
  void initState() {
    super.initState();
    ref.read(chatControllerProvider(widget.roomId)); // single read, no subscription
  }
}

// ✅ Correct — react to a change from initState without rebuild
class ChatPageState extends ConsumerState<ChatPage> {
  ProviderSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual(chatControllerProvider(widget.roomId), (prev, next) {
      // side effect: navigation, snackbar, etc.
    });
  }

  @override
  void dispose() {
    _sub?.cancel(); // mandatory, otherwise memory leak
    super.dispose();
  }
}

// ❌ Incorrect — ref.read in build(): the view never updates
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.read(chatControllerProvider(roomId)); // silent bug
}

// ❌ Incorrect — ref.watch in initState: AssertionError in debug
void initState() {
  super.initState();
  ref.watch(chatControllerProvider(widget.roomId)); // crash in debug
}
```

### 6.3 `autoDispose` and `keepAlive`

> Reference: https://riverpod.dev/docs/essentials/auto_dispose

- `@riverpod` enables `autoDispose` **by default**: the provider is destroyed when no widget is listening to it anymore.
- Use `ref.keepAlive()` only for providers that must survive navigation (e.g. cache of an active room, persistent network connection).
- Do not use `keepAlive` by default to avoid memory leaks.

```dart
// Example: a keepAlive provider legitimately survives navigation
// (e.g. current session, Matrix client). It does NOT duplicate data
// that the SDK already owns — see GUIDELINES.md §2.4.5.
@Riverpod(keepAlive: true)
Client matrixClient(Ref ref) {
  final client = Client('TwakeApp', databaseFactory: ...);
  ref.onDispose(() => client.dispose());
  return client;
}
```

> ⚠ **Do not create a cache provider that duplicates the SDK Timeline or room state.**
> The Matrix SDK already keeps active rooms hot in memory and persists them in its native DB.
> A `@riverpod` controller for a room (e.g. `ChatController(roomId)`) should stay `autoDispose`:
> when the user leaves the room, the controller disposes, but `Room.getTimeline()` remains valid
> server-side. On re-entry, the same Timeline object is returned — no reload, no divergence.

> ⚠ Do not combine `keepAlive` with `ref.onCancel(() => link.close())` — `onCancel` fires when listeners unsubscribe, which exactly cancels the effect of `keepAlive`.

### 6.4 Parameterized providers (formerly `family`)

> Reference: https://riverpod.dev/docs/essentials/passing_args

With code generation, parameters are declared directly on the function or class. No manual `.family`.

```dart
// ✅ Correct with @riverpod
@riverpod
class ChatController extends _$ChatController {
  @override
  AsyncValue<ChatState> build(String roomId) => const AsyncValue.loading();
}

// Usage
ref.watch(chatControllerProvider('!roomId:server'));
```

- Parameters must be **value-comparable** (`==` + `hashCode`). Prefer primitive types or `@freezed` classes.
- Do not pass mutable objects as parameters.

### 6.5 Provider types: when to use what

All providers use the `@riverpod` annotation (codegen). Two forms exist:

- **`@riverpod` on a class** — for controllers of a screen: state + mutations. The generated provider type (`NotifierProvider`, `AsyncNotifierProvider`, `StreamNotifierProvider`) is inferred from the return type of `build()`.
- **`@riverpod` on a function** — for read-only providers: projections of a source, computed values, pure DI. The generated provider type (`Provider`, `FutureProvider`, `StreamProvider`) is inferred from the return type of the function.

**Decision matrix for a controller** (class with `build()` + mutation methods):

| Canonical source | Return type of `build()` |
|---|---|
| Continuous stream (Matrix SDK: timeline, rooms, typing, presence) | `Stream<T>` |
| Async one-shot (REST Twake: profile, login, invitations, search) | `Future<T>` |
| Local synchronous (Hive: settings, theme, drafts) | `T` |

**Two-step criterion** (in order):
1. Is the source synchronous and local? → yes = `T` ; no = question 2.
2. Continuous flow or single value? → Stream = `Stream<T>` ; Future = `Future<T>`.

**Rule of thumb**: the controller's `build()` return type follows the type exposed by the canonical source. See §2.4.5 *Source of truth par domaine* in `GUIDELINES.md`.

**Anti-pattern to avoid**: a controller with `Future<T>` in `build()` that performs a manual `ref.listen` on a stream to update `state`. If the source is a stream, return `Stream<T>` directly in `build()` — let Riverpod manage the subscription lifecycle.

```dart
// ❌ Anti-pattern — Future<T> + manual ref.listen on a stream
@riverpod
class ChatController extends _$ChatController {
  @override
  Future<ChatState> build(String roomId) async {
    ref.listen(chatServiceProvider, (_, service) {
      service.watchTimeline(roomId).listen((messages) {
        state = AsyncValue.data(ChatState(messages: messages));
      });
    });
    return ChatState.initial();
  }
}

// ✅ Correct — Stream<T> in build(), Riverpod manages the subscription
@riverpod
class ChatController extends _$ChatController {
  @override
  Stream<List<MessageEntity>> build(String roomId) =>
      ref.watch(chatServiceProvider).watchTimeline(roomId);

  Future<void> sendMessage(String body) =>
      ref.read(chatServiceProvider).send(roomId, body);
}
```

**Examples across the app**:

```dart
// Pure DI — @riverpod on a function, no state
@riverpod
InvitationService invitationService(Ref ref) {
  return InvitationService(
    generateLinkUseCase: GenerateInvitationLinkUseCase(
      ref.watch(invitationRepositoryProvider),
    ),
    getStatusUseCase: GetInvitationStatusUseCase(
      ref.watch(invitationRepositoryProvider),
    ),
  );
}

// Read-only projection — @riverpod on a function, Stream return
@riverpod
Stream<List<String>> roomTimelineEventIds(Ref ref, String roomId) =>
    ref.watch(chatServiceProvider).watchEventIds(roomId);

// Derived / computed — @riverpod on a function, pure computation over other providers
@riverpod
int roomUnreadCount(Ref ref, String roomId) {
  final messages = ref.watch(chatControllerProvider(roomId)).valueOrNull ?? [];
  return messages.where((m) => !m.read).length;
}

// Controller — Future<T> in build(), REST one-shot source
@riverpod
class InvitationController extends _$InvitationController {
  @override
  Future<InvitationState> build() async {
    final service = ref.watch(invitationServiceProvider);
    return InvitationState(status: await service.getStatus());
  }

  Future<void> generateLink() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(invitationServiceProvider).generateLink(),
    );
  }
}

// Controller — Stream<T> in build(), Matrix SDK continuous source
// ⚠ Add a debounce in the Service if the stream emits at high frequency
// (e.g. initial Matrix sync). See §9 Risks — risk 8.5
@riverpod
class ChatController extends _$ChatController {
  @override
  Stream<List<MessageEntity>> build(String roomId) =>
      ref.watch(chatServiceProvider).watchTimeline(roomId);

  Future<void> sendMessage(String body) =>
      ref.read(chatServiceProvider).send(roomId, body);
}

// Controller — synchronous T in build(), local Hive source
@riverpod
class SettingsController extends _$SettingsController {
  @override
  SettingsState build() =>
      ref.watch(settingsServiceProvider).load();

  Future<void> updateTheme(ThemeMode mode) async {
    await ref.read(settingsServiceProvider).saveTheme(mode);
    ref.invalidateSelf();
  }
}
```

**Rebuild granularity for high-frequency lists (timeline, room list, etc.)**: it is handled on the UI side, not by multiplying Riverpod providers. Do **not** create a `family(itemId)` provider per list item when all items come from a single stream source — it creates fan-out subscriptions and thrashing with `autoDispose` on scroll.

```dart
// Parent — watches the list provider
ListView.builder(
  itemCount: messages.length,
  itemBuilder: (ctx, i) => MessageItem(
    key: ValueKey(messages[i].eventId), // stable key → O(N) diff
    message: messages[i],
  ),
)

// Item — StatelessWidget, no ref.watch, compared via == on freezed entity
class MessageItem extends StatelessWidget {
  const MessageItem({required this.message, super.key});
  final MessageEntity message;
  // Parent pushes the message; Flutter skips rebuild when the instance is unchanged.
}
```

Flutter's `ListView.builder` already diffs efficiently via `ValueKey` + immutable `@freezed` entities. A family-per-item is justified only when each item has its own independent source (e.g. `userByIdProvider(userId)` fetching per user via REST) — not when all items share the same stream source.

**Evolution option post-POC** (not for the pilot): `matrix-dart-sdk` exposes native callbacks scoped by index on `Timeline` (`onInsert(i)`, `onChange(i)`, `onRemove(i)`). If measurements during the POC show that re-emitting a full `List<MessageEntity>` on every event is a hotspot, the service can evolve to a `Stream<TimelineDiff>` (sealed: `Insert` / `Change` / `Remove` / `Clear`) and the controller can switch to a synchronous `T = List<MessageEntity>` return in `build()` that applies patches in O(1). Do not preempt this optimization — measure first.

### 6.6 Pure domain — no Riverpod imports allowed

The `domain/` layer (use cases, services, repository interfaces, entities) must contain **no Riverpod imports**. Riverpod belongs only to the presentation layer and the DI configuration.

```dart
// ✅ Pure Dart use case
class SendMessageUseCase {
  final MessageRepository _repo;
  const SendMessageUseCase(this._repo);
  Future<void> execute(String roomId, String content) => _repo.send(roomId, content);
}

// ❌ Forbidden in domain/
import 'package:riverpod_annotation/riverpod_annotation.dart'; // no
```

### 6.7 `select` for rebuild granularity

Use `.select()` to rebuild a widget only on the field that concerns it.

```dart
// Rebuilds only when unreadCount changes, not on the entire RoomState
final unreadCount = ref.watch(
  roomControllerProvider(roomId).select((s) => s.unreadCount),
);
```

Mandatory in lists (e.g. `ChatListItem` must not rebuild if only the typing indicator of another room changes).

### 6.8 Error handling in Controllers

`AsyncValue.guard()` for generic errors (network, timeout) — the state transitions to `AsyncValue.error` and the view handles display via `.when(error: ...)`:

```dart
Future<void> send(String content) async {
  state = const AsyncValue.loading();
  state = await AsyncValue.guard(
    () => ref.read(sendMessageServiceProvider).send(roomId, content),
  );
}
```

`try/catch` with typed exceptions when errors have different semantics (e.g. expired room, banned user, temporary network error) — sealed exception classes are defined in `domain/exceptions/`:

```dart
Future<void> unblockUser(String userId) async {
  state = const AsyncValue.loading();
  try {
    await ref.read(roomServiceProvider).unblockUser(userId);
    state = const AsyncValue.data(RoomState.updated());
  } on UserNotInIgnoreListException {
    // specific business error — different feedback in the UI
    state = AsyncValue.error(UserNotInIgnoreListException(), StackTrace.current);
  } on UnblockForbiddenException {
    state = AsyncValue.error(UnblockForbiddenException(), StackTrace.current);
  }
}
```

### 6.9 Ownership model & write invariant

> Full rationale and domain-by-domain table: `GUIDELINES.md` §2.4.5.

**Single source of truth per domain**:
- Matrix data (timeline, events, presence, typing) → **SDK Matrix** (+ native DB). Repositories/Services stateless.
- REST Twake data (invitations, contacts, TOM) → **API Twake**. Local Hive cache legitimate.
- Drafts, settings → **Hive** (only local source).

**Write invariant (mandatory)**: `UI → Controller.action() → Service → Repository → canonical source → subscription → state update → UI rebuild`. A user action never mutates `state` directly.

**Consequence for this migration**: any controller that tracks "pending messages" or caches a room timeline in its own state violates the invariant. The Matrix SDK already handles local echo natively (`Event.status`); projection into `ChatState` must happen exclusively through the Timeline stream subscription.

---

## 7. Module prioritization

### 6.1 Prioritization criteria

| Criterion | Weight |
|---|---|
| Low complexity (few dependencies, few screens) | High |
| Weak coupling with the Matrix SDK | High |
| Existing tests (safety net) | High |
| Pedagogical value (serves as example for subsequent modules) | Medium |
| User impact in case of regression | To minimize |

### 6.2 Proposed order

#### Wave 1 — Isolated modules, low risk (pattern validation)

| Module | Justification |
|---|---|
| **Invitation** (pilot) | Already chosen, existing tests (6 test files), bounded scope |
| **Recovery** | Small module (3 interactors), isolated, not critical |
| **App Grid** | Simple module (1 interactor), configuration only |
| **Capabilities** | 1 interactor, read-only, no side effects |
| **Preview URL** | 1 interactor, isolated |

#### Wave 2 — Medium modules, validation at larger scale

| Module | Justification |
|---|---|
| **Contacts** | 7 interactors, touches Tom server + phonebook, medium complexity |
| **User Info** | 3 interactors, important but well-defined |
| **Settings** | 2 interactors, UI impact but simple logic |
| **Reactions** | 2 interactors, Hive local, well bounded |
| **Search** | 3 interactors, cross-cutting but API-driven |

#### Wave 3 — Heavy modules, core of the app

| Module | Justification |
|---|---|
| **Room** (messaging) | The largest module (~20 interactors), core of the app, massive Matrix SDK coupling |
| **Chat / Chat List** | The most complex screens, multiple dependencies |
| **Forward** | Depends on Room |
| **Direct Chat** | Depends on Room + Contacts |

#### Wave 4 — Auth and bootstrap

| Module | Justification |
|---|---|
| **Login / Sign Up** | Critical, but migrated last as it touches app initialization |
| **Bootstrap** | Tom initialization, deep dependencies |
| **Homeserver Picker** | Tied to the auth flow |

> **Order justification**: we start with the leaves (modules with no dependencies) and work toward the core. The Room module is migrated before auth because it represents the bulk of the volume, and it is better to have the pattern stabilized before touching the initialization flow.

---

## 8. Validation criteria per migrated module

Each migrated module must pass the following checklist before merge:

### 7.1 Tests

1. **Identification of tests associated** with the migrated module: everything must pass, zero regressions
2. **Controller test additions**: validate Controllers individually via `overrideWith` / `ProviderContainer`
3. **UseCase integration tests**: migrated use cases (Future\<T\>) must have unit tests
4. **Bridge non-regression test**: if the migrated module is consumed by a legacy module, verify the bridge works

### 7.2 Architecture

1. **Zeus validation**: invocation of the AI agent to validate GUIDELINES.md compliance
2. **Manual review**: verification that the domain is pure (no Flutter, Riverpod, Matrix SDK, Dio imports)
3. **Dependency check**: no cross-imports between features

### 7.3 Runtime

1. **Manual smoke test** on the relevant flow (at minimum)
2. **No performance regression**: no excessive rebuild introduced by the state management change
3. **Verification on iOS and Android** at minimum (web if applicable to the module)

---

## 9. Risks and mitigations

### 8.1 Risk of large PRs

**Risk**: PRs too large to be reviewed properly.

**Mitigation**:
- Segment by atomic commit: one commit = one reviewable change
- Use individual commits for review rather than the global diff
- Aim for PRs of max ~500 lines of significant diff
- Break the module into sub-PRs if necessary: (1) DataSource+Repository, (2) UseCase+Service, (3) Controller+Screen

### 8.2 Risk of regressions

**Risk**: breaking existing behaviour during migration.

**Mitigation**:
- Run all existing tests for the module BEFORE AND AFTER migration
- Add missing tests BEFORE migrating (not after)
- Systematic manual smoke test
- Keep legacy code in place until the new code is validated

### 8.3 Risk of migrating the Either -> Future pattern (semantics)

**Risk**: the current `Stream<Either<Failure, Success>>` pattern encodes intermediate states (loading, partial success). Migrating to `Future<T>` loses this granularity. Some interactors emit multiple values in the stream (e.g. `GenerateInvitationLinkInteractor` emits `Loading` then `Success`).

**Mitigation**:
- Audit each interactor: does it truly emit multiple values, or is it just the pattern that forces a `yield Loading` followed by `yield Success`?
- If the interactor is truly a stream (real-time listening, polling), use `StreamNotifier` instead of `AsyncNotifier`
- If it is just request/response, `Future<T>` + `AsyncValue.guard()` handles loading natively

### 8.4 Risk of inconsistency during coexistence

**Risk**: two DI systems, two state patterns, two conventions -> developer confusion, subtle bugs at boundaries.

**Mitigation**:
- Clearly document which module is migrated and which pattern to use
- Lint rules or custom analyzer to forbid `getIt.get` in a migrated module
- `MIGRATION_STATUS.md` file updated at each merge

### 8.5 Risk of performance issues (Riverpod rebuilds)

**Risk**: Riverpod rebuilds widgets when a provider changes. A poorly scoped provider (too global) can cause cascading rebuilds.

**Mitigation**:
- Use `select` to rebuild only on the fields that change
- Prefer family providers (`family`) for parameterized data
- Profile with Flutter DevTools after each migrated module
- Do not put all state in a single monolithic provider

### 8.6 Risk of getting blocked on the Room module

**Risk**: the Room module (~20 interactors, massive Matrix SDK coupling) may become a bottleneck that blocks the migration for weeks.

**Mitigation**:
- Break Room into sub-modules: messages, members, settings, media, pinned events
- Migrate each sub-module independently
- Accept that Room may be in a mixed state for several sprints

### 8.7 Risk of Matrix SDK divergence

**Risk**: the `matrix` package evolves. The SDK types we map to domain entities may change during an upgrade, breaking Repository Impl.

**Mitigation**:
- Repository Impl are the single point of contact with SDK types: an SDK upgrade only touches this layer
- Add mapping tests (SDK model -> domain entity) in each repository

### 8.8 Risk regarding the Hive layer

**Risk**: Hive is in limited maintenance. The migration is an opportunity to reconsider local storage.

**Mitigation**:
- Do not migrate the local database choice in this effort. One problem at a time.
- Abstract behind DataSource interfaces to allow a future replacement (Isar, Drift, etc.)
- If a replacement is considered, plan it as a separate effort after the Riverpod migration

---

## 10. Estimated timeline

### Assumptions

- 1 developer part-time on the migration (~60% of time, the rest = features + bugs)
- The Invitation module (pilot) is in progress or nearly complete
- ~25 modules total (18 usecase dirs + presentation modules without a dedicated usecase)
- Modules vary enormously in size: from 1 interactor (AppGrid) to ~20 (Room)

### Estimation by wave

| Wave | Modules | Estimated effort | Calendar duration |
|---|---|---|---|
| **Phase 0**: Infrastructure | get_it/Riverpod bridge, Matrix.of abstraction | 1-2 weeks | 2-3 weeks |
| **Wave 1**: Pilots | Invitation, Recovery, AppGrid, Capabilities, PreviewURL | 1 week/module, except Invitation (already in progress) | 4-6 weeks |
| **Wave 2**: Medium modules | Contacts, UserInfo, Settings, Reactions, Search | 1-2 weeks/module | 6-10 weeks |
| **Wave 3**: Core | Room (broken down), Chat, Forward, DirectChat | 2-4 weeks/module | 10-16 weeks |
| **Wave 4**: Auth/Bootstrap | Login, SignUp, Bootstrap, HomeserverPicker | 1-2 weeks/module | 4-8 weeks |
| **Final cleanup** | Remove get_it, app_state/, bridges | 2-3 weeks | 2-3 weeks |

### Total estimate: 6-10 months

This is a long effort. A few observations:

- **It is not linear.** The first modules are slow (discovering patterns, adjusting). From wave 2 onwards, velocity increases significantly.
- **The Room module is the wall.** On its own, it may represent 30% of the effort. Breaking it into sub-modules is non-negotiable.
- **Parallelism is possible.** If a second developer joins, waves 1 and 2 can be parallelized — the modules are independent.
- **Abstracting Matrix.of(context) is the critical path.** Until this abstraction is in place, wave 3 cannot start effectively.

---

## 11. Open questions

See [03_open_questions.md](./03_open_questions.md).

---

## Appendix A — Invitation module as reference

The Invitation module serves as the pilot. Its target structure:

```
features/invitation/
  domain/
    entities/
      invitation_status.dart          # @freezed
      invitation_medium_enum.dart     # enhanced enum
    repositories/
      invitation_repository.dart      # interface
    usecases/
      generate_invitation_link.dart   # Future<InvitationLink>
      get_invitation_status.dart      # Future<InvitationStatus>
      send_invitation.dart            # Future<void>
    services/
      invitation_service.dart         # orchestration: check status, generate, send, cleanup
    exceptions/
      invitation_exception.dart       # sealed class
  data/
    datasources/
      invitation_api_datasource.dart      # interface
      invitation_local_datasource.dart    # interface (Hive)
    datasources_impl/
      invitation_api_datasource_impl.dart     # Dio / Tom server
      invitation_local_datasource_impl.dart   # Hive
    models/
      invitation_request.dart         # DTO for API
      invitation_response.dart        # DTO for API, with toEntity()
    repositories/
      invitation_repository_impl.dart # combines API + local, maps to entities
  presentation/
    controllers/
      invitation_controller.dart      # AsyncNotifier<InvitationState>
    states/
      invitation_state.dart           # @freezed sealed class
    pages/
      invitation_page.dart            # ConsumerWidget
    widgets/
      # widgets specific to the module
```

### Legacy files to delete after migration

- `lib/domain/app_state/invitation/*.dart` (6 files)
- `lib/presentation/mixins/invitation_status_mixin.dart`
- `lib/domain/usecase/invitation/*_interactor.dart` (6 files)
- Corresponding get_it registration in `get_it_initializer.dart`
