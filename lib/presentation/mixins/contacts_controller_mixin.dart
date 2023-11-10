import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/domain/model/contact/contacts_manager_agruments.dart';
import 'package:fluffychat/domain/model/extensions/contact/contacts_extension.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';

mixin class ContactsControllerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  final TextEditingController textEditingController = TextEditingController();

  // FIXME: Consider can use FocusNode instead ?
  final ValueNotifier<bool> isSearchModeNotifier = ValueNotifier(false);

  final ValueNotifier<List<PresentationContact>> presentationContactNotifier =
      ValueNotifier([]);

  final ValueNotifier<bool> isShowContactsWarningBannerNotifier =
      ValueNotifier(false);

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
    presentationContactNotifier.addListener(() {
      Logs().d(
        'ContactManagerMixin()::initSearchContacts: ${presentationContactNotifier.value.length}',
      );
    });
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) {
      _handleSearchContacts(keyword);
    });
    contactsManager.initialSynchronizeContacts();
  }

  void _handleSearchContacts(String keyword) {
    final contactsMatched =
        contactsManager.tomContacts.toList().searchContacts(keyword);
    if (contactsMatched.isEmpty && isExternalContact) {
      _handleSearchExternalContacts(keyword);
    } else {
      presentationContactNotifier.value = contactsMatched
          .expand((contact) => contact.toPresentationContacts())
          .toList();
    }
  }

  void _handleSearchExternalContacts(String keyword) {
    final externalContact = PresentationContact(
      matrixId: textEditingController.text,
      displayName: textEditingController.text.substring(1),
      type: ContactType.external,
    );
    presentationContactNotifier.value = [externalContact];
  }

  void _handlePresentationContactChange() {
    presentationContactNotifier.value = contactsManager.tomContacts
        .expand((contact) => contact.toPresentationContacts())
        .toList();
  }

  void _handleContactsPermissionChange(ContactsManagerArguments arg) {
    isShowContactsWarningBannerNotifier.value =
        arg.displayWaringContactsBannerState ==
            DisplayWaringContactsBannerState.show;
  }

  void closeContactsWarningBanner() {
    contactsManager.closeContactsWarningBanner();
  }

  void _listenContactsDataChange() {
    contactsManager.contactsStream.stream.listen((arg) {
      Logs().d(
        "ContactManagerMixin()::_listenContactsDataChange(): TomContacts - ${arg.tomContacts}",
      );
      Logs().d(
        "ContactManagerMixin()::_listenContactsDataChange(): displayWaringContactsBannerState - ${arg.displayWaringContactsBannerState}",
      );
      _handlePresentationContactChange();
      _handleContactsPermissionChange(arg);
    });
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
