# 32. Refactor sharing intent and universal link handling

Date: 2025-12-15
Updated: 2025-12-16

## Status

Accepted

## Context

The previous implementation of sharing intents and universal links had several architectural issues:

1. **Timing Problem**: `getInitialMedia()` and `getInitialLinkString()` were being called immediately during app initialization, before the Matrix client completed its first sync. This caused shared content to be processed with incomplete room data, leading to potential failures or incorrect behavior.

2. **Non-logged-in State**: When the app was awakened from background while not logged in, there was no mechanism to cache and defer the processing of shared content until after login and sync completion.

3. **Race Conditions**: The stream listeners and initial intent handling were intermingled, making it difficult to reason about the order of operations and leading to potential race conditions.

4. **Scattered Logic**: The sharing intent initialization was called from multiple places in the codebase (matrix.dart, app_adaptive_scaffold_body.dart) without clear separation of concerns.

## Decision

Implement a unified caching approach for sharing intent and universal link handling:

### Architecture

**On app initialization** (`setupSharingIntentStreams()` called from `initMatrix()`):
1. Set up both file and URI stream listeners immediately
2. Fetch initial values asynchronously (non-blocking):
   - `getInitialMedia()` for files shared when app was terminated
   - `getInitialLinkString()` for universal links when app was terminated
3. Stream behavior depends on sync state (`matrixState.waitForFirstSync`):
   - **If already synced**: Process incoming files/URIs immediately
   - **If not yet synced**: Cache using last-write-wins (latest file/URI overwrites previous)
4. Initial values are always cached (processed after sync)

**After `_trySync()` completes** (`processCachedSharingIntents()` called from `chat_list.dart`):
- Process cached files (if any)
- Process cached URIs (if any)
- Both can be processed simultaneously as they don't conflict
- Clear caches after processing

### Implementation

**lib/pages/chat_list/receive_sharing_intent_mixin.dart**:
- `_cachedSharedMediaFiles`: Stores the latest shared files
- `_cachedSharedUri`: Stores the latest shared URI
- `setupSharingIntentStreams()`: Sets up streams and fetches initial values, all update caches
- `processCachedSharingIntents()`: Processes and clears caches after sync

**lib/widgets/matrix.dart**:
- `_hasSetupSharingStreams`: Ensures streams are set up only once
- `_setupSharingStreamsOnce()`: Called during `initMatrix()` to initialize caching
- `dispose()`: Cancels all stream subscriptions

**lib/pages/chat_list/chat_list.dart**:
- `_waitForFirstSyncAfterLogin()`: Calls `processCachedSharingIntents()` after sync
- `_waitForFirstSync()`: Calls `processCachedSharingIntents()` after sync

## Consequences

### Positive

1. **Correct Timing**: Shared content is processed only after the Matrix client completes its first sync, ensuring all room data is available

2. **Unified Approach**: Single caching mechanism handles all scenarios (terminated/background, logged-in/not-logged-in), simplifying the logic

3. **No Race Conditions**: Initial values and stream values update the same cache, eliminating double-processing issues

4. **Independent File and URI Caching**: Files and URIs are cached separately and can both be processed simultaneously

5. **Last-write-wins Strategy**:
   - Only the most recent file is cached
   - Only the most recent URI is cached
   - Files and URIs don't override each other

6. **Proper Resource Management**: All stream subscriptions are canceled in the dispose method

7. **Simple Code Path**: Single flow handles all scenarios without conditional branching

### Potential Issues

1. **User Experience**:
   - If a user shares multiple files before sync, only the last file is processed
   - If a user shares multiple URIs before sync, only the last URI is processed
   - This is intentional but should be understood

2. **Testing**: The new flow requires testing multiple scenarios:
   - Sharing files while logged in (terminated and background states)
   - Sharing URIs while logged in (terminated and background states)
   - Sharing files while not logged in (terminated and background states)
   - Sharing URIs while not logged in (terminated and background states)
   - Sharing both files and URIs before sync
   - Multiple shares in quick succession before sync

3. **Debugging**: Comprehensive logging helps trace the flow through different scenarios

### Issues Addressed

1. **Double-opening of rooms from universal links**: Universal links now update a single cache that is processed once after sync, preventing duplicate processing

2. **Lost links when app not logged in**: Both file and URI streams are set up immediately on app initialization, ensuring all sharing intents are captured regardless of login state

3. **Processing before sync completion**: All cached content is processed only after `_trySync()` completes, ensuring room data is available

### Maintenance

- All sharing intent logic is centralized in `ReceiveSharingIntentMixin`
- Method comments document the caching flow
- Single code path handles all scenarios without complex conditionals

## Update 2025-12-16: Race Condition Fix

### Issue

A critical race condition was identified where initial sharing intents from cold start (app terminated state) could be lost:

1. `setupSharingIntentStreams()` was called synchronously during `initMatrix()`
2. Initial values were fetched asynchronously via `.then()` callbacks without awaiting
3. If sync completed quickly (e.g., from cached data), `processCachedSharingIntents()` would execute before initial values arrived
4. The cache would be empty, so nothing would be processed
5. Later when initial values arrived, they would populate the cache, but `processCachedSharingIntents()` had already run
6. **Result**: User's shared file/link from cold start was permanently lost

This race condition was particularly likely in scenarios with fast sync (locally cached data) and is guaranteed to occur since `getMediaStream()` and `getInitialMedia()` are **separate data sources**:
- `getMediaStream()`: Only emits shares arriving **while app is in memory**
- `getInitialMedia()`: Only retrieves the share that **launched the app from terminated state**

These do not overlap, so if `getInitialMedia()` completes after `processCachedSharingIntents()`, the data is irretrievably lost.

### Decision

Changed `setupSharingIntentStreams()` to async and await both initial value calls:

**Before:**
```dart
void setupSharingIntentStreams() {
  // ... stream setup ...

  // Fire and forget (race condition)
  ReceiveSharingIntent.instance.getInitialMedia().then((files) { ... });
  appLinks.getInitialLinkString().then((uri) { ... });
}
```

**After:**
```dart
Future<void> setupSharingIntentStreams() async {
  // ... stream setup ...

  // MUST await to prevent race condition
  final files = await ReceiveSharingIntent.instance.getInitialMedia();
  // ... cache files ...

  final uri = await appLinks.getInitialLinkString();
  // ... cache uri ...
}
```

### Changes

1. **lib/pages/chat_list/receive_sharing_intent_mixin.dart**:
   - Changed `setupSharingIntentStreams()` to `Future<void>` and await initial values
   - Added documentation explaining the race condition prevention

2. **lib/widgets/matrix.dart**:
   - Changed `_setupSharingStreamsOnce()` to `Future<void>` and await `setupSharingIntentStreams()`
   - Changed `initMatrix()` to async and await `_setupSharingStreamsOnce()`

### Consequences

**Positive:**
- **Guaranteed correctness**: Initial sharing intents are always cached before sync completes
- **No data loss**: Cold start shares are never lost regardless of sync speed
- **Deterministic behavior**: Removes timing-dependent bugs

**Trade-offs:**
- **Slight initialization delay**: App initialization now waits for initial intent retrieval (~10-100ms typically)
- **Acceptable cost**: Reading initial intents is a fast local operation, and correctness is more important than minimal startup delay
