import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/utils/clipboard.dart';
import 'package:twake_chat/utils/date_time_extension.dart';
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

/// A transaction id ends with the millisecond it was created at; any value
/// below this is not a time (the SDK format is `<client>-<counter>-<millis>`).
const _minTransactionMillis = 1000000000000;

/// Orders events newest first for the chat list.
///
/// A local echo (an event still being sent, or one that failed) has the
/// transaction id as event id. Its time is not usable for ordering: the
/// placeholder carries the time of its creation, and the SDK replaces it with
/// a new echo stamped "now" when the file starts to send, so the images of one
/// send would swap places as they go one after the other. Local echoes
/// therefore sort after every sent event, and among themselves by the creation
/// time inside their transaction id, which never changes, then by its counter
/// when two were created in the same millisecond. An echo whose id has no such
/// time counts as older than the others and is ordered by its own time among
/// its kind, so the order stays consistent for any mix. A failed event is not
/// an echo: it keeps its place in time, as before.
int compareEventsNewestFirst(Event a, Event b) {
  final aEcho = _isLocalEcho(a);
  if (aEcho != _isLocalEcho(b)) return aEcho ? -1 : 1;
  if (aEcho) {
    final aCreated = _transactionCreatedAt(a.eventId);
    final bCreated = _transactionCreatedAt(b.eventId);
    if (aCreated != null && bCreated != null) {
      if (aCreated != bCreated) return bCreated.compareTo(aCreated);
      final aCounter = _transactionCounter(a.eventId) ?? -1;
      final bCounter = _transactionCounter(b.eventId) ?? -1;
      if (aCounter != bCounter) return bCounter.compareTo(aCounter);
    } else if (aCreated != null || bCreated != null) {
      return aCreated != null ? -1 : 1;
    }
  }
  return b.originServerTs.compareTo(a.originServerTs);
}

bool _isLocalEcho(Event event) => event.status.isSending;

/// The counter of a transaction id (`<client>-<counter>-<millis>`), or null.
int? _transactionCounter(String eventId) {
  final end = eventId.lastIndexOf('-');
  final start = end > 0 ? eventId.lastIndexOf('-', end - 1) : -1;
  return start < 0 ? null : int.tryParse(eventId.substring(start + 1, end));
}

/// Milliseconds at the end of a transaction id, or null for any other id.
int? _transactionCreatedAt(String eventId) {
  final millis = int.tryParse(eventId.substring(eventId.lastIndexOf('-') + 1));
  return millis != null && millis > _minTransactionMillis ? millis : null;
}

/// Extension for managing and syncing lists of Matrix events.
/// Provides efficient operations for detecting changes, additions, and removals.
extension EventListExtension on List<Event> {
  static const _textMessageTypes = {
    MessageTypes.Text,
    MessageTypes.Notice,
    MessageTypes.Emote,
  };

  static const _fileMessageTypes = {
    MessageTypes.Image,
    MessageTypes.Video,
    MessageTypes.Audio,
    MessageTypes.File,
  };

  List<Event> get copyableEvents => where(
    (event) =>
        event.type == EventTypes.Message &&
        !event.redacted &&
        (_textMessageTypes.contains(event.messageType) ||
            _fileMessageTypes.contains(event.messageType)),
  ).sortedBy((event) => event.originServerTs);

  Future<void> copyTexts(BuildContext context, Timeline timeline) async {
    final text = copyableEvents
        .map((event) => _copiedMessage(event, context, timeline))
        .nonNulls
        .join('\n\n');
    if (text.isEmpty) return;
    await TwakeClipboard.instance.copyText(text);
    if (!context.mounted) return;
    TwakeSnackBar.show(context, L10n.of(context)!.textCopiedToClipboard);
  }

  static String? _copiedMessage(
    Event event,
    BuildContext context,
    Timeline timeline,
  ) {
    final text =
        _fileMessageTypes.contains(event.messageType) &&
            !event.isCaptionModeOrReply()
        ? event.filename
        : event.getSelectedEventString(context, timeline);
    if (text.isEmpty) return null;
    final sender = event.senderFromMemoryOrFallback.calcDisplayname();
    final sentAt = event.originServerTs;
    return '$sender, ${sentAt.relativeTime(context)} '
        '${sentAt.localizedTimeOfDay(context)}\n$text';
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
