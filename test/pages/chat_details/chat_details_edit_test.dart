import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderContainer, UncontrolledProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/data/room_access/repositories/room_access_repository.provider.dart';
import 'package:twake_chat/domain/room_access/entities/room_access.dart';
import 'package:twake_chat/domain/room_access/exceptions/room_access_exception.dart';
import 'package:twake_chat/domain/room_access/repositories/room_access_repository.dart';
import 'package:twake_chat/domain/usecase/room/update_group_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/domain/usecase/verify_name_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/chat_details_edit.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import 'room_access/public_groups_summary.dart';
import 'chat_details_edit_test.mocks.dart';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String? supportChatRoomId;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<Room>(),
  MockSpec<RoomAccessRepository>(),
  MockSpec<UpdateGroupChatInteractor>(),
  MockSpec<UploadContentInteractor>(),
  MockSpec<UploadContentInBytesInteractor>(),
  MockSpec<VerifyNameInteractor>(),
])
void main() {
  const roomId = '!room:example.com';
  const invite = RoomAccess(
    joinRule: JoinRuleChoice.invite,
    isListed: false,
    isEncrypted: false,
    canChange: true,
  );

  late MockClient client;
  late MockRoom room;
  late MockRoomAccessRepository repository;

  setUp(() {
    TwakeApp.routerKey = GlobalKey<NavigatorState>();
    final getIt = GetIt.instance;
    getIt.registerSingleton(ResponsiveUtils());
    final updateGroupChat = MockUpdateGroupChatInteractor();
    when(
      updateGroupChat.execute(
        client: anyNamed('client'),
        room: anyNamed('room'),
        avatarUrl: anyNamed('avatarUrl'),
        displayName: anyNamed('displayName'),
        description: anyNamed('description'),
        isDeleteAvatar: anyNamed('isDeleteAvatar'),
      ),
    ).thenAnswer((_) => const Stream.empty());
    getIt.registerSingleton<UpdateGroupChatInteractor>(updateGroupChat);
    getIt.registerSingleton<UploadContentInteractor>(
      MockUploadContentInteractor(),
    );
    getIt.registerSingleton<UploadContentInBytesInteractor>(
      MockUploadContentInBytesInteractor(),
    );
    getIt.registerSingleton<VerifyNameInteractor>(MockVerifyNameInteractor());

    client = MockClient();
    room = MockRoom();
    repository = MockRoomAccessRepository();
    when(client.getRoomById(roomId)).thenReturn(room);
    when(room.id).thenReturn(roomId);
    when(room.name).thenReturn('Group');
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
    when(room.enableEncryption()).thenAnswer((_) async {});
    when(
      repository.watchRoomAccess(roomId),
    ).thenAnswer((_) => Stream.value(invite));
  });

  tearDown(() => GetIt.instance.reset());

  Future<ChatDetailsEditController> pumpEdit(WidgetTester tester) async {
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
            navigatorKey: TwakeApp.routerKey,
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(context, Brightness.light, null),
            home: Provider<MatrixState>.value(
              value: _FakeMatrixState(client),
              child: const Scaffold(body: ChatDetailsEdit(roomId: roomId)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<ChatDetailsEditController>(
      find.byType(ChatDetailsEdit),
    );
  }

  Future<void> choosePublic(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Public'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Public'));
    await tester.pumpAndSettle();
  }

  testWidgets('save_whenTheServerRefuses_showsWhyAndKeepsDone', (tester) async {
    // Arrange
    when(
      repository.setJoinRule(roomId, JoinRuleChoice.public),
    ).thenThrow(const RoomAccessForbiddenException(cause: 'M_FORBIDDEN'));
    await pumpEdit(tester);
    await choosePublic(tester);

    // Act
    await tester.tap(find.byIcon(Icons.done));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('The server refused this change.'), findsOneWidget);
    expect(find.byIcon(Icons.done), findsOneWidget);
  });

  testWidgets('enableEncryption_publicRoomWithoutTheSection_sendsNothing', (
    tester,
  ) async {
    // Arrange
    when(
      repository.watchRoomAccess(roomId),
    ).thenAnswer((_) => Stream.value(invite.copyWith(canChange: false)));
    when(room.joinRules).thenReturn(JoinRules.public);
    final controller = await pumpEdit(tester);

    // Act
    controller.enableEncryption(null);
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(room.enableEncryption());
  });

  testWidgets('enableEncryption_roomMadePublicDuringTheDialog_sendsNothing', (
    tester,
  ) async {
    // Arrange
    final controller = await pumpEdit(tester);
    controller.enableEncryption(null);
    await tester.pumpAndSettle();
    when(room.joinRules).thenReturn(JoinRules.public);

    // Act
    await tester.tap(find.text('YES'));
    await tester.pump(const Duration(seconds: 1));

    // Assert
    verifyNever(room.enableEncryption());
  });

  testWidgets('enableEncryption_refusedByTheServer_keepsTheSwitchOff', (
    tester,
  ) async {
    // Arrange
    when(room.enableEncryption()).thenAnswer(
      (_) async => throw MatrixException.fromJson({'errcode': 'M_FORBIDDEN'}),
    );
    final controller = await pumpEdit(tester);
    controller.enableEncryption(null);
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('YES'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('Cancel').last);
    await tester.pump(const Duration(seconds: 1));

    // Assert
    expect(controller.isRoomEnabledEncryptionNotifier.value, isFalse);
  });

  testWidgets('save_whenABugThrows_closesTheLoadingDialog', (tester) async {
    // Arrange
    when(
      repository.setJoinRule(roomId, JoinRuleChoice.public),
    ).thenAnswer((_) async => throw StateError('bug'));
    final controller = await pumpEdit(tester);
    await choosePublic(tester);
    Object? error;

    // Act
    runZonedGuarded(
      () => controller.handleSaveAction(controller.context),
      (e, _) => error = e,
    );
    await tester.pumpAndSettle();

    // Assert
    expect(error, isA<StateError>());
    expect(find.byType(ProgressDialog), findsNothing);
  });
}
