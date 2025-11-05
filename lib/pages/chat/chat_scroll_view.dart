import 'package:collection/collection.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_event_list_item.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:matrix/matrix.dart';

class ChatScrollView extends StatefulWidget {
  const ChatScrollView({
    super.key,
    required this.events,
    required this.controller,
    required this.constraints,
  });

  final List<Event> events;
  final ChatController controller;
  final BoxConstraints constraints;

  @override
  State<ChatScrollView> createState() => _ChatScrollViewState();
}

class _ChatScrollViewState extends State<ChatScrollView> {
  final _top = <Event>[], _bottom = <Event>[];
  ChatController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _bottom.addAll(widget.events);
  }

  /// Checks if two events are the same, considering both eventId and transaction_id.
  /// Returns true if events match by eventId or by transaction_id (for sending/sent events).
  bool _isSameEvent(Event a, Event b) {
    // Compare event IDs
    if (a.eventId == b.eventId) {
      return true;
    }

    // Get transaction IDs from unsigned field
    final aTransactionId = a.unsigned?['transaction_id'] as String?;
    final bTransactionId = b.unsigned?['transaction_id'] as String?;

    // If both have transaction IDs, compare them
    if (aTransactionId != null && bTransactionId != null) {
      return aTransactionId == bTransactionId;
    }

    // Check if one event's eventId matches the other's transaction_id
    // This handles the case where a sending event (with transaction_id) is replaced
    // by a sent event (with eventId matching the transaction_id)
    if (aTransactionId != null && aTransactionId == b.eventId) {
      return true;
    }
    if (bTransactionId != null && bTransactionId == a.eventId) {
      return true;
    }

    return false;
  }

  @override
  void didUpdateWidget(ChatScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.events == oldWidget.events) return;

    final oldEvents = oldWidget.events;
    final newEvents = widget.events;

    // Check if new items are completely different
    final hasCommonItems = oldEvents.any((item) => newEvents.contains(item));

    if (!hasCommonItems) {
      // Completely different list - clear _top and set _bottom to new items
      _top.clear();
      _bottom.clear();
      _bottom.addAll(newEvents);
      return;
    }

    // First, update existing events that may have changed (e.g., sending -> sent)
    _updateExistingEvents(newEvents);

    // Find new items at the start
    int startDiff = 0;
    while (startDiff < newEvents.length &&
        !_isSameEvent(newEvents[startDiff], oldEvents[0])) {
      startDiff++;
    }

    // Find new items at the end
    int endDiff = 0;
    while (endDiff < newEvents.length &&
        !_isSameEvent(
          newEvents[newEvents.length - 1 - endDiff],
          oldEvents[oldEvents.length - 1],
        )) {
      endDiff++;
    }

    // Add new items at the start to _top
    if (startDiff > 0) {
      final newStartItems = newEvents.sublist(0, startDiff);
      _top.addAll(newStartItems.reversed);
    }

    // Add new items at the end to _bottom
    if (endDiff > 0) {
      final newEndItems = newEvents.sublist(newEvents.length - endDiff);
      _bottom.addAll(newEndItems);
    }
  }

  /// Updates existing events in _top and _bottom that have changed.
  /// This handles cases like sending events becoming sent events.
  void _updateExistingEvents(List<Event> newEvents) {
    // Update events in _top
    for (int i = 0; i < _top.length; i++) {
      final matchingEvent = newEvents.firstWhereOrNull(
        (newEvent) => _isSameEvent(_top[i], newEvent),
      );
      if (matchingEvent != null && matchingEvent != _top[i]) {
        _top[i] = matchingEvent;
      }
    }

    // Update events in _bottom
    for (int i = 0; i < _bottom.length; i++) {
      final matchingEvent = newEvents.firstWhereOrNull(
        (newEvent) => _isSameEvent(_bottom[i], newEvent),
      );
      if (matchingEvent != null && matchingEvent != _bottom[i]) {
        _bottom[i] = matchingEvent;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const centerKey = ValueKey('ChatEventList-center-key');
    final horizontalPadding = TwakeThemes.isColumnMode(context) ? 16.0 : 0.0;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 8.0,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: InViewNotifierCustomScrollView(
        isInViewPortCondition: controller.isInViewPortCondition,
        center: centerKey,
        anchor: 1,
        controller: controller.scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _bottom.length) {
                  if (controller.timeline!.isRequestingHistory) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (controller.timeline!.canRequestHistory) {
                    return Center(
                      child: IconButton(
                        onPressed: controller.requestHistory,
                        icon: const Icon(Icons.refresh_outlined),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final currentEventIndex = widget.events.indexOf(_bottom[index]);
                final previousEvent = currentEventIndex > 0
                    ? widget.events[currentEventIndex - 1]
                    : null;
                final nextEvent = currentEventIndex < widget.events.length - 1
                    ? widget.events[currentEventIndex + 1]
                    : null;
                return ChatEventListItem(
                  event: _bottom[index],
                  index: currentEventIndex + 1,
                  controller: controller,
                  constraints: widget.constraints,
                  previousEvent: previousEvent,
                  nextEvent: nextEvent,
                );
              },
              childCount: _bottom.length + 1,
            ),
          ),
          SliverList(
            key: centerKey,
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == _top.length) {
                  if (controller.timeline!.isRequestingFuture) {
                    return const Center(
                      child: CupertinoActivityIndicator(),
                    );
                  }
                  if (controller.timeline!.canRequestFuture) {
                    return Center(
                      child: IconButton(
                        onPressed: controller.requestFuture,
                        icon: const Icon(Icons.refresh_outlined),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }
                final currentEventIndex = widget.events.indexOf(_top[index]);
                final previousEvent = currentEventIndex > 0
                    ? widget.events[currentEventIndex - 1]
                    : null;
                final nextEvent = currentEventIndex < widget.events.length - 1
                    ? widget.events[currentEventIndex + 1]
                    : null;
                return ChatEventListItem(
                  event: _top[index],
                  index: currentEventIndex + 1,
                  controller: controller,
                  constraints: widget.constraints,
                  previousEvent: previousEvent,
                  nextEvent: nextEvent,
                );
              },
              childCount: _top.length + 1,
            ),
          ),
        ],
      ),
    );
  }
}
