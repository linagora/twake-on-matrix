import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success_converter.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/pages/search/get_contacts_controller.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin class SearchContactsController {
  static const _debouncerIntervalInMilliseconds = 300;

  final _getContactController =
      GetContactsController(_PresentationContactConverter());
  final _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );
  final TextEditingController textEditingController = TextEditingController();
  // FIXME: Consider can use FocusNode instead ?
  final isSearchModeNotifier = ValueNotifier(false);
  final searchFocusNode = FocusNode();

  ValueNotifier<Either<Failure, Success>> get contactsNotifier =>
      _getContactController.contactsNotifier;

  void initSearchContacts() {
    _getContactController.contactsNotifier.addListener(() {
      Logs().d('contactsNotifier: ${contactsNotifier.value}');
    });
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) async {
      fetchContacts(keyword: keyword);
    });

    fetchContacts(keyword: '');
  }

  void fetchContacts({required String keyword}) {
    _getContactController.fetch(keyword: keyword);
  }

  void loadMoreContacts() {
    _getContactController.loadMore();
  }

  void onCloseSearchTapped() {
    isSearchModeNotifier.value = false;
    textEditingController.clear();
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

  void openSearchBar() {
    isSearchModeNotifier.value = true;
    searchFocusNode.requestFocus();
  }

  void disposeSearchContacts() {
    _debouncer.cancel();
    _getContactController.dispose();
    textEditingController.dispose();
  }
}

class _PresentationContactConverter implements SuccessConverter {
  @override
  Success convert(Success success) {
    if (success is GetContactsSuccess) {
      return PresentationContactsSuccess(
        data: success.data.expand((e) => e.toPresentationContacts()).toList(),
        offset: success.offset,
        isEnd: success.isEnd,
        keyword: success.keyword,
      );
    }
    return success;
  }
}
