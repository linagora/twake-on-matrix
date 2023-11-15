import 'package:collection/collection.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/contact_status.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';
import 'package:matrix/matrix.dart';

class LookupMxidInteractor {
  final LookupRepository _lookupRepository = getIt.get<LookupRepository>();

  Stream<List<Contact>> execute({
    required List<Contact> phonebookContacts,
    int lookupChunkSize = 50,
  }) async* {
    try {
      final hashDetails = await _lookupRepository.getHashDetails();
      final thirdPartyIdToHashMap = {
        for (final contact in phonebookContacts)
          contact.thirdPartyId:
              contact.calLookupAddress(hashDetails: hashDetails),
      };
      final chunks =
          thirdPartyIdToHashMap.values.whereNotNull().slices(lookupChunkSize);
      for (final addresses in chunks) {
        final response = await _lookupRepository.lookupListMxid(
          LookupListMxidRequest(
            addresses: addresses.toSet(),
            algorithm: hashDetails.algorithms?.firstOrNull,
            pepper: hashDetails.lookupPepper,
          ),
        );
        phonebookContacts = phonebookContacts.map((contact) {
          if (contact.thirdPartyId != null) {
            final hash = thirdPartyIdToHashMap[contact.thirdPartyId];
            if (hash != null && response.mappings?[hash] != null) {
              return contact.copyWith(
                matrixId: response.mappings![hash],
                status: ContactStatus.active,
              );
            }
            if (hash != null && response.inactiveMappings?[hash] != null) {
              return contact.copyWith(
                matrixId: response.inactiveMappings![hash],
                status: ContactStatus.inactive,
              );
            }
          }
          return contact;
        }).toList();
        yield phonebookContacts;
      }
    } catch (e) {
      Logs().e('LookupMxidInteractor::error', e);
      yield [];
    }
  }
}
