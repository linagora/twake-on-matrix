import 'package:matrix/matrix.dart';
import 'package:twake_chat/config/feed_config.dart';
import 'package:twake_chat/data/datasource/feed/feed_datasource.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';

class FeedDatasourceImpl implements FeedDatasource {
  const FeedDatasourceImpl(this._client);

  final Client _client;

  @override
  Future<String> createFeed({String? name, String? avatarUrl}) async {
    try {
      final roomId = await _createFeedRoom(name: name, avatarUrl: avatarUrl);

      // Navigating to the room fails if it has not reached the sync yet.
      if (_client.getRoomById(roomId) == null) {
        await _client.waitForRoomInSync(roomId, join: true);
      }

      return roomId;
    } on Exception catch (exception, stackTrace) {
      throw _toFeedException(exception, stackTrace);
    }
  }

  /// Raw request rather than [Client.createRoom] because [CreateRoomPreset]
  /// is a closed Dart enum: the feed preset cannot be custom.
  Future<String> _createFeedRoom({String? name, String? avatarUrl}) async {
    final response = await _client.request(
      RequestType.POST,
      '/client/v3/createRoom',
      data: {
        'preset': FeedConfig.preset,
        'creation_content': {'type': FeedConfig.roomType},
        if (name != null) 'name': name,
        'initial_state': [
          StateEvent(
            type: EventTypes.RoomAvatar,
            content: {'url': avatarUrl},
            stateKey: '',
          ).toJson(),
          StateEvent(
            type: EventTypes.HistoryVisibility,
            content: {'history_visibility': HistoryVisibility.shared.name},
            stateKey: '',
          ).toJson(),
        ],
      },
    );

    final roomId = response.tryGet<String>('room_id');
    if (roomId == null) {
      throw const FormatException('No room_id in the response');
    }
    return roomId;
  }

  FeedException _toFeedException(Exception exception, StackTrace stackTrace) {
    // The preset is the only non-standard field of this request, so a
    // M_BAD_JSON means the homeserver does not know it.
    if (exception is MatrixException &&
        exception.error == MatrixError.M_BAD_JSON) {
      Logs().w('FeedDatasourceImpl::createFeed', exception, stackTrace);
      return const FeedNotSupportedByHomeserverException();
    }
    Logs().e('FeedDatasourceImpl::createFeed', exception, stackTrace);
    return FeedCreationFailedException(cause: exception);
  }
}
