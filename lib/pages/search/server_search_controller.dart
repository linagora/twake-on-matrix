import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/search/server_side_search_categories.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/domain/usecase/search/server_search_interactor.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_state.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_empty_search.dart';
import 'package:fluffychat/presentation/model/search/presentation_server_side_search.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/result_extension.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';
import 'package:matrix/matrix.dart';

class ServerSearchController with SearchDebouncerMixin {
  final String? inRoomId;

  BuildContext? currentContext;

  ServerSearchController({
    this.inRoomId,
  });

  final _serverSearchInteractor = getIt.get<ServerSearchInteractor>();

  final searchResultsNotifier = ValueNotifier<PresentationServerSideUIState>(
    PresentationServerSideInitial(),
  );

  static const int _limitServerSideSearchFilter = 20;

  final isLoadingMoreNotifier = ValueNotifier<bool>(false);

  StreamSubscription? _searchSubscription;

  String? _nextBatch;

  ServerSideSearchCategories? _searchCategories;

  bool get searchTermIsNotEmpty =>
      _searchCategories?.searchTerm.isNotEmpty == true;

  void initSearch({
    BuildContext? context,
    Function(String)? onSearchEncryptedMessage,
  }) {
    currentContext = context;
    initializeDebouncer((searchTerm) {
      if (onSearchEncryptedMessage != null) {
        onSearchEncryptedMessage(searchTerm);
        return;
      }
      updateSearchCategories(searchTerm);
      resetSearchResults();
      if (searchTerm.isNotEmpty) {
        searchUnencryptedMessages();
      } else {
        resetSearchResults();
      }
    });
  }

  void dispose() {
    super.disposeDebouncer();
    _searchSubscription?.cancel();
    isLoadingMoreNotifier.dispose();
    resetNextBatch();
    resetSearchResults();
    disposeDebouncer();
    _searchCategories = null;
  }

  void _handleListenServerSearch(Either<Failure, Success> searchResult) {
    searchResult.fold(
      (failure) => resetNextBatch(),
      (success) {
        if (!searchTermIsNotEmpty) {
          return;
        }

        if (success is ServerSearchInitial) {
          searchResultsNotifier.value = PresentationServerSideInitial();
        }

        if (success is ServerSearchChatSuccess) {
          updateNextBatch(success.nextBatch);
          if (success.results?.isEmpty == true) {
            if (isLoadingMoreNotifier.value) {
              searchResultsNotifier.value = PresentationServerSideSearch(
                searchResults: [
                  if (searchResultsNotifier.value
                      is PresentationServerSideSearch)
                    ...(searchResultsNotifier.value
                            as PresentationServerSideSearch)
                        .searchResults,
                  ...success.results ?? <Result>[],
                ]
                    .where(
                      (result) => result.isDisplayableResult(
                        context: currentContext,
                        event: result.getEvent(currentContext),
                        matrixLocalizations: currentContext == null
                            ? const MatrixDefaultLocalizations()
                            : MatrixLocals(L10n.of(currentContext!)!),
                        searchWord: _searchCategories!.searchTerm,
                      ),
                    )
                    .toList(),
              );
            } else {
              searchResultsNotifier.value = PresentationServerSideEmptySearch();
            }
          } else {
            searchResultsNotifier.value = PresentationServerSideSearch(
              searchResults: [
                if (searchResultsNotifier.value is PresentationServerSideSearch)
                  ...(searchResultsNotifier.value
                          as PresentationServerSideSearch)
                      .searchResults,
                ...success.results ?? <Result>[],
              ]
                  .where(
                    (result) => result.isDisplayableResult(
                      context: currentContext,
                      event: result.getEvent(currentContext),
                      matrixLocalizations: currentContext == null
                          ? const MatrixDefaultLocalizations()
                          : MatrixLocals(L10n.of(currentContext!)!),
                      searchWord: _searchCategories!.searchTerm,
                    ),
                  )
                  .toList(),
            );
          }
        }
      },
    );
  }

  void resetSearchResults() {
    searchResultsNotifier.value = PresentationServerSideSearch(
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

    if (searchTerm.isContainsUrlSeparator()) {
      searchTerm = searchTerm.removeUrlSeparatorAndPreceding();
    }

    _searchCategories = ServerSideSearchCategories(
      searchTerm: searchTerm,
      searchFilter: SearchFilter(
        limit: _limitServerSideSearchFilter,
        rooms: inRoomId != null ? [inRoomId!] : null,
      ),
    );
  }

  void onSearchBarChanged(String keyword) {
    setDebouncerValue(keyword);
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

  void loadMore() {
    if (_searchCategories == null ||
        isLoadingMoreNotifier.value ||
        ((searchResultsNotifier.value is PresentationServerSideSearch) &&
            (searchResultsNotifier.value as PresentationServerSideSearch)
                .searchResults
                .isEmpty) ||
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
