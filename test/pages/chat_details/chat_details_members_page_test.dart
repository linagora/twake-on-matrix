import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/assign_roles_member_picker/selected_user_notifier.dart';
import 'package:twake_chat/pages/chat_details/chat_details_page_view/chat_details_members_page.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';

class _FakeClient extends Fake implements Client {}

class _FakeMatrixState extends Fake implements MatrixState {
  @override
  Client get client => _FakeClient();

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

class _FakeRoom extends Fake implements Room {
  _FakeRoom({required this.ownPowerLevel, required this.canBan});

  @override
  final PowerLevel ownPowerLevel;

  @override
  final bool canBan;

  @override
  String get id => '!room:example.com';
}

class _FakeUser extends Fake implements User {
  _FakeUser(this.room, {required this.powerLevel});

  @override
  final Room room;

  @override
  final PowerLevel powerLevel;

  @override
  String get id => '@member:example.com';

  @override
  bool get canBan => room.canBan && powerLevel < room.ownPowerLevel;

  @override
  Membership get membership => Membership.join;

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
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(GetIt.instance.reset);

  Future<void> pumpMembersPage(
    WidgetTester tester, {
    required Room room,
    VoidCallback? onAddMembers,
  }) async {
    final selectedUsersNotifier = SelectedUsersMapChangeNotifier();
    addTearDown(selectedUsersNotifier.dispose);
    final membersNotifier = ValueNotifier<List<User>?>([
      _FakeUser(room, powerLevel: PowerLevel(10)),
    ]);
    addTearDown(membersNotifier.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        localizationsDelegates: L10n.localizationsDelegates,
        home: Provider<MatrixState>.value(
          value: _FakeMatrixState(),
          child: Scaffold(
            body: ChatDetailsMembersPage(
              displayMembersNotifier: membersNotifier,
              actualMembersCount: 1,
              openDialogInvite: () {},
              requestMoreMembersAction: () {},
              isMobileAndTablet: false,
              selectedUsersMapChangeNotifier: selectedUsersNotifier,
              onAddMembers: onAddMembers,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('ChatDetailsMembersPage', () {
    final moderatorRoom = _FakeRoom(
      ownPowerLevel: PowerLevel(50),
      canBan: true,
    );
    final readOnlyRoom = _FakeRoom(ownPowerLevel: PowerLevel(0), canBan: false);

    testWidgets('shows the add members row when inviting is allowed', (
      tester,
    ) async {
      var tapCount = 0;
      await pumpMembersPage(
        tester,
        room: moderatorRoom,
        onAddMembers: () => tapCount++,
      );

      await tester.tap(find.byIcon(Icons.person_add_outlined));

      expect(tapCount, 1);
    });

    testWidgets('hides the add members row when inviting is not allowed', (
      tester,
    ) async {
      await pumpMembersPage(tester, room: readOnlyRoom);

      expect(find.byIcon(Icons.person_add_outlined), findsNothing);
      expect(find.text('Member'), findsOneWidget);
    });

    testWidgets('offers the remove swipe on a member that can be removed', (
      tester,
    ) async {
      await pumpMembersPage(tester, room: moderatorRoom);

      expect(find.byType(Slidable), findsOneWidget);
    });

    testWidgets('has no remove swipe when the member cannot be removed', (
      tester,
    ) async {
      await pumpMembersPage(tester, room: readOnlyRoom);

      expect(find.byType(Slidable), findsNothing);
    });

    testWidgets('has no remove swipe on a member of higher or equal role', (
      tester,
    ) async {
      await pumpMembersPage(
        tester,
        room: _FakeRoom(ownPowerLevel: PowerLevel(10), canBan: true),
      );

      expect(find.byType(Slidable), findsNothing);
    });
  });
}
