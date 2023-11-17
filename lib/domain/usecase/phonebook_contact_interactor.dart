import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contacts_state.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';

class PhonebookContactInteractor {
  static const int _progressStep = 10;
  static const int _progressMax = 100;
  final PhonebookContactRepository _phonebookContactRepository =

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 50,
  }) async* {
    try {
      int progress = 0;
      yield Right(GetPhonebookContactsLoading(progress: progress));

      final contacts = await _phonebookContactRepository.fetchContacts();
      yield Right(
        GetPhonebookContactsLoading(progress: progress += _progressStep),
      );
      yield Right(GetPhonebookContactsSuccess(contacts: lookupContacts));
    } catch (e) {
      Logs().e('PhonebookContactInteractor::error', e);
      yield Left(GetPhonebookContactsFailure(exception: e));
    }
  }

  void addListener(VoidCallback callback) {
    _phonebookContactRepository.addListener(callback);
  }

  void removeListener(VoidCallback callback) {
    _phonebookContactRepository.removeListener(callback);
  }
}
