import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_rules.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_relation_extension.dart';
import 'package:matrix/matrix.dart';

mixin RetryTextMessageMixin {
  Future<void> retryTextMessage(Event event) async {
    if (event.status != EventStatus.error) {
      Logs().w('RetryTextMessageMixin: Event is not in error state');
      return;
    }

    if (event.messageType != MessageTypes.Text) {
      Logs().w('RetryTextMessageMixin: Event is not a text message');
      return;
    }

    final room = event.room;
    final messageBody = event.body;

    if (messageBody.isEmpty) {
      Logs().w('RetryTextMessageMixin: Message body is empty');
      return;
    }

    Event? replyEvent;
    String? editEventId;

    final threadRootId = event.threadRootId;
    // A thread reply keeps its relation; its in_reply_to is a quote unless
    // it is only the fallback to the last event of the thread.
    final threadLastEventId = threadRootId == null
        ? null
        : event.content
              .tryGetMap<String, Object?>('m.relates_to')
              ?.tryGetMap<String, Object?>('m.in_reply_to')
              ?.tryGet<String>('event_id');

    final quotedEventId = event.inReplyToEventId(includingFallback: false);
    if (quotedEventId != null) {
      replyEvent = await room.getEventById(quotedEventId);
    } else if (event.relationshipType == RelationshipTypes.edit &&
        event.relationshipEventId != null) {
      editEventId = event.relationshipEventId;
    }

    try {
      final eventId = await room.sendTextEvent(
        messageBody,
        txid: event.transactionId,
        inReplyTo: replyEvent,
        editEventId: editEventId,
        threadRootEventId:
            threadRootId ??
            (replyEvent == null ? null : ThreadRules.threadRootOf(replyEvent)),
        threadLastEventId: threadLastEventId,
      );
      if (eventId == null) {
        throw StateError('Sent event return null id');
      }

      Logs().i('RetryTextMessageMixin: Text message retry successful');
    } catch (e) {
      Logs().e('RetryTextMessageMixin: Failed to retry text message', e);
      rethrow;
    }
  }
}
