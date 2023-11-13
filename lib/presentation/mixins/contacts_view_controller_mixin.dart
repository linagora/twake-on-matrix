import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin class ContactsViewControllerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  final TextEditingController textEditingController = TextEditingController();

  // FIXME: Consider can use FocusNode instead ?
  final ValueNotifier<bool> isSearchModeNotifier = ValueNotifier(false);

  final presentationContactNotifier = ValueNotifier<Either<Failure, Success>>(
    const Right(ContactsInitial()),
  );

  final warningBannerNotifier = ValueNotifier<WarningContactsBannerState>(
    WarningContactsBannerState.hide,
  );

  final FocusNode searchFocusNode = FocusNode();

  final Debouncer _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );

  final contactsManager = getIt.get<ContactsManager>();

  bool get isExternalContact =>
      textEditingController.text.isValidMatrixId &&
      textEditingController.text.startsWith("@");

  void initialFetchContacts() async {
    _listenContactsDataChange();
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) {
      contactsManager.searchContacts(keyword);
    });
    contactsManager.initialSynchronizeContacts();
  }

  void _listenContactsDataChange() {
    contactsManager.contactsStream.stream.listen(
      (state) => presentationContactNotifier.value = state,
    );
    contactsManager.warningBannerStateStream.stream.listen(
      (state) => warningBannerNotifier.value = state,
    );
  }

  void openSearchBar() {
    isSearchModeNotifier.value = true;
    searchFocusNode.requestFocus();
  }

  void onSelectedContact() {
    searchFocusNode.requestFocus();
    textEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: textEditingController.text.length,
    );
  }

  void closeSearchBar() {
    textEditingController.clear();
    searchFocusNode.unfocus();
    isSearchModeNotifier.value = false;
  }

  void disposeContactsMixin() {
    textEditingController.clear();
    searchFocusNode.dispose();
    textEditingController.dispose();
  }
}
