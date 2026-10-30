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
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'new_group_chat_info_screen_test.mocks.dart';

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
    bool? isServerLimitedByDefault,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeMatrixClientProvider.overrideWithBuild(
            (_, _) => ActiveClientSnapshot(mockClient),
          ),
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
                    'public_groups': {
                      'enabled': isPublicGroupsEnabled,
                      'default_server_limited': ?isServerLimitedByDefault,
                    },
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

    Future<NewGroupChatInfoScreenState> pumpGroupCreationScreen(
      WidgetTester tester, {
      required bool isPublicGroupsEnabled,
      bool? isServerLimitedByDefault,
    }) => pumpScreen(
      tester,
      isPublicGroupsEnabled: isPublicGroupsEnabled,
      isServerLimitedByDefault: isServerLimitedByDefault,
    );
    testWidgets(
      'createNewGroup_whenThePrivacyIsPublic_requestsAPublicServerLimitedGroup',
      (WidgetTester tester) async {
        // Arrange
        final controller = await pumpGroupCreationScreen(
          tester,
          isPublicGroupsEnabled: true,
        );
        controller.setPublic(isPublic: true);

        // Act
        controller.createNewGroup();

        // Assert
        final request = capturedRequest();
        expect(request.isPublic, isTrue);
        expect(request.isServerLimited, isTrue);
      },
    );

    testWidgets(
      'createNewGroup_whenPublicGroupsAreDisabled_requestsAPrivateGroup',
      (WidgetTester tester) async {
        // Arrange
        final controller = await pumpGroupCreationScreen(
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
      final controller = await pumpGroupCreationScreen(
        tester,
        isPublicGroupsEnabled: true,
      );
      controller.setPublic(isPublic: true);

      // Act
      controller.createNewGroup();
      await tester.pumpAndSettle();

      // Assert
      expect(
        controller.groupPrivacyNotifier.value,
        const GroupPrivacyState(isPublic: true, isServerLimited: true),
      );
    });

    testWidgets('groupPrivacy_whenCreated_startsPrivate', (
      WidgetTester tester,
    ) async {
      // Act
      final controller = await pumpGroupCreationScreen(
        tester,
        isPublicGroupsEnabled: true,
      );

      // Assert
      expect(controller.groupPrivacyNotifier.value, const GroupPrivacyState());
    });

    final transitionCases =
        <
          ({
            String name,
            bool? isServerLimitedByDefault,
            bool startsPublic,
            void Function(NewGroupChatInfoScreenState controller) act,
            GroupPrivacyState expected,
          })
        >[
          (
            name: 'setPublic_whenWellKnownHasNoDefault_limitsToTheServer',
            isServerLimitedByDefault: null,
            startsPublic: false,
            act: (controller) => controller.setPublic(isPublic: true),
            expected: const GroupPrivacyState(
              isPublic: true,
              isServerLimited: true,
            ),
          ),
          (
            name: 'setPublic_whenWellKnownOpensGroupsByDefault_doesNotLimit',
            isServerLimitedByDefault: false,
            startsPublic: false,
            act: (controller) => controller.setPublic(isPublic: true),
            expected: const GroupPrivacyState(isPublic: true),
          ),
          (
            name: 'setPublic_whenBackToPrivate_clearsTheServerLimit',
            isServerLimitedByDefault: null,
            startsPublic: true,
            act: (controller) => controller.setPublic(isPublic: false),
            expected: const GroupPrivacyState(),
          ),
          (
            name: 'setServerLimited_whenPublic_keepsTheGroupPublic',
            isServerLimitedByDefault: null,
            startsPublic: true,
            act: (controller) =>
                controller.setServerLimited(isServerLimited: false),
            expected: const GroupPrivacyState(isPublic: true),
          ),
        ];

    for (final testCase in transitionCases) {
      testWidgets(testCase.name, (WidgetTester tester) async {
        // Arrange
        final controller = await pumpGroupCreationScreen(
          tester,
          isPublicGroupsEnabled: true,
          isServerLimitedByDefault: testCase.isServerLimitedByDefault,
        );
        if (testCase.startsPublic) controller.setPublic(isPublic: true);

        // Act
        testCase.act(controller);

        // Assert
        expect(controller.groupPrivacyNotifier.value, testCase.expected);
      });
    }
  });
}
