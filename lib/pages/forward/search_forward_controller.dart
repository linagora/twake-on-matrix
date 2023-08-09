import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

class SearchForwardController {
  static const debouncerIntervalInMilliseconds = 400;

  late final Debouncer<String> _debouncer;
  final TextEditingController textEditingController = TextEditingController();
  void Function(String)? onSearchKeywordChanged;
  late final isSearchModeNotifier = ValueNotifier(false);

  String searchKeyword = "";

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

    _debouncer.values.listen((keyword) async {
      Logs().d(
        "SearchForwardController::_initializeDebouncer: searchKeyword: $searchKeyword",
      );
      searchKeyword = keyword;
      if (onSearchKeywordChanged != null) {
        onSearchKeywordChanged!(textEditingController.text);
      }
    });
  }

  void onSearchBarChanged(String keyword) {
    _debouncer.setValue(keyword);
    searchKeyword = keyword;
  }

  void onCloseSearchTapped() {
    textEditingController.clear();
  }

  void dispose() {
    _debouncer.cancel();
    textEditingController.dispose();
  }
}
