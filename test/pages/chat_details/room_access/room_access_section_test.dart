import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository.provider.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_draft.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_section.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import 'public_groups_summary.dart';
import 'room_access_section_test.mocks.dart';

@GenerateNiceMocks([MockSpec<RoomAccessRepository>()])
void main() {
  const roomId = '!room:example.com';
  const invite = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: false,
    canChange: true,
  );

  late MockRoomAccessRepository repository;
  late ValueNotifier<RoomAccessDraft> draft;

  setUp(() {
    repository = MockRoomAccessRepository();
    draft = ValueNotifier(const RoomAccessDraft());
  });

  tearDown(() => draft.dispose());

  Future<void> pumpSection(
    WidgetTester tester, {
    RoomAccess access = invite,
    bool isPublicGroupsEnabled = true,
  }) async {
    when(
      repository.watchRoomAccess(roomId),
    ).thenAnswer((_) => Stream.value(access));
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        roomAccessRepositoryProvider.overrideWithValue(repository),
        loginHomeserverSummaryProvider.overrideWithBuild(
          (_, _) => summaryWith(isPublicGroupsEnabled: isPublicGroupsEnabled),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoomAccessSection(roomId: roomId, draft: draft),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('build_whenPublicGroupsAreDisabled_showsNothing', (tester) async {
    // Act
    await pumpSection(tester, isPublicGroupsEnabled: false);

    // Assert
    expect(find.text('Who can join'), findsNothing);
  });

  testWidgets('build_always_showsTheThreeRulesAndTheListing', (tester) async {
    // Act
    await pumpSection(tester);

    // Assert
    expect(find.text('Who can join'), findsOneWidget);
    expect(find.byType(LinagoraRadioItem), findsNWidgets(3));
    expect(find.text('In directory'), findsOneWidget);
    final invite = tester.widget<LinagoraRadioItem>(
      find.widgetWithText(LinagoraRadioItem, 'Invite only'),
    );
    expect(invite.selected, isTrue);
  });

  testWidgets('tapPublic_always_selectsItAndTurnsTheListingOn', (tester) async {
    // Arrange
    await pumpSection(tester);

    // Act
    await tester.tap(find.text('Public'));
    await tester.pumpAndSettle();

    // Assert
    final public = tester.widget<LinagoraRadioItem>(
      find.widgetWithText(LinagoraRadioItem, 'Public'),
    );
    expect(public.selected, isTrue);
    final listed = tester.widget<LinagoraSettingItem>(
      find.widgetWithText(LinagoraSettingItem, 'In directory'),
    );
    expect(listed.value, isTrue);
    expect(draft.value.joinRule, JoinRuleChoice.public);
  });

  testWidgets('build_encryptedRoom_offersNeitherPublicNorTheListing', (
    tester,
  ) async {
    // Act
    await pumpSection(tester, access: invite.copyWith(isEncrypted: true));

    // Assert
    expect(find.text('Public'), findsNothing);
    expect(find.text('In directory'), findsNothing);
    expect(
      find.text("An encrypted room can't be public or listed."),
      findsOneWidget,
    );
  });

  testWidgets('build_restrictedRoom_saysSoAndKeepsTheListing', (tester) async {
    // Act
    await pumpSection(tester, access: invite.copyWith(joinRule: null));

    // Assert
    expect(find.byType(LinagoraRadioItem), findsNothing);
    expect(
      find.text("Members of a space can join. This isn't changed here."),
      findsOneWidget,
    );
    expect(find.text('In directory'), findsOneWidget);
  });

  testWidgets('build_always_offersTheRulesInOrder', (tester) async {
    // Act
    await pumpSection(tester);

    // Assert
    final titles = tester
        .widgetList<LinagoraRadioItem>(find.byType(LinagoraRadioItem))
        .map((item) => item.title);
    expect(titles, ['Invite only', 'On request', 'Public']);
  });

  testWidgets('build_withPublicPage_locksPublicAndTheListing', (tester) async {
    // Act
    await pumpSection(
      tester,
      access: invite.copyWith(
        joinRule: JoinRuleChoice.public,
        isListed: true,
        hasPublicPage: true,
      ),
    );

    // Assert
    final titles = tester
        .widgetList<LinagoraRadioItem>(find.byType(LinagoraRadioItem))
        .map((item) => item.title);
    expect(titles, ['Public']);
    final listed = tester.widget<LinagoraSettingItem>(
      find.byType(LinagoraSettingItem),
    );
    expect(listed.enabled, isFalse);
    expect(
      find.text('The public web page is on: the room stays public and listed.'),
      findsOneWidget,
    );
  });
}
