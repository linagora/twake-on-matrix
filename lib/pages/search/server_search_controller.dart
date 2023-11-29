import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/domain/usecase/search/server_search_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';

class ServerSearchController with SearchDebouncerMixin {
  final _serverSearchInteractor = getIt.get<ServerSearchInteractor>();

  final serverSearchResultNotifier = ValueNotifier<List<MatrixEvent?>?>([]);

  final serverSearchResultCountNotifier = ValueNotifier<int>(0);

  String keyword = '';

  void init() {
    initializeDebouncer((searchTerm) {
      if (searchTerm.isNotEmpty) {
        keyword = searchTerm;
        searchUncryptedMessages(searchTerm);
      } else {
        serverSearchResultCountNotifier.value = 0;
        serverSearchResultNotifier.value = [];
      }
    });
  }

  void dispose() {
    super.disposeDebouncer();
  }

  void searchUncryptedMessages(String searchTerm) {
    _serverSearchInteractor
        .execute(
      searchTerm: searchTerm,
    )
        .listen((searchResult) {
      handleServerSearch(searchResult);
    });
  }

  void handleServerSearch(Either<Failure, Success> searchResult) {
    searchResult.fold(
      (left) => serverSearchResultNotifier.value = [],
      (right) {
        if (right is ServerSearchChatSuccess) {
          Logs().d(
            "SearchController::handleServerSearch(): found ${right.count ?? 0} messages",
          );
          if (right.count != null) {
            serverSearchResultCountNotifier.value = right.count!;
          }

          serverSearchResultNotifier.value =
              right.results?.map((result) => result.result).toList();
        }
      },
    );
  }

  void onSearchBarChanged(String keyword) {
    setDebouncerValue(keyword);
  }
}
