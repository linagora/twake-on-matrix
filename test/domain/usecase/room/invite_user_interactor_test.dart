import 'dart:async';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/app_state/room/invite_user_state.dart';
import 'package:twake_chat/domain/exception/room/invite_user_exception.dart';
import 'package:twake_chat/domain/usecase/room/invite_user_interactor.dart';

class _FakeClient extends Fake implements Client {
  final slowInvite = Completer<void>();
  final invited = <String>[];
  final failingUsers = <String>{};

  @override
  Future<void> inviteUser(
    String roomId,
    String userId, {
    String? reason,
  }) async {
    if (userId == _slowUser) await slowInvite.future;
    if (failingUsers.contains(userId)) {
      throw MatrixException.fromJson({
        'errcode': 'M_FORBIDDEN',
        'error': 'Not allowed',
      });
    }
    invited.add(userId);
  }
}

class _CountingClient extends Fake implements Client {
  final release = Completer<void>();
  int running = 0;
  int maxRunning = 0;
  int started = 0;

  @override
  Future<void> inviteUser(
    String roomId,
    String userId, {
    String? reason,
  }) async {
    started++;
    running++;
    maxRunning = max(maxRunning, running);
    await release.future;
    running--;
  }
}

class _RateLimitedClient extends Fake implements Client {
  int attempts = 0;

  @override
  Future<void> inviteUser(
    String roomId,
    String userId, {
    String? reason,
  }) async {
    attempts++;
    if (attempts == 1) {
      throw MatrixException.fromJson({
        'errcode': 'M_LIMIT_EXCEEDED',
        'error': 'Too many requests',
        'retry_after_ms': 1000,
      });
    }
  }
}

class _MaxRandom extends Fake implements Random {
  @override
  double nextDouble() => 1;
}

const _roomId = '!group:hs1.localhost';
const _slowUser = '@bob:hs2.localhost';
const _fastUser = '@carol:hs1.localhost';

Future<Object> _invite(Client client, List<String> userIds) =>
    InviteUserInteractor()
        .execute(matrixClient: client, roomId: _roomId, userIds: userIds)
        .last
        .then((state) => state.fold((f) => f, (s) => s));

void main() {
  group('InviteUserInteractor with a slow federated invite', () {
    test('aFastInvite_isNotHeldByTheSlowOne', () async {
      final client = _FakeClient();
      final result = _invite(client, [_slowUser, _fastUser]);

      await pumpEventQueue();
      expect(client.invited, [_fastUser]);

      client.slowInvite.complete();
      expect(await result, isA<InviteUserSuccess>());
      expect(client.invited, [_fastUser, _slowUser]);
    });

    test('aFailingInvite_isReportedWhileTheOthersSucceed', () async {
      final client = _FakeClient()..failingUsers.add(_fastUser);
      client.slowInvite.complete();

      final result = await _invite(client, [_slowUser, _fastUser]);

      expect(client.invited, [_slowUser]);
      expect(result, isA<InviteUserSomeFailed>());
      final failed = (result as InviteUserSomeFailed)
          .inviteUserPartialFailureException
          .failedUsers;
      expect(failed.keys, [_fastUser]);
      expect(failed[_fastUser], isA<GenericInviteException>());
    });

    test('manyInvites_runAtMostFiveAtOnce', () async {
      final client = _CountingClient();
      final result = _invite(
        client,
        List.generate(12, (i) => '@user$i:hs2.localhost'),
      );

      await pumpEventQueue();
      expect(client.started, 5);

      client.release.complete();
      expect(await result, isA<InviteUserSuccess>());
      expect(client.started, 12);
      expect(client.maxRunning, 5);
    });

    test('aRateLimitedInvite_retriesAfterTheServerDelayPlusJitter', () {
      fakeAsync((async) {
        final client = _RateLimitedClient();
        Object? result;
        InviteUserInteractor(random: _MaxRandom())
            .execute(
              matrixClient: client,
              roomId: _roomId,
              userIds: [_fastUser],
            )
            .last
            .then((state) => result = state.fold((f) => f, (s) => s));

        async.elapse(const Duration(milliseconds: 1249));
        expect(client.attempts, 1);

        async.elapse(const Duration(milliseconds: 1));
        expect(client.attempts, 2);
        async.flushMicrotasks();
        expect(result, isA<InviteUserSuccess>());
      });
    });
  });
}
