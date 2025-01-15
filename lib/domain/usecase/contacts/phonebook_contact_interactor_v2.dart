import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_response.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository_v2.dart';

class PhonebookContactInteractorV2 {
  final PhonebookContactRepositoryV2 _phonebookContactRepository =
      getIt.get<PhonebookContactRepositoryV2>();

  final LookupRepository _lookupRepository = getIt.get<LookupRepository>();

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
  }) async* {
    final contacts = await _phonebookContactRepository.fetchContacts();

    if (contacts.isEmpty) {
      return;
    }

    final hashDetails = await _lookupRepository.getHashDetails();

    final contactIdToHashMap = {
      for (final contact in contacts) contact.id: contact,
    };

    final chunks = contactIdToHashMap.values.slices(lookupChunkSize);

    final Map<String, List<String>> hashToContactIdMappings = {};

    for (final chunkContacts in chunks) {
      for (final contact in chunkContacts) {
        if (contact.phoneNumbers != null && contact.phoneNumbers!.isNotEmpty) {
          final Map<String, List<String>> phoneToHashMap = {};

          for (final phoneNumber in contact.phoneNumbers!) {
            final hashes = phoneNumber.calculateHashUsingAllPeppers(
              hashDetails: hashDetails,
            );
            phoneToHashMap[phoneNumber.number] = hashes;
            phoneNumber.setThirdPartyIdToHashMap(hashes);
          }
          hashToContactIdMappings[contact.id]?.addAll(
            phoneToHashMap.values.expand((hash) => hash),
          );
        }

        if (contact.emails != null && contact.emails!.isNotEmpty) {
          final Map<String, List<String>> emailToHashMap = {};

          for (final email in contact.emails!) {
            final hashes =
                email.calculateHashUsingAllPeppers(hashDetails: hashDetails);
            emailToHashMap[email.address] = hashes;
            email.setThirdPartyIdToHashMap(hashes);
          }

          hashToContactIdMappings[contact.id]?.addAll(
            emailToHashMap.values.expand((hash) => hash),
          );
        }
      }

      final response = await _lookupRepository.lookupListMxid(
        LookupListMxidRequest(
          addresses:
              hashToContactIdMappings.values.expand((hash) => hash).toSet(),
          algorithm: hashDetails.algorithms?.firstOrNull,
          pepper: hashDetails.lookupPepper,
        ),
      );

      await _handleLookupMappings(mappings: response.mappings ?? {});
      _handleLookupThirdPartyId(
        thirdPartyMappings: response.thirdPartyMappings ?? {},
      );
    }
  }

  Future<void> _handleLookupMappings({
    required Map<String, String> mappings,
  }) async {}

  void _handleLookupThirdPartyId({
    required Map<String, ThirdPartyMappingsData> thirdPartyMappings,
  }) {}
}
