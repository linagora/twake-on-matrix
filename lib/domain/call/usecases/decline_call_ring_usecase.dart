import 'package:twake_chat/domain/model/call/call_ring.dart';
import 'package:twake_chat/domain/repository/call/call_repository.dart';

class DeclineCallRingUseCase {
  const DeclineCallRingUseCase(this._repository);

  final CallRepository _repository;

  Future<void> execute(CallRing ring) => _repository.declineRing(ring);
}
