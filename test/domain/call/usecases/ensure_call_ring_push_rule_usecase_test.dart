import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/ensure_call_ring_push_rule_usecase.dart';

import '../fake_call_repository.dart';

void main() {
  test('asks for the push rules of the ring to be there', () async {
    final repository = FakeCallRepository();

    await EnsureCallRingPushRuleUseCase(repository).execute();

    expect(repository.calls, ['ensureCallRingPushRules']);
  });

  test('a server that refuses the rule does not block the session', () async {
    final repository = FakeCallRepository()
      ..pushRulesError = Exception('M_FORBIDDEN');

    await expectLater(
      EnsureCallRingPushRuleUseCase(repository).execute(),
      completes,
    );
    expect(repository.calls, ['ensureCallRingPushRules']);
  });
}
