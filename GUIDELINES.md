# Twake Chat — Flutter/Dart Guidelines

> Living document, open to proposals and changes. Goal: improve code quality and follow the best practices and recommendations of the Flutter/Dart ecosystem.

---

## Table of Contents

1. [Fundamental Principles](#1-fundamental-principles)
2. [Architecture](#2-architecture)
3. [Naming Conventions](#3-naming-conventions)
4. [Dart Code Style](#4-dart-code-style)
5. [Navigation](#5-navigation)
6. [Tests](#6-tests)
7. [Documentation](#7-documentation)
8. [Git & Code Quality](#8-git--code-quality)
9. [Legacy Management](#9-legacy-management)
10. [Appendix — analysis_options.yaml](#10-appendix--analysis_optionsyaml)

---

## 1. Fundamental Principles

### 1.1 SOLID

SOLID principles are guidelines, not dogmas. The goal is readable, testable, and maintainable code — not a mechanical application of each rule in every situation.

#### S — Single Responsibility Principle

**One class = one responsibility.** A class that does several things is hard to test, evolve, and understand. If you cannot describe what a class does in one short sentence, it's a signal.

❌ **BAD** — `UserScreen` handles authentication, database, and UI:

```dart
class UserScreen extends StatefulWidget {
  void login() { /* direct API call in the view */ }
  void saveToDatabase(User user) { /* direct DB access */ }

  @override
  Widget build(BuildContext context) { /* UI + business logic mixed */ }
}
```

✅ **GOOD** — each class has a single responsibility:

```dart
class LoginUseCase {
  Future<AuthEntity> execute(LoginParams params) { ... }
}
class UserRepositoryImpl implements UserRepository { ... }
class AuthController extends Notifier<AuthState> { /* UI logic only */ }
class LoginScreen extends ConsumerWidget { /* UI only */ }
```

---

#### O — Open/Closed Principle

**Open for extension, closed for modification.** Adding new behavior must not require modifying existing code. We extend via new implementations.

❌ **BAD** — every new notification type forces a modification:

```dart
class NotificationService {
  void send(String type, String message) {
    if (type == 'push') { ... }
    else if (type == 'email') { ... } // edit here for every new type
  }
}
```

✅ **GOOD** — a new notification = a new class, no modification:

```dart
abstract class NotificationSender {
  Future<void> send(String message);
}
class PushNotificationSender implements NotificationSender { ... }
class EmailNotificationSender implements NotificationSender { ... }
```

---

#### L — Liskov Substitution Principle

**A subtype must be substitutable for its base type without altering the expected behavior.** In practice: any implementation of an interface must honor its contract — no method that throws `UnimplementedError`, no behavior that surprises the consumer.

The most useful application of LSP in our context is not multiplying segmented interfaces, but the **consistency of implementations**: a well-defined interface, with implementations that fully respect it.

❌ **BAD** — the implementation silently violates the contract:

```dart
// The interface promises save(), but the implementation throws at runtime
class ReadOnlyUserRepository extends UserRepository {
  @override
  Future<void> save(User user) => throw UnimplementedError();
}
```

✅ **GOOD** — one interface per aggregate, well-scoped, always honored:

```dart
// An interface consistent with the real needs of the domain
abstract class UserRepository {
  Future<UserEntity?> findById(String id);
  Future<List<UserEntity>> findByIds(List<String> ids);
  Future<void> save(UserEntity user);
  Stream<UserEntity?> watchUser(String userId);
}

// The implementation implements the full contract — no cheating
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._dataSource);
  final UserDataSource _dataSource;

  @override Future<UserEntity?> findById(String id) => ...;
  @override Future<List<UserEntity>> findByIds(List<String> ids) => ...;
  @override Future<void> save(UserEntity user) => ...;
  @override Stream<UserEntity?> watchUser(String userId) => ...;
}
```

---

#### I — Interface Segregation Principle

**Multiple specific interfaces are better than a single general interface.** Don't force a class to implement methods it doesn't need.

> **Relationship with LSP**: these two principles operate at different levels. LSP applies to **domain repositories** — one interface per aggregate, always fully implemented. ISP applies to **SDK/client interfaces** in the data layer — a datasource only implements the portion of the client it needs. The two are consistent: the domain is stable and homogeneous, the data layer is granular and segmented.

❌ **BAD** — interface too broad, every implementation must provide everything:

```dart
abstract class MatrixClient {
  Future<void> login();
  Future<void> sendMessage(String roomId, String body);
  Future<void> uploadFile(Uint8List bytes);
  Future<void> createRoom(String name);
  Future<void> joinRoom(String roomId);
}
```

✅ **GOOD** — focused interfaces, implementations that only carry what they need:

```dart
abstract class AuthClient {
  Future<void> login(String userId, String password);
}
abstract class MessagingClient {
  Future<void> sendMessage(String roomId, String body);
}
abstract class RoomClient {
  Future<void> joinRoom(String roomId);
}

// A datasource only implements the interface it covers
class MatrixMessagingDataSource implements MessagingClient {
  MatrixMessagingDataSource(this._client);
  final Client _client;

  @override
  Future<void> sendMessage(String roomId, String body) =>
      _client.getRoomById(roomId)!.sendTextEvent(body);
}
```

---

#### D — Dependency Inversion Principle

**Depend on abstractions, not implementations.** High-level layers (use cases, controllers) must not know the implementation details of low-level layers (Matrix SDK, HTTP, DB).

The dependency chain is: `DataSource → Repository → UseCase → Controller`. Each link depends on the interface of the previous link, not on its implementation.

❌ **BAD** — the controller depends directly on the Matrix SDK:

```dart
class RoomController extends Notifier<RoomState> {
  final _matrix = MatrixSDK(); // tight coupling, impossible to test
  Future<void> loadMessages() => _matrix.getMessages();
}
```

✅ **GOOD** — each layer depends on an abstraction:

```dart
// Domain — pure contract
abstract class RoomRepository {
  Stream<List<MessageEntity>> watchMessages(String roomId);
}

// Data — concrete implementation of the contract
class RoomRepositoryImpl implements RoomRepository {
  RoomRepositoryImpl(this._dataSource);
  final RoomDataSource _dataSource; // also depends on an abstraction

  @override
  Stream<List<MessageEntity>> watchMessages(String roomId) =>
      _dataSource.watchMessages(roomId).map(
        (models) => models.map((m) => m.toEntity()).toList(),
      );
}

// Domain — use case uses the interface, not the impl
class WatchRoomMessagesUseCase {
  WatchRoomMessagesUseCase(this._repository);
  final RoomRepository _repository;

  Stream<List<MessageEntity>> execute(String roomId) =>
      _repository.watchMessages(roomId);
}

// Presentation — controller uses the use case
class RoomController extends Notifier<RoomState> {
  RoomController(this._watchMessages);
  final WatchRoomMessagesUseCase _watchMessages;
}
```

---

### 1.2 KISS — Keep It Simple

**Don't over-engineer.** Complexity must be justified by a real need, not by anticipating a hypothetical one. Every abstraction layer has a cost in readability and maintenance.

❌ **BAD** — building a custom system for something Riverpod already handles natively:

```dart
// Useless: custom StateManager that reinvents AsyncNotifier
class StateManager<T> {
  final _stateController = StreamController<StateWrapper<T>>.broadcast();
  Stream<StateWrapper<T>> get stream => _stateController.stream;
  void setState(T data) => _stateController.add(StateWrapper.data(data));
  void setError(Object e) => _stateController.add(StateWrapper.error(e));
  void setLoading() => _stateController.add(StateWrapper.loading());
  void dispose() => _stateController.close();
}
```

✅ **GOOD** — use Riverpod's `AsyncNotifier`, designed for exactly this:

```dart
@riverpod
class RoomController extends _$RoomController {
  @override
  FutureOr<RoomState> build(String roomId) => _fetchInitialState(roomId);

  Future<void> sendMessage(String body) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _useCase.sendMessage(body));
  }
}
```

---

### 1.3 DRY — Don't Repeat Yourself

**Don't duplicate logic.** Two places doing the same thing = two places to maintain, two potential sources of divergence. Factoring must remain justified, though: don't abstract prematurely something repeated only twice.

❌ **BAD** — `l10n` and `displayName` repeated everywhere:

```dart
// In 5 different files
Text(AppLocalizations.of(context)!.hello)
Text(AppLocalizations.of(context)!.cancel)

// In 3 different classes
final name = '${user.firstName} ${user.lastName}'.trim();
```

✅ **GOOD** — extensions and services centralize the behavior:

```dart
// BuildContext extension — once
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
}

// Usage everywhere
Text(context.l10n.hello)

// UserService — centralizes User manipulation
class UserService {
  UserService(this._session);
  final SessionEntity _session;

  String getDisplayName(UserEntity user) =>
      '${user.firstName} ${user.lastName}'.trim();

  bool isCurrentUser(String userId) => _session.userId == userId;
}
```

---

## 2. Architecture

### 2.1 Clean Architecture — Feature First

The architecture follows the **Clean Architecture** principle organized as **Feature First**: each feature is a self-contained module containing its three layers. The `core/` folder only contains what is shared between multiple features.

```
lib/
├── core/                         # Pure infrastructure — no domain entities
│   ├── errors/                   # AppException, NetworkException, AuthException
│   ├── network/                  # DioClient, MatrixClient, interceptors
│   ├── theme/                    # AppTheme, ColorTokens, TextStyles
│   ├── utils/                    # DateFormatter, EmailValidator, StringUtils
│   ├── extensions/               # BuildContextX, StringX, DateTimeX
│   └── services/                 # LoggingService, AnalyticsService, ConnectivityService
│
├── shared/                       # Domain components shared between multiple features
│   ├── domain/
│   │   ├── entities/             # UserEntity, MediaEntity (if multi-feature)
│   │   ├── repositories/         # UserRepository (interface), MediaRepository
│   │   └── services/             # PresenceService, PushNotificationService  ← know about entities
│   └── data/
│       ├── models/               # UserRemoteModel, MediaRemoteModel
│       └── repositories/         # UserRepositoryImpl, MediaRepositoryImpl
│
├── features/
│   ├── auth/
│   ├── user_profile/
│   ├── workspaces/
│   └── messaging/
│       ├── data/
│       │   ├── datasources/      # MatrixRoomDataSource, LocalRoomDataSource
│       │   ├── models/           # MessageRemoteModel, RoomRemoteModel
│       │   └── repositories/     # RoomRepositoryImpl, MessageRepositoryImpl
│       │
│       ├── domain/
│       │   ├── entities/         # MessageEntity, RoomEntity, MemberEntity
│       │   ├── enums/            # MessageType, RoomType, MemberRole
│       │   ├── repositories/     # RoomRepository (interface), MessageRepository
│       │   ├── usecases/         # SendMessageUseCase, WatchRoomUseCase
│       │   ├── services/         # TypingService (shared between RoomController + ThreadController)
│       │   └── exceptions/       # MessagingException, RoomNotFoundException
│       │
│       └── presentation/
│           ├── screens/          # RoomScreen, RoomListScreen
│           ├── controllers/      # RoomController, RoomListController
│           ├── states/           # RoomState, RoomListState
│           └── widgets/          # MessageBubble, MessageInput, RoomAvatar
│
└── main.dart
```

> **Decision rule — where do state/logic go?**
> - Trivial logic, **a single controller** → in the controller
> - **Complex or independently testable** logic, even with a single consumer → service
> - Service **specific to one feature** → `features/X/domain/services/`
> - Service **shared between multiple features** → `shared/domain/services/`
> - Service **without domain entities** (logging, analytics, connectivity) → `core/services/`
>
> Never cross-import between features (`messaging/` never imports from `user_profile/`).
>

---

### 2.2 Dependency Graph Between Layers

Dependencies **always point toward the domain**. The domain knows no one. The data layer implements the contracts of the domain.

```
┌────────────────────────────────────────────────────────────────┐
│                        PRESENTATION                            │
│        Screens • Controllers (Riverpod) • States • Widgets     │
└────────────────────────────────┬───────────────────────────────┘
                                 │ depends on
                                 ▼
┌────────────────────────────────────────────────────────────────┐
│                     DOMAIN  (feature + shared)                 │
│      Entities • Enums • Use Cases • Repository Interfaces      │
│                    Services • Exceptions                        │
└────────────────────────────────▲───────────────────────────────┘
                                 │ implements the interfaces
                                 │
┌────────────────────────────────┴───────────────────────────────┐
│                    DATA  (feature + shared)                    │
│     Repository Impl • DataSources • DTOs/Models • Endpoints    │
└─────────────────────────────────┬──────────────────────────────┘
                                  │ uses
                                  ▼
┌────────────────────────────────────────────────────────────────┐
│                           CORE                                 │
│       Network • Theme • Utils • Extensions • Infra Services    │
└────────────────────────────────────────────────────────────────┘

Call flow: Screen → Controller → Service → UseCase → Repository → DataSource
Data flow: DataSource → Model.toEntity() → Entity → State → Widget
Cross-cutting dependencies: shared/ ← features/ (never feature/ ← feature/)
```

> **Absolute rule**: no `import` of `data/` or `presentation/` inside `domain/`. The domain is pure Dart — no Flutter, no Matrix SDK, no Riverpod.

---

### 2.3 The Domain Layer

The domain is the heart of the application. It contains business rules, contracts, and entities. It knows **no infrastructure details**: no Riverpod, no Flutter, no Matrix SDK, no database.

#### 2.3.1 Business Models (Entities)

Entities represent the business concepts of the application. They are **immutable**: you never mutate an entity, you create a new version via `copyWith`. Immutability guarantees state predictability and simplifies debugging.

Use `@freezed` (the `freezed` package) rather than `Equatable`. `@freezed` automatically generates `==`, `hashCode`, `copyWith`, `toString`, and union types — without the risk of forgetting a field in `props`, which was the main source of bugs with Equatable.

❌ **BAD** — Equatable: the `senderId` field forgotten in `props` silently makes equality incorrect:

```dart
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.body,
    required this.senderId,
  });
  final String id;
  final String body;
  final String senderId;

  @override
  List<Object?> get props => [id, body]; // senderId forgotten = silent bug
}
```

✅ **GOOD** — `@freezed`: all fields are included, `copyWith` generated, union types possible:

```dart
@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String id,
    required String body,
    required String senderId,
    DateTime? editedAt,
    @Default(false) bool isDeleted,
  }) = _MessageEntity;
}

// Immutable usage
final updated = message.copyWith(editedAt: DateTime.now());
```

> **Note**: `@freezed` also supports **sealed classes** for states:
> ```dart
> @freezed
> sealed class AuthState with _$AuthState {
>   const factory AuthState.idle() = _Idle;
>   const factory AuthState.loading() = _Loading;
>   const factory AuthState.authenticated(UserEntity user) = _Authenticated;
>   const factory AuthState.error(String message) = _Error;
> }
> ```
>
> Source: https://pub.dev/packages/freezed

---

#### 2.3.2 Enums

Use **enhanced enums** (Dart 2.17+) rather than string constants or simple enums. Rich enums centralize associated values, conversion methods, and derived properties — and the compiler checks `switch` exhaustiveness.

❌ **BAD** — scattered string comparisons, possible typos at runtime:

```dart
if (room.type == 'direct') { ... }
if (membership == 'invite') { ... }
const String statusOnline = 'online'; // orphan constant
```

✅ **GOOD** — rich enum with Matrix values and methods:

```dart
enum RoomType {
  direct('m.direct'),
  group(''),
  space('m.space');

  const RoomType(this.matrixType);
  final String matrixType;

  bool get isDirect => this == RoomType.direct;

  static RoomType fromMatrix(String? type) => switch (type) {
    'm.direct' => RoomType.direct,
    'm.space'  => RoomType.space,
    _          => RoomType.group,
  };
}
```

> An exhaustive `switch` on an enum guarantees that every added value forces the compiler to flag uncovered cases. Source: https://dart.dev/language/branches#exhaustiveness-checking

---

#### 2.3.3 Repository (Interfaces)

Repository interfaces define the **contract** between the domain and the data layer. They contain no implementation logic — only signatures. Use cases depend on these interfaces, not on the implementations.

```dart
/// Contract for accessing messaging data.
/// Implemented by [RoomRepositoryImpl] in the data layer.
abstract class RoomRepository {
  /// Listens in real time to the messages of a room.
  Stream<List<MessageEntity>> watchMessages(String roomId);

  /// Fetches a page of historical messages.
  Future<List<MessageEntity>> fetchMessages(
    String roomId, {
    String? from,
    int limit = 20,
  });

  /// Sends a text message.
  Future<MessageEntity> sendMessage(String roomId, String body);
}
```

---

#### 2.3.4 Use Cases (Interactors)

Use cases encapsulate **one and only one business action**. They use repository interfaces, know no data-layer details, and are the only entry points into business logic for the presentation layer.

**Proposal: `Future<T>` + typed exceptions + `AsyncValue.guard`.** Use cases return `Future<T>` and throw typed exceptions. The Riverpod controller uses `AsyncValue.guard()`, which natively handles `loading/data/error` states. No `Either`, no `ResultState` — these are wrappers that duplicate what `AsyncValue` already does.


**Proposal: always go through a use case.** A uniform rule — even for simple operations — reduces cognitive load, prevents routing errors, and guarantees that every business action has a testable entry point. Mixing direct repository calls and use case calls in controllers creates an inconsistency that is hard to maintain.


```dart
// Base interface — standardizes the execute() contract
abstract class UseCase<T, P> {
  Future<T> execute(P params);
}

abstract class UseCaseNoParams<T> {
  Future<T> execute();
}

// Use case with real orchestration: validation + repository call
class SendMessageUseCase implements UseCase<MessageEntity, SendMessageParams> {
  SendMessageUseCase(this._repository, this._encryptionService);
  final RoomRepository _repository;
  final EncryptionService _encryptionService;

  @override
  Future<MessageEntity> execute(SendMessageParams params) async {
    if (params.body.trim().isEmpty) throw InvalidMessageException();
    final body = await _encryptionService.encrypt(params.body.trim(), params.roomId);
    return _repository.sendMessage(params.roomId, body);
  }
}

// Simple use case — thin wrapper, but uniform and testable
class GetRoomUseCase implements UseCase<RoomEntity?, String> {
  GetRoomUseCase(this._repository);
  final RoomRepository _repository;

  @override
  Future<RoomEntity?> execute(String roomId) => _repository.findById(roomId);
}

@freezed
abstract class SendMessageParams with _$SendMessageParams {
  const factory SendMessageParams({
    required String roomId,
    required String body,
  }) = _SendMessageParams;
}
```

**Error handling** is done at the controller level via `AsyncValue.guard`, which captures thrown exceptions and wraps them in `AsyncValue.error` — the UI renders them via `.when(error: ...)`.

**Timeouts** are a separate concern — `AsyncValue.guard` does not impose a deadline by itself. Configure the timeout at the layer that owns the deadline:

| Concern | Layer | How |
|---|---|---|
| Network transport (connect, receive) | DataSource | `Dio(BaseOptions(connectTimeout: ..., receiveTimeout: ...))` for REST ; `timeout:` parameter on Matrix SDK methods (e.g. `setTyping(timeout: 30000)`) |
| Business deadline ("must succeed within 10s") | UseCase | `.timeout(Duration(seconds: 10))` chained on the repository call |
| UX deadline ("don't stay in loading more than 5s") | Controller | `.timeout(...)` before passing to `AsyncValue.guard` |

The resulting `TimeoutException` is captured by `AsyncValue.guard` like any other exception — a single error-handling code path regardless of the timeout origin:

```dart
Future<void> sendMessage(String body) async {
  state = const AsyncLoading();
  state = await AsyncValue.guard(
    () => _sendMessageUseCase
        .execute(SendMessageParams(roomId: roomId, body: body))
        .timeout(const Duration(seconds: 10)), // UX-level deadline
  );
}
```

---

#### 2.3.5 Stateful Business Services

Services are responsible for **centralizing and maintaining state related to an entity or a cross-cutting behavior**. They can be stateful (a typing, presence, or sync service) and expose streams so that consumer classes can react to changes.

❌ **BAD** — typing state is handled locally in each screen, duplicated:

```dart
class RoomScreen extends ConsumerWidget {
  bool _isTyping = false;
  Timer? _typingTimer;

  void _onTextChanged(String text) {
    _isTyping = true;
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () => _isTyping = false);
    // duplicated logic in ChatScreen, ThreadScreen...
  }
}
```

✅ **GOOD** — the service maintains its own state, the controller exposes it and handles mutations:

```dart
// Domain — contract of the stateful service
abstract class TypingService {
  /// Stream of userIds currently typing in a room.
  Stream<List<String>> watchTypingUsers(String roomId);
  /// Notifies the server that the user is typing (or stops).
  Future<void> setTyping(String roomId, {required bool isTyping});
}

// Data — stateful implementation: maintains the state of Matrix typing events
class MatrixTypingService implements TypingService {
  MatrixTypingService(this._client);
  final Client _client;

  @override
  Stream<List<String>> watchTypingUsers(String roomId) =>
      _client.onRoomState.stream
          .where((event) => event.roomId == roomId && event.type == 'm.typing')
          .map((event) => List<String>.from(event.content['user_ids'] as List));

  @override
  Future<void> setTyping(String roomId, {required bool isTyping}) =>
      _client.getRoomById(roomId)!.setTyping(isTyping, timeout: 30000);
}

// Presentation — StreamNotifier controller: exposes state AND handles mutations
// The screen always goes through the controller, never directly through the service
@riverpod
class TypingController extends _$TypingController {
  Timer? _debounce;

  @override
  Stream<List<String>> build(String roomId) {
    ref.onDispose(() => _debounce?.cancel());
    // The controller delegates to the service for the stream
    return ref.read(typingServiceProvider).watchTypingUsers(roomId);
  }

  void onTextChanged(String text) {
    _debounce?.cancel();
    final service = ref.read(typingServiceProvider);
    unawaited(service.setTyping(roomId, isTyping: true));
    _debounce = Timer(const Duration(seconds: 3), () {
      unawaited(service.setTyping(roomId, isTyping: false));
    });
  }
}

// Screen — observes via the controller, never directly via the service
class TypingIndicator extends ConsumerWidget {
  const TypingIndicator({required this.roomId, super.key});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typingUsers = ref.watch(typingControllerProvider(roomId));
    return typingUsers.when(
      data: (users) => _TypingText(users),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

> **Rule**: the screen must never import or directly observe a service. The controller is the single entry point of the presentation layer — it exposes state (via its `build`) and mutations (via its methods). `StreamNotifier` is the right tool when a controller exposes a reactive stream while also having mutation methods.

---

#### 2.3.6 Exceptions

Typed exceptions allow the presentation layer to **react precisely** to different error cases without inspecting string messages. Use `sealed class` to group exceptions by functional domain.

```dart
sealed class MessagingException implements Exception {
  const MessagingException(this.message, {this.cause});
  final String message;
  final Object? cause;
}

class RoomNotFoundException extends MessagingException {
  const RoomNotFoundException(String roomId)
      : super('Room $roomId not found');
}

class InvalidMessageException extends MessagingException {
  const InvalidMessageException()
      : super('Message body cannot be empty');
}

class SendMessageException extends MessagingException {
  const SendMessageException({required Object super.cause})
      : super('Failed to send message');
}
```

In the controller:

```dart
// AsyncValue.guard captures the exception and wraps it in AsyncError
state = await AsyncValue.guard(() => _useCase.execute(params));

// In the widget, we can switch on the exception type
ref.listen(roomControllerProvider, (_, next) {
  next.whenOrNull(
    error: (error, _) => switch (error) {
      RoomNotFoundException() => showRoomNotFoundDialog(context),
      SendMessageException() => showRetrySnackbar(context),
      _ => showGenericError(context),
    },
  );
});
```

---

### 2.4 The Data Layer

The data layer **implements** the interfaces defined in the domain. It translates external data (JSON, Matrix SDK, local DB) into domain entities, and vice versa.

#### 2.4.1 Repository (Implementations)

Repository implementations bridge domain interfaces and datasources. They orchestrate calls to datasources, convert models into entities via `toEntity()`, and — **only when no external source already handles persistence** — manage a local cache.

**Cache rule**: see §2.4.5 *Source of truth per domain*. In short:
- **Matrix domain** (timeline, events, rooms, presence): **stateless** Repository, pure SDK → entities adapter. The SDK and its native DB are the source of truth; adding a Hive cache recreates a competing SSOT.
- **Twake REST domain** (invitations, contacts, TOM): legitimate local Hive cache.

✅ **Matrix example — stateless, pure adapter**:

```dart
class MatrixRoomRepositoryImpl implements RoomRepository {
  MatrixRoomRepositoryImpl(this._remoteDataSource);

  final RoomRemoteDataSource _remoteDataSource;

  @override
  Stream<List<MessageEntity>> watchMessages(String roomId) =>
      _remoteDataSource.watchMessages(roomId).map(
        (models) => models.map((m) => m.toEntity()).toList(),
      );

  @override
  Future<List<MessageEntity>> fetchMessages(
    String roomId, {
    String? from,
    int limit = 20,
  }) async {
    final models = await _remoteDataSource.fetchMessages(
      roomId,
      from: from,
      limit: limit,
    );
    // No cacheMessages: the Matrix SDK already persists events in its native DB.
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<MessageEntity> sendMessage(String roomId, String body) async {
    // The write goes through the SDK only; the watchMessages stream will emit the event
    // (first as a local echo `status: sending`, then `synced` after the server ACK).
    final model = await _remoteDataSource.sendMessage(roomId, body);
    return model.toEntity();
  }
}
```

✅ **Twake REST example — legitimate local cache**:

```dart
class InvitationRepositoryImpl implements InvitationRepository {
  InvitationRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final InvitationRemoteDataSource _remoteDataSource;
  final InvitationLocalDataSource _localDataSource;

  @override
  Future<List<InvitationEntity>> fetchInvitations({bool force = false}) async {
    if (!force) {
      final cached = await _localDataSource.getInvitations();
      if (cached.isNotEmpty) return cached.map((m) => m.toEntity()).toList();
    }
    final models = await _remoteDataSource.fetchInvitations();
    await _localDataSource.cacheInvitations(models); // only local persistent source
    return models.map((m) => m.toEntity()).toList();
  }
}
```

---

#### 2.4.2 DataSources (Abstract and implementations)

Datasources are the **contact points** with external data sources. They have an abstract interface in the data layer (not in the domain), and one or more concrete implementations. This allows switching sources (Matrix → another SDK, REST → WebSocket) without touching the domain.

**Abstract interface:**

```dart
abstract class RoomRemoteDataSource {
  Stream<List<MessageRemoteModel>> watchMessages(String roomId);
  Future<List<MessageRemoteModel>> fetchMessages(
    String roomId, {
    String? from,
    int limit = 20,
  });
  Future<MessageRemoteModel> sendMessage(String roomId, String body);
}
```

**Matrix SDK implementation:**

```dart
class MatrixRoomDataSource implements RoomRemoteDataSource {
  MatrixRoomDataSource(this._client);
  final Client _client;

  @override
  Stream<List<MessageRemoteModel>> watchMessages(String roomId) {
    final room = _client.getRoomById(roomId);
    return room!.onUpdate.stream.map(
      (_) => room.timeline.events
          .map(MessageRemoteModel.fromMatrixEvent)
          .toList(),
    );
  }

  @override
  Future<MessageRemoteModel> sendMessage(String roomId, String body) async {
    final room = _client.getRoomById(roomId)!;
    final eventId = await room.sendTextEvent(body);
    return MessageRemoteModel(id: eventId, body: body, senderId: _client.userID!);
  }
}
```

**REST implementation (Retrofit) — for non-Matrix Twake APIs:**

```dart
abstract class RoomHttpDataSource implements RoomRemoteDataSource {
  // inherits the interface, implemented via Retrofit (see §2.4.4)
}
```

---

#### 2.4.3 DTOs / Models

Models (DTOs) represent the data as it exists in the external source — JSON, Matrix event, local DB. They use `@freezed` for serialization and expose a `toEntity()` method to convert to the domain.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.remote_model.freezed.dart';
part 'message.remote_model.g.dart';

@freezed
abstract class MessageRemoteModel with _$MessageRemoteModel {
  const factory MessageRemoteModel({
    @JsonKey(name: 'event_id') required String id,
    required String body,
    @JsonKey(name: 'sender') required String senderId,
    @JsonKey(name: 'origin_server_ts') required int timestampMs,
    String? editedEventId,
  }) = _MessageRemoteModel;

  factory MessageRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$MessageRemoteModelFromJson(json);

  factory MessageRemoteModel.fromMatrixEvent(Event event) => MessageRemoteModel(
    id: event.eventId,
    body: event.body,
    senderId: event.senderId,
    timestampMs: event.originServerTs.millisecondsSinceEpoch,
  );
}

// Mapping extension — in the model file, not in the entity
extension MessageRemoteModelX on MessageRemoteModel {
  MessageEntity toEntity() => MessageEntity(
    id: id,
    body: body,
    senderId: senderId,
    sentAt: DateTime.fromMillisecondsSinceEpoch(timestampMs),
    isEdited: editedEventId != null,
  );
}
```

---

#### 2.4.4 Endpoints (Retrofit)

For Twake REST APIs, Retrofit generates the full HTTP implementation from an annotated abstract class: serialization, deserialization, request building, query param handling — everything is generated by `build_runner`. `Dio` is never touched directly in datasources.

```dart
part 'twake_room.endpoint.g.dart';

/// Retrofit interface — only the contract is written, the implementation is generated.
@RestApi(baseUrl: 'https://api.twake.app/v1')
abstract class TwakeRoomEndpoint {
  factory TwakeRoomEndpoint(Dio dio, {String? baseUrl}) = _TwakeRoomEndpoint;

  @GET('/rooms/{roomId}/messages')
  Future<MessageListResponse> getMessages(
    @Path('roomId') String roomId, {
    @Query('from') String? from,
    @Query('limit') int limit = 20,
  });

  @POST('/rooms/{roomId}/messages')
  Future<SendMessageResponse> sendMessage(
    @Path('roomId') String roomId,
    @Body() SendMessageRequest request,
  );

  @DELETE('/rooms/{roomId}/messages/{eventId}')
  Future<void> deleteMessage(
    @Path('roomId') String roomId,
    @Path('eventId') String eventId,
  );
}
```

The endpoint is injected into the datasource — never exposed directly beyond the data layer:

```dart
/// REST implementation of RoomRemoteDataSource — for non-Matrix Twake APIs.
class TwakeRoomDataSource implements RoomRemoteDataSource {
  TwakeRoomDataSource(this._endpoint);
  final TwakeRoomEndpoint _endpoint;

  @override
  Future<List<MessageRemoteModel>> fetchMessages(String roomId, {String? from, int limit = 20}) async {
    final response = await _endpoint.getMessages(roomId, from: from, limit: limit);
    return response.messages; // MessageListResponse contains List<MessageRemoteModel>
  }

  @override
  Future<MessageRemoteModel> sendMessage(String roomId, String body) async {
    final response = await _endpoint.sendMessage(
      roomId,
      SendMessageRequest(body: body, type: 'm.text'),
    );
    return response.event;
  }
}
```

---

#### 2.4.5 Source of truth per domain

Every piece of data in the application has **one and only one source of truth** (SSOT). Any other place where the data appears (controller state, Riverpod cache, in-memory variable) is a **projection** of that source. On divergence, the source always wins.

| Domain | Source of truth | Local cache allowed? | Repository / Service |
|---|---|---|---|
| Timeline, events, rooms, presence, typing (Matrix) | Matrix SDK + SDK native DB | ❌ No — the SDK already persists | **Stateless**, pure adapter |
| Invitations, contacts, TOM (Twake REST) | Twake API | ✅ Yes — legitimate Hive cache | Can be **stateful** (intermediate cache) |
| Unsent drafts, settings, UI preferences | Hive | ✅ Yes — the only place this data lives | The cache is the source |

**Why it matters**: without an explicit SSOT, two projections can diverge and there is no way to decide which one is correct. Example of an anti-pattern: a `List<MessageEntity>` cached in a Matrix Repository **on top of** the SDK Timeline — on the first event received during a scroll, event ordering can become inconsistent between the two.

**Write invariant (absolute rule)**:

```
UI → Controller.action() → Service → Repository → canonical source (SDK or API)
                                                        ↓
                                              subscription / stream
                                                        ↓
UI ← rebuild ← state update ← listener ← Controller
```

A user action **never modifies the Controller's state directly**. It goes through the Repository to the canonical source, and state updates happen **only** via the subscription to that source's stream.

❌ **Anti-pattern**:

```dart
@riverpod
class ChatController extends _$ChatController {
  @override
  ChatState build(String roomId) => ChatState.initial();

  void sendMessage(String body) {
    // BUG: state modified before SDK write — guaranteed divergence on failure.
    state = state.copyWith(messages: [...state.messages, PendingMessage(body)]);
    ref.read(chatServiceProvider).send(roomId, body);
  }
}
```

✅ **Correct** — state follows the stream, never the other way around:

```dart
@riverpod
class ChatController extends _$ChatController {
  @override
  Stream<ChatState> build(String roomId) =>
      ref.watch(chatServiceProvider).watchRoom(roomId);

  Future<void> sendMessage(String body) =>
      ref.read(chatServiceProvider).send(roomId, body);
      // State updates via the stream: local echo (status: sending)
      // then sync (status: synced) — no manual manipulation.
}
```

**Optimistic UI**: for Matrix, there is no need to handle an optimistic state in the controller. The Matrix SDK immediately inserts the event with `Event.status = sending` into the Timeline, then transitions to `sent` / `synced` / `error`. The stream emits every transition — the view is always consistent with the source.

---

#### 2.4.6 Persistence

§2.4.5 covers **what** to persist where. This section covers **how** — which technology to use, how to distribute it via Riverpod, and how to keep the access rules consistent with the rest of the data layer.

**Technology choice per use case**:

| Use case | Technology | Rationale |
|---|---|---|
| Simple primitive values (theme, language, feature flags, "last used X" hints) | `shared_preferences` | Key/value, sync API after init, no adapter needed. |
| Structured data, typed caches, objects with `@HiveType` adapters (REST caches, drafts, custom app state) | `hive` | Typed, fast, supports encryption via `HiveAesCipher`. |
| Matrix timeline, events, room state, device keys | `sqflite` | Owned by the Matrix SDK — the app must not read or write here directly. |

Encryption of sensitive data (Matrix session keys, tokens) already uses the pattern implemented in `lib/utils/matrix_sdk_extensions/flutter_hive_collections_database.dart`: encryption key stored in `FlutterSecureStorage`, Hive box opened with `HiveAesCipher`. Any new box holding secrets must follow the same pattern — never store tokens in unencrypted boxes or in SharedPreferences.

**Access rules** (same principle as §2.4.2):

- UI, Controller, and Service **never** call `Hive.box(...)`, `Hive.openBox(...)`, or `SharedPreferences.getInstance()` directly.
- All persistence access goes through a `LocalDataSource` that depends on a persistence provider.
- The `LocalDataSource` exposes a typed domain-oriented API (`getInvitations()`, `saveDraft()`) — not raw Hive/SharedPreferences primitives.

**Riverpod distribution**:

Every persistence instance (Hive box, SharedPreferences instance) is exposed as a `@Riverpod(keepAlive: true)` provider. DataSources consume them via `ref.watch`. Persistence instances must survive navigation — hence `keepAlive`.

```dart
// data/persistence/hive_providers.dart
@Riverpod(keepAlive: true)
Future<Box<InvitationModel>> invitationsBox(Ref ref) async {
  final box = await Hive.openBox<InvitationModel>('app.invitations');
  ref.onDispose(() => box.close());
  return box;
}

// data/persistence/shared_preferences_provider.dart
@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) =>
    SharedPreferences.getInstance();
```

**Startup init + override pattern**: to avoid propagating `AsyncValue` through every controller that reads settings, pre-initialize persistence in `main()` and override the providers with already-resolved values. From the controllers' point of view, the instance is synchronously available.

```dart
// main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  final prefs = await SharedPreferences.getInstance();
  final invitationsBox = await Hive.openBox<InvitationModel>('app.invitations');

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWith(
          (ref) => Future.value(prefs),
        ),
        invitationsBoxProvider.overrideWith(
          (ref) => Future.value(invitationsBox),
        ),
      ],
      child: const TwakeApp(),
    ),
  );
}
```

**DataSource consuming persistence providers**:

```dart
// data/datasources/invitation_local_data_source.dart
@riverpod
Future<InvitationLocalDataSource> invitationLocalDataSource(Ref ref) async {
  final box = await ref.watch(invitationsBoxProvider.future);
  return HiveInvitationLocalDataSource(box);
}

class HiveInvitationLocalDataSource implements InvitationLocalDataSource {
  HiveInvitationLocalDataSource(this._box);
  final Box<InvitationModel> _box;

  @override
  Future<List<InvitationModel>> getInvitations() async =>
      _box.values.toList();

  @override
  Future<void> cacheInvitations(List<InvitationModel> invitations) async {
    await _box.clear();
    await _box.addAll(invitations);
  }
}
```

**Naming conventions**:

- Hive box names: prefix with `app.` to avoid collision with Matrix SDK boxes (which use `matrix.*`). Examples: `app.invitations`, `app.drafts`, `app.settings_cache`. Never use a generic name like `settings` or `cache` — boxes are a flat namespace shared with the SDK.
- SharedPreferences keys: prefix with the feature domain, snake_case. Examples: `settings.theme_mode`, `settings.language`, `onboarding.last_step_completed`.
- Provider names: `xxxBoxProvider` for a Hive box, `sharedPreferencesProvider` for the SharedPreferences instance, `xxxLocalDataSourceProvider` for the DataSource.

**Hive schema migrations**: when a class annotated with `@HiveType` evolves (new field, type change, removed field), define the migration path. Adding an optional field is safe. Removing or renaming a field requires either:

1. A new `typeId` + a one-shot migration task at startup that reads from the old box, converts, writes to the new box, and deletes the old box.
2. A `fromJson`-style tolerant adapter that accepts both schemas during a transition window.

Document the migration in the PR description and add a migration test.

**Thread safety**:

- `Hive.openBox<T>(name)` is idempotent: calling it twice with the same name returns the same `Box` instance. Safe to `await` concurrently in different providers.
- `Box.put` / `Box.get` are synchronous once the box is open — no concurrency issue at the API level, but avoid heavy writes in a tight loop that would block the isolate.
- `Hive.close()` / `box.close()` must never be called from user code — persistence providers own the lifecycle via `ref.onDispose`.

**Testability**:

```dart
setUp(() async {
  // In-memory Hive
  Hive.init(Directory.systemTemp.createTempSync().path);
  final box = await Hive.openBox<InvitationModel>('test.invitations');

  // Mocked SharedPreferences
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  container = ProviderContainer(
    overrides: [
      invitationsBoxProvider.overrideWith((ref) => Future.value(box)),
      sharedPreferencesProvider.overrideWith((ref) => Future.value(prefs)),
    ],
  );
});

tearDown(() async {
  await Hive.deleteFromDisk();
  container.dispose();
});
```

In practice: never mock the DataSource directly in tests — override the persistence provider with an in-memory instance and let the real DataSource run. Mocking the DataSource hides schema bugs and serialization issues.

---

#### 2.4.7 Logging

**Single entry point** — All application logs go through `Logs()` from `package:matrix/matrix_api_lite/utils/logs.dart`. Never use `print()`, `debugPrint()`, or `developer.log()` directly in application code.

```dart
// ✅ CORRECT
Logs().d('RoomRepository: fetching timeline for $roomId');
Logs().w('ContactService: phonebook permission denied');
Logs().e('UploadManager: upload failed', error, stackTrace);

// ❌ WRONG — bypasses the logging pipeline
print('something happened');
debugPrint('debug: $value');
```

**Log levels** — Use the level that matches the situation:

| Level | Method | When to use |
|-------|--------|-------------|
| Debug | `Logs().d()` | Development-time tracing — removed or guarded before release |
| Info | `Logs().i()` | Meaningful lifecycle events (login, sync start, room join) |
| Warning | `Logs().w()` | Recoverable issues (permission denied, fallback triggered, timeout retried) |
| Error | `Logs().e()` | Unexpected failures requiring investigation |

**Architecture** — The project uses a `LogOrchestrator` (singleton) with pluggable loggers:

| Logger | Role | Active when |
|--------|------|-------------|
| `ConsoleLogger` | Prints to debug console | `kDebugMode` only |
| `SentryLogger` | Captures `wtf`-level entries as Sentry exceptions | Release builds |

The bridge between `Logs()` (SDK) and `LogOrchestrator` (app) is `initMatrixLogger()`, which maps SDK log levels to `LogLevel` and forwards every `LogEvent` as a `LogEntry`.

**Error capture pattern**:

```dart
// In a Service or Repository — always pass error + stackTrace
try {
  await sdkClient.sendMessage(roomId, content);
} catch (e, s) {
  Logs().e('MessageService: send failed for $roomId', e, s);
  rethrow; // let the controller handle the AsyncValue.error
}
```

Errors logged at `.e()` level with an exception object are automatically forwarded to Sentry via `SentryLogger` for `wtf`-level entries. For critical / "should never happen" failures, use `Logs().wtf()` to ensure Sentry capture.

**What to NEVER log** — The application handles end-to-end encrypted data. The following must never appear in any log, at any level:

- Decrypted message content or plaintext bodies
- Session keys, Megolm keys, or any encryption material
- Access tokens, refresh tokens, or SSO codes
- Personally identifiable information (email, phone number, display names of other users in bulk)
- Full request/response bodies from authenticated API calls

When debugging encrypted flows, log only event IDs, room IDs, session IDs (not session keys), and algorithm names.

**Where to log** — Logs belong in **Services**, **Repositories**, and **DataSources**. Controllers and UI widgets must not log directly — they observe state and delegate to the domain layer, which handles its own tracing.

| Layer | Logging? | Rationale |
|-------|----------|-----------|
| UI / Widget | No | Observes and renders only |
| Controller | No | Delegates to services; errors surface as `AsyncValue.error` |
| Service / UseCase | Yes | Business logic decisions, orchestration events |
| Repository | Yes | Data access failures, cache hits/misses |
| DataSource | Yes | Network/SDK calls, serialization errors |

**Debug UI** — The app includes a `LogView` widget (accessible via dev settings) that displays the in-memory log buffer. This is useful for on-device debugging without a connected console.

---

### 2.5 The Presentation Layer

The presentation layer **contains no business logic**. It observes state, reacts to user events, and delegates everything to the controller. Screens only do two things: display the state and forward the user's intents.

**Pattern for actions with UI confirmation**: the screen passes the confirmation function as a parameter to the controller. The controller handles the result and decides what comes next.

❌ **BAD** — the screen handles the result of the confirmation:

```dart
class RoomScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () async {
        final confirmed = await showDialog<bool>( // result logic in the view
          context: context,
          builder: (_) => const ConfirmDeleteDialog(),
        );
        if (confirmed == true) { // check in the view
          ref.read(roomControllerProvider.notifier).deleteMessage(messageId);
        }
      },
    );
  }
}
```

✅ **GOOD** — the screen passes the means to confirm, the controller handles the result:

```dart
// Screen — passes the function, does not handle the result
class RoomScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () => ref.read(roomControllerProvider.notifier).deleteMessage(
        messageId: messageId,
        confirm: () => showDialog<bool>(
          context: context,
          builder: (_) => const ConfirmDeleteDialog(),
        ),
      ),
    );
  }
}

// Controller — receives the function and handles the result
class RoomController extends Notifier<RoomState> {
  Future<void> deleteMessage({
    required String messageId,
    required Future<bool?> Function() confirm,
  }) async {
    final confirmed = await confirm(); // call the UI function
    if (confirmed != true) return;    // check in the controller
    state = await AsyncValue.guard(
      () => _deleteMessageUseCase.execute(messageId),
    );
  }
}
```

---

#### 2.5.0bis Choosing the return type of a controller's `build()`

All controllers use the `@riverpod` annotation (codegen). The generated provider type (`NotifierProvider`, `AsyncNotifierProvider`, `StreamNotifierProvider`) is **inferred from the return type of `build()`** — you don't pick a base class manually.

**Selection rule**: the return type of `build()` follows the type exposed by the canonical source (see §2.4.5 *Source of truth per domain*).

| Canonical source | `build()` return type |
|---|---|
| Continuous stream (Matrix SDK: timeline, rooms, typing, presence) | `Stream<T>` |
| One-shot async (Twake REST: profile, login, invitations, search) | `Future<T>` |
| Local synchronous (Hive: settings, theme, drafts) | `T` |

**Decision in 2 questions**:
1. Is the source synchronous and local? → yes = `T`; no = question 2.
2. Continuous stream or single value? → Stream = `Stream<T>`; Future = `Future<T>`.

❌ **Anti-pattern** — `Future<T>` + a manual `ref.listen` on a stream inside `build()`:

```dart
@riverpod
class ChatController extends _$ChatController {
  @override
  Future<ChatState> build(String roomId) async {
    ref.listen(chatServiceProvider, (_, service) {
      service.watchTimeline(roomId).listen((messages) {
        state = AsyncValue.data(ChatState(messages: messages)); // hand-rolled lifecycle
      });
    });
    return ChatState.initial();
  }
}
```

✅ **Correct** — `Stream<T>` in `build()`, Riverpod handles the subscription:

```dart
@riverpod
class ChatController extends _$ChatController {
  @override
  Stream<List<MessageEntity>> build(String roomId) =>
      ref.watch(chatServiceProvider).watchTimeline(roomId);

  Future<void> sendMessage(String body) =>
      ref.read(chatServiceProvider).send(roomId, body);
}
```

**Controllers vs read-only providers** — two forms of `@riverpod`:
- **Controllers** (`@riverpod` on a class): state + mutation methods. One per screen.
- **Read-only providers** (`@riverpod` on a function): projections of a source, derived computations, pure injection. No mutations. Consumed by controllers or directly by read-only widgets.

```dart
// Read-only projection of a source
@riverpod
Stream<List<String>> roomTimelineEventIds(Ref ref, String roomId) =>
    ref.watch(chatServiceProvider).watchEventIds(roomId);

// Derived / computed
@riverpod
int roomUnreadCount(Ref ref, String roomId) {
  final messages = ref.watch(chatControllerProvider(roomId)).valueOrNull ?? [];
  return messages.where((m) => !m.read).length;
}
```

**Rebuild granularity for high-frequency lists**: handled on the UI side, not by multiplying Riverpod providers. Do **not** create a `family(itemId)` provider per item when all items come from the same stream source — it multiplies subscriptions and causes thrashing with `autoDispose` during scroll. Use `ListView.builder` with `ValueKey(itemId)` on each item + const `StatelessWidget` items receiving the `@freezed` entity as a parameter. Flutter diffs the list efficiently via keys; unchanged items don't rebuild.

`family` remains legitimate for cases with **independent sources** (e.g. `userProfileProvider(userId)` fetching REST per user) — not for items of a list sharing the same source.

---

#### 2.5.1 What the view must never contain

The view is a **pure function of state**: `f(state) → widgets`. As soon as you see these patterns in a screen, it's a warning signal:

❌ **BAD** — business logic in build:

```dart
class MessageListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider);

    // Data manipulation in the view ❌
    final unread = messages.where((m) => !m.isRead && m.senderId != currentUserId);
    final grouped = groupBy(unread, (m) => m.sentAt.day);

    // Direct repository call from the view ❌
    final user = ref.read(userRepositoryProvider).getCurrentUser();

    // JSON parsing in the view ❌
    final name = (rawData['profile'] as Map)['displayName'] as String;

    return ListView(...);
  }
}
```

✅ **GOOD** — the view consumes an already-computed state:

```dart
class MessageListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(messageListControllerProvider);

    return state.when(
      loading: () => const _LoadingView(),
      error: (e, _) => _ErrorView(error: e),
      data: (state) => _MessageList(
        groups: state.groupedMessages, // computed in the controller
        unreadCount: state.unreadCount,
      ),
    );
  }
}
```

---

#### 2.5.2 Presentation Extensions and Mixins

**Extensions**: a powerful tool to add methods to existing types without inheritance. Main use cases:

- Presentation getters and methods on entities (`@freezed` does not support native getters without the `const factory` trick)
- `BuildContext` shortcuts (`l10n`, `colorScheme`, `textTheme`)
- Utility type conversions

```dart
// Extension on entity — in presentation/, not in domain/
extension MessageEntityX on MessageEntity {
  bool get isEdited => editedAt != null;
  bool get isFromCurrentUser => senderId == ...; // via a service
  String get shortPreview =>
      body.length > 60 ? '${body.substring(0, 60)}…' : body;
}

// BuildContext extension
extension BuildContextX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
```

**Mixins**: mixins solve a precise problem — sharing behavior between classes that **have no common inheritance relationship**. They are suitable for **stateless**, simple, and generic behaviors.

A legitimate use: `Comparable`, a lightweight log mixin, a dependency-free serialization mixin.

❌ **BAD** — using mixins as a substitute for composition, piling up dependencies:

```dart
// Impossible to tell where each method comes from
// Order of mixins = source of silent bugs (MRO)
// Impossible to test each behavior in isolation
// If a mixin changes, all consumers are impacted
class RoomController extends StateNotifier<RoomState>
    with LoggerMixin,
         AnalyticsMixin,
         ErrorHandlerMixin,
         LocalStorageMixin,
         NetworkAwareMixin {
  // Who provides log()? analytics? handleError()?
  // Which mixin takes priority on onNetworkChange()?
}
```

✅ **GOOD** — composition: dependencies are explicit, injectable, testable:

```dart
final class RoomController extends Notifier<RoomState> {
  RoomController(this._analytics, this._logger, this._sendMessage);

  final AnalyticsService _analytics; // explicit
  final Logger _logger;              // individually testable
  final SendMessageUseCase _sendMessage;
}
```

> **Rule**: if a mixin needs to know the host class's state or access other dependencies, it's a service, not a mixin. Mixins must not depend on the context in which they are applied.

---

### 2.6 Core & Standalone Modules

`core/` contains utilities and abstractions shared between multiple features. A healthy `core/` module is **stable**: we read it often, we modify it rarely.

**Rule**: if something is used in only one feature, it does not belong in `core/`. Do not use `core/utils/` as a catch-all.

Example of a utility class in `core/utils/` — with a constructor, no static methods (testable, configurable):

```dart
/// Formats dates for display in message lists.
final class MessageDateFormatter {
  const MessageDateFormatter({required this.locale});

  final String locale;

  /// Shows the time if today, the short date otherwise.
  String format(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;

    return isToday
        ? DateFormat.Hm(locale).format(date)
        : DateFormat.MMMd(locale).format(date);
  }
}

// Usage — injectable, testable, configurable
final formatter = MessageDateFormatter(locale: 'fr');
final label = formatter.format(message.sentAt);
```

> Static methods are **not** preferred here: a `MessageDateFormatter(locale: locale)` is testable, injectable via Riverpod, and its behavior varies with context (locale, timezone). A static `DateUtils.format(date)` cannot vary without a global parameter.

---

### 2.7 Dependency Injection — Migration to Riverpod

DI is currently done via GetIt. The migration to Riverpod is ongoing and will happen **progressively, feature by feature**. The goal is the complete removal of GetIt over time. New features no longer use GetIt.


With `@riverpod`, each dependency is a provider co-located with its implementation. The dependency chain is declarative and traceable: DI providers (datasource, repository, use case, service) use `ref.watch` to declare their dependencies. The controller uses `ref.read` to access use cases in its methods (one-shot read, no reactivity needed).

❌ **BAD** — GetIt: global registration, fragile ordering, no reactivity:

```dart
getIt.registerLazySingleton<RoomDataSource>(
  () => MatrixRoomDataSource(getIt<Client>()),
);
getIt.registerLazySingleton<RoomRepository>(
  () => RoomRepositoryImpl(getIt<RoomDataSource>()),
);
```

✅ **GOOD** — `@riverpod`: explicit and reactive dependency chain:

```dart
// data/datasources/room_data_source.provider.dart
@riverpod
RoomDataSource roomDataSource(Ref ref) =>
    MatrixRoomDataSource(ref.watch(matrixClientProvider));

// data/repositories/room_repository.provider.dart
@riverpod
RoomRepository roomRepository(Ref ref) =>
    RoomRepositoryImpl(ref.watch(roomDataSourceProvider));

// domain/usecases/send_message_usecase.provider.dart
@riverpod
SendMessageUseCase sendMessageUseCase(Ref ref) =>
    SendMessageUseCase(ref.watch(roomRepositoryProvider));

// presentation/controllers/room_controller.dart
@riverpod
class RoomController extends _$RoomController {
  @override
  AsyncValue<RoomState> build(String roomId) {
    // ref.watch in build() — automatic subscription, rebuild if the use case changes
    final sendMessage = ref.watch(sendMessageUseCaseProvider);
    // ...
  }
}
```

> **Full workflow**: `RoomController` → `ref.read(sendMessageUseCaseProvider)` → `SendMessageUseCase(roomRepository)` → `RoomRepositoryImpl(roomDataSource)` → `MatrixRoomDataSource(matrixClient)`. Every link is independently testable via `ProviderContainer.overrides`.

Source: https://riverpod.dev/docs/concepts/about_code_generation

#### Rules for using `ref`

> Reference: https://docs-v2.riverpod.dev/docs/concepts/reading

| Method | Allowed in | Forbidden in | Effect |
|---|---|---|---|
| `ref.watch` | `build()`, DI provider | Callbacks, methods, `initState` — **AssertionError in debug** | Subscribes, rebuilds on every change |
| `ref.read` | Callbacks, methods, `initState` | `ConsumerWidget.build()`, `Notifier.build()` | Reads once, no rebuild |
| `ref.listen` | `build()` only | Outside `build()` | Subscribes, side effect without rebuild |
| `ref.listenManual` | `initState`, `didChangeDependencies` | — | Subscribes, returns a `ProviderSubscription` to `cancel()` in `dispose()` |

```dart
// ✅ ref.watch in build() — rebuild on change
class RoomPage extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(roomControllerProvider(roomId));
    return state.when(...);
  }
}

// ✅ ref.read in a controller method — one-shot read
@riverpod
class RoomController extends _$RoomController {
  Future<void> sendMessage(String text) async {
    await ref.read(sendMessageUseCaseProvider).execute(text);
  }
}

// ✅ ref.listenManual in initState — side effect without rebuild
class RoomPageState extends ConsumerState<RoomPage> {
  ProviderSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual(roomControllerProvider(widget.roomId), (prev, next) {
      next.whenOrNull(error: (e, _) => showErrorSnackbar(context, e));
    });
  }

  @override
  void dispose() {
    _sub?.cancel(); // mandatory — otherwise memory leak
    super.dispose();
  }
}

// ❌ ref.watch in initState — AssertionError in debug
void initState() {
  super.initState();
  ref.watch(roomControllerProvider(widget.roomId)); // crash
}

// ❌ ref.read in build() — silent bug, the view never updates
Widget build(BuildContext context, WidgetRef ref) {
  final state = ref.read(roomControllerProvider(roomId)); // will never rebuild
}
```

---

## 3. Naming Conventions

Dart's naming conventions are defined in the [Dart Style Guide](https://dart.dev/effective-dart/style) and the [Flutter Style Guide](https://github.com/flutter/flutter/wiki/Style-guide-for-Flutter-repo). Following them without exception guarantees consistency between our code and the ecosystem — and simplifies onboarding.

### 3.1 Files and folders

**`snake_case`** for all files and folders, without exception. The file name reflects the main content and its role.

```
room_screen.dart
message_bubble.dart
room_repository_impl.dart
send_message_usecase.dart
message.remote_model.dart    ← convention for DTOs: entity.type.dart
message.remote_model.g.dart  ← generated files: ignored by the linter
```

Source: https://dart.dev/effective-dart/style#do-name-libraries-and-source-files-using-lowercase_with_underscores

---

### 3.2 Classes

**`PascalCase`** for all classes, enums, extensions, typedefs, and mixins. Suffix classes with their architectural role for immediate readability.

```dart
class RoomRepositoryImpl { ... }       // Impl = interface implementation
class SendMessageUseCase { ... }       // UseCase = use case
class RoomController { ... }           // Controller = Riverpod Notifier
class RoomState { ... }                // State = immutable state
abstract class RoomDataSource { ... }  // no Abstract suffix — the keyword is enough
extension BuildContextX on BuildContext { ... } // X = extension convention
```

---

### 3.3 Attributes and visibility

**`camelCase`** for all attributes. Private fields carry an underscore prefix. No underscore on public fields.

Fields must be `final` by default — see §4.1.

❌ **BAD**:

```dart
class UserProfile {
  String _Name = '';       // underscore but PascalCase
  String PublicName = '';  // PascalCase on an attribute
  var x = 0;               // non-descriptive name
}
```

✅ **GOOD**:

```dart
final class UserProfile {
  UserProfile({required this.displayName});

  final String displayName;   // public: camelCase, no underscore
  String? _cachedAvatarUrl;   // private: underscore prefix
  int _retryCount = 0;
}
```

> Presentation logic (`initials`, `shortName`) does not belong in the domain class — it goes in an extension in the presentation layer (see §2.5.2):
> ```dart
> // presentation/extensions/user_profile_x.dart
> extension UserProfileX on UserProfile {
>   String get initials =>
>       displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
> }
> ```

Source: https://dart.dev/effective-dart/style#prefer-using-lowercamelcase-for-variable-names

---

### 3.4 Booleans

Booleans must be **prefixed** so that reading them yields an affirmative sentence. `is` describes a present state, `has` a past state or possession. Positional boolean parameters must always be named.

❌ **BAD**:

```dart
void sendMessage(bool b) { ... }  // unreadable positional bool parameter
bool loaded = false;               // no prefix
bool messages = false;             // ambiguous, boolean or list?
```

✅ **GOOD**:

```dart
bool isLoading = false;
bool hasUnreadMessages = false;
bool get isCurrentUser => _session?.userId == userId;

// Named parameter — clear reading at the call site
void sendMessage({required bool isEncrypted}) { ... }
// Call: sendMessage(isEncrypted: true) ← readable
// vs    sendMessage(true)             ← opaque
```

Source: https://dart.dev/effective-dart/design#prefer-naming-a-method-to---something-using-is-or-has

---

### 3.5 Methods — Standard Vocabulary

A shared vocabulary reduces cognitive load. Each prefix has a precise semantic:

| Prefix | Semantic |
|---|---|
| `fetch` | Accesses data via a network call |
| `search` | Like `fetch` but with search criteria |
| `get` | Accesses data locally (cache, memory) |
| `find` | Like `get` but with search criteria |
| `save` | Creates or updates an entity |
| `delete` | Deletes an entity |
| `compute` | Computes a value from other data |
| `make` | Builds an object from scratch |
| `build` | Builds an object from a builder (standard pattern) |
| `create` | Builds an object from a factory (standard pattern) |
| `normalize` | Transforms data to conform to a schema |
| `ensure` | Guarantees a condition is met (idempotent) |
| `is` / `has` | Returns a boolean (see §3.4) |
| `doXAndForget` | Wraps an async Future as sync (intentional fire-and-forget) |

---

### 3.6 Enums

Use **enhanced enums** (Dart 2.17+). Enum values are in `camelCase`. Avoid string comparisons or isolated constants where an enum is enough.

❌ **BAD**:

```dart
const String statusOnline = 'online';
if (user.status == 'online') { ... }    // possible typo, no completion
if (user.status == 'Offline') { ... }   // inconsistent casing
```

✅ **GOOD**:

```dart
enum UserPresence {
  online('online'),
  offline('offline'),
  unavailable('unavailable');

  const UserPresence(this.matrixValue);
  final String matrixValue;

  bool get isAvailable => this == UserPresence.online;

  static UserPresence fromMatrix(String value) =>
      values.firstWhere(
        (e) => e.matrixValue == value,
        orElse: () => UserPresence.offline,
      );
}
```

Source: https://dart.dev/language/enums#declaring-enhanced-enums

---

### 3.7 Constants

Anything that does not change during the scope's lifetime must be `const`. In Flutter, `const` widgets are **never rebuilt**, even if their parent widget is. This is the simplest and most effective performance optimization.

❌ **BAD** — new instances created on every rebuild:

```dart
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Icon(Icons.send),        // new instance on every rebuild
      SizedBox(height: 8),     // same
      Text('Send'),            // same
    ],
  );
}
```

✅ **GOOD** — shared canonical instances, Flutter skips the rebuild:

```dart
@override
Widget build(BuildContext context) {
  return const Column(
    children: [
      Icon(Icons.send),
      SizedBox(height: 8),
      Text('Send'),
    ],
  );
}

// For values shared across files:
const _kMessageMaxLength = 4096;
const _kAvatarRadius = 20.0;
```

> `const` at the widget level lets Flutter skip the `build()` step entirely for that widget during parent rebuilds. Source: https://docs.flutter.dev/perf/best-practices#control-build-cost

---

### 3.8 Imports

Always use **`package:` imports**, never relative imports. Relative imports are fragile across folder-structure refactors, and create ambiguities.

❌ **BAD**:

```dart
import '../../core/utils/date_formatter.dart';
import '../../../features/auth/domain/entities/user.dart';
```

✅ **GOOD**:

```dart
import 'package:twake/core/utils/date_formatter.dart';
import 'package:twake/features/auth/domain/entities/user.dart';
```

The linter's `always_use_package_imports` rule enforces this automatically. Source: https://dart.dev/tools/linter-rules/always_use_package_imports

---

## 4. Dart Code Style

### 4.1 `final` and immutability

**By default, everything is `final`.** A mutable field must be the justified exception, not the rule. This applies doubly to states: a mutable state bypasses the entire Riverpod architecture and makes debugging impossible.

`final class` prevents unintended extension and enables compiler optimizations.

❌ **BAD**:

```dart
class AuthController extends Notifier<AuthState> {
  UserRepository repository; // mutable, can be reassigned after init
}

class AuthState {
  bool isLoading = false; // directly mutable — bypasses copyWith
  User? user;
}
```

✅ **GOOD**:

```dart
final class AuthController extends Notifier<AuthState> {
  AuthController(this._repository);
  final UserRepository _repository;
}

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    User? user,
    String? errorMessage,
  }) = _AuthState;
}

// In the controller, mutation via copyWith
state = state.copyWith(isLoading: true);
```

Source: https://dart.dev/language/class-modifiers#final

---

### 4.2 Explicit typing

**Avoid `dynamic` and `var` when the type is not obvious.** `dynamic` completely disables the type system — type errors become runtime errors invisible at compile time. Typing explicitly documents intent and secures refactors.

❌ **BAD**:

```dart
var result = fetchData();                 // unknown type without reading the implementation
dynamic data = jsonDecode(rawString);     // disables the type system
final list = [];                          // List<dynamic> by inference
```

✅ **GOOD**:

```dart
final List<Message> messages = await fetchMessages();
final Map<String, dynamic> json = jsonDecode(raw) as Map<String, dynamic>;
final MessageEntity message = await _useCase.execute(params);
```

`strict-inference: true` in `analysis_options.yaml` detects ambiguous inferences at compile time. Source: https://dart.dev/tools/analysis#enabling-additional-type-checks

---

### 4.3 Early Returns (Guard Clauses)

Prefer **early returns** for exclusion cases, null checks, and preconditions. This avoids excessive nesting and puts the nominal cases at the end of the function, in plain sight.

❌ **BAD** — pyramid of doom, nominal case buried in nesting:

```dart
Future<void> sendMessage(String? content) async {
  if (content != null) {
    if (content.isNotEmpty) {
      if (_isConnected) {
        if (!_isSending) {
          await _repository.send(content);
        }
      }
    }
  }
}
```

✅ **GOOD** — guards up front, nominal case at the end:

```dart
Future<void> sendMessage(String? content) async {
  if (content == null || content.isEmpty) return;
  if (!_isConnected) return;
  if (_isSending) return;

  await _repository.send(content);
}
```

---

### 4.4 Futures and `async`

**Always return Futures.** An ignored Future is a silent error. If a Future is intentionally not awaited (fire-and-forget), flag it explicitly with `unawaited()`.

❌ **BAD**:

```dart
void loadProfile() {
  _repository.getUser(); // ignored Future, silent exceptions
}

Future<void> refresh() async {
  _repository.refresh(); // unawaited inside an async function — likely a bug
}
```

✅ **GOOD**:

```dart
Future<void> loadProfile() async {
  await _repository.getUser();
}

// If intentionally not awaited, make it explicit
void startBackgroundSync() {
  unawaited(_syncService.start()); // intentional and visible
}
```

The linter's `unawaited_futures` rule detects non-returned futures. Source: https://dart.dev/tools/linter-rules/unawaited_futures

---

### 4.5 `setState`

**Always include the mutation inside the `setState` callback.** Flutter does not look at what changed inside the callback — `setState` simply triggers a widget rebuild, whatever the callback contains. In that sense, `_x = 1; setState(() {})` and `setState(() { _x = 1; })` produce the **same rebuild**.

The reason to put the mutation inside the callback is **semantic, about readability, and about safety**:
- The code is explicit: "these mutations are the reason for this rebuild"
- Guaranteed atomicity: all mutations happen before the next frame
- Protection against silent mutations: a mutation outside `setState` does not trigger a rebuild — the widget shows an incorrect state until the next rebuild is triggered for another reason
- In debug mode, Flutter runs assertions inside the callback (widget mounted, not currently building, etc.)
- An empty `setState(() {})` is clearly identifiable as a rebuild without a reason


❌ **BAD**:

```dart
_isLoading = true;        // hidden mutation, outside the setState context
setState(() {});           // rebuild triggered, but why? unreadable

setState(() {});           // no mutation = rebuild without reason
```

✅ **GOOD**:

```dart
setState(() {
  _isLoading = true;       // the reason for the rebuild is visible
  _errorMessage = null;
});
```

Source: https://api.flutter.dev/flutter/widgets/State/setState.html

---

### 4.6 Mixins — Limited use

See §2.5.2 for full context. In short: **prefer composition over mixins** as soon as there is state, dependencies, or more than one mixin per class.

❌ **BAD** — 5 mixins on a single class:

```dart
class RoomScreen extends StatefulWidget
    with LoggerMixin, AnalyticsMixin, ErrorHandlerMixin, LoadingMixin, LifecycleMixin { }
```

✅ **GOOD** — behaviors injected explicitly:

```dart
final class RoomController extends Notifier<RoomState> {
  RoomController(this._analytics, this._logger, this._errorHandler);
  final AnalyticsService _analytics;
  final Logger _logger;
  final ErrorHandler _errorHandler;
}
```

---

### 4.7 File size and widget splitting

**Indicative limit: 300 lines per file.** A file exceeding this limit probably has too many responsibilities or too deep a widget tree. Splitting it is a quality and readability refactor.

For widgets: extract into a dedicated `StatelessWidget`, not into `_buildX()` methods. Widgets can be `const` and benefit from Flutter's cache; build methods cannot.

❌ **BAD** — 100+ line tree inside `build()`:

```dart
@override
Widget build(BuildContext context) {
  return Column(children: [
    Container(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        CircleAvatar(...),
        Column(children: [
          Text(message.sender),
          Text(message.body),
          // ... 80 more lines
        ]),
      ]),
    ),
  ]);
}
```

✅ **GOOD** — widgets extracted, `build()` readable at a glance:

```dart
@override
Widget build(BuildContext context) {
  return Column(children: [
    _MessageHeader(sender: message.sender, avatarUrl: message.avatarUrl),
    _MessageBody(body: message.body, isEdited: message.isEdited),
    _MessageFooter(timestamp: message.sentAt, status: message.status),
  ]);
}
```

> `source-lines-of-code: 50` in `dart_code_metrics` is a metric applied per **method/function** — not per file. It is consistent with the 300-line-per-file limit: the two measure different things. A 50-line method = a sign of multiple responsibilities. Source: https://dcm.dev/docs/rules/common/function-lines-of-code/

---

### 4.8 Parsing

**Never navigate `Map`s manually.** Every manual access to a JSON key is a potential runtime crash. Always go through typed models with `fromJson`.

❌ **BAD**:

```dart
final name = (response['user'] as Map<String, dynamic>)['profile']['displayName'] as String;
final url = (data[0] as Map)['avatar_url']; // NPE if the list is empty
```

✅ **GOOD**:

```dart
final model = UserRemoteModel.fromJson(response);
final name = model.profile.displayName;
final url = model.avatarUrl;
```

---

### 4.9 Method naming

**A long, explicit name is better than a short, opaque one.** Code is read far more often than it is written. A method name is free documentation. See also §3.5 for the standard vocabulary.

❌ **BAD**:

```dart
void upd(User u) { ... }
Future<dynamic> getData() { ... }
bool chk(String s) { ... }
void proc() { ... }
```

✅ **GOOD**:

```dart
Future<void> updateUserDisplayName(String newDisplayName) async { ... }
Future<List<Message>> fetchRoomMessages({required String roomId}) async { ... }
bool isValidMatrixUserId(String userId) { ... }
Future<void> processIncomingMatrixEvents(List<Event> events) async { ... }
```

---

## 5. Navigation

### 5.1 Route declaration

Routes are declared via `@TypedGoRoute` with a hierarchy for nested routes. Implementation code is generated by `build_runner` — we only maintain the route classes.

```dart
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<RoomRoute>(path: 'room/:id'),
    TypedGoRoute<ProfileRoute>(path: 'profile/:userId'),
    TypedGoRoute<SettingsRoute>(path: 'settings'),
  ],
)
@immutable
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const HomeScreen();
}

@immutable
class RoomRoute extends GoRouteData {
  const RoomRoute({required this.id, this.$extra});
  final String id;
  final RoomEntity? $extra; // to pass complex objects without serialization
}
```

Source: https://pub.dev/packages/go_router#type-safe-routes

---

### 5.2 Typed navigation (GoRouter builder pattern)

Never navigate via strings or enums. Use the generated route classes — the compiler catches navigation errors, missing parameters, and incorrect types.

❌ **BAD** — string-based navigation, untyped parameters:

```dart
context.push('/room/abc123');
context.push('/room/${room.id}?name=${Uri.encodeComponent(room.name)}');
Navigator.pushNamed(context, '/profile'); // no type safety
```

✅ **GOOD** — generated typed classes, compile-time safety:

```dart
RoomRoute(id: room.id).push(context);
RoomRoute(id: room.id, $extra: room).go(context);
ProfileRoute(userId: user.id).push(context);

// With typed optional parameters
SettingsRoute().push(context);
```

Source: https://pub.dev/documentation/go_router/latest/topics/Type-safe%20routes-topic.html

---

### 5.3 Route guards — `redirect` callback

Use GoRouter's `redirect` to enforce route-level guards (auth, session, deep-link validation). **Centralize the guard logic in a Riverpod provider** — never query state directly inside `redirect`, it must stay pure and synchronous.

❌ **BAD** — guard scattered across screens, state read from globals:

```dart
@override
Widget build(BuildContext context) {
  if (!AuthManager.instance.isLoggedIn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go('/login');
    });
    return const SizedBox.shrink();
  }
  return const HomeScreen();
}
```

✅ **GOOD** — guard declared on the route via `redirect`, state via a provider:

```dart
@TypedGoRoute<HomeRoute>(path: '/')
@immutable
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  FutureOr<String?> redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = ProviderScope.containerOf(context).read(authControllerProvider).isLoggedIn;
    return isLoggedIn ? null : const LoginRoute().location;
  }

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}
```

Rules:

- `redirect` returns `null` to allow the navigation, or a target `String` location to redirect.
- Prefer per-route `redirect` over a single top-level one — keeps guards colocated with their route.
- Keep it pure: no side effects, no `await` on I/O, no navigation calls. Read state, decide, return.
- For async guards (token refresh, session validation), move the logic to the controller and expose a synchronous status the `redirect` can read.

Source: https://pub.dev/documentation/go_router/latest/topics/Redirection-topic.html

---

## 6. Tests

### 6.1 Organization — Mirror of `lib/`

`test/` reproduces the exact structure of `lib/`. Every file has its `_test.dart` counterpart at the same relative path. This structure makes it trivial to discover the tests of any given class.

```
test/
├── features/
│   ├── auth/
│   │   ├── data/repositories/auth_repository_impl_test.dart
│   │   ├── domain/usecases/login_usecase_test.dart
│   │   └── presentation/controllers/auth_controller_test.dart
│   └── messaging/
│       ├── domain/usecases/send_message_usecase_test.dart
│       └── presentation/controllers/room_controller_test.dart
└── core/
    └── utils/message_date_formatter_test.dart
```

**What to test:** use cases, repository impls (with mocked datasource), controllers/notifiers.
**What not to test:** purely visual widgets without logic, `@freezed` data classes, generated code `*.g.dart`.

---

### 6.2 Test naming

Format: `[unitUnderTest]_[scenario]_[expectedBehavior]` — readable without context.

```dart
void main() {
  group('SendMessageUseCase', () {
    test('whenBodyIsEmpty_throwsInvalidMessageException', () { ... });
    test('whenRoomExists_returnsMessageEntity', () { ... });
    test('whenRepositoryFails_propagatesException', () { ... });
  });

  group('RoomRepositoryImpl', () {
    test('fetchMessages_whenCacheIsValid_doesNotCallRemote', () { ... });
    test('fetchMessages_whenRemoteFails_throwsSendMessageException', () { ... });
  });
}
```

---

### 6.3 Test structure — AAA

**Arrange / Act / Assert** pattern, applied systematically. The three sections are always separated and commented.

```dart
test('sendMessage_whenRoomExists_returnsMessageEntity', () async {
  // Arrange
  const roomId = 'room-123';
  const body = 'Hello';
  when(mockDataSource.sendMessage(roomId, body))
      .thenAnswer((_) async => fakeMessageModel);

  // Act
  final result = await repository.sendMessage(roomId, body);

  // Assert
  expect(result.body, equals(body));
  expect(result.senderId, equals(fakeMessageModel.senderId));
  verify(mockDataSource.sendMessage(roomId, body)).called(1);
  verifyNoMoreInteractions(mockDataSource);
});
```

---

### 6.4 Mocking (Mockito)

Mockito generates mocks via `@GenerateMocks` + `build_runner`. Don't write mocks by hand — they are a source of bugs and needless maintenance.

```dart
@GenerateMocks([RoomRepository, RoomDataSource, TypingService])
void main() { ... }
```

```dart
final mockRepo = MockRoomRepository();

// thenAnswer (lazy) — mandatory for Future and Stream
when(mockRepo.fetchMessages(any)).thenAnswer((_) async => fakeMessages);
when(mockRepo.watchMessages(any)).thenAnswer((_) => Stream.value(fakeMessages));

// thenThrow — to test error cases
when(mockRepo.sendMessage(any, any)).thenThrow(const SendMessageException());

// Verification
verify(mockRepo.fetchMessages('room-1')).called(1);
verifyNever(mockRepo.sendMessage(any, any));
```

Source: https://pub.dev/packages/mockito

---

### 6.5 Integration tests — Patrol + Robot Pattern

**One integration test = one feature, one scenario.** The **Robot pattern** encapsulates interactions in dedicated classes to keep tests readable and resilient to UI changes.

```dart
// Robot — encapsulates interactions of the login feature
class LoginRobot {
  LoginRobot(this.$);
  final PatrolIntegrationTester $;

  Future<void> enterEmail(String email) => $(#emailField).enterText(email);
  Future<void> enterPassword(String pwd) => $(#passwordField).enterText(pwd);
  Future<void> tapLoginButton() => $(#loginButton).tap();
  Future<void> expectHomeVisible() => $(HomeScreen).waitUntilVisible();
  Future<void> expectLoginError() => $(#loginErrorBanner).waitUntilVisible();
}

// Test — readable, no implementation details
patrolTest('valid credentials navigate to home screen', ($) async {
  final robot = LoginRobot($);
  await robot.enterEmail('user@twake.app');
  await robot.enterPassword('correct-password');
  await robot.tapLoginButton();
  await robot.expectHomeVisible();
});
```

Source: https://patrol.leancode.co | Robot pattern: https://jakewharton.com/testing-robots/

---

## 7. Documentation

### 7.1 Dartdoc — Mandatory

Documentation is mandatory for anything **public and non-trivial**: public API of `core/` modules, structural architecture classes, methods with non-obvious behavior or side effects.

Think of contributors and new developers: what is obvious today will not be in 6 months.

❌ **BAD** — complex method without doc:

```dart
Future<bool> sync(String roomId, {int? since, bool force = false}) async { ... }
```

✅ **GOOD**:

```dart
/// Synchronizes the room state from the Matrix homeserver.
///
/// If [since] is provided, only events after this pagination token
/// are fetched.
/// Pass [force] as `true` to bypass the local cache.
///
/// Returns `true` if new events were received.
/// Throws [NetworkException] if the homeserver is unreachable.
Future<bool> syncRoom(String roomId, {String? since, bool force = false}) async { ... }
```

---

### 7.2 Dartdoc — Recommended

Document when the method name is not enough to understand the behavior, the pre/post-conditions, or the edge cases.

❌ **BAD** — comment redundant with the name:

```dart
/// Gets the user
User? getUser() { ... }
```

✅ **GOOD** — adds what the name doesn't say:

```dart
/// Returns the user from the session cache, without a network call.
/// Returns `null` if no active session exists.
User? getCachedCurrentUser() { ... }
```

---

### 7.3 When not to comment

Don't comment what is self-documenting. A comment that paraphrases the code is noise. An empty comment (a lone `///`) is worse than no comment.

❌ **BAD**:

```dart
/// The user's name
final String userName;

/// Check if user is null
if (user == null) return;
```

✅ **GOOD** — comment the *why*, never the *what*:

```dart
final String userName; // no need

// Matrix spec requires event_id to start with '$'
assert(eventId.startsWith(r'$'), 'Invalid Matrix event ID: $eventId');
```

---

### 7.4 ADRs — Architecture Decision Records

Document decisions that **commit the team long-term** and whose reasoning isn't visible in the code. An ADR answers the question: "why did we make this choice?"

**When to create an ADR:**
- Choice of a structural package (Riverpod vs BLoC, GoRouter vs AutoRoute)
- Architectural decision (feature-first vs layer-first)
- Deliberate trade-off (e.g. no local cache on media)
- Abandoning an approach (e.g. removal of GetIt)

**Format**: `docs/adr/NNNN-short-title.md`

```markdown
# ADR-0001: Adoption of Riverpod for DI and state management

## Context
GetIt made integration tests difficult (GetIt.reset() is fragile).
ChangeNotifier did not handle async states natively.

## Decision
Migrate to Riverpod with @riverpod code generation, feature by feature.

## Consequences
+ Testability via ProviderContainer.overrides
+ Typed providers, autoDispose by default
+ Co-located with their implementation
- Progressive migration: temporary coexistence of GetIt/Riverpod
```

Source: https://adr.github.io

---

## 8. Git & Code Quality

### 8.1 Commit messages

A good Git history is a diagnostic tool, not an activity log. Commit messages must let you understand **why** a change was made — not just what and how.

**Format:**

```
type(scope): Subject in imperative, max 50 characters

Optional body: explains the WHY, not the HOW.
72 characters per line max. Blank line between subject and body.

Refs: TW-1234
```

**Types:**

| Type | Usage |
|---|---|
| `feat` | New feature |
| `fix` | Bug fix |
| `refacto` | Refactoring without behavior change |
| `test` | Adding or modifying tests |
| `docs` | Documentation only |
| `style` | Formatting, no logic change |
| `chore` | Build, dependencies, CI — no production code |

**Scope**: the impacted feature or component, in lowercase (`auth`, `messaging`, `room-list`).

❌ **BAD**:

```
fix stuff
update code
WIP
```

✅ **GOOD**:

```
feat(messaging): Add read receipt indicators on messages

Matrix read receipts were not reflected in the UI. The RoomController
now watches m.read events and updates MessageState.readByUserIds.

Refs: TW-2341
```

```
fix(auth): Prevent login loop when session token expires

The MatrixClient was retrying login indefinitely on 401.
Added exponential backoff and a max retry count of 3.

Refs: TW-1987
```

Source: https://dhwthompson.com/2019/my-favourite-git-commit

---

### 8.2 Branch naming

**If a ticket exists:**
```
feat/TW-0001-typing-indicators
fix/TW-1234-login-loop
refacto/TW-0987-riverpod-migration
```

**Without a ticket:**
```
fix/message-scroll-broken
docs/update-contribution-guide
chore/bump-flutter-3-19
```

---

### 8.3 Atomic commits

Every commit must be **coherent and reversible**. In particular:

- Every dependency upgrade = its own commit, with the required adaptations
- Separate refactoring from behavior changes in distinct commits
- A commit must compile and pass tests — makes `git bisect` easy

---

### 8.4 Pull Requests — Pre-merge checklist

- [ ] `dart format` applied (`dart format --set-exit-if-changed .`)
- [ ] `flutter analyze` — zero warning, zero info ignored without justification
- [ ] Tests added or updated for new behaviors
- [ ] No unintentional `print()`
- [ ] No `TODO` without a referenced ticket
- [ ] PR description: context, resolved problem, screenshots if UI change
- [ ] Breaking changes documented

---

### 8.5 `dart format`

`dart format` is **mandatory** before every commit or PR. Configure it as a pre-commit hook or as a blocking CI check.

```bash
# CI check (fails if not formatted)
dart format --output=none --set-exit-if-changed .

# Local run
dart format .
```

Source: https://dart.dev/tools/dart-format

---

### 8.6 `flutter analyze` — Zero warnings

Goal: **zero warnings, zero unjustified `// ignore`**. A warning ignored without a documented reason is invisible technical debt.

When an `// ignore` is needed, document the why on the same line:

```dart
// ignore: deprecated_member_use — Matrix SDK not yet migrated, ticket TW-1234
final room = client.getRoomById(id);
```

Use `dart fix --apply` to automatically fix lintable issues. Source: https://dart.dev/tools/dart-fix

---

### 8.7 Linter rules

The full `analysis_options.yaml` configuration is in the **Appendix** (§10) at the end of the document — it is stable and rarely consulted day-to-day. Active rules, their rationale, and possible adjustments are documented there.

---

### 8.8 Forked dependencies

The team often need to fork dependencies to fix issue faster in third party code. This result in hard to audit dependencies that do not get maintained. While sometime necessary this practice must be limited and clearly documented. Namely:
 - Comment with the issue for which the fork was needed
 - Link to the upstream PR
 - Rationals in one line of human readable english

## 9. Legacy Management

### 9.1 Boy Scout Rule

**Leave the code in a better state than you found it.** The scope is proportional to the impact:

| Scope | Action |
|---|---|
| Whole file touched | Style: naming, imports, `final`, format |
| Class modified | Structure: responsibilities, splitting |
| Code directly modified | Behavior: architecture, patterns |

Don't refactor what you don't touch — unnecessary risk for no immediate value.

Source: https://www.oreilly.com/library/view/97-things-every/9780596809515/ch08.html

---

### 9.2 Cleanup of utility classes

The principle and examples of well-written utility classes are defined in §2.6. For existing legacy, the actions to take when passing through a file:

- Remove catch-all `Utils` / `Helper` classes — replace them with specialized classes (§2.6)
- Convert static methods into instance methods with a constructor
- Move enums out of `utils/` into their feature or `shared/`
- Move UI logic (`Color`, `Widget`) out of `utils/` into the presentation layer

---

### 9.3 Progressive migration to `@freezed`

All entities and models still using `Equatable` must be migrated to `@freezed`. Migrate feature by feature, starting with domain entities (broadest impact on consistency).

**Recommended order:**
1. Domain entities (impact on all tests and controllers)
2. Presentation states
3. Data-layer models

Each migration = a separate commit:
```
refacto(messaging): Migrate MessageEntity to @freezed
refacto(auth): Migrate AuthState to @freezed
```

---

## 10. Appendix — `analysis_options.yaml`

Reference linter configuration. Stable, rarely modified — consulted to add or understand a rule.

> `source-lines-of-code: 50` applies per **method/function**, consistent with the 300-line-per-file limit — the two measure different things.
> `public_member_api_docs` is disabled — designed for published packages, too verbose for an app.

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - camel_case_types
    - avoid_print
    - constant_identifier_names
    - prefer_final_locals
    - prefer_final_in_for_each
    - require_trailing_commas
    - always_declare_return_types

analyzer:
  language:
    strict-inference: true
    strict-raw-types: true

  errors:
    close_sinks: ignore
    unrelated_type_equality_checks: warning
    collection_methods_unrelated_type: warning
    missing_return: error
    missing_required_param: error
    record_literal_one_positional_no_trailing_comma: error

  exclude:
    - lib/generated_plugin_registrant.dart
    - lib/l10n/*.dart
    - "**.g.dart"

dart_code_metrics:
  metrics:
    cyclomatic-complexity: 20
    number-of-arguments: 4
    maximum-nesting-level: 5
    source-lines-of-code: 50   # per method — consistent with 300 lines/file
    maintainability-index: 40

  rules:
    - always_declare_return_types
    - always_put_required_named_parameters_first
    - always_use_package_imports
    - annotate_overrides
    - avoid_bool_literals_in_conditional_expressions
    - avoid_catches_without_on_clauses
    - avoid_catching_errors
    - avoid_dynamic_calls
    - avoid_empty_else
    - avoid_positional_boolean_parameters
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_unnecessary_containers
    - avoid_unused_constructor_parameters
    - avoid_void_async
    - cancel_subscriptions
    - curly_braces_in_flow_control_structures
    - directives_ordering
    - discarded_futures
    - empty_catches
    - exhaustive_cases
    - hash_and_equals
    - no_literal_bool_comparisons
    - no_logic_in_create_state
    - omit_local_variable_types
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_const_literals_to_create_immutables
    - prefer_final_fields
    - prefer_final_in_for_each
    - prefer_final_locals
    - prefer_is_empty
    - prefer_is_not_empty
    - prefer_null_aware_operators
    - prefer_single_quotes
    - require_trailing_commas
    - sized_box_for_whitespace
    - sort_child_properties_last
    - sort_constructors_first
    - unawaited_futures
    - unnecessary_const
    - unnecessary_lambdas
    - unnecessary_null_checks
    - unnecessary_overrides
    - unnecessary_this
    - unrelated_type_equality_checks
    - use_build_context_synchronously
    - use_colored_box
    - use_enums
    - use_key_in_widget_constructors
    - use_rethrow_when_possible
    - use_super_parameters
    - valid_regexps
    - void_checks

  metrics-exclude:
    - test/**
  rules-exclude:
    - test/**
  anti-patterns:
    - long-method
    - long-parameter-list
```
