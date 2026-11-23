import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/decline_call_ring_usecase.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

import '../fake_call_repository.dart';

final _ring = CallRing(
  eventId: r'$ring',
  room: const CallRoom('!room'),
  senderId: '@alice:hs.test',
  isVideo: true,
  expiresAt: DateTime(2030),
);

void main() {
  test('declining a ring declines that very ring', () async {
    final repository = FakeCallRepository();

    await DeclineCallRingUseCase(repository).execute(_ring);

    expect(repository.calls, [r'decline $ring']);
  });

  test('a decline that fails is told to the caller of the use case', () async {
    final repository = FakeCallRepository()
      ..declineError = const CallMembershipFailedException();

    await expectLater(
      DeclineCallRingUseCase(repository).execute(_ring),
      throwsA(isA<CallMembershipFailedException>()),
    );
  });
}
