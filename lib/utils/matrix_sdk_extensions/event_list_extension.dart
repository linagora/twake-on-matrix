import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/clipboard.dart';
import 'package:twake_chat/utils/logging/sentry_tracked_events.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/filtered_timeline_extension.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:matrix/matrix.dart';

/// Result of syncing event lists between old and new states.
class EventListSyncResult extends Equatable {
  const EventListSyncResult({
    required this.top,
    required this.bottom,
    required this.shouldScrollToBottom,
    required this.hasNewEvents,
  });

  final List<Event> top;
  final List<Event> bottom;
  final bool shouldScrollToBottom;

  /// Whether new events were added during this sync (from any sender).
  final bool hasNewEvents;

  @override
  List<Object?> get props => [top, bottom, shouldScrollToBottom, hasNewEvents];
}

/// Extension for managing and syncing lists of Matrix events.
/// Provides efficient operations for detecting changes, additions, and removals.
extension EventListExtension on List<Event> {
  List<Event> get copyableTextEvents => where(
    (event) =>
        event.type == EventTypes.Message &&
        !event.redacted &&
        {
          MessageTypes.Text,
          MessageTypes.Notice,
          MessageTypes.Emote,
        }.contains(event.messageType),
  ).sortedBy((event) => event.originServerTs);

  Future<void> copyTexts(BuildContext context, Timeline timeline) async {
    final text = copyableTextEvents
        .map((event) => event.getSelectedEventString(context, timeline))
        .where((text) => text.isNotEmpty)
        .join('\n');
    if (text.isEmpty) return;
    await TwakeClipboard.instance.copyText(text);
    if (!context.mounted) return;
    TwakeSnackBar.show(context, L10n.of(context)!.textCopiedToClipboard);
  }

  /// Builds a map of events for O(1) lookup by eventId and transactionId.
  /// Returns a map where keys are eventId/transactionId and values are the events.
  static Map<String, Event> buildEventMap(List<Event> events) {
    final map = <String, Event>{};
    for (final event in events) {
      // Add by eventId
      map[event.eventId] = event;

      // Add by transactionId if available
      final transactionId = event.unsigned?['transaction_id'] as String?;
      if (transactionId != null) {
        map[transactionId] = event;
      }
    }
    return map;
  }

  /// Splits [newEvents] around the centered event, so events landing between
  /// two shown ones are not dropped.
  static EventListSyncResult syncEventLists({
    required List<Event> oldEvents,
    required List<Event> newEvents,
    required List<Event> currentTop,
    required List<Event> currentBottom,
    required bool wasRequestingFuture,
  }) {
    final newEventsMap = buildEventMap(newEvents);
    bool isKept(Event event) => event.findEventInMap(newEventsMap) != null;

    final bottomAnchor = currentBottom.firstWhereOrNull(isKept);
    final anchor = (bottomAnchor ?? currentTop.firstWhereOrNull(isKept))
        ?.findEventInMap(newEventsMap);
    final anchorIndex = anchor == null
        ? -1
        : newEvents.indexWhere((event) => identical(event, anchor));

    if (anchorIndex == -1) return _reset(oldEvents, newEvents);

    final splitIndex = bottomAnchor != null ? anchorIndex : anchorIndex + 1;
    final shownEventsMap = buildEventMap([...currentTop, ...currentBottom]);
    bool isAdded(Event event) => event.findEventInMap(shownEventsMap) == null;
    final top = newEvents.sublist(0, splitIndex).reversed.toList();
    final newestShown = currentTop.lastOrNull ?? currentBottom.first;

    return EventListSyncResult(
      top: top,
      bottom: newEvents.sublist(splitIndex),
      shouldScrollToBottom:
          !wasRequestingFuture &&
          top.any(
            (event) =>
                isAdded(event) &&
                event.originServerTs.isAfter(newestShown.originServerTs) &&
                event.isVisibleInGui &&
                event.isOwnMessage,
          ),
      hasNewEvents: newEvents.any(isAdded),
    );
  }

  static EventListSyncResult _reset(
    List<Event> oldEvents,
    List<Event> newEvents,
  ) {
    if (oldEvents.isNotEmpty && newEvents.isNotEmpty) {
      final oldNewest = oldEvents.first.eventId;
      final newNewest = newEvents.first.eventId;
      if (oldNewest != newNewest) {
        Logs().d(
          '${SentryTrackedEvents.missingLastMessage.message}: '
          'syncEventLists() no common items — full reset '
          '(oldCount=${oldEvents.length}, newCount=${newEvents.length}, '
          'oldNewest=$oldNewest, newNewest=$newNewest)',
        );
      }
    }
    return EventListSyncResult(
      top: const [],
      bottom: List.from(newEvents),
      shouldScrollToBottom: false,
      hasNewEvents:
          newEvents.isNotEmpty &&
          (oldEvents.isEmpty ||
              newEvents.first.eventId != oldEvents.first.eventId),
    );
  }
}
