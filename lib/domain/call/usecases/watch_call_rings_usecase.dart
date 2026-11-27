import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class WatchCallRingsUseCase {
  const WatchCallRingsUseCase(this._repository);

  final CallRepository _repository;

  Stream<List<CallRing>> execute() => _repository.watchRings();
}
