# Why migrate to Riverpod 3.0?

---

## 1. Current state of the codebase and its fragilities

The codebase relies on a mix of `StatefulWidget` + `ValueNotifier` + manual `StreamSubscription` + `GetIt` for dependency injection. There is no unified state manager. Presentation, state, and domain logic are often mixed together in the same classes. Flutter best practices (distinct Screen / ViewModel / State) are not followed.

### 1.1 A non-unified mix of state solutions

Each screen manages its state differently: some via `ValueNotifier`, others via `StreamController`, others directly via `setState`. There is no shared convention across screens.

`chat.dart` alone contains 14+ independent `ValueNotifier`s:

```dart
final ValueNotifier<bool> showScrollDownButtonNotifier = ValueNotifier(false);
final ValueNotifier<bool> showEmojiPickerNotifier = ValueNotifier(false);
final ValueNotifier<ViewEventListUIState> openingChatViewStateNotifier = ValueNotifier(ViewEventListInitial());
final ValueNotifier<bool> isBlockedUserNotifier = ValueNotifier(false);
final replyEventNotifier = ValueNotifier<Event?>(null);
final editEventNotifier = ValueNotifier<Event?>(null);
// ...
```
> `lib/pages/chat/chat.dart:294–401`

These notifiers have no declared relationship to each other, no shared lifecycle, and are disposed manually.

### 1.2 Manual StreamSubscription management

`chat.dart` declares 6 independent `StreamSubscription`s, all created and cancelled manually:

```dart
StreamSubscription? onUpdateEventStreamSubcription;
StreamSubscription? ignoredUsersStreamSub;
StreamSubscription<EventId>? _jumpToEventIdSubscription;
StreamSubscription<String>? _jumpToEventFromSearchSubscription;
StreamSubscription<CachedPresence>? cachedPresenceStreamSubscription;
StreamSubscription? keyboardVisibilitySubscription;
```
> `lib/pages/chat/chat.dart:195–3534`

Forgetting a `.cancel()` in `dispose()` is a direct source of memory leaks. The lifecycle is entirely the developer's responsibility.

### 1.3 Nested FutureBuilder / StreamBuilder in the view layer

The chat view wraps the entire `Scaffold` in a `StreamBuilder` which is itself nested inside a `FutureBuilder`:

```dart
StreamBuilder(
  stream: controller.room!.onUpdate.stream.rateLimit(Duration(seconds: 1)),
  builder: (context, snapshot) => FutureBuilder(
    future: controller.loadTimelineFuture,
    builder: (BuildContext context, snapshot) {
      return Scaffold(...); // the entire Scaffold rebuilds on every update
    },
  ),
)
```
> `lib/pages/chat/chat_view.dart:106–112`

The `FutureBuilder` recreates the `Future` on every parent rebuild if `loadTimelineFuture` is not properly memoized. The entire view subtree is potentially rebuilt on every Matrix event.

### 1.4 Inconsistent error handling across layers

The domain layer uses `Either<Failure, Success>` with `.fold()`. The presentation layer does not apply this pattern consistently: some screens use `.fold()`, others use `snapshot.error`, others use a direct snackbar without capturing state.

Example in `unblock_user_mixin.dart`: a single operation generates 4 nested `if (failure is ...)` branches inside a `.listen()`:

```dart
unblockUserSubscription = unblockUserInteractor
    .execute(client: client, userId: userID)
    .listen((event) => event.fold(
      (failure) {
        if (failure is UnblockUserFailure) { ... }
        if (failure is NoPermissionForUnblockFailure) { ... }
        if (failure is NotValidMxidUnblockFailure) { ... }
        if (failure is NotInTheIgnoreListFailure) { ... }
      },
      (success) {
        if (success is UnblockUserLoading) { ... }
        if (success is UnblockUserSuccess) { ... }
      },
    ));
```
> `lib/presentation/mixins/unblock_user_mixin.dart:33–82`

### 1.5 Strong coupling with the Matrix SDK in presentation

220+ files in `lib/pages/` directly import `package:matrix/matrix.dart`. The types `Room`, `Client`, `Timeline`, `Event` are manipulated directly in presentation controllers, without going through domain models.

`ChatController extends State<Chat>` directly declares:

```dart
Room? room;
Client? sendingClient;
Timeline? timeline;
MatrixState? matrix;
```
> `lib/pages/chat/chat.dart:200–207`

There is no abstraction layer between the SDK and the presentation.

### 1.6 Either pattern partially applied

`Either<Failure, Success>` is correctly used in the interactors:

```dart
// lib/domain/usecase/room/unblock_user_interactor.dart
Stream<Either<Failure, Success>> execute({...}) async* {
  yield Right(UnblockUserLoading());
  // ...
  yield Left(UnblockUserFailure(exception: error));
}
```

But this pattern is not propagated throughout the presentation. The `dartz` dependency adds functional complexity (`.fold()`, `Right`, `Left`) without uniform benefit across the entire codebase.

---

## 2. Why these fragilities block scalability

### 2.1 Cognitive load and regression risk

Each screen has its own conventions. A developer touching `chat.dart` must simultaneously understand 6 subscriptions, 14 notifiers, multiple mixins, and direct calls to the Matrix SDK. The file is 2000+ lines long. Any modification carries a high risk of regression.

### 2.2 Limited testability of controllers

`ChatController extends State<Chat>`: it is impossible to instantiate this controller without the Flutter widget tree. Testing the business logic for sending a message, managing scroll, or handling a reaction requires a full widget test with context, whereas a simple unit test would suffice.

### 2.3 No explicit lifecycle model

Nothing in the code formally expresses that a state should survive navigation, be shared between two screens, or be released when a room is closed. These decisions are scattered across `dispose()` and `initState()` without centralized logic.

