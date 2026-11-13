import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class WatchCallRoomEncryptedUseCase {
  const WatchCallRoomEncryptedUseCase(this._repository);

  final CallRepository _repository;

  /// Emits when encryption is turned on in [roomId] (DECISION.md D14).
  Stream<void> execute(String roomId) =>
      _repository.watchRoomEncrypted(CallRoom(roomId));
}
