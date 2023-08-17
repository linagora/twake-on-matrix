import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success_converter.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/pages/search/get_contacts_controller.dart';
import 'package:fluffychat/presentation/converters/presentation_contact_converter.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

mixin class SearchContactsController {
  static const _debouncerIntervalInMilliseconds = 300;

  GetContactsController? _getContactController;
  final _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );
  final TextEditingController textEditingController = TextEditingController();
  // FIXME: Consider can use FocusNode instead ?
  final isSearchModeNotifier = ValueNotifier(false);
  final searchFocusNode = FocusNode();

  ValueNotifier<Either<Failure, Success>>? get contactsNotifier =>
      _getContactController?.contactsNotifier;

  RefreshController? get refreshController =>
      _getContactController?.refreshController;

  void initSearchContacts({
    SuccessConverter? converter,
  }) {
    _getContactController =
        GetContactsController(converter ?? PresentationContactConverter());
    contactsNotifier?.addListener(() {
      Logs().d('contactsNotifier: ${contactsNotifier?.value}');
    });
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) async {
      fetchContacts(keyword: keyword);
    });

    fetchContacts();
  }

  void fetchContacts({String? keyword}) {
    _getContactController?.fetch(
      keyword: keyword ?? textEditingController.text,
    );
  }

  void loadMoreContacts() {
    _getContactController?.loadMore();
  }

  void toggleSearchMode() {
    isSearchModeNotifier.value = !isSearchModeNotifier.value;
    if (isSearchModeNotifier.value) {
      searchFocusNode.requestFocus();
    } else {
      textEditingController.clear();
    }
  }

  void onSelectedContact() {
    textEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textEditingController.text.length,
    );
  }

  void clearSearchBar() {
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
    textEditingController.clear();
  }

  void disposeSearchContacts() {
    _debouncer.cancel();
    _getContactController?.dispose();
    textEditingController.dispose();
  }
}
