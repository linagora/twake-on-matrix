import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/leave_call_usecase.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';

import '../fake_call_repository.dart';

void main() {
  test('leaves the membership, then disconnects the media', () async {
    final repository = FakeCallRepository();

    await LeaveCallUseCase(repository).execute('!room');

    expect(repository.calls, ['leave !room', 'disconnect']);
  });

  test('disconnects the media even when the leave fails', () async {
    final repository = FakeCallRepository(
      leaveError: const CallMembershipFailedException(),
    );

    await expectLater(
      LeaveCallUseCase(repository).execute('!room'),
      throwsA(isA<CallMembershipFailedException>()),
    );
    expect(repository.calls, ['leave !room', 'disconnect']);
  });
}
