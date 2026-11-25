import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/voice_message/datasources/voice_message_datasource.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_relation_extension.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/voice_message_extension.dart';

class VoiceMessageDatasourceImpl implements VoiceMessageDatasource {
  const VoiceMessageDatasourceImpl(this._client);

  final Client _client;

  static const _firstPageSize = 50;
  static const _maxEvents = 3200;

  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
    String? threadRootId,
  }) async {
    final room = _client.getRoomById(roomId);
    if (room == null) return null;
    for (var limit = _firstPageSize; limit <= _maxEvents; limit *= 2) {
      final newestFirst = await _client.database.getEventList(
        room,
        limit: limit,
      );
      final index = newestFirst.indexWhere((e) => e.eventId == eventId);
      if (index >= 0) {
        return _nextVoiceMessageId(
          newestFirst[index],
          newestFirst.take(index).toList().reversed,
          threadRootId,
        );
      }
      if (newestFirst.length < limit) return null;
    }
    return null;
  }

  /// [threadRootId] is the thread screen the message plays in, null in the
  /// chat: the root of a thread plays in both.
  String? _nextVoiceMessageId(
    Event played,
    Iterable<Event> newer,
    String? threadRootId,
  ) {
    if (!played.isVoiceMessage) return null;
    final inThread = threadRootId != null;
    for (final event in newer) {
      if (inThread && event.threadRootId != threadRootId) continue;
      if (!EventVisibilityResolver.isVisibleInTimeline(
        event,
        inThread: inThread,
      )) {
        continue;
      }
      return event.isVoiceMessage ? event.eventId : null;
    }
    return null;
  }
}
