import 'package:flutter/gestures.dart';
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

Future<void> _pumpMembersPage(
  WidgetTester tester, {
  required Room room,
  VoidCallback? onAddMembers,
  void Function(User member)? onSelectMember,
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
            onSelectMember: onSelectMember,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDown(GetIt.instance.reset);

  group('ChatDetailsMembersPage', () {
    final moderatorRoom = _FakeRoom(
      ownPowerLevel: PowerLevel(50),
      canBan: true,
    );
    final readOnlyRoom = _FakeRoom(ownPowerLevel: PowerLevel(0), canBan: false);
    final sameRoleRoom = _FakeRoom(ownPowerLevel: PowerLevel(10), canBan: true);

    testWidgets('shows the add members row when onAddMembers is provided', (
      tester,
    ) async {
      var tapCount = 0;
      await _pumpMembersPage(
        tester,
        room: moderatorRoom,
        onAddMembers: () => tapCount++,
      );

      await tester.tap(find.byIcon(Icons.person_add_outlined));

      expect(tapCount, 1);
    });

    testWidgets('hides the add members row when onAddMembers is null', (
      tester,
    ) async {
      await _pumpMembersPage(tester, room: readOnlyRoom);

      expect(find.byIcon(Icons.person_add_outlined), findsNothing);
      expect(find.text('Member'), findsOneWidget);
    });

    final removalCases = [
      ('a removable member', moderatorRoom, true),
      ('a member without the ban permission', readOnlyRoom, false),
      ('a member of equal role', sameRoleRoom, false),
    ];
    for (final (member, room, isOffered) in removalCases) {
      final outcome = isOffered ? 'offers' : 'does not offer';

      testWidgets('$outcome the remove swipe on $member', (tester) async {
        await _pumpMembersPage(tester, room: room);

        expect(
          find.byType(Slidable),
          isOffered ? findsOneWidget : findsNothing,
        );
      });

      testWidgets('$outcome selection on long press of $member', (
        tester,
      ) async {
        final selected = <User>[];
        await _pumpMembersPage(
          tester,
          room: room,
          onSelectMember: selected.add,
        );

        await tester.longPress(find.text('Member'));

        expect(selected, hasLength(isOffered ? 1 : 0));
      });

      testWidgets('$outcome the remove button on hover of $member', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await _pumpMembersPage(tester, room: room);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Member')));
        await tester.pump();

        expect(
          find.byIcon(Icons.delete_outlined),
          isOffered ? findsOneWidget : findsNothing,
        );
      });
    }
  });
}
