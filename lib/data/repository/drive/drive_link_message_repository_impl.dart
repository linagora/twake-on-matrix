import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/drive/drive_file_content.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';
import 'package:twake_chat/domain/model/drive/drive_link_message.dart';
import 'package:twake_chat/domain/repository/drive/drive_link_message_repository.dart';

class DriveLinkMessageRepositoryImpl implements DriveLinkMessageRepository {
  const DriveLinkMessageRepositoryImpl(this._client);

  final Client _client;

  @override
  Future<bool> canSendTo(String roomId) async =>
      _client.getRoomById(roomId)?.canSendDefaultMessages ?? false;

  @override
  Future<void> send(String roomId, DriveLinkMessage message) async {
    final room = _client.getRoomById(roomId);
    if (room == null) throw const DriveRoomUnavailableException();
    await room.sendEvent(driveLinkMessageContent(message));
  }
}

Map<String, dynamic> driveLinkMessageContent(DriveLinkMessage message) => {
  'msgtype': MessageTypes.Text,
  'body': message.body,
  driveFileContentKey: DriveFileContent(
    id: message.fileId,
    name: message.name,
    size: message.size,
    mimeType: message.mimeType,
    url: message.url,
    thumbnailUrl: message.thumbnailUrl,
  ).toJson(),
};
