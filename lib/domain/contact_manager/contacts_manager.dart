import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contacts_manager_agruments.dart';
import 'package:fluffychat/domain/usecase/get_all_contacts_interactor.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

enum SyncContactsState {
  initial,
  synchronizing,
  synchronized,
}

enum DisplayWaringContactsBannerState {
  show,
  hide,
}

class ContactsManager {
  SyncContactsState _syncContactsState = SyncContactsState.initial;

  DisplayWaringContactsBannerState _displayWaringContactsBannerState =
      DisplayWaringContactsBannerState.show;

  bool _isNotDisplayWarningAgainCacheMemory = false;

  final _getAllContactsInteractor = getIt.get<GetAllContactsInteractor>();

  final PermissionHandlerService permissionHandlerService =
      PermissionHandlerService();

  Set<Contact> _tomContacts = {};

  Set<Contact> _phonebookContacts = {};

  Set<Contact> get tomContacts => _tomContacts;

  Set<Contact> get phonebookContacts => _phonebookContacts;

  bool get firstSynchronizing =>
      _syncContactsState == SyncContactsState.synchronizing ||
      _syncContactsState == SyncContactsState.initial;

  bool get firstSynchronized =>
      _syncContactsState == SyncContactsState.synchronized;

  StreamController<ContactsManagerArguments> contactsStream =
      StreamController<ContactsManagerArguments>.broadcast();

  void initialSynchronizeContacts() async {
    if (PlatformInfos.isMobile && !_isNotDisplayWarningAgainCacheMemory) {
      await _handleRequestContactsPermission();
    }
    if (!firstSynchronized) {
      _syncContactsState = SyncContactsState.synchronizing;
      _getAllContacts();
    } else {
      _handleContactsHasDataChange();
    }
  }

  Future<void> _handleRequestContactsPermission() async {
    final currentContactsPermissionStatus =
        await permissionHandlerService.requestContactsPermissionActions();
    if (currentContactsPermissionStatus == PermissionStatus.granted) {
      _isNotDisplayWarningAgainCacheMemory = true;
      _displayWaringContactsBannerState = DisplayWaringContactsBannerState.hide;
    } else {
      if (!_isNotDisplayWarningAgainCacheMemory) {
        _displayWaringContactsBannerState =
            DisplayWaringContactsBannerState.show;
      }
    }
  }

  void _getAllContacts() {
    _getAllContactsInteractor
        .execute(limit: AppConfig.maxFetchContacts)
        .listen((event) {
      event.fold(
        (_) {},
        (success) {
          if (success is GetContactsSuccess) {
            _tomContacts = success.tomContacts.toSet();
            _phonebookContacts = {};
            _handleContactsHasDataChange();
            Logs().d(
              "ContactManagerMixin()::getAllContacts(): TomContacts: ${_tomContacts.length}",
            );
            Logs().d(
              "ContactManagerMixin()::getAllContacts(): PhonebookContacts: ${_phonebookContacts.length}",
            );
          }
        },
      );
    });
  }

  void closeContactsWarningBanner() {
    _displayWaringContactsBannerState = DisplayWaringContactsBannerState.hide;
    _isNotDisplayWarningAgainCacheMemory = true;
    _handleContactsHasDataChange();
  }

  void _handleContactsHasDataChange() {
    _syncContactsState = SyncContactsState.synchronized;
    contactsStream.add(
      ContactsManagerArguments(
        tomContacts: tomContacts,
        displayWaringContactsBannerState: _displayWaringContactsBannerState,
      ),
    );
  }
}
