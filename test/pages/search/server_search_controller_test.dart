import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/app_state/failure.dart';
import 'package:twake_chat/app_state/success.dart';
import 'package:twake_chat/domain/app_state/search/server_search_state.dart';
import 'package:twake_chat/domain/model/search/server_side_search_categories.dart';
import 'package:twake_chat/domain/usecase/search/server_search_interactor.dart';
import 'package:twake_chat/pages/search/server_search_controller.dart';
import 'package:twake_chat/presentation/model/search/presentation_server_side_empty_search.dart';

class _FakeServerSearchInteractor implements ServerSearchInteractor {
  Either<Failure, Success> response = Right(ServerSearchInitial());

  final pendingSearches =
      <String, StreamController<Either<Failure, Success>>>{};

  bool holdResponses = false;

  @override
  Stream<Either<Failure, Success>> execute({
    required ServerSideSearchCategories searchCategories,
    String? nextBatch,
  }) async* {
    yield Right(ServerSearchInitial());
    if (holdResponses) {
      final pending = StreamController<Either<Failure, Success>>();
      pendingSearches[searchCategories.searchTerm] = pending;
      yield* pending.stream;
      return;
    }
    yield response;
  }
}

void main() {
  late _FakeServerSearchInteractor interactor;
  late ServerSearchController controller;

  setUp(() {
    interactor = _FakeServerSearchInteractor();
    GetIt.instance.registerSingleton<ServerSearchInteractor>(interactor);
    controller = ServerSearchController();
  });

  tearDown(() async {
    controller.dispose();
    await GetIt.instance.reset();
  });

  Future<void> search(String term) async {
    controller.updateSearchCategories(term);
    controller.resetSearchResults();
    controller.searchUnencryptedMessages();
    await pumpEventQueue();
  }

  test('shows the empty state when the search request fails', () async {
    interactor.response = Left(
      ServerSearchChatFailed(exception: Exception('offline')),
    );

    await search('running');

    expect(
      controller.searchResultsNotifier.value,
      isA<PresentationServerSideEmptySearch>(),
    );
  });

  test(
    'shows the empty state when no server result can be displayed',
    () async {
      interactor.response = Right(
        ServerSearchChatSuccess(
          results: [
            Result(
              rank: 1,
              result: MatrixEvent(
                type: EventTypes.Message,
                content: {'msgtype': 'm.text', 'body': 'running late'},
                senderId: '@bob:localhost',
                eventId: r'$event',
                roomId: '!room:localhost',
                originServerTs: DateTime(2026),
              ),
            ),
          ],
        ),
      );

      await search('late morning');

      expect(
        controller.searchResultsNotifier.value,
        isA<PresentationServerSideEmptySearch>(),
      );
    },
  );

  test(
    'ignores a failure of a previous search term after a new search started',
    () async {
      interactor.holdResponses = true;
      await search('late');
      await search('morning');

      interactor.pendingSearches['late']!.add(
        Left(ServerSearchChatFailed(exception: Exception('timeout'))),
      );
      await pumpEventQueue();

      expect(
        controller.searchResultsNotifier.value,
        isNot(isA<PresentationServerSideEmptySearch>()),
      );
    },
  );

  test('stops loading more when a new search starts', () async {
    interactor.holdResponses = true;
    await search('late');
    interactor.pendingSearches['late']!.add(
      const Right(ServerSearchChatSuccess(results: [], nextBatch: 'next')),
    );
    await pumpEventQueue();

    controller.loadMore();
    await pumpEventQueue();
    expect(controller.isLoadingMoreNotifier.value, isTrue);

    await search('morning');

    expect(controller.isLoadingMoreNotifier.value, isFalse);
  });
}
