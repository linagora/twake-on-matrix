import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/search/server_side_search_categories.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/domain/usecase/search/server_search_interactor.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_search.dart';
import 'package:fluffychat/utils/scroll_controller_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';
import 'package:matrix/matrix.dart';

class ServerSearchController with SearchDebouncerMixin {
  final _serverSearchInteractor = getIt.get<ServerSearchInteractor>();

  final searchResultsNotifier = ValueNotifier<PresentationServerSideSearch>(
    const PresentationServerSideSearch(
      searchResults: [],
    ),
  );

  static const int _limitServerSideSearchFilter = 20;

  final isLoadingMoreNotifier = ValueNotifier<bool>(false);

  final scrollController = ScrollController();

  StreamSubscription? _searchSubscription;

  String? _nextBatch;

  ServerSideSearchCategories? _searchCategories;

  void init() {
    initializeDebouncer((searchTerm) {
      updateSearchCategories(searchTerm);
      resetSearchResults();
      if (searchTerm.isNotEmpty) {
        searchUnencryptedMessages();
      } else {
        resetSearchResults();
      }
    });
    scrollController.addLoadMoreListener(loadMore);
  }

  void dispose() {
    super.disposeDebouncer();
    scrollController.dispose();
    _searchSubscription?.cancel();
    isLoadingMoreNotifier.dispose();
    resetNextBatch();
    resetSearchResults();
    _searchCategories = null;
  }

  void _handleListenServerSearch(Either<Failure, Success> searchResult) {
    searchResult.fold(
      (failure) => resetNextBatch(),
      (success) {
        if (success is ServerSearchChatSuccess) {
          updateNextBatch(success.nextBatch);
          searchResultsNotifier.value = PresentationServerSideSearch(
            searchResults: [
              ...searchResultsNotifier.value.searchResults,
              ...success.results ?? [],
            ],
          );
        }
      },
    );
  }

  void resetSearchResults() {
    searchResultsNotifier.value = const PresentationServerSideSearch(
      searchResults: [],
    );
  }

  void resetNextBatch() {
    _nextBatch = null;
    Logs().d('ServerSearchController::resetNextBatch(): $_nextBatch');
  }

  void updateNextBatch(String? newBatch) {
    _nextBatch = newBatch;
    Logs().d('ServerSearchController::updateNextBatch(): $_nextBatch');
  }

  void updateSearchCategories(String searchTerm) {
    resetNextBatch();
    _searchCategories = ServerSideSearchCategories(
      searchTerm: searchTerm,
      searchFilter: SearchFilter(
        limit: _limitServerSideSearchFilter,
      ),
    );
  }

  void searchUnencryptedMessages() {
    _searchSubscription = _serverSearchInteractor
        .execute(
          searchCategories: _searchCategories!,
        )
        .listen(
          (searchResult) => _handleListenServerSearch(searchResult),
        );
  }

  void onSearchBarChanged(String keyword) {
    setDebouncerValue(keyword);
  }

  void loadMore() {
    if (_searchCategories == null ||
        isLoadingMoreNotifier.value ||
        searchResultsNotifier.value.searchResults.isEmpty ||
        _nextBatch == null) {
      return;
    }
    isLoadingMoreNotifier.value = true;
    _searchSubscription = _serverSearchInteractor
        .execute(
      searchCategories: _searchCategories!,
      nextBatch: _nextBatch,
    )
        .listen(
      (searchResult) => _handleListenServerSearch(searchResult),
      onDone: () {
        isLoadingMoreNotifier.value = false;
      },
    );
  }
}
