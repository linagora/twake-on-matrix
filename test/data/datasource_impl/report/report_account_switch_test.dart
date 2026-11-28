import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/report/usecases/report_room_usecase.provider.dart';
import 'package:twake_chat/domain/report/usecases/report_user_usecase.provider.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';

import 'report_account_switch_test.mocks.dart';

class _ActiveClient extends Notifier<Client?> {
  _ActiveClient(this._initial);

  final Client? _initial;

  @override
  Client? build() => _initial;

  void switchTo(Client? client) => state = client;
}

final _activeClient = NotifierProvider<_ActiveClient, Client?>(
  () => throw UnimplementedError(),
);

@GenerateNiceMocks([MockSpec<Client>()])
void main() {
  late MockClient accountA;
  late MockClient accountB;
  late ProviderContainer container;

  setUp(() {
    accountA = MockClient();
    accountB = MockClient();
    container = ProviderContainer.test(
      overrides: [
        _activeClient.overrideWith(() => _ActiveClient(accountA)),
        activeMatrixClientProvider.overrideWith(
          (ref) => ref.watch(_activeClient),
        ),
      ],
    );
  });

  void switchTo(Client client) =>
      container.read(_activeClient.notifier).switchTo(client);

  test(
    'reportRoom_whenTheAccountSwitchesMidReport_staysOnTheFirstAccount',
    () async {
      final answer = Completer<void>();
      when(accountA.reportRoom(any, any)).thenAnswer((_) => answer.future);

      final report = container
          .read(reportRoomUseCaseProvider)
          .execute(roomId: '!room:a', reason: 'Spam');
      switchTo(accountB);
      answer.complete();
      await report;

      verify(accountA.reportRoom('!room:a', 'Spam')).called(1);
      verifyNever(accountB.reportRoom(any, any));
    },
  );

  test('reportUser_afterAnAccountSwitch_usesTheNewAccount', () async {
    when(accountB.reportUser(any, any)).thenAnswer((_) async => {});

    switchTo(accountB);
    await container
        .read(reportUserUseCaseProvider)
        .execute(userId: '@bob:b', reason: 'Spam');

    verify(accountB.reportUser('@bob:b', 'Spam')).called(1);
    verifyNever(accountA.reportUser(any, any));
  });
}
