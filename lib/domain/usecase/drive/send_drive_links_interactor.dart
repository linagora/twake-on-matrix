import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/drive/drive_picked_entry.dart';
import 'package:twake_chat/domain/model/drive/drive_link_message.dart';
import 'package:twake_chat/domain/repository/drive/drive_link_message_repository.dart';

class SendDriveLinksInteractor {
  const SendDriveLinksInteractor(this._repository);

  final DriveLinkMessageRepository _repository;

  Future<int> execute({
    required String roomId,
    required List<DrivePickedEntry> documents,
  }) async {
    if (!await _repository.canSendTo(roomId)) return 0;
    var sent = 0;
    for (final message in documents.map(DriveLinkMessage.fromDocument)) {
      if (message == null) continue;
      if (await _trySend(roomId, message)) sent++;
    }
    return sent;
  }

  Future<bool> _trySend(String roomId, DriveLinkMessage message) async {
    try {
      await _repository.send(roomId, message);
      return true;
    } catch (e) {
      Logs().w('SendDriveLinksInteractor: send failed: ${e.runtimeType}');
      return false;
    }
  }
}
