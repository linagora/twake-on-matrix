import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/call/usecases/join_call_usecase.dart';
import 'package:twake_chat/domain/exception/call/call_exception.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

import '../fake_call_repository.dart';

void main() {
  late FakeCallRepository repository;

  setUp(() => repository = FakeCallRepository());

  Future<CallRoomInfo?> join({
    String? serviceUrl = 'https://rtc.test',
    bool Function()? isCancelled,
  }) => JoinCallUseCase(repository).execute(
    roomId: '!room',
    serviceUrl: serviceUrl,
    isVideo: true,
    isCancelled: isCancelled ?? () => false,
  );

  test(
    'ends the stale membership, then gets the token, connects and joins',
    () async {
      final room = await join();

      expect(room, repository.roomInfo);
      expect(repository.calls, [
        'endStale !room',
        'fetchServer !room https://rtc.test',
        'connect mic=true camera=true',
        'join !room video=true',
      ]);
    },
  );

  test('without a token service it touches nothing', () async {
    await expectLater(
      join(serviceUrl: null),
      throwsA(isA<CallServiceUnavailableException>()),
    );
    expect(repository.calls, isEmpty);
  });

  test('refuses an encrypted room until media keys are exchanged', () async {
    repository.roomInfo = const CallRoomInfo(
      isEncrypted: true,
      isDirect: false,
    );

    await expectLater(
      join(),
      throwsA(isA<CallEncryptionUnsupportedException>()),
    );
    expect(repository.calls, isEmpty);
  });

  test('a token failure sends no membership', () async {
    repository.fetchError = const CallTokenFailedException();

    await expectLater(join(), throwsA(isA<CallTokenFailedException>()));
    expect(repository.calls, isNot(contains('join !room video=true')));
    expect(repository.calls.last, startsWith('fetchServer'));
  });

  test('a media failure sends no membership', () async {
    repository.connectError = const CallMediaFailedException();

    await expectLater(join(), throwsA(isA<CallMediaFailedException>()));
    expect(repository.calls.last, 'connect mic=true camera=true');
  });

  test('a membership failure disconnects the media', () async {
    repository.joinError = const CallNoPermissionException();

    await expectLater(join(), throwsA(isA<CallNoPermissionException>()));
    expect(repository.calls.last, 'disconnect');
  });

  test('execute_whenCancelledBeforeTheMedia_connectsNothing', () async {
    final room = await join(isCancelled: () => true);

    expect(room, isNull);
    expect(repository.calls, [
      'endStale !room',
      'fetchServer !room https://rtc.test',
    ]);
  });

  test('execute_whenCancelledWhileTheMediaConnects_disconnectsIt', () async {
    var isCancelled = false;
    repository.connectGate = Completer<void>();

    final joining = join(isCancelled: () => isCancelled);
    await pumpEventQueue();
    isCancelled = true;
    repository.connectGate!.complete();

    expect(await joining, isNull);
    expect(repository.calls.last, 'disconnect');
    expect(repository.calls, isNot(contains('join !room video=true')));
  });

  test('execute_withoutTheRightToJoin_touchesNothing', () async {
    repository.roomInfo = const CallRoomInfo(
      isEncrypted: false,
      isDirect: false,
      canJoin: false,
    );

    await expectLater(join(), throwsA(isA<CallNoPermissionException>()));
    expect(repository.calls, isEmpty);
  });
}
