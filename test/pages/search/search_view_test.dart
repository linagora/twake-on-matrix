import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/config/themes.dart';
import 'package:twake_chat/domain/app_state/search/pre_search_state.dart';
import 'package:twake_chat/domain/app_state/search/search_state.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/search/public_groups_search_section.dart';
import 'package:twake_chat/pages/search/public_groups_search_term.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/pages/search/search_contacts_and_chats_controller.dart';
import 'package:twake_chat/pages/search/search_view.dart';
import 'package:twake_chat/pages/search/server_search_controller.dart';
import 'package:twake_chat/pages/search/server_search_view.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_server_side_state.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/theme_builder.dart';

import 'search_view_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SearchScreenState>(),
  MockSpec<ServerSearchController>(),
  MockSpec<SearchContactsAndChatsController>(),
  MockSpec<Room>(),
])
void main() {
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  Future<void> pumpSearchView(
    WidgetTester tester, {
    Success? preSearch,
    TextScaler textScaler = TextScaler.noScaling,
  }) async {
    final searchController = MockSearchScreenState();
    final serverSearchController = MockServerSearchController();
    final contactsController = MockSearchContactsAndChatsController();
    final textController = TextEditingController();
    final scrollController = ScrollController();
    final searchTerm = PublicGroupsSearchTerm(textController);
    addTearDown(() {
      searchTerm.dispose();
      scrollController.dispose();
      textController.dispose();
    });
    when(searchController.textEditingController).thenReturn(textController);
    when(searchController.scrollController).thenReturn(scrollController);
    when(searchController.publicGroupsSearchTerm).thenReturn(searchTerm);
    when(searchController.preSearchRecentContactsNotifier).thenReturn(
      ValueNotifier<Either<Failure, Success>>(
        Right(preSearch ?? SearchInitial()),
      ),
    );
    when(
      searchController.serverSearchController,
    ).thenReturn(serverSearchController);
    when(
      searchController.searchContactAndRecentChatController,
    ).thenReturn(contactsController);
    when(serverSearchController.searchResultsNotifier).thenReturn(
      ValueNotifier<PresentationServerSideUIState>(
        PresentationServerSideEmptySearch(),
      ),
    );
    when(
      serverSearchController.isLoadingMoreNotifier,
    ).thenReturn(ValueNotifier(false));
    when(
      contactsController.recentAndContactsNotifier,
    ).thenReturn(ValueNotifier<List<PresentationSearch>>([]));
    when(
      contactsController.isShowChatsAndContactsNotifier,
    ).thenReturn(ValueNotifier(false));

    await tester.pumpWidget(
      ProviderScope(
        child: ThemeBuilder(
          builder: (context, themeMode, primaryColor) => MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            theme: TwakeThemes.buildTheme(
              context,
              Brightness.light,
              primaryColor,
            ),
            home: MediaQuery.withClampedTextScaling(
              minScaleFactor: textScaler.scale(1),
              maxScaleFactor: textScaler.scale(1),
              child: SearchView(searchController),
            ),
          ),
        ),
      ),
    );
  }

  MockRoom room(String id, String name) {
    final room = MockRoom();
    when(room.id).thenReturn(id);
    when(room.avatar).thenReturn(null);
    when(room.getLocalizedDisplayname(any)).thenReturn(name);
    return room;
  }

  testWidgets('build_always_putsPublicGroupsBeforeTheMessages', (tester) async {
    // Act
    await pumpSearchView(tester);

    // Assert
    final slivers = tester
        .widget<CustomScrollView>(find.byType(CustomScrollView))
        .slivers;
    final section = slivers.indexWhere(
      (sliver) => sliver is PublicGroupsSearchSection,
    );
    final messages = slivers.indexWhere(
      (sliver) => sliver is ServerSearchMessagesList,
    );
    expect(section, isNot(-1));
    expect(section, lessThan(messages));
  });

  testWidgets('build_withRecentContactsAtTheLargestTextSize_doesNotOverflow', (
    tester,
  ) async {
    // Arrange
    const longName = 'Alexandrine-Marie Delacroix-Montgolfier';

    // Act
    await pumpSearchView(
      tester,
      preSearch: PreSearchRecentContactsSuccess(
        rooms: [
          room('!long:localhost', longName),
          room('!short:localhost', 'Jo'),
        ],
      ),
      textScaler: const TextScaler.linear(2),
    );

    // Assert
    expect(find.text(longName, findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