---

## 3. What Riverpod 3.0 concretely brings

### 3.1 Unified state management and dependency injection

GetIt and `ValueNotifier`s are replaced by Riverpod alone. A provider is both an injectable dependency and an observable state container. No more need for two parallel systems — GetIt is entirely removed.

```dart
// Before: getIt.get<SendMessageService>() in the controller
// After: declarative DI via ref
@riverpod
class ChatController extends _$ChatController {
  @override
  AsyncValue<ChatState> build(String roomId) {
    // ref.watch in build() — automatic subscription, rebuild if the service changes
    final service = ref.watch(sendMessageServiceProvider);
    // The service orchestrates the use cases (SendMessageInteractor, etc.)
    return ...;
  }

  Future<void> send(String text) async {
    // ref.read in a method — one-time read
    await ref.read(sendMessageServiceProvider).send(text);
  }
}
```

### 3.2 Dependency graph with automatic lifecycle

A provider parameterized by `roomId` is instantiated on demand and automatically released when no widget is listening to it anymore (`autoDispose` enabled by default with `@riverpod`). The `StreamSubscription`s tied to a room are no longer managed manually.

```dart
@riverpod
Stream<RoomState> roomStream(Ref ref, String roomId) {
  final subscription = ...;
  ref.onDispose(() => subscription.cancel()); // declarative lifecycle
  // ...
}
```

> Riverpod docs — passing arguments (formerly `family`): https://riverpod.dev/docs/essentials/passing_args

### 3.3 AsyncNotifier as the answer to the loading/error/data problem

`AsyncNotifier` replaces the `StreamBuilder → FutureBuilder` pattern. Async state is encoded in `AsyncValue<T>` and rendered via `.when()` — a single source of truth for loading, error, and data:

```dart
ref.watch(timelineProvider(roomId)).when(
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => ErrorWidget(e),
  data: (timeline) => TimelineView(timeline),
)
```

The view is only rebuilt when the provider's state changes, not on every parent rebuild.

### 3.4 Testability via ProviderContainer isolated from the widget tree

A `Notifier` can be tested without a Flutter harness. Dependencies are overridden in the `ProviderContainer`:

```dart
final container = ProviderContainer(
  overrides: [matrixClientProvider.overrideWithValue(mockClient)],
);
final notifier = container.read(chatNotifierProvider('roomId').notifier);
// testing pure logic, without a widget
```

### 3.5 Fine-grained rebuild granularity with `select`

On a list of 300 rooms, only what has actually changed is rebuilt:

```dart
final unreadCount = ref.watch(
  roomProvider(roomId).select((s) => s.unreadCount),
);
```

### 3.6 Code generation and enforced structure via `@riverpod`

`@riverpod` + `build_runner` generates boilerplate and enforces a uniform structure. All providers have the same shape, regardless of which team member writes them.

---

## 4. Why not the alternatives

### 4.1 BLoC: does not replace GetIt and does not unify DI

BLoC manages presentation state but does not replace dependency injection — GetIt would still be necessary. Riverpod covers both with a single mechanism. Furthermore, BLoC shines for complex event sequences (pipelines, undo/redo); for our use case — action → state → UI — it is disproportionate. The verbosity (Event, State, Bloc, BlocProvider, BlocBuilder) burdens the code without benefit.

### 4.2 setState alone: not viable at this scale

`setState` does not allow state sharing between screens, provides no explicit lifecycle, and forces logic into the widget tree. Not feasible for an app of this complexity.

### 4.3 Keeping the existing code: accumulating debt

The current mix works but generates regular bugs (subscription leaks, inconsistent state between screens, difficulty writing tests). The debt increases with every feature added to `ChatController`.

---

## 5. What we are dropping and why

### 5.1 Either / dartz: dropped

`Either<Failure, Success>` is dropped. Use cases now return `Future<T>` and throw typed exceptions. Riverpod's `AsyncValue<T>` natively handles loading/error/data states in the presentation layer — `Either` becomes redundant and `dartz` is removed from the project.

This decision is tied to the migration: `AsyncController`s directly consume `Future<T>`s, which simplifies the bridge between use cases and presentation.

```dart
// Before
Stream<Either<Failure, Success>> execute({...}) async* { ... }

// After
Future<void> unblockUser(String userId) async {
  // throws UnblockUserException on failure
}
```

### 5.2 Direct FutureBuilder / StreamBuilder in views

Replaced by `AsyncNotifier` and `ref.watch`. Views no longer manage async logic directly.

---

## 6. Riverpod limitations to anticipate

### 6.1 Non-trivial mental model (`ref.watch` vs `ref.read` vs `ref.listen`)

`ref.read` inside a `build()` is a silent anti-pattern. `ref.watch` must not be called conditionally. These mistakes do not always generate an immediate exception. **A clear team convention and careful code review are essential.**

### 6.2 `build_runner`: accidental complexity on a large project

On a project with 200+ providers, `build_runner` can be slow and generation errors can be opaque. Plan clear generation scripts and a CI that verifies the generated code is up to date.

### 6.3 No transactions between providers

A Matrix event may need to simultaneously update the unread counter, the room list, and the state of the open room. Riverpod does not guarantee atomicity between providers. Inconsistent intermediate states are possible — this must be explicitly designed via an orchestration provider.

### 6.4 Matrix SDK bridge (high-frequency stream) must be explicitly designed

The Matrix SDK potentially emits thousands of events during an initial sync. A `StreamProvider` without debouncing will cause cascading rebuilds. A batching layer between the SDK and providers is necessary — this is not provided by Riverpod.

---

## 7. Migration strategy

See [01_migration_plan.md](./01_migration_plan.md) for the detailed plan: phases, layer order, GetIt/Riverpod coexistence, team conventions, and validation criteria.
