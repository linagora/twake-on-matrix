import 'dart:async';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/usecase/get_all_contacts_interactor.dart';
import 'package:matrix/matrix.dart';

enum SyncContactsState {
  initial,
  synchronizing,
  synchronized,
}

class ContactsManager {
  SyncContactsState _syncContactsState = SyncContactsState.initial;

  final _getAllContactsInteractor = getIt.get<GetAllContactsInteractor>();

  Set<Contact> _tomContacts = {};

  Set<Contact> _phonebookContacts = {};

  Set<Contact> get tomContacts => _tomContacts;

  Set<Contact> get phonebookContacts => _phonebookContacts;

  bool get firstSynchronizing =>
      _syncContactsState == SyncContactsState.synchronizing;

  bool get firstSynchronized =>
      _syncContactsState == SyncContactsState.synchronized;

  StreamSubscription? contactsStreamSubscription;

  void initialSynchronizeContacts() {
    if (!firstSynchronized) {
      _syncContactsState = SyncContactsState.synchronizing;
      _getAllContacts();
    }
  }

  void _getAllContacts() {
    contactsStreamSubscription = _getAllContactsInteractor
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
    });
  }
}
