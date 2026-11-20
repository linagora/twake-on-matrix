import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/direct_chat/repositories/direct_chat_repository_impl.provider.dart';
import 'package:twake_chat/domain/direct_chat/repositories/direct_chat_repository.dart';
import 'package:twake_chat/domain/direct_chat/usecases/find_direct_chat_usecase.dart';
import 'package:twake_chat/domain/direct_chat/usecases/find_direct_chat_usecase.provider.dart';
import 'package:twake_chat/pages/search/search_result_controller.dart';
import 'package:twake_chat/pages/search/search_result_state.dart';
import 'package:twake_chat/providers/active_user_id_provider.dart';
import 'package:twake_chat/providers/report_failure_provider.dart';

class _FakeDirectChatRepository extends Fake implements DirectChatRepository {
  final rooms = <String, String>{};
  final lookups = <String>[];
  Object? error;

  @override
  String? findDirectChat({required String contactMxId}) {
    lookups.add(contactMxId);
    final failure = error;
    if (failure != null) throw failure;
    return rooms[contactMxId];
  }
}

class _PendingFindDirectChatUseCase extends Fake
    implements FindDirectChatUseCase {
  final lookups = <Completer<String?>>[];

  @override
  Future<String?> execute({required String contactMxId}) {
    final lookup = Completer<String?>();
    lookups.add(lookup);
    return lookup.future;
  }
}

void main() {
  const me = '@me:server';
  const contact = '@alice:server';

  late _FakeDirectChatRepository repository;
  late ProviderContainer container;
  late List<SearchResultState> states;
  late List<Object> reported;

  setUp(() {
    repository = _FakeDirectChatRepository();
    reported = [];
    container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        directChatRepositoryProvider.overrideWithValue(repository),
        activeUserIdProvider.overrideWithValue(me),
        reportFailureProvider.overrideWithValue(
          (error, _, _) => reported.add(error),
        ),
      ],
    );
    states = [];
    container.listen(
      searchResultControllerProvider,
      (_, next) => states.add(next),
    );
  });

  SearchResultController controller() =>
      container.read(searchResultControllerProvider.notifier);

  test('build_always_startsIdle', () {
    // Assert
    expect(
      container.read(searchResultControllerProvider),
      const SearchResultState.idle(),
    );
  });

  test('openContact_withExistingDirectChat_opensTheRoom', () async {
    // Arrange
    repository.rooms[contact] = '!dm:server';

    // Act
    await controller().openContact(matrixId: contact, displayName: 'Alice');

    // Assert
    expect(states, const [
      SearchResultState.opening(),
      SearchResultState.room('!dm:server'),
    ]);
  });

  test('openContact_withoutDirectChat_opensADraft', () async {
    // Act
    await controller().openContact(matrixId: contact, displayName: 'Alice');

    // Assert
    expect(
      states.last,
      const SearchResultState.draft(matrixId: contact, displayName: 'Alice'),
    );
  });

  test('openContact_withTheActiveUser_opensTheProfile', () async {
    // Act
    await controller().openContact(matrixId: me);

    // Assert
    expect(states, const [
      SearchResultState.opening(),
      SearchResultState.ownProfile(),
    ]);
    expect(repository.lookups, isEmpty);
  });

  test('openContact_twiceWithTheActiveUser_notifiesTwice', () async {
    // Act
    await controller().openContact(matrixId: me);
    await controller().openContact(matrixId: me);

    // Assert
    expect(states.whereType<SearchResultOwnProfile>(), hasLength(2));
  });

  test('openContact_whenTheLookupFails_reportsAndBackToIdle', () async {
    // Arrange
    repository.error = StateError('No active Matrix client');

    // Act
    await controller().openContact(matrixId: contact);

    // Assert
    expect(
      container.read(searchResultControllerProvider),
      const SearchResultState.idle(),
    );
    expect(reported, [isA<StateError>()]);
  });

  group('with a pending lookup', () {
    late _PendingFindDirectChatUseCase useCase;
    late ProviderContainer pendingContainer;

    setUp(() {
      useCase = _PendingFindDirectChatUseCase();
      pendingContainer = ProviderContainer.test(
        retry: (_, _) => null,
        overrides: [
          findDirectChatUseCaseProvider.overrideWithValue(useCase),
          activeUserIdProvider.overrideWithValue(me),
        ],
      );
    });

    test('openContact_whileAlreadyOpening_runsASingleLookup', () async {
      // Arrange
      final pendingStates = <SearchResultState>[];
      pendingContainer.listen(
        searchResultControllerProvider,
        (_, next) => pendingStates.add(next),
      );
      final notifier = pendingContainer.read(
        searchResultControllerProvider.notifier,
      );

      // Act
      final first = notifier.openContact(matrixId: contact);
      final second = notifier.openContact(matrixId: '@bob:server');
      useCase.lookups.single.complete('!dm:server');
      await Future.wait([first, second]);

      // Assert
      expect(useCase.lookups, hasLength(1));
      expect(pendingStates, const [
        SearchResultState.opening(),
        SearchResultState.room('!dm:server'),
      ]);
    });

    test('openContact_disposedDuringTheLookup_leavesTheStateAlone', () async {
      // Arrange
      final pendingStates = <SearchResultState>[];
      final subscription = pendingContainer.listen(
        searchResultControllerProvider,
        (_, next) => pendingStates.add(next),
      );
      final opening = pendingContainer
          .read(searchResultControllerProvider.notifier)
          .openContact(matrixId: contact);
      subscription.close();
      await pendingContainer.pump();

      // Act
      useCase.lookups.single.complete('!dm:server');
      await opening;

      // Assert
      expect(pendingContainer.exists(searchResultControllerProvider), isFalse);
      expect(pendingStates, const [SearchResultState.opening()]);
    });
  });
}
