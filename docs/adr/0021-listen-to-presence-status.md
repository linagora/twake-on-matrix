# 21. Listen to presence status

Date: 2024-04-08

## Status

Accepted

## Context

The status of presence of a user on a direct chat was not stable. By this we mean that it changes multiple times in a small timeline (few seconds).
This was because the UI was listening to `onPresenceChanged`'s stream which is updated in a for loop where there can be multiple items. So if there was 6 items in this loop, the status was updated 6 times.

```dart
  /// Callback will be called on presence updates.
  final CachedStreamController<CachedPresence> onPresenceChanged =
      CachedStreamController();

  for (final newPresence in sync.presence ?? []) {
      final cachedPresence = CachedPresence.fromMatrixEvent(newPresence);
      presences[newPresence.senderId] = cachedPresence;
      // ignore: deprecated_member_use_from_same_package
      onPresence.add(newPresence);
      onPresenceChanged.add(cachedPresence);
  }
```

## Decision

To avoid this problem we created a new stream which purpose is to get the status of presence the closest of current time: `onlatestPresenceChanged` . That's the one who should be listened by the UI.

Here `lastActivePresence` is updated for each items in `sync.presence` list if it is `null` or if the current item's timestamp is after the one in `lastActivePresence`. Then when the loop is over and we are sure to have the right value, we can update `onLatestPresenceChange` with the right value and this way update the UI.

```dart
  /// Callback will be called on presence updates.
  final CachedStreamController<CachedPresence> onPresenceChanged =
    CachedStreamController();

  /// Callback will be called on presence update and return latest value.
  final CachedStreamController<CachedPresence> onlatestPresenceChanged =
    CachedStreamController();

  CachedPresence? lastActivePresence;

  for (final newPresence in sync.presence ?? []) {
    final cachedPresence = CachedPresence.fromMatrixEvent(newPresence);
    presences[newPresence.senderId] = cachedPresence;
    // ignore: deprecated_member_use_from_same_package
    onPresence.add(newPresence);
    onPresenceChanged.add(cachedPresence);

    if (lastActivePresence == null ||
        (cachedPresence.lastActiveTimestamp != null &&
            lastActivePresence.lastActiveTimestamp != null &&
            cachedPresence.lastActiveTimestamp!
                .isAfter(lastActivePresence.lastActiveTimestamp!))) {
      lastActivePresence = cachedPresence;
    }
  }

  if (lastActivePresence != null) {
    onlatestPresenceChanged.add(lastActivePresence);
  }
```