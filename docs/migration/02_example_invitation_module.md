# Migration example: Invitation module

> **WIP** — Document in progress.

## Why this module?

The **Invitation** module is the ideal candidate for a first migration example:

- **Small and self-contained**: ~150 lines of UI, no complex cross-dependencies
- **Full stack**: covers all architecture layers
- **3 types of datasources**: Tom server API (Dio), Hive cache, and Matrix SDK (to abstract)
- **Representative**: the pattern appears in all other modules
- **Illustrates a cross-cutting problem**: direct coupling to the Matrix SDK from the UI layer

## Current architecture

### UI layer (Screen)

- `lib/pages/invitation_selection/invitation_selection.dart`
- `lib/pages/invitation_selection/invitation_selection_web.dart`

### State layer

- `lib/domain/app_state/invitation/send_invitation_state.dart`
- `lib/domain/app_state/invitation/generate_invitation_link_state.dart`
- `lib/domain/app_state/invitation/get_invitation_status_state.dart`
- `lib/domain/app_state/invitation/store_invitation_status_state.dart`
- `lib/domain/app_state/invitation/hive_get_invitation_status_state.dart`
- `lib/domain/app_state/invitation/hive_delete_invitation_status_state.dart`

### UseCase layer (Interactors)

- `lib/domain/usecase/invitation/send_invitation_interactor.dart`
- `lib/domain/usecase/invitation/generate_invitation_link_interactor.dart`
- `lib/domain/usecase/invitation/get_invitation_status_interactor.dart`
- `lib/domain/usecase/invitation/store_invitation_status_interactor.dart`
- `lib/domain/usecase/invitation/hive_get_invitation_status_interactor.dart`
- `lib/domain/usecase/invitation/hive_delete_invitation_status_interactor.dart`

### Repository layer (Interface)

- `lib/domain/repository/invitation/invitation_repository.dart`
- `lib/domain/repository/invitation/hive_invitation_status_repository.dart`

### Repository layer (Implementation)

- `lib/data/repository/invitation/invitation_repository_impl.dart`
- `lib/data/repository/invitation/hive_invitation_status_repository_impl.dart`

### DataSource layer (Interface)

- `lib/data/datasource/invitation/invitation_datasource.dart`
- `lib/data/datasource/invitation/hive_invitation_status_datasource.dart`

### DataSource layer (Implementation)

- `lib/data/datasource_impl/invitation/invitation_datasource_impl.dart` _(remote - Tom server via Dio)_
- `lib/data/datasource_impl/invitation/hive_invitation_status_datasource_impl.dart` _(local - Hive cache)_

## Problems identified in the current architecture

### 1. Direct coupling to the Matrix SDK in the screen

The `invitation_selection.dart` screen directly calls the Matrix SDK:

```dart
// ❌ Layer violation — the screen imports package:matrix/matrix.dart
Room get _room => Matrix.of(context).client.getRoomById(_roomId!)!;

List<String> get disabledContactIds => Matrix.of(context).client
    .getRoomById(_roomId!)!
    .getParticipants()
    .map((participant) => participant.id)
    .toList();
```

**Problem**: the presentation layer directly depends on an infrastructure SDK. This prevents unit testing the screen without mocking the entire SDK, and couples every SDK change to UI code.

### 2. `UnbanAndInviteUsersInteractor` outside its domain

The screen uses `UnbanAndInviteUsersInteractor` which:

- Takes a `Room` object from the SDK directly (infrastructure leak into the domain)
- Belongs to the **room/membership** domain, not the invitation domain
- Should take a `roomId` and resolve the room via a datasource

### 3. No Matrix datasource

Unlike the Tom API (abstracted behind `InvitationDatasource` + Dio) and Hive (abstracted behind `HiveInvitationStatusDatasource`), Matrix SDK calls have **no abstraction layer**. This `Matrix.of(context)` pattern is pervasive throughout the entire app.

## Target architecture (after Riverpod 3.0 migration)

### Founding principle: the app NEVER directly depends on the SDK

`package:matrix/matrix.dart` must only be imported in **datasource implementations**. Never in domain, never in presentation.

### New layer: Matrix datasources per business domain

Rather than a monolithic `MatrixDataSource` god-datasource, we split by **business domain**:

```
MatrixMemberDataSource      → getParticipants, inviteUser, banUser, unbanUser
MatrixRoomDataSource        → getRooms, getRoom, joinRoom, leaveRoom
MatrixAuthDataSource        → login, logout, watchAuthState
MatrixMessageDataSource     → getTimeline, sendMessage
...
```

