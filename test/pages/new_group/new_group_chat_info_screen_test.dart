import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/data/repository/new_group/new_group_repository.provider.dart';
import 'package:twake_chat/domain/exception/feed/feed_exception.dart';
import 'package:twake_chat/domain/exception/spaces/space_exception.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/room/create_new_group_chat_request.dart';
import 'package:twake_chat/domain/repository/new_group/new_group_repository.dart';
import 'package:twake_chat/domain/usecase/feed/create_new_feed_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_for_web_interactor.dart';
import 'package:twake_chat/domain/usecase/room/upload_content_interactor.dart';
import 'package:twake_chat/domain/spaces/new_space.dart';
import 'package:twake_chat/domain/spaces/space_models.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.dart';
import 'package:twake_chat/domain/spaces/usecases/create_space_usecase.provider.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/new_group/states/group_privacy_state.dart';
import 'package:twake_chat/pages/new_group/new_group_chat_info.dart';
import 'package:twake_chat/pages/new_group/states/new_group_kind.dart';
import 'package:twake_chat/pages/new_group/providers/new_feed_providers.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/providers/room_list/room_list_providers.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'new_group_chat_info_screen_test.mocks.dart';
import '../../providers/fake_active_account.dart';

@GenerateNiceMocks([
  MockSpec<Client>(),
  MockSpec<CreateNewFeedInteractor>(),
  MockSpec<CreateSpaceUseCase>(),
  MockSpec<NewGroupRepository>(),
  MockSpec<UploadContentInteractor>(),
  MockSpec<UploadContentInBytesInteractor>(),
])
void main() {
  late MockClient mockClient;
  late MockCreateNewFeedInteractor mockCreateNewFeedInteractor;
  late MockCreateSpaceUseCase createSpaceUseCase;
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
    createSpaceUseCase = MockCreateSpaceUseCase();
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
    NewGroupKind kind = NewGroupKind.group,
    bool isPublicGroupsEnabled = true,
    bool? isServerAclEnabled,
    String? parentSpaceId,
    List<SpaceSummary> addableSpaces = const [],
    bool pushed = false,
  }) async {
    final screen = NewGroupChatInfo(
      contactsList: const {},
      kind: kind,
      parentSpaceId: parentSpaceId,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...activeAccountOverrides(mockClient),
          newGroupRepositoryProvider.overrideWithValue(mockRepository),
          addableSpacesProvider.overrideWithValue(addableSpaces),
          createSpaceUseCaseProvider.overrideWithValue(createSpaceUseCase),
          createNewFeedInteractorProvider.overrideWithValue(
            mockCreateNewFeedInteractor,
          ),
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
                      'server_acl': ?isServerAclEnabled,
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
          home: pushed ? const SizedBox() : screen,
        ),
      ),
    );
    if (pushed) {
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(MaterialPageRoute<void>(builder: (_) => screen)),
      );
    }
    await tester.pumpAndSettle();
    return tester.state<NewGroupChatInfoScreenState>(
      find.byType(NewGroupChatInfo),
    );
  }

  group('NewGroupChatInfoScreenState space creation', () {
    testWidgets('createNewGroup_whenSpaceCreationFails_saysSo', (
      WidgetTester tester,
    ) async {
      when(
        createSpaceUseCase.execute(any),
      ).thenThrow(const SpaceCreationFailedException());
      final screen = await pumpScreen(tester, kind: NewGroupKind.space);

      screen.createNewGroup();
      await tester.pumpAndSettle();

      final l10n = L10n.of(tester.element(find.byType(NewGroupChatInfo)))!;
      expect(find.text(l10n.createFailed), findsOneWidget);
      expect(find.text(l10n.inviteUserErrorMessage), findsNothing);
    });

    testWidgets('createNewGroup_trimsTheNameAndTheDescription', (
      WidgetTester tester,
    ) async {
      final creation = Completer<String>();
      when(createSpaceUseCase.execute(any)).thenAnswer((_) => creation.future);
      final screen = await pumpScreen(tester, kind: NewGroupKind.space);
      screen.groupNameTextEditingController.text = '  Team  ';
      screen.topicTextEditingController.text = '   ';

      screen.createNewGroup();
      await tester.pump();

      final space =
          verify(createSpaceUseCase.execute(captureAny)).captured.single
              as NewSpace;
      expect(space.name, 'Team');
      expect(space.topic, isEmpty);
      creation.completeError(const SpaceCreationFailedException());
      await tester.pumpAndSettle();
    });

    testWidgets('back_whileCreating_leavesTheNextFormAlone', (
      WidgetTester tester,
    ) async {
      final creation = Completer<String>();
      when(createSpaceUseCase.execute(any)).thenAnswer((_) => creation.future);
      final screen = await pumpScreen(
        tester,
        kind: NewGroupKind.space,
        pushed: true,
      );

      screen.createNewGroup();
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_ios));
      await tester.pumpAndSettle();
      expect(find.byType(NewGroupChatInfo), findsNothing);

      // Back on a new screen while the first creation still runs.
      unawaited(
        tester
            .state<NavigatorState>(find.byType(Navigator))
            .push(
              MaterialPageRoute<void>(
                builder: (_) => const NewGroupChatInfo(
                  contactsList: {},
                  kind: NewGroupKind.space,
                ),
              ),
            ),
      );
      await tester.pumpAndSettle();
      final again = tester.state<NewGroupChatInfoScreenState>(
        find.byType(NewGroupChatInfo),
      );
      // A fresh form: the end of the first creation is none of its business.
      expect(again.isCreatingRoom, isFalse);
      again.groupNameTextEditingController.text = 'Second';

      creation.complete('!first');
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(NewGroupChatInfo), findsOneWidget);
      expect(again.groupNameTextEditingController.text, 'Second');
      verify(createSpaceUseCase.execute(any)).called(1);
    });
  });

  group('NewGroupChatInfoScreenState feed creation', () {
    testWidgets(
      'createNewGroup_whenHomeserverDoesNotSupportFeeds_showsTheDedicatedMessage',
      (WidgetTester tester) async {
        // Arrange
        stubFeedCreationFailure(const FeedNotSupportedByHomeserverException());
        final screen = await pumpScreen(tester, kind: NewGroupKind.feed);

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
      final screen = await pumpScreen(tester, kind: NewGroupKind.feed);

      // Act
      screen.createNewGroup();
      await tester.pumpAndSettle();

      // Assert
      final l10n = L10n.of(tester.element(find.byType(NewGroupChatInfo)))!;
      expect(find.text(l10n.inviteUserErrorMessage), findsOneWidget);
      expect(find.text(l10n.feedNotSupportedByHomeserver), findsNothing);
    });
  });

  group('NewGroupChatInfoScreenState plain group without contact', () {
    const space = SpaceSummary(
      id: '!space',
      name: 'Team',
      memberCount: 3,
      isPublic: false,
      canInvite: true,
      canAddChildren: true,
    );

    Future<void> typeName(WidgetTester tester) async {
      await tester.enterText(find.byKey(const ValueKey('new_group_name')), 'A');
      await tester.pump();
    }

    testWidgets('canSubmit_whenParentIsNotAddable_isFalseAndHidesDone', (
      WidgetTester tester,
    ) async {
      final screen = await pumpScreen(tester, parentSpaceId: '!unknown');
      await typeName(tester);

      expect(screen.canSubmit, isFalse);
      expect(find.byIcon(Icons.done), findsNothing);
    });

    testWidgets('canSubmit_whenParentIsSetToNone_isFalseAndHidesDone', (
      WidgetTester tester,
    ) async {
      final screen = await pumpScreen(
        tester,
        parentSpaceId: '!space',
        addableSpaces: const [space],
      );
      await typeName(tester);
      expect(screen.canSubmit, isTrue);
      expect(find.byIcon(Icons.done), findsOneWidget);

      screen.parentSpaceNotifier.value = null;
      await tester.pump();

      expect(screen.canSubmit, isFalse);
      expect(find.byIcon(Icons.done), findsNothing);
    });

    testWidgets('parentSpace_whileCreating_doesNotOpenThePicker', (
      WidgetTester tester,
    ) async {
      final screen = await pumpScreen(
        tester,
        parentSpaceId: '!space',
        addableSpaces: const [space],
      );
      final title = L10n.of(
        tester.element(find.byType(NewGroupChatInfo)),
      )!.createInTheSpace;
      screen.createNewGroup();
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('new_group_parent_space')));
      await tester.pumpAndSettle();

      expect(find.text(title), findsOneWidget);
    });

    testWidgets('description_whileCreating_isDisabled', (
      WidgetTester tester,
    ) async {
      when(
        createSpaceUseCase.execute(any),
      ).thenAnswer((_) => Completer<String>().future);
      final screen = await pumpScreen(tester, kind: NewGroupKind.space);
      screen.createNewGroup();
      await tester.pump();

      final field = tester.widget<LinagoraTextField>(
        find.byKey(const ValueKey('new_space_description')),
      );

      expect(field.enabled, isFalse);
    });

    testWidgets('canSubmit_whenSpace_isTrueWithNobody', (
      WidgetTester tester,
    ) async {
      final screen = await pumpScreen(tester, kind: NewGroupKind.space);

      expect(screen.canSubmit, isTrue);
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
      final request = capturedRequest();
      expect(request.isPublic, isTrue);
      expect(request.isServerAclEnabled, isFalse);
    });

    testWidgets(
      'createNewGroup_whenTheServerAppliesTheAcl_requestsAGroupKeptLocalByTheAcl',
      (WidgetTester tester) async {
        // Arrange
        final controller = await pumpScreen(
          tester,
          isPublicGroupsEnabled: true,
          isServerAclEnabled: true,
        );
        controller.setPublic(isPublic: true);

        // Act
        controller.createNewGroup();

        // Assert
        final request = capturedRequest();
        expect(request.isPublic, isTrue);
        expect(request.isServerAclEnabled, isTrue);
      },
    );

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
