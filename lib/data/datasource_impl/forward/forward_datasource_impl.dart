import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/datasource/forward/forward_datasource.dart';
import 'package:twake_chat/domain/forward/exceptions/forward_exception.dart';

class ForwardDatasourceImpl implements ForwardDatasource {
  const ForwardDatasourceImpl(this._client);

  final Client? _client;

  @override
  bool isJoined(String roomId) =>
      _client?.getRoomById(roomId)?.membership == Membership.join;

  @override
  Future<void> sendMessage({
    required String roomId,
    required Map<String, Object?> content,
  }) async {
    try {
      final room = _client?.getRoomById(roomId);
      if (room == null) throw ForwardRoomNotFoundException(roomId);
      await room.sendEvent(content);
    } catch (e, s) {
      Logs().e('ForwardDatasourceImpl::sendMessage() failed', e, s);
      rethrow;
    }
  }
}
