import 'dart:async';

import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

/// Mixin that automatically marks messages as read based on what the user sees.
///
/// This mixin tracks visible events and marks them as read after a 2-second
/// debounce. It respects the fullyRead marker to avoid skipping unread messages.
///
/// Usage:
/// 1. Add mixin to your controller: `with AutoMarkAsReadMixin`
/// 2. Call `initAutoMarkAsReadMixin()` in initState()
/// 3. Call `disposeAutoMarkAsReadMixin()` in dispose()
/// 4. Call `onEventVisible(event)` when events become visible
/// 5. Implement required getters: context, room, timeline, setReadMarker
mixin AutoMarkAsReadMixin {
  final _autoMarkAsReadDebouncer =
      Debouncer<String?>(const Duration(seconds: 2), initialValue: null);
  String? _newestVisibleEventId;
  StreamSubscription? _autoMarkAsReadSubscription;

  /// Required getters that the implementing class must provide
  BuildContext get context;
  Room? get room;
  Timeline? get timeline;

  /// Required method that the implementing class must provide
  void setReadMarker({String? eventId});

  /// Initialize the auto-mark-as-read functionality.
  /// Call this in initState().
  void initAutoMarkAsReadMixin() {
    _autoMarkAsReadSubscription =
        _autoMarkAsReadDebouncer.values.listen(_performAutoMarkAsRead);
  }

  /// Called when an event becomes visible on screen.
  /// Tracks the newest (furthest down) event the user has seen.
  /// Only updates if the new event is newer than the previously tracked one.
  void onEventVisible(Event event) {
    final timeline = this.timeline;
    if (timeline == null || timeline.events.isEmpty) return;

    // Find the index of the new visible event
    final newEventIndex = timeline.events.indexWhere(
      (e) => e.eventId == event.eventId,
    );
    if (newEventIndex == -1) return;

    // If we haven't tracked any event yet, or this event is newer (lower index),
    // update our tracked event
    if (_newestVisibleEventId == null) {
      _newestVisibleEventId = event.eventId;
      _autoMarkVisibleMessagesAsRead();
    } else {
      final currentNewestIndex = timeline.events.indexWhere(
        (e) => e.eventId == _newestVisibleEventId,
      );

      // Lower index = newer event (index 0 is newest in timeline.events)
      if (currentNewestIndex == -1 || newEventIndex < currentNewestIndex) {
        _newestVisibleEventId = event.eventId;
        _autoMarkVisibleMessagesAsRead();
      }
    }
  }

  /// Automatically marks messages as read based on what the user can see on screen.
  /// This is called when scrolling or when new messages arrive.
  /// It has a 2-second debounce to avoid excessive API calls.
  void _autoMarkVisibleMessagesAsRead() {
    _autoMarkAsReadDebouncer.value = _newestVisibleEventId;
  }

  void _performAutoMarkAsRead(String? eventId) {
    if (eventId == null) return;
    if (room == null) return;
    if (!Matrix.of(context).webHasFocus) return;

    final timeline = this.timeline;
    if (timeline == null || timeline.events.isEmpty) return;

    // Only mark as read if this event is after the fullyRead marker
    final fullyRead = room?.fullyRead;
    if (fullyRead != null && fullyRead.isNotEmpty) {
      final fullyReadIndex = timeline.events.indexWhere(
        (e) => e.eventId == fullyRead,
      );

      // If fullyRead marker exists but is not in current timeline,
      // it means there are older unread messages we haven't loaded yet.
      // Don't auto-mark anything in this case to avoid skipping unread messages.
      if (fullyReadIndex == -1) {
        return;
      }

      final lastVisibleIndex = timeline.events.indexWhere(
        (e) => e.eventId == eventId,
      );

      // In timeline.events, index 0 is newest, so if fullyReadIndex <= lastVisibleIndex,
      // it means fullyRead is newer or same as what we're trying to mark
      if (lastVisibleIndex != -1 && fullyReadIndex <= lastVisibleIndex) {
        return; // Don't mark older messages as read
      }
    }

    setReadMarker(eventId: eventId);
    // Reset tracked event after marking as read
    _newestVisibleEventId = null;
  }

  /// Clean up resources.
  /// Call this in dispose().
  void disposeAutoMarkAsReadMixin() {
    _autoMarkAsReadSubscription?.cancel();
    _autoMarkAsReadDebouncer.cancel();
  }
}
