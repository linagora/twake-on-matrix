import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contacts_extension.dart';
import 'package:fluffychat/domain/usecase/get_all_contacts_interactor.dart';
import 'package:fluffychat/presentation/enum/contacts/warning_contacts_banner_enum.dart';
import 'package:fluffychat/utils/permission_service.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:matrix/matrix.dart';
import 'package:permission_handler/permission_handler.dart';

enum SyncContactsState {
  initial,
  synchronizing,
  synchronized,
}

class ContactsManager {
  SyncContactsState _syncContactsState = SyncContactsState.initial;

  bool _doNotShowWarningContactsBannerAgain = false;

  final _getAllContactsInteractor = getIt.get<GetAllContactsInteractor>();

  final PermissionHandlerService _permissionHandlerService =
      PermissionHandlerService();

  Set<Contact> _tomContacts = {};

  Set<Contact> _phonebookContacts = {};

  Set<Contact> get tomContacts => _tomContacts;

  Set<Contact> get phonebookContacts => _phonebookContacts;

  bool get _firstSynchronizing =>
      _syncContactsState == SyncContactsState.synchronizing ||
      _syncContactsState == SyncContactsState.initial;

  bool _isExternalContact(String keyword) =>
      keyword.isValidMatrixId && keyword.startsWith("@");

  StreamController<Either<Failure, Success>> contactsStream =
      StreamController<Either<Failure, Success>>.broadcast();

  StreamController<WarningContactsBannerState> warningBannerStateStream =
      StreamController<WarningContactsBannerState>.broadcast();

  void initialSynchronizeContacts() async {
    if (PlatformInfos.isMobile &&
        !_doNotShowWarningContactsBannerAgain &&
        _firstSynchronizing) {
      contactsStream.add(const Right(ContactsLoading()));
      await _handleRequestContactsPermission();
    }
    switch (_syncContactsState) {
      case SyncContactsState.synchronizing:
        break;
      case SyncContactsState.initial:
        _syncContactsState = SyncContactsState.synchronizing;
        _getAllContacts();
        break;
      case SyncContactsState.synchronized:
        _handleContactsHasSynchronized();
        break;
    }
  }

  Future<void> _handleRequestContactsPermission() async {
    final currentContactsPermissionStatus =
        await _permissionHandlerService.requestContactsPermissionActions();
    if (currentContactsPermissionStatus == PermissionStatus.granted) {
      warningBannerStateStream.add(WarningContactsBannerState.hide);
    } else {
      if (!_doNotShowWarningContactsBannerAgain) {
        warningBannerStateStream.add(WarningContactsBannerState.display);
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
            _syncContactsState = SyncContactsState.synchronized;
            Logs().d(
              "ContactManagerMixin()::getAllContacts(): TomContacts: ${_tomContacts.length}",
            );
            Logs().d(
              "ContactManagerMixin()::getAllContacts(): PhonebookContacts: ${_phonebookContacts.length}",
            );
          }
        },
      );

      contactsStream.add(event);
    });
  }

  void closeContactsWarningBanner() {
    _doNotShowWarningContactsBannerAgain = true;
    warningBannerStateStream.add(WarningContactsBannerState.notDisplayAgain);
  }

  void searchContacts(String keyword) {
    final contactsMatched = tomContacts.toList().searchContacts(keyword);
    if (contactsMatched.isEmpty && _isExternalContact(keyword)) {
      contactsStream.add(
        Right(SearchExternalContactsSuccessState(keyword: keyword)),
      );
    } else {
      _handleFetchContactsSuccess(
        tomContacts: contactsMatched,
        phonebookContacts: [],
      );
    }
  }

  void goToSettingsForPermissionActions() {
    _permissionHandlerService.goToSettingsForPermissionActions();
  }

  void _handleFetchContactsSuccess({
    required List<Contact> tomContacts,
    required List<Contact> phonebookContacts,
    String keyword = '',
  }) {
    contactsStream.add(
      Right(
        GetContactsSuccess(
          tomContacts: tomContacts,
          phonebookContacts: phonebookContacts,
          keyword: keyword,
        ),
      ),
    );
  }

  void _handleContactsHasSynchronized() {
    if (_doNotShowWarningContactsBannerAgain) {
      warningBannerStateStream.add(WarningContactsBannerState.display);
    } else {
      warningBannerStateStream.add(WarningContactsBannerState.hide);
    }
    _handleFetchContactsSuccess(
      tomContacts: _tomContacts.toList(),
      phonebookContacts: _phonebookContacts.toList(),
    );
  }

  void dispose() {
    contactsStream.close();
  }
}
