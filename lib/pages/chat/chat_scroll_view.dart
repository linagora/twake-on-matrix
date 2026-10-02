import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_event_list_item.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_list_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:inview_notifier_list/inview_notifier_list.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
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
  Map<String, int> _bottomIndexMap = const {};
  Map<String, int> _topIndexMap = const {};
  List<Event> _visibleEvents = const [];
  Map<String, int> _visiblePosition = const {};

  @override
  void initState() {
    super.initState();
    _currentEvents = List<Event>.from(widget.events)
      ..sort((a, b) => b.originServerTs.compareTo(a.originServerTs));
    _bottom.addAll(_currentEvents);
    _indexEvents();
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

    // Snapshot before lists change. History grows minScrollExtent; without
    // restoring pixels the viewport/thumb can jump (e.g. 30% → 10%).
    final scroll = controller.scrollController;
    final savedPixels = result.hasHistoryEvents && scroll.hasClients
        ? scroll.position.pixels
        : null;

    // Update the current events
    _currentEvents = newEvents;

    // Update the lists before re-indexing (bottom/top maps need final order).
    _top
      ..clear()
      ..addAll(result.top);
    _bottom
      ..clear()
      ..addAll(result.bottom);
    _indexEvents();

    // Scroll to bottom if needed
    if (result.shouldScrollToBottom) {
      _scrollToBottom();
    } else if (result.hasHistoryEvents) {
      _restoreScrollAfterHistory(savedPixels);
      // Live messages may arrive in the same sync — still update the button.
      if (result.hasLiveEvents) {
        _handleLiveEventsArrived();
      }
    } else if (result.hasLiveEvents) {
      _handleLiveEventsArrived();
    }
  }

  /// Keep the same absolute [ScrollPosition.pixels] after history append.
  ///
  /// Center + anchor already aim to preserve content, but extent/layout
  /// corrections after `_bottom` grows can still shift pixels toward
  /// [ScrollPosition.minScrollExtent]. Re-apply the pre-sync offset once
  /// the new metrics are laid out.
  void _restoreScrollAfterHistory(double? savedPixels) {
    if (savedPixels == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final scroll = controller.scrollController;
      if (!scroll.hasClients) return;
      final position = scroll.position;
      final target = savedPixels.clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if ((position.pixels - target).abs() <= 0.5) return;
      scroll.jumpTo(target);
    });
  }

  /// Live (newer) events only — never use this for history appends.
  void _handleLiveEventsArrived() {
    // Snapshot whether we're at the bottom NOW (before layout adds the new
    // message and grows maxScrollExtent), then act after layout.
    final wasAtBottom =
        controller.scrollController.hasClients &&
        (controller.scrollController.position.maxScrollExtent -
                controller.scrollController.position.pixels) <=
            2.0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!controller.scrollController.hasClients) return;
      if (wasAtBottom) {
        controller.scrollController.jumpTo(
          controller.scrollController.position.maxScrollExtent,
        );
        controller.showScrollDownButtonNotifier.value = false;
      } else {
        controller.showScrollDownButtonNotifier.value = true;
      }
    });
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

  void _indexEvents() {
    _eventIndexMap = {
      for (var i = 0; i < _currentEvents.length; i++)
        _currentEvents[i].eventId: i,
    };
    _bottomIndexMap = {
      for (var i = 0; i < _bottom.length; i++) _bottom[i].eventId: i,
    };
    _topIndexMap = {for (var i = 0; i < _top.length; i++) _top[i].eventId: i};
    _visibleEvents = [
      for (final event in _currentEvents)
        if (event.isVisibleInGui) event,
    ];
    _visiblePosition = {
      for (var i = 0; i < _visibleEvents.length; i++)
        _visibleEvents[i].eventId: i,
    };
  }

  int? _findBottomChildIndex(Key key) {
    if (key is! ValueKey<String>) return null;
    return _bottomIndexMap[key.value];
  }

  int? _findTopChildIndex(Key key) {
    if (key is! ValueKey<String>) return null;
    return _topIndexMap[key.value];
  }

  @override
  Widget build(BuildContext context) {
    final centerKey = ChatKeys.eventListCenter.valueKey;
    final horizontalPadding = TwakeThemes.isColumnMode(context)
        ? LinagoraSpacing.base * 2
        : 0.0;
    final horizontalPaddingInsets = EdgeInsets.symmetric(
      horizontal: horizontalPadding,
    );

    return InViewNotifierCustomScrollView(
      isInViewPortCondition: controller.isInViewPortCondition,
      center: centerKey,
      anchor: 1,
      // Raised during jump-to-event so off-cache rows mount AutoScrollTags
      // before layout-aware reveal (see chat_scroll_to_event_mixin.dart).
      cacheExtent: controller.jumpListCacheExtent,
      controller: controller.scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: horizontalPaddingInsets,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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

                final visiblePos = _visiblePosition[currentEvent.eventId];
                final previousEvent = visiblePos != null && visiblePos > 0
                    ? _visibleEvents[visiblePos - 1]
                    : null;
                final nextEvent =
                    visiblePos != null && visiblePos < _visibleEvents.length - 1
                    ? _visibleEvents[visiblePos + 1]
                    : null;
                return ChatEventListItem(
                  key: ValueKey(currentEvent.eventId),
                  event: currentEvent,
                  index: currentEventIndex + 1,
                  controller: controller,
                  constraints: widget.constraints,
                  previousEvent: previousEvent,
                  nextEvent: nextEvent,
                );
              },
              childCount: _bottom.length + 1,
              findChildIndexCallback: _findBottomChildIndex,
            ),
          ),
        ),
        SliverPadding(
          key: centerKey,
          padding: horizontalPaddingInsets,
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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

                final visiblePos = _visiblePosition[currentEvent.eventId];
                final previousEvent = visiblePos != null && visiblePos > 0
                    ? _visibleEvents[visiblePos - 1]
                    : null;
                final nextEvent =
                    visiblePos != null && visiblePos < _visibleEvents.length - 1
                    ? _visibleEvents[visiblePos + 1]
                    : null;
                return ChatEventListItem(
                  key: ValueKey(currentEvent.eventId),
                  event: currentEvent,
                  index: currentEventIndex + 1,
                  controller: controller,
                  constraints: widget.constraints,
                  previousEvent: previousEvent,
                  nextEvent: nextEvent,
                );
              },
              childCount: _top.length + 1,
              findChildIndexCallback: _findTopChildIndex,
            ),
          ),
        ),
      ],
    );
  }
}
