import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info_view.dart';
import 'package:twake_chat/presentation/extensions/value_notifier_custom.dart';
import 'package:twake_chat/presentation/model/contact/presentation_contact.dart';
import 'package:twake_chat/presentation/model/pick_avatar_state.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/app_bars/twake_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'new_group_chat_info_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<NewGroupChatInfoScreenState>(),
  MockSpec<Client>(),
])
void main() {
  late MockNewGroupChatInfoScreenState mockController;

  // TwakeAppBar still reads ResponsiveUtils from GetIt.
  setUpAll(() => GetIt.instance.registerSingleton(ResponsiveUtils()));

  tearDownAll(() => GetIt.instance.reset());

  setUp(() {
    mockController = MockNewGroupChatInfoScreenState();

    // Setup default mock values for controller properties
    when(
      mockController.enableEncryptionNotifier,
    ).thenReturn(ValueNotifier(false));
    when(mockController.haveGroupNameNotifier).thenReturn(ValueNotifier(false));
    when(
      mockController.groupPrivacyNotifier,
    ).thenReturn(ValueNotifier(const GroupPrivacyState()));
    when(
      mockController.avatarUploadStateNotifier,
    ).thenReturn(ValueNotifier<Either<Failure, Success>?>(null));
    when(
      mockController.groupNameTextEditingController,
    ).thenReturn(TextEditingController());
    when(mockController.groupNameFocusNode).thenReturn(FocusNode());
    when(mockController.contactsList).thenReturn(<PresentationContact>{});
    when(mockController.isCreatingRoom).thenReturn(false);
    when(mockController.isUploadingAvatar).thenReturn(false);
    when(mockController.getErrorMessage(any)).thenReturn(null);
    when(
      mockController.avatarAssetEntityNotifier,
    ).thenReturn(ValueNotifier(null));
    when(mockController.pickAvatarUIState).thenReturn(
      ValueNotifierCustom<Either<Failure, Success>>(
        Right(GetAvatarInitialUIState()),
      ),
    );
    when(mockController.responsiveUtils).thenReturn(ResponsiveUtils());
  });

  group('NewGroupChatInfo AppBar verification - widget test', () {
    testWidgets('verify TwakeAppBar inside NewGroupChatInfoView', (
      WidgetTester tester,
    ) async {
      // Pump NewGroupChatInfoView directly with mock controller
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: ProviderScope(child: NewGroupChatInfoView(mockController)),
        ),
      );

      // Wait for widget to build
      await tester.pumpAndSettle();

      // Verify TwakeAppBar exists inside NewGroupChatInfoView
      expect(find.byType(TwakeAppBar), findsOneWidget);

      // Get the TwakeAppBar widget
      final twakeAppBar = tester.widget<TwakeAppBar>(find.byType(TwakeAppBar));

      // Verify TwakeAppBar properties
      expect(twakeAppBar.centerTitle, isTrue);
      expect(twakeAppBar.withDivider, isTrue);
      expect(twakeAppBar.enableLeftTitle, isTrue);

      // Verify title text
      final context = tester.element(find.byType(TwakeAppBar));
      expect(twakeAppBar.title, equals(L10n.of(context)!.newGroupChat));

      // Verify back button icon
      expect(find.byIcon(Icons.arrow_back_ios), findsOneWidget);
    });
  });

  group('NewGroupChatInfo in feed mode - widget test', () {
    HomeserverSummary summaryWith({required bool isPublicGroupsEnabled}) =>
        HomeserverSummary(
          discoveryInformation: DiscoveryInformation(
            mHomeserver: HomeserverInformation(
              baseUrl: Uri.parse('https://matrix.example.com'),
            ),
            additionalProperties: {
              'app.twake.chat': {
                'public_groups': {'enabled': isPublicGroupsEnabled},
              },
            },
          ),
          versions: GetVersionsResponse(versions: ['r1.6.0']),
          loginFlows: [],
        );

    Future<ValueNotifier<GroupPrivacyState>> pumpView(
      WidgetTester tester, {
      bool isPublicGroupsEnabled = true,
      GroupPrivacyState privacy = const GroupPrivacyState(),
    }) async {
      final privacyNotifier = ValueNotifier(privacy);
      addTearDown(privacyNotifier.dispose);
      when(mockController.groupPrivacyNotifier).thenReturn(privacyNotifier);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeMatrixClientProvider.overrideWithBuild((_, _) {
              final client = MockClient();
              when(client.userID).thenReturn('@alice:example.com');
              return ActiveClientSnapshot(client);
            }),
            loginHomeserverSummaryProvider.overrideWithBuild(
              (_, _) =>
                  summaryWith(isPublicGroupsEnabled: isPublicGroupsEnabled),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            home: NewGroupChatInfoView(mockController),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return privacyNotifier;
    }

    testWidgets('build_whenFeed_titlesTheScreenAfterTheFeed', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(true);

      // Act
      await pumpView(tester);

      // Assert
      final twakeAppBar = tester.widget<TwakeAppBar>(find.byType(TwakeAppBar));
      final context = tester.element(find.byType(TwakeAppBar));
      expect(twakeAppBar.title, equals(L10n.of(context)!.newFeed));
    });

    testWidgets('build_whenFeed_hidesTheEncryptionToggle', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(true);

      // Act
      await pumpView(tester);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.enableEncryption), findsNothing);
    });

    testWidgets('build_whenGroup_showsTheEncryptionToggle', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);

      // Act
      await pumpView(tester);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.enableEncryption), findsOneWidget);
      expect(
        find.text(L10n.of(context)!.groupPrivacyLimitToServer('example.com')),
        findsNothing,
      );
    });

    testWidgets(
      'build_whenPublic_showsTheServerLimitToggleAndHidesEncryption',
      (WidgetTester tester) async {
        // Arrange
        when(mockController.isFeed).thenReturn(false);

        // Act
        await pumpView(
          tester,
          privacy: const GroupPrivacyState(
            isPublic: true,
            isServerLimited: true,
          ),
        );

        // Assert
        final context = tester.element(find.byType(TwakeAppBar));
        expect(
          find.text(L10n.of(context)!.groupPrivacyLimitToServer('example.com')),
          findsOneWidget,
        );
        expect(find.text(L10n.of(context)!.enableEncryption), findsNothing);
      },
    );

    testWidgets('build_whenPublicGroupsDisabled_hidesThePublicToggle', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);

      // Act
      await pumpView(tester, isPublicGroupsEnabled: false);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.makeChatPublic), findsNothing);
      expect(find.text(L10n.of(context)!.enableEncryption), findsOneWidget);
    });

    Future<void> tapSetting(WidgetTester tester, String title) async {
      await tester.ensureVisible(find.text(title));
      await tester.tap(find.text(title));
      await tester.pumpAndSettle();
    }

    testWidgets('makeChatPublicToggle_whenTapped_makesTheGroupPublic', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);
      await pumpView(tester);
      final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;

      // Act
      await tapSetting(tester, l10n.makeChatPublic);

      // Assert
      verify(mockController.setPublic(isPublic: true)).called(1);
    });

    testWidgets(
      'build_whenPrivacyBecomesPublic_showsTheServerLimitToggleAndHidesEncryption',
      (WidgetTester tester) async {
        // Arrange
        when(mockController.isFeed).thenReturn(false);
        final privacyNotifier = await pumpView(tester);
        final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;

        // Act
        privacyNotifier.value = const GroupPrivacyState(
          isPublic: true,
          isServerLimited: true,
        );
        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text(l10n.groupPrivacyLimitToServer('example.com')),
          findsOneWidget,
        );
        expect(find.text(l10n.enableEncryption), findsNothing);
      },
    );

    testWidgets('serverLimitToggle_whenTapped_opensTheGroupToOtherServers', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);
      await pumpView(
        tester,
        privacy: const GroupPrivacyState(isPublic: true, isServerLimited: true),
      );
      final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;

      // Act
      await tapSetting(tester, l10n.groupPrivacyLimitToServer('example.com'));

      // Assert
      verify(mockController.setServerLimited(isServerLimited: false)).called(1);
    });

    testWidgets(
      'build_whenKeyboardLeavesLittleRoomUnderPublicSettings_doesNotOverflow',
      (WidgetTester tester) async {
        // Arrange
        when(mockController.isFeed).thenReturn(false);
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(411, 914);
        addTearDown(tester.view.reset);

        for (
          var keyboardHeight = 0;
          keyboardHeight <= 600;
          keyboardHeight += 5
        ) {
          // Act
          tester.view.viewInsets = FakeViewPadding(
            bottom: keyboardHeight.toDouble(),
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await pumpView(
            tester,
            privacy: const GroupPrivacyState(
              isPublic: true,
              isServerLimited: true,
            ),
          );

          // Assert
          expect(
            tester.takeException(),
            isNull,
            reason: 'Overflow with a $keyboardHeight px keyboard',
          );
        }
      },
    );

    testWidgets('build_whenEncryptionIsEnabled_showsTheWarning', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);
      when(
        mockController.enableEncryptionNotifier,
      ).thenReturn(ValueNotifier(true));

      // Act
      await pumpView(tester);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.encryptionWarning), findsOneWidget);
    });

    testWidgets('build_whenEncryptionIsDisabled_hidesTheWarning', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);

      // Act
      await pumpView(tester);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.encryptionWarning), findsNothing);
    });
  });
}
