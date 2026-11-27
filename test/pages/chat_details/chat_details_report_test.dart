import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:matrix/src/utils/cached_stream_controller.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart' show Provider;
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/exception/report/report_exception.dart';
import 'package:twake_chat/domain/report/usecases/report_room_usecase.dart';
import 'package:twake_chat/domain/report/usecases/report_room_usecase.provider.dart';
import 'package:twake_chat/domain/usecase/room/ban_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/timeline_search_event_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_details/chat_details.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import '../../domain/report/fake_report_repository.dart';
import 'chat_details_report_test.mocks.dart';

class _FakeMatrixState extends Fake implements MatrixState {
  _FakeMatrixState(this.client);

  @override
  final Client client;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeMatrixState';
}

const _roomId = '!group:example.com';

MockClient _clientWithGroup() {
  final client = MockClient();
  final room = MockRoom();
  when(client.getRoomById(_roomId)).thenReturn(room);
  when(client.onEvent).thenReturn(CachedStreamController());
  when(client.onSync).thenReturn(CachedStreamController());
  when(room.id).thenReturn(_roomId);
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
  when(room.getTimeline()).thenAnswer((_) async => MockTimeline());
  return client;
}

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<Room>(),
  MockSpec<Timeline>(),
  MockSpec<BanUserInteractor>(),
  MockSpec<TimelineSearchEventInteractor>(),
])
void main() {
  late FakeReportRepository repository;

  setUp(() {
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<BanUserInteractor>(MockBanUserInteractor())
      ..registerSingleton<TimelineSearchEventInteractor>(
        MockTimelineSearchEventInteractor(),
      );
    repository = FakeReportRepository();
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> pumpDetails(WidgetTester tester) async {
    final client = _clientWithGroup();
    final router = GoRouter(
      navigatorKey: TwakeApp.routerKey = GlobalKey<NavigatorState>(),
      initialLocation: '/details',
      routes: [
        GoRoute(
          path: '/details',
          builder: (_, _) => const Scaffold(
            body: ChatDetails(roomId: _roomId, isInStack: true),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matrixClientProvider.overrideWithValue(client),
          reportRoomUseCaseProvider.overrideWithValue(
            ReportRoomUseCase(repository),
          ),
        ],
        child: Provider<MatrixState>.value(
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
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  Future<void> openReport(WidgetTester tester) async {
    await pumpDetails(tester);
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
  }

  testWidgets('report_fromTheMoreMenu_opensTheReasonsWithoutSending', (
    tester,
  ) async {
    await openReport(tester);

    expect(find.text('What’s the issue with this chat?'), findsOneWidget);
    expect(find.text('Spam'), findsOneWidget);
    expect(repository.roomReports, isEmpty);
  });

  testWidgets('report_whenAReasonIsPicked_asksForConfirmation', (tester) async {
    await openReport(tester);

    await tapText(tester, 'Spam');

    expect(find.text('Send this report?'), findsOneWidget);
    expect(find.text('Reason: Spam'), findsOneWidget);
    expect(repository.roomReports, isEmpty);
  });

  testWidgets('report_whenConfirmed_sendsTheReasonAndShowsSuccess', (
    tester,
  ) async {
    await openReport(tester);
    await tapText(tester, 'Spam');

    await tapText(tester, 'Send Report');

    expect(repository.roomReports, [(roomId: _roomId, reason: 'Spam')]);
    expect(
      find.text('The content has been reported to the server admins'),
      findsOneWidget,
    );
  });

  testWidgets('report_whenTheConfirmIsCancelled_sendsNothing', (tester) async {
    await openReport(tester);
    await tapText(tester, 'Spam');

    await tapText(tester, 'Cancel');

    expect(repository.roomReports, isEmpty);
    expect(find.text('Send this report?'), findsNothing);
  });

  testWidgets('report_withOther_sendsTheComment', (tester) async {
    await openReport(tester);
    await tapText(tester, 'Other');
    await tester.enterText(find.byType(TextField), 'rude');
    await tapText(tester, 'Send Report');

    expect(find.text('Reason: Other: rude'), findsOneWidget);
    await tapText(tester, 'Send Report');

    expect(repository.roomReports, [(roomId: _roomId, reason: 'Other: rude')]);
  });

  testWidgets('report_whenTheServerFails_showsErrorAndKeepsTheDraft', (
    tester,
  ) async {
    repository.reportRoomError = ReportRoomFailedException(
      roomId: _roomId,
      cause: Exception('server error'),
    );
    await openReport(tester);
    await tapText(tester, 'Spam');
    await tapText(tester, 'Send Report');

    expect(find.text('Oops, something went wrong…'), findsOneWidget);
    expect(find.text('Reason: Spam'), findsOneWidget);
    expect(
      find.text('The content has been reported to the server admins'),
      findsNothing,
    );

    repository.reportRoomError = null;
    await tapText(tester, 'Send Report');

    expect(repository.roomReports, [(roomId: _roomId, reason: 'Spam')]);
  });
}
