import 'dart:async';

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

const _roomId = '!group:hs1.localhost';
const _slowUser = '@bob:hs2.localhost';
const _fastUser = '@carol:hs1.localhost';

void main() {
  group('InviteUserInteractor with a slow federated invite', () {
    test('aFastInvite_isNotHeldByTheSlowOne', () async {
      final client = _FakeClient();
      final states = InviteUserInteractor()
          .execute(
            matrixClient: client,
            roomId: _roomId,
            userIds: [_slowUser, _fastUser],
          )
          .toList();

      await pumpEventQueue();
      expect(client.invited, [_fastUser]);

      client.slowInvite.complete();
      final result = (await states).last.fold((f) => f, (s) => s);
      expect(client.invited, [_fastUser, _slowUser]);
      expect(result, isA<InviteUserSuccess>());
    });

    test('aFailingInvite_isReportedWhileTheOthersSucceed', () async {
      final client = _FakeClient()..failingUsers.add(_fastUser);
      client.slowInvite.complete();

      final result =
          (await InviteUserInteractor()
                  .execute(
                    matrixClient: client,
                    roomId: _roomId,
                    userIds: [_slowUser, _fastUser],
                  )
                  .last)
              .fold((f) => f, (s) => s);

      expect(client.invited, [_slowUser]);
      expect(result, isA<InviteUserSomeFailed>());
      final failed = (result as InviteUserSomeFailed)
          .inviteUserPartialFailureException
          .failedUsers;
      expect(failed.keys, [_fastUser]);
      expect(failed[_fastUser], isA<GenericInviteException>());
    });
  });
}
