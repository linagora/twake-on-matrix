import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:provider/provider.dart' as provider;
import 'package:twake_chat/data/model/search/server_search_response.dart';
import 'package:twake_chat/data/repository/public_rooms/public_rooms_repository.provider.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/model/homeserver_summary.dart';
import 'package:twake_chat/domain/repository/server_search_repository.dart';
import 'package:twake_chat/domain/usecase/search/pre_search_recent_contacts_interactor.dart';
import 'package:twake_chat/domain/usecase/search/search_recent_chat_interactor.dart';
import 'package:twake_chat/domain/usecase/search/server_search_interactor.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/contacts_tab/contacts_controller.dart';
import 'package:twake_chat/pages/search/public_groups_search_term.dart';
import 'package:twake_chat/pages/search/search.dart';
import 'package:twake_chat/providers/login_homeserver_summary_provider.dart';
import 'package:twake_chat/providers/matrix_client_provider.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/utils/search/search_engine.dart';
import 'package:twake_chat/widgets/matrix.dart';

import '../../domain/public_rooms/fake_public_rooms_repository.dart';
import '../../fake_client.dart';
import '../../providers/fake_active_account.dart';
import '../chat_list/chat_list_header_test_harness.dart' show FakeMatrixState;

// `Search` fed by a field it does not own: the bottom bar of a phone.

/// The query of the bar; remembers who listens to it.
class _BorrowedQuery extends TextEditingController {
  _BorrowedQuery(String text) : super(text: text);

  final listeners = <VoidCallback>[];

  @override
  void addListener(VoidCallback listener) {
    listeners.add(listener);
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    listeners.remove(listener);
    super.removeListener(listener);
  }
}

class _ServerSearch implements ServerSearchRepository {
  final terms = <String>[];

  @override
  Future<ServerSearchResponse> search({
    required Categories searchCategories,
    String? nextBatch,
  }) {
    terms.add(searchCategories.roomEvents!.searchTerm);
    // Never answers: only what is asked matters here.
    return Completer<ServerSearchResponse>().future;
  }
}

class _NoContacts extends ContactsController {
  @override
  Stream<List<UnifiedContact>> build() => Stream.value(const []);

  @override
  Future<void> refresh({bool resolvePhonebook = false}) async {}
}

class _Harness {
  _Harness(this.query);

  final _BorrowedQuery query;
  final serverSearch = _ServerSearch();
  final publicRooms = FakePublicRoomsRepository();

  /// Whether the results are on screen.
  final shown = ValueNotifier(true);
}

/// Three recent conversations, then Alice: she shows only when searched.
Client _client() {
  final client = Client('testclient', database: EventIdListDatabase(const []));
  for (final name in ['Bob', 'Carol', 'Dave', 'Alice']) {
    final room = Room(id: '!$name:fakeServer', client: client);
    room.setState(
      StrippedStateEvent(
        type: EventTypes.RoomName,
        senderId: '@admin:fakeServer',
        stateKey: '',
        content: {'name': name},
      ),
    );
    client.rooms.add(room);
  }
  return client;
}

HomeserverSummary _publicGroupsEnabled() => HomeserverSummary(
  discoveryInformation: DiscoveryInformation(
    mHomeserver: HomeserverInformation(
      baseUrl: Uri.parse('https://fakeServer.notExisting'),
    ),
    additionalProperties: {
      'app.twake.chat': {
        'public_groups': {'enabled': true},
      },
    },
  ),
  versions: GetVersionsResponse(versions: ['r1.6.0']),
  loginFlows: [],
);

