import 'package:dartz/dartz.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/contact_manager/contacts_manager.dart';
import 'package:fluffychat/domain/model/contact/contact_type.dart';
import 'package:fluffychat/domain/model/extensions/contact/contacts_extension.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/presentation/extensions/contact/presentation_contact_extension.dart';
import 'package:fluffychat/presentation/model/get_presentation_contacts_success.dart';
import 'package:fluffychat/presentation/model/presentation_contact.dart';
import 'package:fluffychat/presentation/model/presentation_contact_success.dart';
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

  final presentationPhonebookContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(GetPhonebookContactsInitial()),
  );

  ValueNotifier<WarningContactsBannerState> get warningBannerNotifier =>
      contactsManager.warningBannerNotifier;

  final FocusNode searchFocusNode = FocusNode();

  final Debouncer<String> _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );

  final contactsManager = getIt.get<ContactsManager>();

  void initialFetchContacts() async {
    _refreshContacts();
    _listenContactsDataChange();
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) {
      _refreshContacts();
    });
    contactsManager.initialSynchronizeContacts();
  }

  void _listenContactsDataChange() {
    contactsManager.contactsNotifier.addListener(_refreshContacts);
    contactsManager.phonebookContactsNotifier.addListener(_refreshContacts);
  }

  void _refreshContacts() {
    final keyword = _debouncer.value;
    if (keyword.isValidMatrixId && keyword.startsWith("@")) {
      presentationContactNotifier.value = Right(
        PresentationExternalContactSuccess(
          contact: PresentationContact(
            matrixId: keyword,
            displayName: keyword.substring(1),
            type: ContactType.external,
          ),
        ),
      );
      presentationPhonebookContactNotifier.value =
          const Right(GetPhonebookContactsInitial());
      return;
    }
    presentationContactNotifier.value =
        contactsManager.contactsNotifier.value.map((success) {
      if (success is GetContactsSuccess) {
        return GetPresentationContactsSuccess(
          contacts: success.contacts
              .searchContacts(keyword)
              .expand((contact) => contact.toPresentationContacts())
              .toList(),
          keyword: keyword,
        );
      }
      return success;
    });
    presentationPhonebookContactNotifier.value =
        contactsManager.phonebookContactsNotifier.value.map((success) {
      if (success is GetPhonebookContactsSuccess) {
        return GetPresentationContactsSuccess(
          contacts: success.contacts
              .searchContacts(keyword)
              .expand((contact) => contact.toPresentationContacts())
              .toList(),
          keyword: keyword,
        );
      }
      return success;
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
    presentationContactNotifier.dispose();
    presentationPhonebookContactNotifier.dispose();
    contactsManager.contactsNotifier.removeListener(_refreshContacts);
    contactsManager.phonebookContactsNotifier.removeListener(_refreshContacts);
  }
}
