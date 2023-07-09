import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/search/search_interactor_state.dart';
import 'package:fluffychat/domain/usecase/search/search_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SearchContactAndRecentChatController {
  final BuildContext context;
  SearchContactAndRecentChatController(this.context);

  static const debouncerIntervalInMilliseconds = 300;
  String searchKeyword = "";

  final SearchContactsAndRecentChatInteractor _searchContactsAndRecentChatInteractor = getIt.get<SearchContactsAndRecentChatInteractor>();
  Debouncer<String>? _debouncer;
  final TextEditingController textEditingController = TextEditingController();
  StreamController<Either<Failure, GetContactAndRecentChatSuccess>> getContactAndRecentChatStream = StreamController();
  void Function(String)? onSearchKeywordChanged;
  late final isSearchModeNotifier = ValueNotifier(false);



  void init() {
    _initializeDebouncer();
    textEditingController.addListener(() {
      if (textEditingController.text.isNotEmpty) {
        isSearchModeNotifier.value = true;
      } else {
        isSearchModeNotifier.value = false;
      }
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
      fetchLookupContacts();
    });
  }

  void fetchLookupContacts({
    int? limitContacts,
    int? limitRecentChats,
  }) {
    _searchContactsAndRecentChatInteractor.execute(
      keyword: searchKeyword,
      context: context,
      limitContacts: limitContacts,
      limitRecentChats: limitRecentChats,
      enableSearch: true,
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