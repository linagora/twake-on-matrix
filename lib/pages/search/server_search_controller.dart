import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/search/search_debouncer_mixin.dart';
import 'package:fluffychat/domain/usecase/search/server_search_interactor.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/domain/app_state/search/server_search_state.dart';

class ServerSearchController with SearchDebouncerMixin {
  final _serverSearchInteractor = getIt.get<ServerSearchInteractor>();

  final serverSearchNotifier = ValueNotifier<Either<Failure, Success>>(
    Right(ServerSearchInitial()),
  );

  String keyword = '';

  void init() {
    initializeDebouncer((searchTerm) {
      if (searchTerm.isNotEmpty) {
        keyword = searchTerm;
        searchUnencryptedMessages(searchTerm);
      } else {
        serverSearchNotifier.value = Right(ServerSearchInitial());
      }
    });
  }

  void dispose() {
    super.disposeDebouncer();
  }

  void searchUnencryptedMessages(String searchTerm) {
    _serverSearchInteractor
        .execute(
      searchTerm: searchTerm,
    )
        .listen((searchResult) {
      serverSearchNotifier.value = searchResult;
    });
  }

  void onSearchBarChanged(String keyword) {
    setDebouncerValue(keyword);
  }
}
