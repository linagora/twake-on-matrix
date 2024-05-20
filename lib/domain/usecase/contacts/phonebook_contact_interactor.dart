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
import 'package:matrix/matrix.dart';

class PhonebookContactInteractor {
  static const int _progressStep = 10;
  static const int _progressMax = 100;
  final PhonebookContactRepository _phonebookContactRepository =
      getIt.get<PhonebookContactRepository>();

  final LookupRepository _lookupRepository = getIt.get<LookupRepository>();

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

      final hashDetails = await _lookupRepository.getHashDetails();
      yield Right(
        GetPhonebookContactsLoading(progress: progress += _progressStep),
      );

      final thirdPartyIdToHashMap = {
        for (final contact in contacts)
          contact.thirdPartyId:
              contact.calLookupAddress(hashDetails: hashDetails),
      };
      final chunks =
          thirdPartyIdToHashMap.values.whereNotNull().slices(lookupChunkSize);

      if (chunks.isEmpty) {
        if (contacts.isEmpty) {
          yield const Left(GetPhonebookContactsIsEmpty());
        } else {
          yield Right(GetPhonebookContactsSuccess(contacts: contacts));
        }
        return;
      }

      final int progressStep = (_progressMax - progress) ~/ chunks.length;
      final Map<String, String> hashToMatrixIdMappings = {};
      final Map<String, String> hashToInactiveMatrixIdMappings = {};

      for (final chunkAddresses in chunks) {
        final response = await _lookupRepository.lookupListMxid(
          LookupListMxidRequest(
            addresses: chunkAddresses.toSet(),
            algorithm: hashDetails.algorithms?.firstOrNull,
            pepper: hashDetails.lookupPepper,
          ),
        );
        hashToMatrixIdMappings.addAll(response.mappings ?? {});
        hashToInactiveMatrixIdMappings.addAll(response.inactiveMappings ?? {});
        yield Right(
          GetPhonebookContactsLoading(progress: progress += progressStep),
        );
      }
      final lookupContacts = contacts.map((contact) {
        if (contact.thirdPartyId != null) {
          final hash = thirdPartyIdToHashMap[contact.thirdPartyId];
          if (hashToMatrixIdMappings[hash] != null) {
            return contact.copyWith(
              matrixId: hashToMatrixIdMappings[hash],
              status: ContactStatus.active,
            );
          }
          if (hashToInactiveMatrixIdMappings[hash] != null) {
            return contact.copyWith(
              matrixId: hashToInactiveMatrixIdMappings[hash],
              status: ContactStatus.inactive,
            );
          }
        }
        return contact;
      }).toList();

      if (lookupContacts.isEmpty) {
        yield const Left(GetPhonebookContactsIsEmpty());
      } else {
        yield Right(GetPhonebookContactsSuccess(contacts: lookupContacts));
      }
    } catch (e) {
      Logs().e('PhonebookContactInteractor::error', e);
      yield Left(GetPhonebookContactsFailure(exception: e));
    }
  }
}
