import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/rtc_focus.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.dart';
import 'package:twake_chat/domain/video_call/usecases/start_video_call_usecase.provider.dart';
import 'package:twake_chat/domain/exception/video_call/video_call_exception.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat/chat.dart';
import 'package:twake_chat/pages/chat/chat_video_call_button.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

import 'chat_video_call_button_test.mocks.dart';

class _FakeChatController extends Fake implements ChatController {
  _FakeChatController(this.room);

  @override
  final Room? room;

  @override
  bool canStartVideoCall(String? videoCallBaseUrl) => videoCallBaseUrl != null;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      '_FakeChatController';
}

@GenerateNiceMocks([
  MockSpec<StartVideoCallUseCase>(),
  MockSpec<Client>(),
  MockSpec<Room>(),
])
void main() {
  late MockStartVideoCallUseCase mockUseCase;
  late MockClient mockClient;
  late MockRoom mockRoom;

  const testRoomId = '!room:example.com';

  HomeserverSummary summaryOf({required bool withVideoCall}) =>
      HomeserverSummary(
        discoveryInformation: DiscoveryInformation(
          mHomeserver: HomeserverInformation(
            baseUrl: Uri.parse('https://matrix.example.com'),
          ),
          additionalProperties: {
            if (withVideoCall)
              RtcFocus.rtcFociKey: [
                {
                  'type': RtcFocus.liveKitType,
                  'livekit_base_url': 'https://meet.example.com/',
                },
              ],
          },
        ),
        versions: GetVersionsResponse(versions: ['v1.11']),
        loginFlows: [],
      );

  PostExpectation<Future<void>> whenExecute() => when(
    mockUseCase.execute(
      roomId: anyNamed('roomId'),
      baseUrl: anyNamed('baseUrl'),
      startedTitle: anyNamed('startedTitle'),
    ),
  );

  Future<void> pumpButton(
    WidgetTester tester, {
    bool withVideoCall = true,
  }) async {
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        startVideoCallUseCaseProvider(
          mockClient,
        ).overrideWithValue(mockUseCase),
      ],
    );
    container
        .read(loginHomeserverSummaryProvider.notifier)
        .set(summaryOf(withVideoCall: withVideoCall));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: ChatVideoCallButton(_FakeChatController(mockRoom)),
          ),
        ),
      ),
    );
  }

  setUp(() {
    GetIt.instance.registerSingleton(ResponsiveUtils());
    mockUseCase = MockStartVideoCallUseCase();
    mockClient = MockClient();
    mockRoom = MockRoom();
    when(mockRoom.client).thenReturn(mockClient);
    when(mockRoom.id).thenReturn(testRoomId);
  });

  tearDown(() => GetIt.instance.reset());

  group('ChatVideoCallButton', () {
    testWidgets('build_whenHomeserverHasNoVideoCall_isHidden', (tester) async {
      // Act
      await pumpButton(tester, withVideoCall: false);

      // Assert
      expect(find.byType(TwakeIconButton), findsNothing);
    });

    testWidgets('onTap_always_startsTheCallOnTheVideoCallBaseUrl', (
      tester,
    ) async {
      // Arrange
      await pumpButton(tester);

      // Act
      await tester.tap(find.byType(TwakeIconButton));
      await tester.pump();

      // Assert
      verify(
        mockUseCase.execute(
          roomId: testRoomId,
          baseUrl: 'https://meet.example.com',
          startedTitle: 'Has started a video call',
        ),
      ).called(1);
    });

    testWidgets('build_whileTheCallIsStarting_showsAProgressIndicator', (
      tester,
    ) async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);
      await pumpButton(tester);

      // Act
      await tester.tap(find.byType(TwakeIconButton));
      await tester.pump();

      // Assert
      expect(find.byType(TwakeIconButton), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pump();
      expect(find.byType(TwakeIconButton), findsOneWidget);
    });

    testWidgets('onTap_whileTheCallIsStarting_startsASingleCall', (
      tester,
    ) async {
      // Arrange
      final completer = Completer<void>();
      whenExecute().thenAnswer((_) => completer.future);
      await pumpButton(tester);

      // Act
      await tester.tap(find.byType(TwakeIconButton));
      await tester.pump();
      await tester.tap(find.byType(CircularProgressIndicator));
      completer.complete();
      await tester.pump();

      // Assert
      verify(
        mockUseCase.execute(
          roomId: anyNamed('roomId'),
          baseUrl: anyNamed('baseUrl'),
          startedTitle: anyNamed('startedTitle'),
        ),
      ).called(1);
    });

    testWidgets('build_whenTheCallFailsToStart_showsASnackBar', (tester) async {
      // Arrange
      whenExecute().thenAnswer(
        (_) => Future.error(
          VideoCallRoomCreationFailedException(cause: Exception('502')),
        ),
      );
      await pumpButton(tester);

      // Act
      await tester.tap(find.byType(TwakeIconButton));
      await tester.pump();
      await tester.pump();

      // Assert
      expect(find.text('Failed to start the call'), findsOneWidget);
      expect(find.byType(TwakeIconButton), findsOneWidget);
    });
  });
}
