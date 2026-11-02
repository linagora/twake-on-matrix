import 'package:dartz/dartz.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
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
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
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

    void stubKind(NewGroupKind kind) {
      when(mockController.kind).thenReturn(kind);
      when(mockController.isFeed).thenReturn(kind.isFeed);
      when(mockController.isSpace).thenReturn(kind.isSpace);
    }

    Future<ValueNotifier<GroupPrivacyState>> pumpView(
      WidgetTester tester, {
      bool isPublicGroupsEnabled = true,
      GroupPrivacyState privacy = const GroupPrivacyState(),
      List<SpaceSummary> spaces = const [],
      String? parentSpaceId,
    }) async {
      final privacyNotifier = ValueNotifier(privacy);
      addTearDown(privacyNotifier.dispose);
      when(mockController.groupPrivacyNotifier).thenReturn(privacyNotifier);
      final parentNotifier = ValueNotifier<String?>(parentSpaceId);
      addTearDown(parentNotifier.dispose);
      when(mockController.parentSpaceNotifier).thenReturn(parentNotifier);
      final topic = TextEditingController();
      addTearDown(topic.dispose);
      when(mockController.topicTextEditingController).thenReturn(topic);
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
            addableSpacesProvider.overrideWithValue(spaces),
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

    LinagoraSettingItem settingItem(WidgetTester tester, String title) =>
        tester.widget<LinagoraSettingItem>(
          find.widgetWithText(LinagoraSettingItem, title),
        );

    const team = SpaceSummary(
      id: '!team',
      name: 'Team',
      memberCount: 1,
      isPublic: false,
      canInvite: true,
      canAddChildren: true,
    );

    testWidgets('build_whenSpace_keepsTheFormWithoutEncryption', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.space);

      // Act
      await pumpView(tester);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      final l10n = L10n.of(context)!;
      expect(
        tester.widget<TwakeAppBar>(find.byType(TwakeAppBar)).title,
        l10n.newSpace,
      );
      expect(find.text(l10n.enableEncryption), findsNothing);
      expect(find.text(l10n.makeChatPublic), findsOneWidget);
      expect(
        find.byKey(const ValueKey('new_space_description')),
        findsOneWidget,
      );
    });

    testWidgets('build_whenGroup_hasNoDescription', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.group);

      // Act
      await pumpView(tester);

      // Assert
      expect(find.byKey(const ValueKey('new_space_description')), findsNothing);
    });

    testWidgets('build_whenUserHasSpaces_offersThemForAGroup', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.group);

      // Act
      await pumpView(tester, spaces: const [team], parentSpaceId: '!team');

      // Assert
      expect(
        find.byKey(const ValueKey('new_group_parent_space')),
        findsOneWidget,
      );
      expect(find.text('Team'), findsOneWidget);
    });

    testWidgets('build_whenUserHasNoSpace_offersNothing', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.group);

      // Act
      await pumpView(tester);

      // Assert
      expect(
        find.byKey(const ValueKey('new_group_parent_space')),
        findsNothing,
      );
    });

    testWidgets('build_whenFeed_offersNoSpace', (WidgetTester tester) async {
      // Arrange
      stubKind(NewGroupKind.feed);

      // Act
      await pumpView(tester, spaces: const [team]);

      // Assert
      expect(
        find.byKey(const ValueKey('new_group_parent_space')),
        findsNothing,
      );
    });

    testWidgets('build_whenFeed_titlesTheScreenAfterTheFeed', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.feed);

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
      stubKind(NewGroupKind.feed);

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
      stubKind(NewGroupKind.group);

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
      'build_whenPublic_showsTheServerLimitToggleAndGreysOutEncryption',
      (WidgetTester tester) async {
        // Arrange
        stubKind(NewGroupKind.group);

        // Act
        await pumpView(
          tester,
          privacy: const GroupPrivacyState(
            isPublic: true,
            isServerLimited: true,
          ),
        );

        // Assert
        final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;
        expect(
          find.text(l10n.groupPrivacyLimitToServer('example.com')),
          findsOneWidget,
        );
        expect(settingItem(tester, l10n.enableEncryption).enabled, isFalse);
        expect(
          find.text(l10n.encryptionUnavailableForPublicChat),
          findsOneWidget,
        );
        expect(settingItem(tester, l10n.makeChatPublic).enabled, isTrue);
      },
    );

    testWidgets(
      'build_whenEncrypted_greysOutPublicAndHidesTheServerLimitToggle',
      (WidgetTester tester) async {
        // Arrange
        when(mockController.isFeed).thenReturn(false);

        // Act
        await pumpView(
          tester,
          privacy: const GroupPrivacyState(isEncrypted: true),
        );

        // Assert
        final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;
        expect(settingItem(tester, l10n.makeChatPublic).enabled, isFalse);
        expect(
          find.text(l10n.publicUnavailableForEncryptedChat),
          findsOneWidget,
        );
        expect(settingItem(tester, l10n.enableEncryption).enabled, isTrue);
        expect(
          find.text(l10n.groupPrivacyLimitToServer('example.com')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'build_whenPrivateAndUnencrypted_showsBothTogglesEnabledEncryptionFirst',
      (WidgetTester tester) async {
        // Arrange
        when(mockController.isFeed).thenReturn(false);

        // Act
        await pumpView(tester);

        // Assert
        final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;
        final encryption = settingItem(tester, l10n.enableEncryption);
        final public = settingItem(tester, l10n.makeChatPublic);
        expect(encryption.enabled && !encryption.value, isTrue);
        expect(public.enabled && !public.value, isTrue);
        expect(
          tester.getTopLeft(find.text(l10n.enableEncryption)).dy,
          lessThan(tester.getTopLeft(find.text(l10n.makeChatPublic)).dy),
        );
      },
    );

    testWidgets('build_whenPublicGroupsDisabled_hidesThePublicToggle', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.group);

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
      stubKind(NewGroupKind.group);
      await pumpView(tester);
      final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;

      // Act
      await tapSetting(tester, l10n.makeChatPublic);

      // Assert
      verify(mockController.setPublic(isPublic: true)).called(1);
    });

    testWidgets(
      'build_whenPrivacyBecomesPublic_showsTheServerLimitToggleAndGreysOutEncryption',
      (WidgetTester tester) async {
        // Arrange
        stubKind(NewGroupKind.group);
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
        expect(settingItem(tester, l10n.enableEncryption).enabled, isFalse);
      },
    );

    testWidgets('encryptionToggle_whenTapped_encryptsTheGroup', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);
      await pumpView(tester);
      final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;

      // Act
      await tapSetting(tester, l10n.enableEncryption);

      // Assert
      verify(mockController.setEncrypted(isEncrypted: true)).called(1);
    });

    testWidgets('makeChatPublicToggle_whenEncrypted_ignoresTaps', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(mockController.isFeed).thenReturn(false);
      await pumpView(
        tester,
        privacy: const GroupPrivacyState(isEncrypted: true),
      );
      final l10n = L10n.of(tester.element(find.byType(TwakeAppBar)))!;

      // Act
      await tapSetting(tester, l10n.makeChatPublic);

      // Assert
      verifyNever(mockController.setPublic(isPublic: anyNamed('isPublic')));
    });

    testWidgets('serverLimitToggle_whenTapped_opensTheGroupToOtherServers', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.group);
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
        stubKind(NewGroupKind.group);
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
      stubKind(NewGroupKind.group);

      // Act
      await pumpView(
        tester,
        privacy: const GroupPrivacyState(isEncrypted: true),
      );

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.encryptionWarning), findsOneWidget);
    });

    testWidgets('build_whenEncryptionIsDisabled_hidesTheWarning', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubKind(NewGroupKind.group);

      // Act
      await pumpView(tester);

      // Assert
      final context = tester.element(find.byType(TwakeAppBar));
      expect(find.text(L10n.of(context)!.encryptionWarning), findsNothing);
    });
  });
}
