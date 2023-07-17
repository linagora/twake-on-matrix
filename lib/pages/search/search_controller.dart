import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/usecase/search/search_interactor.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SearchContactAndRecentChatController {
  final BuildContext context;
  SearchContactAndRecentChatController(this.context);
  static const int limitPrefetchedRecentChats = 3;
  static const debouncerIntervalInMilliseconds = 300;
  final SearchContactsAndRecentChatInteractor _searchContactsAndRecentChatInteractor = getIt.get<SearchContactsAndRecentChatInteractor>();
  final TextEditingController textEditingController = TextEditingController();
  StreamController<Either<Failure, GetContactAndRecentChatSuccess>> getContactAndRecentChatStream = StreamController();
  void Function(String)? onSearchKeywordChanged;
  Debouncer<String>? _debouncer;
  String searchKeyword = "";
  final isSearchModeNotifier = ValueNotifier(false);

  void init() {
    _initializeDebouncer();
    textEditingController.addListener(() {
      isSearchModeNotifier.value  = textEditingController.text.isNotEmpty;
      onSearchBarChanged(textEditingController.text);
    });
  }

  void _initializeDebouncer() {
    _debouncer = Debouncer(
      const Duration(milliseconds: debouncerIntervalInMilliseconds),
      initialValue: '',
    );

    _debouncer?.values.listen((keyword) async {
      Logs().d("SearchContactAndRecentChatController::_initializeDebouncer: searchKeyword: $searchKeyword");
      searchKeyword = keyword;
      if (onSearchKeywordChanged != null) {
        onSearchKeywordChanged!(textEditingController.text);
      }
      final enableSearch = searchKeyword.isNotEmpty && searchKeyword != '';
      fetchLookupContacts(
        enableSearch: enableSearch,
        limitRecentChats: !enableSearch ? limitPrefetchedRecentChats : null
      );
    });
  }

  void fetchLookupContacts({
    int? limitContacts,
    int? limitRecentChats,
    bool enableSearch = false,
  }) {
    _searchContactsAndRecentChatInteractor.execute(
      keyword: searchKeyword,
      matrixLocalizations: MatrixLocals(L10n.of(context)!),
      rooms: Matrix.of(context).client.rooms,
      limitContacts: limitContacts,
      limitRecentChats: limitRecentChats,
    ).listen((event) {
      getContactAndRecentChatStream.add(event);
    });
  }

  void onSearchBarChanged(String keyword) {
    _debouncer?.setValue(keyword);
    searchKeyword = keyword;
  }

  void onCloseSearchTapped() {
    textEditingController.clear();
  }

  void clearSearchBar() {
    textEditingController.clear();
  }

  void dispose() {
    _debouncer?.cancel();
    textEditingController.dispose();
    getContactAndRecentChatStream.close();
  }
}