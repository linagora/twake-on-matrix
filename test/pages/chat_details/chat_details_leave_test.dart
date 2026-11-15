import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/usecase/room/ban_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/chat_details.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import 'chat_details_leave_test.mocks.dart';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<Room>(),
  MockSpec<BanUserInteractor>(),
  MockSpec<TimelineSearchEventInteractor>(),
])
void main() {
  const roomId = '!group:example.com';

  late MockClient client;
  late MockRoom room;

  setUp(() {
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<BanUserInteractor>(MockBanUserInteractor())
      ..registerSingleton<TimelineSearchEventInteractor>(
        MockTimelineSearchEventInteractor(),
      );
    client = MockClient();
    room = MockRoom();
    when(client.getRoomById(roomId)).thenReturn(room);
    when(client.onEvent).thenReturn(CachedStreamController());
    when(client.onSync).thenReturn(CachedStreamController());
    when(room.id).thenReturn(roomId);
    when(room.client).thenReturn(client);
    when(room.onUpdate).thenReturn(CachedStreamController());
    when(room.isSpace).thenReturn(true);
    when(room.encrypted).thenReturn(true);
    when(room.ownPowerLevel).thenReturn(PowerLevel(0));
    when(room.getState(EventTypes.RoomPowerLevels)).thenReturn(
      StrippedStateEvent(
        type: EventTypes.RoomPowerLevels,
        content: {'state_default': 50, 'events_default': 0, 'ban': 50},
        senderId: '@admin:example.com',
        stateKey: '',
      ),
    );
    when(room.getParticipants()).thenReturn([]);
    when(room.summary).thenReturn(RoomSummary.fromJson({}));
    when(room.getLocalizedDisplayname(any)).thenReturn('Group');
    when(room.leave()).thenAnswer((_) async {});
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpDetails(WidgetTester tester) async {
    final router = GoRouter(
      navigatorKey: TwakeApp.routerKey = GlobalKey<NavigatorState>(),
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/details',
          builder: (_, _) => const Scaffold(
            body: ChatDetails(roomId: roomId, isInStack: true),
          ),
        ),
        GoRoute(
          path: '/rooms',
          builder: (_, _) => const Scaffold(body: Text('rooms')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      Provider<MatrixState>.value(
        value: _FakeMatrixState(client),
        child: Builder(
          builder: (context) => MaterialApp.router(
            routerConfig: router,
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(context, Brightness.light, null),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapLeaveInMoreMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.logout));
    await tester.pumpAndSettle();
  }

  testWidgets('leave_fromTheMoreMenu_asksForConfirmation', (tester) async {
    // Arrange
    await pumpDetails(tester);

    // Act
    await tapLeaveInMoreMenu(tester);

    // Assert
    expect(
      find.text('Are you sure you want to leave this chat?'),
      findsOneWidget,
    );
    verifyNever(room.leave());
  });

  testWidgets('leave_cancelled_keepsTheRoom', (tester) async {
    // Arrange
    await pumpDetails(tester);
    await tapLeaveInMoreMenu(tester);

    // Act
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Assert
    verifyNever(room.leave());
    expect(find.byType(ChatDetails), findsOneWidget);
  });

  testWidgets('leave_confirmed_leavesTheRoom', (tester) async {
    // Arrange
    await pumpDetails(tester);
    await tapLeaveInMoreMenu(tester);

    // Act
    await tester.tap(find.text('Leave'));
    await tester.pumpAndSettle();

    // Assert
    verify(room.leave()).called(1);
    expect(find.text('rooms'), findsOneWidget);
  });
}
