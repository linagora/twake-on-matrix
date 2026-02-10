import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/pages/chat/chat.dart';
import 'package:fluffychat/pages/chat/chat_event_list_item.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_list_extension.dart';
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
  bool _wasRequestingFuture = false;
  List<Event> _currentEvents = [];
  late Map<String, int> _eventIndexMap;

  @override
  void initState() {
    super.initState();
    _currentEvents = List<Event>.from(widget.events)
      ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs));
    _eventIndexMap = {
      for (var i = 0; i < _currentEvents.length; i++)
        _currentEvents[i].eventId: i,
    };
    _bottom.addAll(_currentEvents);
  }

  @override
  void didUpdateWidget(ChatScrollView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Track the previous requestingFuture state
    final currentIsRequestingFuture =
        controller.timeline?.isRequestingFuture ?? false;
    final wasRequestingFutureBeforeUpdate = _wasRequestingFuture;
    _wasRequestingFuture = currentIsRequestingFuture;

    if (widget.events == oldWidget.events) return;

    final newEvents = List<Event>.from(widget.events)
      ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs));

    // Use the extension to sync event lists
    final result = EventListExtension.syncEventLists(
      oldEvents: _currentEvents,
      newEvents: newEvents,
      currentTop: _top,
      currentBottom: _bottom,
      wasRequestingFuture: wasRequestingFutureBeforeUpdate,
    );

    // Update the current events
    _currentEvents = newEvents;
    _eventIndexMap = {
      for (var i = 0; i < _currentEvents.length; i++)
        _currentEvents[i].eventId: i,
    };

    // Update the lists
    _top
      ..clear()
      ..addAll(result.top);
    _bottom
      ..clear()
      ..addAll(result.bottom);

    // Scroll to bottom if needed
    if (result.shouldScrollToBottom) {
      _scrollToBottom();
    }
  }

  /// Scrolls to the bottom of the chat to show new messages.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!controller.scrollController.hasClients) return;

      controller.scrollController.jumpTo(
        controller.scrollController.position.maxScrollExtent,
      );
      controller.showScrollDownButtonNotifier.value = false;
    });
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
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _bottom.length) {
                if (controller.timeline!.isRequestingHistory) {
                  return const Center(child: CupertinoActivityIndicator());
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
              final currentEvent = _bottom[index];
              final currentEventIndex =
                  _eventIndexMap[currentEvent.eventId] ?? -1;

              // If event is not in _currentEvents anymore, skip rendering it
              if (currentEventIndex == -1) {
                return const SizedBox.shrink();
              }

              final previousEvent = currentEventIndex > 0
                  ? _currentEvents[currentEventIndex - 1]
                  : null;
              final nextEvent = currentEventIndex < _currentEvents.length - 1
                  ? _currentEvents[currentEventIndex + 1]
                  : null;
              return ChatEventListItem(
                event: currentEvent,
                index: currentEventIndex + 1,
                controller: controller,
                constraints: widget.constraints,
                previousEvent: previousEvent,
                nextEvent: nextEvent,
              );
            }, childCount: _bottom.length + 1),
          ),
          SliverList(
            key: centerKey,
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index == _top.length) {
                if (controller.timeline!.isRequestingFuture) {
                  return const Center(child: CupertinoActivityIndicator());
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
              final currentEvent = _top[index];
              final currentEventIndex =
                  _eventIndexMap[currentEvent.eventId] ?? -1;

              // If event is not in _currentEvents anymore, skip rendering it
              if (currentEventIndex == -1) {
                return const SizedBox.shrink();
              }

              final previousEvent = currentEventIndex > 0
                  ? _currentEvents[currentEventIndex - 1]
                  : null;
              final nextEvent = currentEventIndex < _currentEvents.length - 1
                  ? _currentEvents[currentEventIndex + 1]
                  : null;
              return ChatEventListItem(
                event: currentEvent,
                index: currentEventIndex + 1,
                controller: controller,
                constraints: widget.constraints,
                previousEvent: previousEvent,
                nextEvent: nextEvent,
              );
            }, childCount: _top.length + 1),
          ),
        ],
      ),
    );
  }
}
