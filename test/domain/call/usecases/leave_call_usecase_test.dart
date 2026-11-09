import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';

import '../fake_call_repository.dart';

void main() {
  test('execute_always_disconnectsTheMediaBeforeTheMembershipLeaves', () async {
    final repository = FakeCallRepository();

    await LeaveCallUseCase(repository).execute('!room');

    expect(repository.calls, ['disconnect', 'leave !room']);
  });

  test('execute_whenTheLeaveFails_hasDisconnectedTheMedia', () async {
    final repository = FakeCallRepository(
      leaveError: const CallMembershipFailedException(),
    );

    await expectLater(
      LeaveCallUseCase(repository).execute('!room'),
      throwsA(isA<CallMembershipFailedException>()),
    );
    expect(repository.calls, ['disconnect', 'leave !room']);
  });
}
