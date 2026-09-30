import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';
import 'package:twake_chat/domain/usecase/room/create_new_group_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/room/invite_user_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/domain/usecase/verify_name_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'new_group_chat_info_controller_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<CreateNewFeedInteractor>(),
  MockSpec<UploadContentInteractor>(),
  MockSpec<UploadContentInBytesInteractor>(),
  MockSpec<CreateNewGroupChatInteractor>(),
  MockSpec<InviteUserInteractor>(),
])
void main() {
  final getIt = GetIt.instance;

  late MockClient mockClient;
  late MockCreateNewFeedInteractor mockCreateNewFeedInteractor;

  setUpAll(() {
    getIt
      ..registerSingleton(ResponsiveUtils())
      ..registerSingleton<UploadContentInteractor>(
        MockUploadContentInteractor(),
      )
      ..registerSingleton<UploadContentInBytesInteractor>(
        MockUploadContentInBytesInteractor(),
      )
      ..registerSingleton<CreateNewGroupChatInteractor>(
        MockCreateNewGroupChatInteractor(),
      )
      ..registerSingleton<InviteUserInteractor>(MockInviteUserInteractor())
      ..registerSingleton(VerifyNameInteractor());
  });

  tearDownAll(() => getIt.reset());

  setUp(() {
    mockClient = MockClient();
    mockCreateNewFeedInteractor = MockCreateNewFeedInteractor();
  });

  void stubFeedCreationFailure(FeedException exception) {
    when(
      mockCreateNewFeedInteractor.execute(
        feedName: anyNamed('feedName'),
        avatarUrl: anyNamed('avatarUrl'),
      ),
    ).thenAnswer((_) => Future.error(exception));
  }

  Future<NewGroupChatInfoController> pumpCreationScreen(
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createNewFeedInteractorProvider(
            mockClient,
          ).overrideWithValue(mockCreateNewFeedInteractor),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: NewGroupChatInfo(contactsList: {}, isFeed: true),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.state<NewGroupChatInfoController>(
      find.byType(NewGroupChatInfo),
    );
  }

  group('NewGroupChatInfoController.createNewFeedAction', () {
    testWidgets(
      'createNewFeedAction_whenHomeserverDoesNotSupportFeeds_showsTheDedicatedMessage',
      (WidgetTester tester) async {
        // Arrange
        stubFeedCreationFailure(const FeedNotSupportedByHomeserverException());
        final controller = await pumpCreationScreen(tester);

        // Act
        await controller.createNewFeedAction(
          matrixClient: mockClient,
          feedName: 'My feed',
          invite: const [],
        );
        await tester.pumpAndSettle();

        // Assert
        final l10n = L10n.of(tester.element(find.byType(NewGroupChatInfo)))!;
        expect(find.text(l10n.feedNotSupportedByHomeserver), findsOneWidget);
        expect(controller.isCreatingRoom, isFalse);
      },
    );

    testWidgets(
      'createNewFeedAction_whenCreationFails_showsTheGenericMessage',
      (WidgetTester tester) async {
        // Arrange
        stubFeedCreationFailure(
          FeedCreationFailedException(cause: Exception('Too many requests')),
        );
        final controller = await pumpCreationScreen(tester);

        // Act
        await controller.createNewFeedAction(
          matrixClient: mockClient,
          feedName: 'My feed',
          invite: const [],
        );
        await tester.pumpAndSettle();

        // Assert
        final l10n = L10n.of(tester.element(find.byType(NewGroupChatInfo)))!;
        expect(find.text(l10n.inviteUserErrorMessage), findsOneWidget);
        expect(find.text(l10n.feedNotSupportedByHomeserver), findsNothing);
      },
    );
  });

  group('NewGroupChatInfoController.setPublic', () {
    void setWellKnown(WidgetTester tester, Map<String, dynamic> publicGroups) {
      ProviderScope.containerOf(tester.element(find.byType(NewGroupChatInfo)))
          .read(loginHomeserverSummaryProvider.notifier)
          .set(
            HomeserverSummary(
              discoveryInformation: DiscoveryInformation(
                mHomeserver: HomeserverInformation(
                  baseUrl: Uri.parse('https://matrix.example.com'),
                ),
                additionalProperties: {
                  'app.twake.chat': {'public_groups': publicGroups},
                },
              ),
              versions: GetVersionsResponse(versions: ['r1.6.0']),
              loginFlows: [],
            ),
          );
    }

    testWidgets(
      'setPublic_whenWellKnownOpensGroupsByDefault_turnsTheServerLimitOff',
      (WidgetTester tester) async {
        // Arrange
        final controller = await pumpCreationScreen(tester);
        setWellKnown(tester, {
          'enabled': true,
          'default_server_limited': false,
        });

        // Act
        controller.setPublic(true);

        // Assert
        expect(controller.isPublicNotifier.value, isTrue);
        expect(controller.isServerLimitedNotifier.value, isFalse);
      },
    );

    testWidgets('setPublic_whenWellKnownHasNoDefault_turnsTheServerLimitOn', (
      WidgetTester tester,
    ) async {
      // Arrange
      final controller = await pumpCreationScreen(tester);
      setWellKnown(tester, {'enabled': true});

      // Act
      controller.setPublic(true);

      // Assert
      expect(controller.isServerLimitedNotifier.value, isTrue);
    });
  });
}
