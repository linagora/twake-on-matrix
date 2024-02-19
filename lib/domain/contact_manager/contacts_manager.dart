import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/domain/app_state/contact/get_contacts_state.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/usecase/contacts/get_tom_contacts_interactor.dart';
import 'package:fluffychat/domain/usecase/contacts/phonebook_contact_interactor.dart';
import 'package:flutter/foundation.dart';

class ContactsManager {
  static const int _lookupChunkSize = 50;

  final GetTomContactsInteractor getTomContactsInteractor;

  final PhonebookContactInteractor phonebookContactInteractor;

  bool _doNotShowWarningContactsBannerAgain = false;

  final ValueNotifier<Either<Failure, Success>> _contactsNotifier =
      ValueNotifier(const Right(ContactsInitial()));

  final ValueNotifier<Either<Failure, Success>> _phonebookContactsNotifier =
      ValueNotifier(const Right(GetPhonebookContactsInitial()));

  ContactsManager({
    required this.getTomContactsInteractor,
    required this.phonebookContactInteractor,
  });

  ValueNotifier<Either<Failure, Success>> getContactsNotifier() =>
      _contactsNotifier;

  ValueNotifier<Either<Failure, Success>> getPhonebookContactsNotifier() =>
      _phonebookContactsNotifier;

  bool get _isInitial =>
      _contactsNotifier.value.getSuccessOrNull<ContactsInitial>() != null;

  bool get isDoNotShowWarningContactsBannerAgain =>
      _doNotShowWarningContactsBannerAgain;

  set updateNotShowWarningContactsBannerAgain(bool value) {
    _doNotShowWarningContactsBannerAgain = value;
  }

  void initialSynchronizeContacts({
    bool isAvailableSupportPhonebookContacts = false,
  }) async {
    if (!_isInitial) {
      return;
    }
    _getAllContacts(
      isAvailableSupportPhonebookContacts: isAvailableSupportPhonebookContacts,
    );
  }

  void _getAllContacts({
    bool isAvailableSupportPhonebookContacts = false,
  }) {
    getTomContactsInteractor.execute(limit: AppConfig.maxFetchContacts).listen(
      (event) {
        _contactsNotifier.value = event;
      },
    ).onDone(
      () => _fetchPhonebookContacts(
        isAvailableSupportPhonebookContacts:
            isAvailableSupportPhonebookContacts,
      ),
    );
  }

  void _fetchPhonebookContacts({
    bool isAvailableSupportPhonebookContacts = false,
  }) async {
    if (!isAvailableSupportPhonebookContacts) {
      return;
    }
    phonebookContactInteractor
        .execute(lookupChunkSize: _lookupChunkSize)
        .listen(
      (event) {
        _phonebookContactsNotifier.value = event;
      },
    );
  }
}
