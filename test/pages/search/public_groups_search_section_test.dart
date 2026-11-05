import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/domain/exception/public_rooms/public_rooms_exception.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/model/public_rooms/public_room.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/search/public_groups_search_section.dart';
import 'package:twake_chat/pages/search/public_groups_search_term.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import '../../domain/public_rooms/fake_public_rooms_repository.dart';

void main() {
  late FakePublicRoomsRepository repository;
  late TextEditingController textController;
  late PublicGroupsSearchTerm searchTerm;

  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

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

  Future<void> pumpSection(
    WidgetTester tester, {
    bool isPublicGroupsEnabled = true,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: CustomScrollView(
              slivers: [
                PublicGroupsSearchSection(
                  searchTerm: searchTerm,
                  header: const SliverToBoxAdapter(child: Text('header')),
                ),
                SliverToBoxAdapter(
                  child: HiddenWhenPublicGroupsFound(
                    searchTerm: searchTerm,
                    child: const Text('No Results'),
                  ),
                ),
              ],
            ),
          ),
        ),
        GoRoute(
          path: '/rooms/:roomid',
          builder: (_, state) => Text('room ${state.pathParameters['roomid']}'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          loginHomeserverSummaryProvider.overrideWithBuild(
            (_, _) => summaryWith(isPublicGroupsEnabled: isPublicGroupsEnabled),
          ),
          publicRoomsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
        ),
      ),
    );
  }

  Future<void> type(WidgetTester tester, String text) async {
    textController.text = text;
    await tester.pump(PublicGroupsSearchTerm.debounceDuration);
    await tester.pumpAndSettle();
  }

  setUp(() {
    textController = TextEditingController();
    searchTerm = PublicGroupsSearchTerm(textController);
    repository = FakePublicRoomsRepository(
      directory: [
        publicRoom('!open', name: 'Équipe'),
        publicRoom(
          '!knock',
          name: 'Équipe privée',
          access: PublicRoomAccess.approval,
        ),
      ],
    );
  });

  tearDown(() {
    searchTerm.dispose();
    textController.dispose();
  });

  testWidgets('build_withOneLetter_asksNothingAndShowsNothing', (tester) async {
    // Arrange
    await pumpSection(tester);

    // Act
    await type(tester, ' é ');

    // Assert
    expect(repository.requestedSearchTerm, isNull);
    expect(find.text('header'), findsNothing);
  });

  testWidgets('build_withTwoLetters_showsTheHeaderAndTheRooms', (tester) async {
    // Arrange
    await pumpSection(tester);

    // Act
    await type(tester, ' éq ');

    // Assert
    expect(repository.requestedSearchTerm, 'éq');
    expect(find.text('header'), findsOneWidget);
    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Ask to join · 3 members'), findsOneWidget);
    expect(find.text('No Results'), findsNothing);
  });

  testWidgets('build_whileTyping_asksOnlyOnceTheTypingStops', (tester) async {
    // Arrange
    await pumpSection(tester);

    // Act
    textController.text = 'éq';
    await tester.pump(const Duration(milliseconds: 100));
    await type(tester, 'équ');

    // Assert
    expect(repository.requestedSearchTerm, 'équ');
    expect(repository.requestedLimit, 20);
  });

  testWidgets('build_whenTheFlagIsOff_asksNothing', (tester) async {
    // Arrange
    await pumpSection(tester, isPublicGroupsEnabled: false);

    // Act
    await type(tester, 'éq');

    // Assert
    expect(repository.requestedSearchTerm, isNull);
    expect(find.text('header'), findsNothing);
    expect(find.text('No Results'), findsOneWidget);
  });

  testWidgets('build_whenNothingIsFound_showsNoSection', (tester) async {
    // Arrange
    repository.pages = [[]];
    await pumpSection(tester);

    // Act
    await type(tester, 'zz');

    // Assert
    expect(find.text('header'), findsNothing);
    expect(find.text('No Results'), findsOneWidget);
  });

  testWidgets('build_whenTheDirectoryFails_showsNoSection', (tester) async {
    // Arrange
    repository.fetchError = PublicRoomsFetchFailedException(
      cause: Exception('down'),
    );
    await pumpSection(tester);

    // Act
    await type(tester, 'éq');

    // Assert
    expect(find.text('header'), findsNothing);
  });

  testWidgets('build_whenTheTextGoesBackUnderTwoLetters_hidesTheSection', (
    tester,
  ) async {
    // Arrange
    await pumpSection(tester);
    await type(tester, 'éq');

    // Act
    await type(tester, 'é');

    // Assert
    expect(find.text('header'), findsNothing);
  });

  testWidgets('tap_onAnOpenRoom_joinsAndOpensIt', (tester) async {
    // Arrange
    await pumpSection(tester);
    await type(tester, 'éq');

    // Act
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();

    // Assert
    expect(repository.joinedIds, ['!open']);
    expect(find.text('room !open'), findsOneWidget);
  });

  testWidgets('tap_onARoomOnApproval_sendsTheRequestAndSaysSo', (tester) async {
    // Arrange
    await pumpSection(tester);
    await type(tester, 'éq');

    // Act
    await tester.tap(find.text('Équipe privée'));
    await tester.pumpAndSettle();

    // Assert
    expect(repository.knockedIds, ['!knock']);
    expect(
      find.text('Request sent: an administrator has to approve it.'),
      findsOneWidget,
    );
    expect(find.text('Request sent · 3 members'), findsOneWidget);
  });

  testWidgets('tap_whenTheJoinFails_saysSo', (tester) async {
    // Arrange
    repository.joinError = PublicRoomJoinFailedException(
      cause: Exception('forbidden'),
    );
    await pumpSection(tester);
    await type(tester, 'éq');

    // Act
    await tester.tap(find.text('Équipe'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('This group could not be joined.'), findsOneWidget);
    expect(find.text('room !open'), findsNothing);
  });
}
