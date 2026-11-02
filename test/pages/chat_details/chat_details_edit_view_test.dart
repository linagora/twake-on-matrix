import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository.provider.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit_view.dart';
import 'package:twake_chat/pages/chat_details/room_access/room_access_draft.dart';
import 'package:twake_chat/presentation/model/pick_avatar_state.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/presentation/extensions/value_notifier_custom.dart';

import 'room_access/public_groups_summary.dart';
import 'chat_details_edit_view_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<ChatDetailsEditController>(),
  MockSpec<Room>(),
  MockSpec<RoomAccessRepository>(),
])
void main() {
  const roomId = '!room:example.com';
  const invite = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: false,
    canChange: true,
  );

  late MockChatDetailsEditController controller;
  late MockRoom room;
  late MockRoomAccessRepository repository;
  late ValueNotifier<RoomAccessDraft> draft;

  setUpAll(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDownAll(() => GetIt.instance.reset());

  setUp(() {
    controller = MockChatDetailsEditController();
    room = MockRoom();
    repository = MockRoomAccessRepository();
    draft = ValueNotifier(const RoomAccessDraft());
    when(room.id).thenReturn(roomId);
    when(room.joinRules).thenReturn(JoinRules.invite);
    when(room.historyVisibility).thenReturn(HistoryVisibility.shared);
    when(room.encrypted).thenReturn(false);
    when(room.ownPowerLevel).thenReturn(PowerLevel(50));
    when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
      StrippedStateEvent(
        type: EventTypes.RoomPowerLevels,
        content: {
          'state_default': 50,
          'events': {EventTypes.RoomPowerLevels: 100},
        },
        senderId: '@admin:example.com',
        stateKey: '',
      ),
    );
    when(room.getLocalizedDisplayname(any)).thenReturn('Group');
    when(controller.room).thenReturn(room);
    when(controller.widget).thenReturn(const ChatDetailsEdit(roomId: roomId));
    when(controller.roomAccessDraftNotifier).thenReturn(draft);
    when(controller.isValidGroupNameNotifier).thenReturn(ValueNotifier(true));
    when(controller.isEditedGroupInfoNotifier).thenReturn(ValueNotifier(false));
    when(
      controller.isRoomEnabledEncryptionNotifier,
    ).thenReturn(ValueNotifier(false));
    when(controller.groupNameEmptyNotifier).thenReturn(ValueNotifier(false));
    when(controller.descriptionEmptyNotifier).thenReturn(ValueNotifier(false));
    when(
      controller.groupNameTextEditingController,
    ).thenReturn(TextEditingController(text: 'Group'));
    when(
      controller.descriptionTextEditingController,
    ).thenReturn(TextEditingController());
    when(controller.groupNameFocusNode).thenReturn(FocusNode());
    when(controller.descriptionFocusNode).thenReturn(FocusNode());
    when(controller.menuController).thenReturn(MenuController());
    when(controller.pickAvatarUIState).thenReturn(
      ValueNotifierCustom<Either<Failure, Success>>(
        Right(GetAvatarInitialUIState()),
      ),
    );
    when(controller.isSupportChat).thenReturn(true);
  });

  tearDown(() => draft.dispose());

  Future<void> pumpView(WidgetTester tester) async {
    when(
      repository.watchRoomAccess(roomId),
    ).thenAnswer((_) => Stream.value(invite));
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        roomAccessRepositoryProvider.overrideWithValue(repository),
        loginHomeserverSummaryProvider.overrideWithBuild(
          (_, _) => summaryWith(isPublicGroupsEnabled: true),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Builder(
          builder: (context) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(context, Brightness.light, null),
            home: ChatDetailsEditView(controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Switch encryptionSwitch(WidgetTester tester) => tester.widget<Switch>(
    find.descendant(
      of: find.widgetWithText(ListTile, 'Encryption'),
      matching: find.byType(Switch),
    ),
  );

  testWidgets('build_inviteRoom_offersEncryptionAndHidesDone', (tester) async {
    // Act
    await pumpView(tester);

    // Assert
    expect(encryptionSwitch(tester).onChanged, isNotNull);
    expect(find.byIcon(Icons.done), findsNothing);
  });

  testWidgets('choosePublic_always_greysEncryptionAndShowsDone', (
    tester,
  ) async {
    // Arrange
    await pumpView(tester);

    // Act
    await tester.ensureVisible(find.text('Public'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Public'));
    await tester.pumpAndSettle();

    // Assert
    expect(encryptionSwitch(tester).onChanged, isNull);
    expect(find.text("A public room can't be encrypted."), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);
  });

  testWidgets('build_worldReadableRoom_greysEncryption', (tester) async {
    // Arrange
    when(room.historyVisibility).thenReturn(HistoryVisibility.worldReadable);

    // Act
    await pumpView(tester);

    // Assert
    expect(encryptionSwitch(tester).onChanged, isNull);
  });
}
