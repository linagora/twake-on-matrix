import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/voice_message/datasources/voice_message_datasource.dart';
import 'package:twake_chat/domain/matrix_events/event_visibility_resolver.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/thread/thread_relation_extension.dart';

class VoiceMessageDatasourceImpl implements VoiceMessageDatasource {
  const VoiceMessageDatasourceImpl(this._client);

  final Client _client;

  static const _firstPageSize = 50;
  static const _maxEvents = 6400;

  @override
  Future<String?> nextVoiceMessageId({
    required String roomId,
    required String eventId,
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
        );
      }
      if (newestFirst.length < limit) return null;
    }
    return null;
  }

  String? _nextVoiceMessageId(Event played, Iterable<Event> newer) {
    if (!_isVoiceMessage(played)) return null;
    final threadRootId = played.threadRootId;
    final inThread = threadRootId != null;
    for (final event in newer) {
      if (inThread && event.threadRootId != threadRootId) continue;
      if (!EventVisibilityResolver.isVisibleInTimeline(
        event,
        inThread: inThread,
      )) {
        continue;
      }
      return _isVoiceMessage(event) ? event.eventId : null;
    }
    return null;
  }

  static bool _isVoiceMessage(Event event) =>
      !event.redacted &&
      event.messageType == MessageTypes.Audio &&
      event.content.containsKey('org.matrix.msc3245.voice');
}
