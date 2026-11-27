import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class WatchCallRingDeclinedUseCase {
  const WatchCallRingDeclinedUseCase(this._repository);

  final CallRepository _repository;

  Stream<void> execute(String roomId) =>
      _repository.watchRingDeclined(CallRoom(roomId));
}
