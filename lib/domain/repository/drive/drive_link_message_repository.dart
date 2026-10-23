import 'package:twake_chat/domain/model/drive/drive_link_message.dart';

abstract interface class DriveLinkMessageRepository {
  Future<bool> canSendTo(String roomId);

  Future<void> send(String roomId, DriveLinkMessage message);
}
