import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/search/pre_search_state.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/search/public_groups_search_term.dart';
import 'package:twake_chat/pages/search/search_view.dart';
import 'package:twake_chat/presentation/model/search/presentation_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:twake_chat/presentation/model/search/presentation_server_side_state.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';

import 'search_view_test.mocks.dart';

/// The search results under the chat list header of a phone, driven by the
/// field of the bottom bar ([embedded]), or the search page of its own.
Future<void> _pumpSearchView(
  WidgetTester tester, {
  required bool embedded,
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
  final room = MockRoom();
  when(room.id).thenReturn('!taisiya:localhost');
  when(room.avatar).thenReturn(null);
  when(room.getLocalizedDisplayname(any)).thenReturn('Taisiya');
  when(searchController.textEditingController).thenReturn(textController);
  when(searchController.scrollController).thenReturn(scrollController);
  when(searchController.publicGroupsSearchTerm).thenReturn(searchTerm);
  when(searchController.preSearchRecentContactsNotifier).thenReturn(
    ValueNotifier<Either<Failure, Success>>(
      Right(PreSearchRecentContactsSuccess(rooms: [room])),
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
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(body: SearchView(searchController, embedded: embedded)),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() {
    if (!GetIt.instance.isRegistered<ResponsiveUtils>()) {
      GetIt.instance.registerSingleton(ResponsiveUtils());
    }
  });

  testWidgets('GIVEN the results under the chat list of a phone\n'
      'THEN they have no search field and no back arrow of their own', (
    tester,
  ) async {
    await _pumpSearchView(tester, embedded: true);

    expect(find.byType(TextField), findsNothing);
    expect(find.byTooltip('Back'), findsNothing);
    expect(find.byType(AppBar), findsNothing);
  });

  testWidgets('GIVEN the results under the chat list of a phone\n'
      'THEN the results show: the recent contacts before any typing', (
    tester,
  ) async {
    await _pumpSearchView(tester, embedded: true);

    expect(find.text('Taisiya', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GIVEN the search page of a wide layout\n'
      'THEN it keeps its own search field and back arrow', (tester) async {
    await _pumpSearchView(tester, embedded: false);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('Back'), findsOneWidget);
  });
}