Each datasource:

- **Interface** in `lib/data/datasource/` — never imports `package:matrix`
- **Returns SDK types** (`User`, `Room`, etc.) — this is normal, the datasource speaks the language of its data source
- **Implementation** in `lib/data/datasource_impl/` — the only place that imports the SDK

It is the **Repository** that does the mapping SDK → domain:

- The datasource returns SDK types (e.g. `User` from the Matrix SDK)
- The repository maps to domain entities (e.g. `Member` from the domain)
- The domain and presentation never see SDK types

### Fundamental piece: `MatrixClientProvider`

The Matrix `Client` is a long-lived object (sync loop, DB, encryption). It must be managed by a singleton Riverpod provider:

```dart
@Riverpod(keepAlive: true)
Client matrixClient(Ref ref) {
  // Single instantiation point of the SDK
  // All Matrix datasources receive the Client via injection
}
```

This replaces `Matrix.of(context)` (InheritedWidget) with clean dependency injection.

### Target stack for the Invitation module

```
InvitationScreen (Widget)
  └→ InvitationViewModel (Riverpod Notifier)
       └→ InvitationService
            ├→ SendInvitationUseCase
            │    └→ InvitationRepository (I)
            │         └→ InvitationRepositoryImpl
            │              └→ InvitationDatasource (I) → InvitationDatasourceImpl (Tom API / Dio)
            │
            ├→ GetRoomParticipantsUseCase        ← NEW
            │    └→ MemberRepository (I)         ← NEW
            │         └→ MemberRepositoryImpl    ← NEW
            │              └→ MatrixMemberDataSource (I) → MatrixMemberDataSourceImpl (SDK)  ← NEW
            │
            ├→ InviteUserToRoomUseCase           ← REPLACES UnbanAndInviteUsersInteractor
            │    └→ MemberRepository (I)
            │
            └→ InvitationStatusUseCase
                 └→ HiveInvitationStatusRepository (I)
                      └→ HiveInvitationStatusRepositoryImpl
                           └→ HiveInvitationStatusDatasource (I) → HiveInvitationStatusDatasourceImpl (Hive)
```

The **Service** centralizes business orchestration: it coordinates use cases and exposes high-level methods to the ViewModel. The ViewModel only manages UI state and delegates all business logic to the Service.

### Files to create for the migration

#### Matrix datasource (shared, reusable by other modules)

- `lib/data/datasource/matrix/matrix_member_datasource.dart` _(interface)_
- `lib/data/datasource_impl/matrix/matrix_member_datasource_impl.dart` _(SDK implementation)_

#### Member Repository (shared)

- `lib/domain/repository/member/member_repository.dart` _(interface)_
- `lib/data/repository/member/member_repository_impl.dart` _(implementation)_

#### Riverpod Provider

- `MatrixClientProvider` (singleton, keepAlive)
- `MatrixMemberDataSourceProvider`
- `MemberRepositoryProvider`
- `InvitationViewModelProvider` (Notifier + State)

## Step-by-step migration strategy

### Phase 0 — Foundation (cross-cutting, done once)

1. Create the Riverpod `MatrixClientProvider` that replaces `Matrix.of(context)`
2. Create the first Matrix datasource: `MatrixMemberDataSource` (interface + impl)
3. Create the `MemberRepository` (interface + impl)

### Phase 1 — Invitation module migration

1. Create the `InvitationViewModel` (Riverpod Notifier) with its state
2. Migrate existing interactors to Riverpod use cases
3. Replace `UnbanAndInviteUsersInteractor(room: _room)` with `InviteUserToRoomUseCase(roomId:)`
4. Migrate the screen to consume the ViewModel instead of calling the SDK
5. The screen no longer imports `package:matrix/matrix.dart`

### Phase 2 — Validation

1. Identify and run existing tests — zero regressions
2. Zeus invocation to validate the architecture (reference = GUIDELINES.md)
3. Add ViewModel unit tests via Riverpod `overrideWith`

## Coexistence rule during migration

> **All new code goes through datasources. Old code is migrated when its feature is touched.**

Coexistence of `Matrix.of(context)` (old) + Riverpod datasources (new) is acceptable during the migration period. What is NOT acceptable: new Riverpod code that still hits the SDK directly.

## Migration to Riverpod 3.0
