import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/style/linagora_text_theme.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/forward/forward_repository.provider.dart';
import 'package:twake_chat/domain/repository/forward/forward_repository.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/forward/forward.dart';
import 'package:twake_chat/utils/dialog/twake_dialog.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/app_bars/searchable_app_bar.dart';

import 'forward_screen_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ForwardRepository>()])
void main() {
  const message = {'msgtype': 'm.text', 'body': 'hello'};
  const roomIds = ['!a:example.com', '!b:example.com'];

  late MockForwardRepository mockRepository;

  // The shared app bar still reads ResponsiveUtils from GetIt.
  setUpAll(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDownAll(() => GetIt.instance.reset());

  setUp(() {
    mockRepository = MockForwardRepository();
    when(mockRepository.isJoined(any)).thenReturn(true);
  });

  Future<L10n> pumpForwardScreen(
    WidgetTester tester, {
    List<Map<String, Object?>> messages = const [message],
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forwardRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Forward(messages: messages),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return L10n.of(tester.element(find.byType(Forward)))!;
  }

  ForwardScreenState screen(WidgetTester tester) =>
      tester.state<ForwardScreenState>(find.byType(Forward));

  bool isBackButtonShown(WidgetTester tester) => tester
      .widget<SearchableAppBar>(find.byType(SearchableAppBar))
      .displayBackButton;

  void selectRooms(WidgetTester tester) {
    for (final roomId in roomIds) {
      screen(tester).onToggleSelectChat(roomId);
    }
  }

  void answerSends(Future<void> Function() answer) => when(
    mockRepository.sendMessage(
      roomId: anyNamed('roomId'),
      content: anyNamed('content'),
    ),
  ).thenAnswer((_) async => answer());

  Future<void> settleSend(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('forward_whenNothingIsSent_keepsTheScreenOpenAndHidesTheDialog', (
    tester,
  ) async {
    // Arrange
    final l10n = await pumpForwardScreen(tester);
    final sent = Completer<void>();
    answerSends(() => sent.future);
    selectRooms(tester);

    // Act
    screen(tester).forwardAction();
    await tester.pump(const Duration(milliseconds: 800));
    final dialogsWhileSending = find.byType(ProgressDialog).evaluate().length;
    final backButtonWhileSending = isBackButtonShown(tester);
    sent.completeError(Exception('network'));
    await settleSend(tester);

    // Assert
    expect(dialogsWhileSending, 1);
    expect(backButtonWhileSending, isFalse);
    expect(find.byType(ProgressDialog), findsNothing);
    expect(find.byType(Forward), findsOneWidget);
    expect(find.text(l10n.forwardFailed), findsOneWidget);
    expect(isBackButtonShown(tester), isTrue);
    expect(screen(tester).selectedRoomIds, roomIds);
  });

  testWidgets('forward_retryAfterFailure_closesTheScreenWithTheSummary', (
    tester,
  ) async {
    // Arrange
    final l10n = await pumpForwardScreen(tester);
    answerSends(() => Future.error(Exception('network')));
    selectRooms(tester);
    screen(tester).forwardAction();
    await settleSend(tester);
    answerSends(() async {});

    // Act
    screen(tester).forwardAction();
    await settleSend(tester);

    // Assert
    expect(find.byType(ProgressDialog), findsNothing);
    expect(find.byType(Forward), findsNothing);
    expect(find.text(l10n.forwardedToChats(2)), findsOneWidget);
  });

  testWidgets('forward_whenOnlySomeRoomsSucceed_closesTheScreen', (
    tester,
  ) async {
    // Arrange
    final l10n = await pumpForwardScreen(tester);
    when(
      mockRepository.sendMessage(roomId: roomIds.last, content: message),
    ).thenAnswer((_) => Future.error(Exception('network')));
    selectRooms(tester);

    // Act
    screen(tester).forwardAction();
    await settleSend(tester);

    // Assert
    expect(find.byType(Forward), findsNothing);
    expect(
      find.text(l10n.forwardedToChatsPartial(1, roomIds.length)),
      findsOneWidget,
    );
  });

  testWidgets(
    'forward_whenEveryRoomGotOnlySomeMessages_closesWithThePartialSummary',
    (tester) async {
      // Arrange
      const second = {'msgtype': 'm.text', 'body': 'second'};
      final l10n = await pumpForwardScreen(tester, messages: [message, second]);
      when(
        mockRepository.sendMessage(roomId: anyNamed('roomId'), content: second),
      ).thenAnswer((_) => Future.error(Exception('network')));
      selectRooms(tester);

      // Act
      screen(tester).forwardAction();
      await settleSend(tester);

      // Assert
      expect(find.byType(Forward), findsNothing);
      expect(find.text(l10n.forwardFailed), findsNothing);
      expect(
        find.text(l10n.forwardedToChatsPartial(0, roomIds.length)),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'forward_whenTheOnlyRoomGotSomeMessages_closesWithThePartialSummary',
    (tester) async {
      // Arrange
      const second = {'msgtype': 'm.text', 'body': 'second'};
      final l10n = await pumpForwardScreen(tester, messages: [message, second]);
      when(
        mockRepository.sendMessage(roomId: roomIds.first, content: second),
      ).thenAnswer((_) => Future.error(Exception('network')));
      screen(tester).onToggleSelectChat(roomIds.first);

      // Act
      screen(tester).forwardAction();
      await settleSend(tester);

      // Assert
      expect(find.byType(Forward), findsNothing);
      expect(find.text(l10n.forwardedToChatsPartial(0, 1)), findsOneWidget);
    },
  );

  testWidgets('forward_whenTheUseCaseThrowsAnError_hidesTheDialogAndStays', (
    tester,
  ) async {
    // Arrange
    final l10n = await pumpForwardScreen(tester);
    when(mockRepository.isJoined(any)).thenThrow(StateError('bug'));
    selectRooms(tester);
    final errors = <Object>[];

    // Act
    runZonedGuarded(
      screen(tester).forwardAction,
      (error, _) => errors.add(error),
    );
    await settleSend(tester);
    final snackBarShown = find.text(l10n.forwardFailed).evaluate().isNotEmpty;
    when(mockRepository.isJoined(any)).thenReturn(true);
    screen(tester).forwardAction();
    await settleSend(tester);

    // Assert
    expect(errors.single, isStateError);
    expect(snackBarShown, isTrue);
    expect(find.byType(ProgressDialog), findsNothing);
    expect(find.byType(Forward), findsNothing);
    expect(find.text(l10n.forwardedToChats(2)), findsOneWidget);
  });
}
