import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/domain/model/user_info/user_info.dart';
import 'package:twake_chat/domain/user_info/exceptions/user_info_exception.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_usecase.dart';
import 'package:twake_chat/domain/user_info/usecases/get_user_info_usecase.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeGetUserInfoUseCase extends Fake implements GetUserInfoUseCase {
  _FakeGetUserInfoUseCase(this._result);

  final Future<UserInfo> Function() _result;

  @override
  Future<UserInfo> execute(String userId) => _result();
}

final _pending = _FakeGetUserInfoUseCase(() => Completer<UserInfo>().future);

class _FakeClient extends Fake implements Client {
  @override
  String get userID => '@me:example.com';

  @override
  Map<String, CachedPresence> get presences => {};
}

class _FakeMatrixState extends Fake implements MatrixState {
  @override
  Client get client => _FakeClient();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _FakeRoom extends Fake implements Room {
  @override
  final Client client = _FakeClient();

  @override
  PowerLevel get ownPowerLevel => PowerLevel(50);

  @override
  bool get canBan => true;

  @override
  String get id => '!room:example.com';

  @override
  StrippedStateEvent? getState(String typeKey, [String stateKey = '']) => null;
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.membership);

  @override
  final Membership membership;

  @override
  final Room room = _FakeRoom();

  @override
  PowerLevel get powerLevel => PowerLevel(0);

  @override
  String get id => '@member:example.com';

  @override
  bool get canBan => room.canBan && powerLevel < room.ownPowerLevel;

  @override
  Uri? get avatarUrl => null;

  @override
  String calcDisplayname({
    bool? formatLocalpart,
    bool? mxidLocalPartFallback,
    MatrixLocalizations i18n = const MatrixDefaultLocalizations(),
  }) => 'Member';
}

Future<void> _pumpBody(
  WidgetTester tester, {
  Membership membership = Membership.join,
  GetUserInfoUseCase? useCase,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          getUserInfoUseCaseProvider.overrideWithValue(useCase ?? _pending),
        ],
      ),
      child: MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        localizationsDelegates: L10n.localizationsDelegates,
        home: Provider<MatrixState>.value(
          value: _FakeMatrixState(),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ProfileInfoBody(user: _FakeUser(membership)),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
  });

  tearDown(GetIt.instance.reset);

  group('ProfileInfoBody remove from group action', () {
    final cases = [
      (Membership.join, true),
      (Membership.invite, true),
      (Membership.ban, false),
      (Membership.leave, false),
    ];
    for (final (membership, isOffered) in cases) {
      final outcome = isOffered ? 'is offered' : 'is not offered';

      testWidgets('$outcome for a ${membership.name} member', (tester) async {
        await _pumpBody(tester, membership: membership);

        expect(
          find.byKey(const Key('profile_action_removeFromGroup')),
          isOffered ? findsOneWidget : findsNothing,
        );
      });
    }
  });

  group('ProfileInfoBody user info', () {
    testWidgets('shows a spinner on the avatar while loading', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pumpBody(tester);

      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('@member:example.com'), findsOneWidget);
    });

    testWidgets('falls back to the Matrix profile when loading fails', (
      tester,
    ) async {
      await _pumpBody(
        tester,
        useCase: _FakeGetUserInfoUseCase(
          () => Future.error(GetUserInfoException(Exception('network'))),
        ),
      );
      await tester.pump();

      expect(find.text('Member'), findsOneWidget);
      expect(find.text('@member:example.com'), findsOneWidget);
      expect(find.text('bob@example.test'), findsNothing);
      expect(find.byType(CupertinoActivityIndicator), findsNothing);
    });

    testWidgets('shows the directory name, phone and email', (tester) async {
      await _pumpBody(
        tester,
        useCase: _FakeGetUserInfoUseCase(
          () async => const UserInfo(
            displayName: 'Bob Directory',
            emails: ['bob@example.test'],
            phones: ['+33612345678'],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bob Directory'), findsOneWidget);
      expect(find.text('Member'), findsNothing);
      expect(find.text('bob@example.test'), findsOneWidget);
      expect(find.text('+33612345678'), findsOneWidget);
    });
  });
}
