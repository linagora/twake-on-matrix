import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact_query.dart';
import 'package:fluffychat/domain/usecase/lookup_contacts_interactor.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SearchContactsController {
  static const debouncerIntervalInMilliseconds = 300;

  final LookupContactsInteractor _lookupNetworkContactsInteractor = getIt.get<LookupContactsInteractor>();
  late final Debouncer<String> _debouncer;
  final TextEditingController textEditingController = TextEditingController();
  StreamController<Either<Failure, Success>> lookupStreamController = StreamController();
  void Function(String)? onSearchKeywordChanged;
  ValueNotifier<bool> isSearchModeNotifier = ValueNotifier(false);
  final searchFocusNode = FocusNode();

  String searchKeyword = "";

  void init() {
    fetchLookupContacts();
    _initializeDebouncer();
    textEditingController.addListener(() {
      onSearchBarChanged(textEditingController.text);
    });
  }

  void _initializeDebouncer() {
    _debouncer = Debouncer(
      const Duration(milliseconds: debouncerIntervalInMilliseconds), 
      initialValue: '',
    );

    _debouncer.values.listen((keyword) async {
      Logs().d("SearchContactsController::_initializeDebouncer: searchKeyword: $searchKeyword");
      searchKeyword = keyword;
      Logs().d("SearchContactsController::_initializeDebouncer: isSearchModeNotifier: ${isSearchModeNotifier.value}");
      if (isSearchModeNotifier.value) {
        if (onSearchKeywordChanged != null) {
          onSearchKeywordChanged!(textEditingController.text);
        }
      }
      fetchLookupContacts();
    });
  }

  void fetchLookupContacts() {
    _lookupNetworkContactsInteractor
      .execute(query: ContactQuery(keyword: searchKeyword)).listen((event) {
        lookupStreamController.add(event);
      });
  }

  void onSearchBarChanged(String keyword) {
    _debouncer.setValue(keyword);
    searchKeyword = keyword;
  }

  void onCloseSearchTapped() {
    isSearchModeNotifier.value = false;
    textEditingController.clear();
  }

  void onSelectedContact() {
    textEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: textEditingController.text.length
    );
  }

  void clearSearchBar() {
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
    textEditingController.clear();
  }

  void openSearchBar() {
    isSearchModeNotifier.value = true;
    searchFocusNode.requestFocus();
  }

  void dispose() {
    _debouncer.cancel();
    textEditingController.dispose();
    lookupStreamController.close();
  }
}