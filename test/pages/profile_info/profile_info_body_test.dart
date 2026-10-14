import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/usecase/user_info/get_user_info_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeGetUserInfoInteractor extends Fake implements GetUserInfoInteractor {
  @override
  Stream<Either<Failure, Success>> execute({String? userId}) =>
      const Stream.empty();
}

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

void main() {
  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    GetIt.instance.registerSingleton<GetUserInfoInteractor>(
      _FakeGetUserInfoInteractor(),
    );
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
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(
              extensions: [LinagoraTextThemeExtension.material()],
            ),
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
        );
        await tester.pump();

        expect(
          find.byKey(const Key('profile_action_removeFromGroup')),
          isOffered ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}
