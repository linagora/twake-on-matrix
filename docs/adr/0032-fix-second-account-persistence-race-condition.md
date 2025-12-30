# 32. Fix Second Account Persistence Race Condition and Database Mismatch

Date: 2025-12-10

## Status

Accepted

## Context

- We change db from hive to sqfite alongsite with using upstream matrix sdk
- When users attempted to add a second account to the application, the account was not being persisted correctly. Investigation revealed two critical issues:

### Issue 1: Race Condition in InitClientDialog

The `InitClientDialog` widget executes a login future and listens for client login state changes via stream. The problem occurred because `widget.future()` would complete and call `_handleFunctionOnDone()` **before** the `onClientLoginStateChanged` stream event fired. This meant:

- The dialog would pop before navigation
- Both `_clientFirstLoggedIn` and `_clientAddAnotherAccount` remained `null`
- No navigation occurred
- User was stuck on the homeserver picker screen

### Issue 2: Database Name Mismatch

When creating a login client in `Matrix.getLoginClient()`, the code used a fallback database with a generic name. Later, when `ClientManager.getClients()` reinitializes clients, it creates databases based on the client's name. This mismatch meant the client couldn't access its persisted data, causing the second account to fail persistence.

### Issue 3: Database Leaks

When users cancelled login or encountered errors, temporary databases created during the login flow were never cleaned up, leading to orphaned database files.

## Decision

### 1. Completer-Based Synchronization in InitClientDialog

Added a `Completer` in `lib/pages/bootstrap/init_client_dialog.dart` to synchronize the login future with the stream event:

- Added `final Completer _loginCompleter = Completer()`
- Complete the Completer when login state event fires (with `isCompleted` check to prevent double-completion)
- Wait for the Completer in `_handleFunctionOnDone()` with 30-second timeout
- Add `mounted` check before navigation
- Complete with error in `_handleFunctionOnError()`

### 2. Database Name Consistency

Modified `lib/widgets/matrix.dart`:

- Added optional `database` parameter to `getLoginClient()`
- Extract client name from database if provided, otherwise generate using `microsecondsSinceEpoch`
- Made `addClientNameToStore()` call awaited in `_handleAddAnotherAccount()`

Modified `lib/pages/homeserver_picker/homeserver_picker.dart` and `lib/pages/twake_welcome/twake_welcome.dart`:

- Create temporary database with proper client name before calling `getLoginClient()`
- Pass database to both `getLoginClient()` calls (first for validation, second for actual login)

### 3. TemporaryDatabaseMixin for Cleanup

Created `lib/presentation/mixins/temporary_database_mixin.dart` with:

- `createTemporaryDatabase()` - Creates database with unique client name using `microsecondsSinceEpoch`
- `cleanupTemporaryDatabase()` - Safely deletes database with error handling
- `disposeTemporaryDatabaseMixin()` - Cleanup method for dispose

Updated `lib/pages/homeserver_picker/homeserver_picker.dart` and `lib/pages/twake_welcome/twake_welcome.dart`:

- Added `TemporaryDatabaseMixin` to controller
- Call `createTemporaryDatabase()` at start of login flow
- Call `cleanupTemporaryDatabase()` in catch blocks when errors occur
- Call `cleanupTemporaryDatabase()` when validation fails (homeserver already exists)
- Call `disposeTemporaryDatabaseMixin()` in dispose method

## Consequences

### Positive

1. Second account persistence now works correctly
2. Race condition resolved with Completer-based synchronization
3. Database names consistent throughout client lifecycle
4. No database leaks - cleaned up on errors, cancellations, and validation failures
5. Better error handling with timeout and mounted checks
6. Code reuse via TemporaryDatabaseMixin eliminates duplication
7. Microsecond timestamps reduce collision risk

### Negative

1. Additional complexity with Completer pattern
2. Slight memory overhead from database references

### Known Considerations

- 30-second timeout may need adjustment for slow networks
- `disposeTemporaryDatabaseMixin()` calls cleanup without awaiting (synchronous constraint of dispose)
- Other login flows can adopt this pattern by adding `TemporaryDatabaseMixin`

### Files Modified/Created

1. `lib/pages/bootstrap/init_client_dialog.dart` - Completer synchronization, timeout, mounted checks
2. `lib/pages/homeserver_picker/homeserver_picker.dart` - TemporaryDatabaseMixin, cleanup on errors
3. `lib/pages/twake_welcome/twake_welcome.dart` - TemporaryDatabaseMixin, cleanup on errors
4. `lib/widgets/matrix.dart` - Database parameter, client name from database
5. `lib/presentation/mixins/temporary_database_mixin.dart` - New mixin for database lifecycle (created)