/// The results of a phone, mounted on a field that already holds [text].
Future<_Harness> _pumpSearch(WidgetTester tester, {String text = ''}) async {
  final harness = _Harness(_BorrowedQuery(text));
  addTearDown(harness.query.dispose);
  addTearDown(harness.shown.dispose);
  getIt.registerSingleton<ServerSearchRepository>(harness.serverSearch);
  getIt.registerSingleton(ServerSearchInteractor());
  final client = _client();
  await tester.pumpWidget(
    provider.Provider<MatrixState>.value(
      value: FakeMatrixState(client),
      child: UncontrolledProviderScope(
        container: ProviderContainer.test(
          retry: (_, _) => null,
          overrides: [
            ...activeAccountOverrides(client),
            matrixClientProvider.overrideWithValue(client),
            contactsControllerProvider.overrideWith(_NoContacts.new),
            publicRoomsRepositoryProvider.overrideWithValue(
              harness.publicRooms,
            ),
            loginHomeserverSummaryProvider.overrideWithBuild(
              (_, _) => _publicGroupsEnabled(),
            ),
          ],
        ),
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: L10n.localizationsDelegates,
          supportedLocales: L10n.supportedLocales,
          home: Scaffold(
            body: ValueListenableBuilder(
              valueListenable: harness.shown,
              builder: (_, shown, _) => shown
                  ? Search(embedded: true, textEditingController: harness.query)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    ),
  );
  await _typingStops(tester);
  return harness;
}

/// Past every debounce of the search.
Future<void> _typingStops(WidgetTester tester) async {
  await tester.pump(PublicGroupsSearchTerm.debounceDuration * 2);
  await tester.pumpAndSettle();
}

Finder _conversation(String name) => find.text(name, findRichText: true);

void main() {
  setUp(() {
    getIt.registerSingleton(ResponsiveUtils());
    getIt.registerSingleton(const SearchEngine());
    getIt.registerSingleton(SearchRecentChatInteractor());
    getIt.registerSingleton(PreSearchRecentContactsInteractor());
  });

  tearDown(getIt.reset);

  _suppliedQueryTests();
  _closingTests();
}

void _suppliedQueryTests() {
  group('[Search] mounted on a field that already holds « alice »', () {
    testWidgets('THEN the matching conversations show, not the recent ones', (
      tester,
    ) async {
      await _pumpSearch(tester, text: 'alice');

      expect(_conversation('Alice'), findsOneWidget);
      expect(_conversation('Bob'), findsNothing);
    });

    testWidgets('THEN the messages are searched for it', (tester) async {
      final harness = await _pumpSearch(tester, text: 'alice');

      expect(harness.serverSearch.terms, ['alice']);
    });

    testWidgets('THEN the public groups are searched for it', (tester) async {
      final harness = await _pumpSearch(tester, text: 'alice');

      expect(harness.publicRooms.requestedSearchTerms, ['alice']);
    });
  });

  group('[Search] mounted on an empty field', () {
    testWidgets('THEN the recent conversations show and nothing is searched', (
      tester,
    ) async {
      final harness = await _pumpSearch(tester);

      expect(_conversation('Bob'), findsOneWidget);
      expect(_conversation('Alice'), findsNothing);
      expect(harness.serverSearch.terms, isEmpty);
      expect(harness.publicRooms.requestedSearchTerms, isEmpty);
    });

    testWidgets('WHEN « alice » is typed\n'
        'THEN it is searched', (tester) async {
      final harness = await _pumpSearch(tester);

      harness.query.text = 'alice';
      await _typingStops(tester);

      expect(_conversation('Alice'), findsOneWidget);
      expect(harness.serverSearch.terms, ['alice']);
      expect(harness.publicRooms.requestedSearchTerms, ['alice']);
    });
  });
}

void _closingTests() {
  group('[Search] closed, its field being borrowed', () {
    testWidgets('THEN it no longer listens to the field', (tester) async {
      final harness = await _pumpSearch(tester);
      expect(harness.query.listeners, isNotEmpty, reason: 'while open');

      harness.shown.value = false;
      await _typingStops(tester);

      expect(harness.query.listeners, isEmpty);
    });

    testWidgets('WHEN it opens and closes again and again\n'
        'THEN no listener piles up on the field', (tester) async {
      final harness = await _pumpSearch(tester);

      for (var i = 0; i < 3; i++) {
        harness.shown.value = false;
        await _typingStops(tester);
        harness.shown.value = true;
        await _typingStops(tester);
      }
      harness.shown.value = false;
      await _typingStops(tester);

      expect(harness.query.listeners, isEmpty);
    });
  });
}
