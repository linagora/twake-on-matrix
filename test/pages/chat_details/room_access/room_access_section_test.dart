import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/data/repository/room_access/room_access_repository.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_controller.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_section.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';

import '../../../domain/room_access/fake_room_access_repository.dart';
import 'public_groups_summary.dart';

void main() {
  const roomId = '!room:example.com';

  late FakeRoomAccessRepository repository;

  setUp(() {
    repository = FakeRoomAccessRepository();
  });

  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    bool isPublicGroupsEnabled = true,
  }) async {
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
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: RoomAccessSection(roomId: roomId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
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
  });

  testWidgets('build_encryptedRoom_offersNeitherPublicNorTheListing', (
    tester,
  ) async {
    // Arrange
    repository.access = repository.access.copyWith(isEncrypted: true);

    // Act
    await pumpSection(tester);

    // Assert
    expect(find.text('Public'), findsNothing);
    expect(find.text('In directory'), findsNothing);
    expect(
      find.text("An encrypted room can't be public or listed."),
      findsOneWidget,
    );
  });

  testWidgets('build_restrictedRoom_saysSoAndKeepsTheListing', (tester) async {
    // Arrange
    repository.access = repository.access.copyWith(joinRule: null);

    // Act
    final container = await pumpSection(tester);

    // Assert
    expect(find.byType(LinagoraRadioItem), findsNothing);
    expect(
      find.text("Members of a space can join. This isn't changed here."),
      findsOneWidget,
    );
    expect(find.text('In directory'), findsOneWidget);
    expect(
      container.read(roomAccessControllerProvider(roomId)).value?.joinRule,
      isNull,
    );
  });

  testWidgets('build_alwaysOffersTheRulesInOrder', (tester) async {
    // Act
    await pumpSection(tester);

    // Assert
    final titles = tester
        .widgetList<LinagoraRadioItem>(find.byType(LinagoraRadioItem))
        .map((item) => item.title);
    expect(titles, ['Invite only', 'On request', 'Public']);
  });
}
