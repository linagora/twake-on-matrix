import 'package:twake_chat/domain/repository/call/call_repository.dart';

class EnsureCallRingPushRuleUseCase {
  const EnsureCallRingPushRuleUseCase(this._repository);

  final CallRepository _repository;

  /// A server that refuses the rules only loses the ring sound of the push.
  Future<void> execute() async {
    try {
      await _repository.ensureCallRingPushRules();
    } on Exception {
      // Only the ring sound is lost. The data layer logs it.
    }
  }
}
