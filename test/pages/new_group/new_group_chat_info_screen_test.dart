import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'new_group_chat_info_screen_test.mocks.dart';
import '../../providers/fake_active_account.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<CreateNewFeedInteractor>(),
  MockSpec<NewGroupRepository>(),
  MockSpec<UploadContentInteractor>(),
  MockSpec<UploadContentInBytesInteractor>(),
])
void main() {
  late MockClient mockClient;
  late MockCreateNewFeedInteractor mockCreateNewFeedInteractor;
  late MockNewGroupRepository mockRepository;

  setUpAll(() {
    GetIt.instance
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<UploadContentInteractor>(
        MockUploadContentInteractor(),
      )
      ..registerSingleton<UploadContentInBytesInteractor>(
        MockUploadContentInBytesInteractor(),
      );
  });

  tearDownAll(() => GetIt.instance.reset());

  setUp(() {
    mockClient = MockClient();
    mockCreateNewFeedInteractor = MockCreateNewFeedInteractor();
    mockRepository = MockNewGroupRepository();
    // Never completes: the screen is not under a router, so it must not navigate.
    when(
      mockRepository.createGroup(any),
    ).thenAnswer((_) => Completer<String>().future);
  });

  void stubFeedCreationFailure(FeedException exception) {
    when(
      mockCreateNewFeedInteractor.execute(
        feedName: anyNamed('feedName'),
        avatarUrl: anyNamed('avatarUrl'),
      ),
    ).thenAnswer((_) => Future.error(exception));
  }

  Future<NewGroupChatInfoScreenState> pumpScreen(
    WidgetTester tester, {
    bool isFeed = false,
    bool isPublicGroupsEnabled = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...activeAccountOverrides(mockClient),
          newGroupRepositoryProvider.overrideWithValue(mockRepository),
          createNewFeedInteractorProvider(
            mockClient,
          ).overrideWithValue(mockCreateNewFeedInteractor),
          loginHomeserverSummaryProvider.overrideWithBuild(
            (_, _) => HomeserverSummary(
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
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: NewGroupChatInfo(contactsList: const {}, isFeed: isFeed),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<NewGroupChatInfoScreenState>(
      find.byType(NewGroupChatInfo),
    );
  }

  group('NewGroupChatInfoScreenState feed creation', () {
    testWidgets(
      'createNewGroup_whenHomeserverDoesNotSupportFeeds_showsTheDedicatedMessage',
      (WidgetTester tester) async {
        // Arrange
        stubFeedCreationFailure(const FeedNotSupportedByHomeserverException());
        final screen = await pumpScreen(tester, isFeed: true);

        // Act
        screen.createNewGroup();
        await tester.pumpAndSettle();

        // Assert
        final l10n = L10n.of(tester.element(find.byType(NewGroupChatInfo)))!;
        expect(find.text(l10n.feedNotSupportedByHomeserver), findsOneWidget);
        expect(screen.isCreatingRoom, isFalse);
      },
    );

    testWidgets('createNewGroup_whenFeedCreationFails_showsTheGenericMessage', (
      WidgetTester tester,
    ) async {
      // Arrange
      stubFeedCreationFailure(
        FeedCreationFailedException(cause: Exception('Too many requests')),
      );
      final screen = await pumpScreen(tester, isFeed: true);

      // Act
      screen.createNewGroup();
      await tester.pumpAndSettle();

      // Assert
      final l10n = L10n.of(tester.element(find.byType(NewGroupChatInfo)))!;
      expect(find.text(l10n.inviteUserErrorMessage), findsOneWidget);
      expect(find.text(l10n.feedNotSupportedByHomeserver), findsNothing);
    });
  });

  group('NewGroupChatInfoScreenState group creation', () {
    CreateNewGroupChatRequest capturedRequest() =>
        verify(mockRepository.createGroup(captureAny)).captured.single
            as CreateNewGroupChatRequest;

    testWidgets('createNewGroup_whenThePrivacyIsPublic_requestsAPublicGroup', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = await pumpScreen(tester, isPublicGroupsEnabled: true);
      controller.setPublic(isPublic: true);

      // Act
      controller.createNewGroup();

      // Assert
      expect(capturedRequest().isPublic, isTrue);
    });

    testWidgets(
      'createNewGroup_whenPublicGroupsAreDisabled_requestsAPrivateGroup',
      (WidgetTester tester) async {
        // Arrange
        final controller = await pumpScreen(
          tester,
          isPublicGroupsEnabled: false,
        );
        controller.setPublic(isPublic: true);

        // Act
        controller.createNewGroup();

        // Assert
        expect(capturedRequest().isPublic, isFalse);
      },
    );

    testWidgets('createNewGroup_whenCreationFails_keepsThePrivacyChoices', (
      WidgetTester tester,
    ) async {
      // Arrange
      when(
        mockRepository.createGroup(any),
      ).thenAnswer((_) => Future.error(Exception('Server error')));
      final controller = await pumpScreen(tester, isPublicGroupsEnabled: true);
      controller.setPublic(isPublic: true);

      // Act
      controller.createNewGroup();
      await tester.pumpAndSettle();

      // Assert
      expect(
        controller.groupPrivacyNotifier.value,
        const GroupPrivacyState(isPublic: true),
      );
    });

    testWidgets(
      'createNewGroup_whenEncrypted_requestsAnEncryptedPrivateGroup',
      (WidgetTester tester) async {
        // Arrange
        final controller = await pumpScreen(
          tester,
          isPublicGroupsEnabled: true,
        );
        controller.setEncrypted(isEncrypted: true);

        // Act
        controller.createNewGroup();

        // Assert
        final request = capturedRequest();
        expect(request.enableEncryption, isTrue);
        expect(request.isPublic, isFalse);
      },
    );

    testWidgets('setPublic_whenEncrypted_isRefused', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = await pumpScreen(tester, isPublicGroupsEnabled: true);
      controller.setEncrypted(isEncrypted: true);

      // Act
      controller.setPublic(isPublic: true);

      // Assert
      expect(
        controller.groupPrivacyNotifier.value,
        const GroupPrivacyState(isEncrypted: true),
      );
    });

    testWidgets('setEncrypted_whenPublic_isRefused', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = await pumpScreen(tester, isPublicGroupsEnabled: true);
      controller.setPublic(isPublic: true);

      // Act
      controller.setEncrypted(isEncrypted: true);

      // Assert
      expect(
        controller.groupPrivacyNotifier.value,
        const GroupPrivacyState(isPublic: true),
      );
    });

    testWidgets('groupPrivacy_whenCreated_startsPrivate', (
      WidgetTester tester,
    ) async {
      // Act
      final controller = await pumpScreen(tester, isPublicGroupsEnabled: true);

      // Assert
      expect(controller.groupPrivacyNotifier.value, const GroupPrivacyState());
    });

    final transitionCases =
        <
          ({
            String name,
            bool startsPublic,
            bool isPublic,
            GroupPrivacyState expected,
          })
        >[
          (
            name: 'setPublic_whenPrivate_makesThePrivacyPublic',
            startsPublic: false,
            isPublic: true,
            expected: const GroupPrivacyState(isPublic: true),
          ),
          (
            name: 'setPublic_whenBackToPrivate_makesThePrivacyPrivate',
            startsPublic: true,
            isPublic: false,
            expected: const GroupPrivacyState(),
          ),
        ];

    for (final testCase in transitionCases) {
      testWidgets(testCase.name, (WidgetTester tester) async {
        // Arrange
        final controller = await pumpScreen(
          tester,
          isPublicGroupsEnabled: true,
        );
        if (testCase.startsPublic) controller.setPublic(isPublic: true);

        // Act
        controller.setPublic(isPublic: testCase.isPublic);

        // Assert
        expect(controller.groupPrivacyNotifier.value, testCase.expected);
      });
    }
  });
}
