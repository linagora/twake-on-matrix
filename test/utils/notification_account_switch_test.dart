import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/utils/notification_account_switch.dart';
import 'package:twake_chat/widgets/set_active_client_state.dart';

import '../data/account/fakes.dart';

class _FakeHost implements NotificationAccountHost {
  _FakeHost(this.accountClients, {required this.settledOn});

  @override
  final List<Client> accountClients;

  /// The account that is active with no switch running; null during a switch.
  Client? settledOn;

  SetActiveClientState result = SetActiveClientState.success;
  Object? error;
  final asked = <Client?>[];
  var lookupCancelled = 0;

  @override
  bool isSettledOn(Client target) => identical(target, settledOn);

  @override
  Future<SetActiveClientState> setActiveClient(Client? newClient) async {
    asked.add(newClient);
    final failure = error;
    if (failure != null) throw failure;
    return result;
  }

  @override
  Future<void> cancelContactsLookup() async => lookupCancelled++;
}

void main() {
  late FakeAccountClient first;
  late FakeAccountClient second;
  late _FakeHost host;

  setUp(() {
    first = FakeAccountClient('first', userID: '@first:s');
    second = FakeAccountClient('second', userID: '@second:s');
    host = _FakeHost([first, second], settledOn: first);
  });

  Future<NotificationAccountOutcome> tap(String? receiverId) =>
      NotificationAccountSwitch(host).switchTo(receiverId);

  group('nothing to switch', () {
    test(
      'a notification without a receiver opens on the active account',
      () async {
        expect(await tap(null), isA<NotificationAccountReady>());
        expect(host.asked, isEmpty);
      },
    );

    test('a receiver that is no account opens on the active account', () async {
      expect(await tap('@nobody:s'), isA<NotificationAccountReady>());
      expect(host.asked, isEmpty);
    });

    test(
      'the active account with no switch running is not asked again',
      () async {
        expect(await tap('@first:s'), isA<NotificationAccountReady>());
        expect(host.asked, isEmpty);
      },
    );
  });

  group('switching', () {
    test('another account is switched to and its lookup cancelled', () async {
      final outcome = await tap('@second:s');

      expect(outcome, isA<NotificationAccountSwitched>());
      expect((outcome as NotificationAccountSwitched).client, same(second));
      expect(host.asked, [same(second)]);
      expect(host.lookupCancelled, 1);
    });

    test(
      'the account being left is asked for during a switch away from it',
      () async {
        // A to B is running: the active account is still A, but tapping A is
        // what cancels the switch, so it must reach the state.
        host.settledOn = null;

        final outcome = await tap('@first:s');

        expect(outcome, isA<NotificationAccountSwitched>());
        expect(host.asked, [same(first)]);
      },
    );
  });

  group('a switch that did not happen', () {
    for (final result in [
      SetActiveClientState.unavailable,
      SetActiveClientState.unknownClient,
      SetActiveClientState.superseded,
    ]) {
      test('$result does not open the room on the old account', () async {
        host.result = result;

        final outcome = await tap('@second:s');

        expect(outcome, isA<NotificationAccountFailed>());
        expect(host.lookupCancelled, 0);
      });
    }

    test('an error of the switch does not open the room either', () async {
      host.error = StateError('switch failed');

      final outcome = await tap('@second:s');

      expect(outcome, isA<NotificationAccountFailed>());
      expect(host.lookupCancelled, 0);
    });
  });
}
