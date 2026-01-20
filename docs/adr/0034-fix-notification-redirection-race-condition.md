# 34. Fix Notification Redirection Race Condition

Date: 2026-01-15

## Status

Accepted

## Context

Users reported that when clicking a notification to navigate to a room, sometimes the messages would fail to load, and the "load more" function would not trigger.
Investigation revealed a race condition in `ChatController`:

- The timeline loading logic (`_tryLoadTimeline`) was called in `initState` but used the `room` variable.
- The `room` variable was previously initialized in the `build` method of `ChatView`.
- When navigating via deep link or notification, the build method might not have run before `initState` tried to access `room`, leading to initialization with a null or stale room, or simply failing to load the correct timeline for the context event.

Additionally, when switching between rooms via notifications (e.g., being in Room A and clicking a notification for Room B), the `ChatController` did not cleanly detect the change and re-initialize the timeline, leading to mixed state.

## Decision

We decided to move the room initialization logic to the earliest possible point in the `ChatController` lifecycle and explicitly handle room updates.

### 1. Early Room Initialization

Moved `room` initialization from `ChatView.build` to `ChatController.initState`.

- A new method `_initRoom()` was created to initialize `matrix` client and `room`.
- `_initRoom()` is called at the beginning of `initState`.

### 2. Explicit Update Handling

Updated `didUpdateWidget` in `ChatController`:

- Checks if `widget.roomId` has changed compared to `oldWidget.roomId`.
- If changed, it performs a full room state reset and re-initialization:
  - Unsubscribes existing room event listeners (canceling any active timers or streams).
  - Clears and re-fetches pinned events.
  - Resets cached presence and participants data.
  - Calls `_initRoom()` to switch the internal matrix room reference.
  - Re-subscribes to room listeners for the new room.
  - Calls `_tryLoadTimeline()` to load the initial messages for the new room.
- This ensures all room-scoped resources are fully refreshed and correctly isolated on room switch.

### 3. Removal of Side-Effects from Build

Removed the assignment of `controller.room` inside `ChatView.build`. The build method now strictly reads from the controller and returns early if `room` is null (though `initState` protections make this unlikely to happen in a visible way).

## Consequences

### Positive

- **Reliability:** Notifications and deep links now reliably load the correct room and timeline.
- **Correctness:** Timeline loading (`_tryLoadTimeline`) now is guaranteed to have a valid `room` instance.
- **Maintainability:** `ChatView.build` is purer and has fewer side effects. State initialization is where it belongs, in `initState`.

### Negative

- **Boilerplate:** We have to manually handle `didUpdateWidget` to detect changes that `build` would have picked up automatically (though incorrectly for this use case).

### Files Modified

1. `lib/pages/chat/chat.dart` - `initState`, `_initRoom`, `didUpdateWidget`.
2. `lib/pages/chat/chat_view.dart` - Removed initialization logic from `build`.
