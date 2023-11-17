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
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/material.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

mixin class ContactsViewControllerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  final TextEditingController textEditingController = TextEditingController();

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  ValueNotifier<WarningContactsBannerState> warningBannerNotifier =
      ValueNotifier(WarningContactsBannerState.hide);

  // FIXME: Consider can use FocusNode instead ?
  final ValueNotifier<bool> isSearchModeNotifier = ValueNotifier(false);

  final presentationContactNotifier = ValueNotifier<Either<Failure, Success>>(
    const Right(ContactsInitial()),
  );

  final presentationPhonebookContactNotifier =
      ValueNotifier<Either<Failure, Success>>(
    const Right(GetPhonebookContactsInitial()),
  );

  final FocusNode searchFocusNode = FocusNode();

  final Debouncer<String> _debouncer = Debouncer(
    const Duration(milliseconds: _debouncerIntervalInMilliseconds),
    initialValue: '',
  );

  final contactsManager = getIt.get<ContactsManager>();

  PermissionStatus contactsPermissionStatus = PermissionStatus.granted;

  void initialFetchContacts() async {
    if (PlatformInfos.isMobile &&
        !contactsManager.isDoNotShowWarningContactsBannerAgain) {
      await _handleRequestContactsPermission();
    }
    _refreshContacts();
    _listenContactsDataChange();
    textEditingController.addListener(() {
      _debouncer.value = textEditingController.text;
    });

    _debouncer.values.listen((keyword) {
      _refreshContacts();
    });
    contactsManager.initialSynchronizeContacts(
      isAvailableSupportPhonebookContacts: PlatformInfos.isMobile &&
          contactsPermissionStatus == PermissionStatus.granted,
    );
  }

  void _listenContactsDataChange() {
    contactsManager.getContactsNotifier().addListener(_refreshContacts);
    contactsManager
        .getPhonebookContactsNotifier()
        .addListener(_refreshContacts);
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
        contactsManager.getContactsNotifier().value.map((success) {
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
        contactsManager.getPhonebookContactsNotifier().value.map((success) {
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

  Future<void> _handleRequestContactsPermission() async {
    final currentContactsPermissionStatus =
        await _permissionHandlerService.requestContactsPermissionActions();
    if (currentContactsPermissionStatus == PermissionStatus.granted) {
      warningBannerNotifier.value = WarningContactsBannerState.hide;
    } else {
      if (!contactsManager.isDoNotShowWarningContactsBannerAgain) {
        warningBannerNotifier.value = WarningContactsBannerState.display;
      }
    }
    contactsPermissionStatus = currentContactsPermissionStatus;
  }

  void closeContactsWarningBanner() {
    contactsManager.updateNotShowWarningContactsBannerAgain = true;
    warningBannerNotifier.value = WarningContactsBannerState.notDisplayAgain;
  }

  void goToSettingsForPermissionActions() {
    _permissionHandlerService.goToSettingsForPermissionActions();
  }

  void disposeContactsMixin() {
    textEditingController.clear();
    searchFocusNode.dispose();
    textEditingController.dispose();
    presentationContactNotifier.dispose();
    presentationPhonebookContactNotifier.dispose();
    contactsManager.getContactsNotifier().removeListener(_refreshContacts);
    contactsManager
        .getPhonebookContactsNotifier()
        .removeListener(_refreshContacts);
  }
}
