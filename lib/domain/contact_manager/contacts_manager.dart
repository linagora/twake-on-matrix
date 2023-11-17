import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/usecase/get_tom_contacts_interactor.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/domain/usecase/phonebook_contact_interactor.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsManager {
  static const int _lookupChunkSize = 50;

  bool _doNotShowWarningContactsBannerAgain = false;

  final _getTomContactsInteractor = getIt.get<GetTomContactsInteractor>();

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  final _phonebookContactInteractor = getIt.get<PhonebookContactInteractor>();

  ValueNotifier<Either<Failure, Success>> contactsNotifier =
      ValueNotifier(const Right(ContactsInitial()));

  ValueNotifier<Either<Failure, Success>> phonebookContactsNotifier =
      ValueNotifier(const Right(GetPhonebookContactsInitial()));

  ValueNotifier<WarningContactsBannerState> warningBannerNotifier =
      ValueNotifier(WarningContactsBannerState.hide);

  ContactsManager() {
    _phonebookContactInteractor.addListener(_fetchPhonebookContacts);
  }

  bool get _isInitial =>
      contactsNotifier.value.getSuccessOrNull<ContactsInitial>() != null;

  void initialSynchronizeContacts() async {
    if (PlatformInfos.isMobile && !_doNotShowWarningContactsBannerAgain) {
      await _handleRequestContactsPermission();
    }
    if (!_isInitial) {
      return;
    }
    _getAllContacts();
  }

  Future<void> _handleRequestContactsPermission() async {
    final currentContactsPermissionStatus =
        await _permissionHandlerService.requestContactsPermissionActions();
    if (currentContactsPermissionStatus == PermissionStatus.granted) {
      warningBannerNotifier.value = WarningContactsBannerState.hide;
    } else {
      if (!_doNotShowWarningContactsBannerAgain) {
        warningBannerNotifier.value = WarningContactsBannerState.display;
      }
    }
  }

  void _getAllContacts() {
    _getTomContactsInteractor
        .execute(limit: AppConfig.maxFetchContacts)
        .listen((event) {
      contactsNotifier.value = event;
    }).onDone(_fetchPhonebookContacts);
  }

  void _fetchPhonebookContacts() async {
    if (!PlatformInfos.isMobile ||
        await _permissionHandlerService.contactsPermissionStatus !=
            PermissionStatus.granted) {
      return;
    }
    _phonebookContactInteractor
        .execute(lookupChunkSize: _lookupChunkSize)
        .listen((event) {
      phonebookContactsNotifier.value = event;
    });
  }

  void closeContactsWarningBanner() {
    _doNotShowWarningContactsBannerAgain = true;
    warningBannerNotifier.value = WarningContactsBannerState.notDisplayAgain;
  }

  void goToSettingsForPermissionActions() {
    _permissionHandlerService.goToSettingsForPermissionActions();
  }
}
