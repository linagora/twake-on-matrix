import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
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

import 'search_view_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SearchController>(),
  MockSpec<ServerSearchController>(),
  MockSpec<SearchContactsAndChatsController>(),
])
void main() {
  testWidgets('build_always_putsPublicGroupsBeforeTheMessages', (tester) async {
    // Arrange
    final searchController = MockSearchController();
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
      ValueNotifier<Either<Failure, Success>>(Right(SearchInitial())),
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

    // Act
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: SearchView(searchController),
        ),
      ),
    );

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
}
