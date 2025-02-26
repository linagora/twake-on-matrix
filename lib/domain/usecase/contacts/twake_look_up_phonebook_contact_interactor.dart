import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:matrix/matrix.dart';

class TwakeLookupPhonebookContactInteractor {
  final PhonebookContactRepository _phonebookContactRepository =
      getIt.get<PhonebookContactRepository>();

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
    required TwakeLookUpArgument argument,
  }) async* {
    int progress = 0;
    yield const Right(GetPhonebookContactsLoading());

    final IdentityLookupManager identityLookupManager = IdentityLookupManager();

    final List<Contact> contacts = [];

    try {
      final res = await _phonebookContactRepository.fetchContacts();

      if (res.isEmpty) {
        yield const Right(GetPhonebookContactsIsEmpty());
        return;
      }

      contacts.addAll(res);
    } catch (e) {
      Logs().e(
        'TwakeLookupPhonebookContactInteractor::execute: Register: $e',
      );
      yield Left(
        GetPhoneBookContactFailure(exception: e),
      );
      return;
    }

    final Set<Contact> updatedContact = {};

    FederationHashDetailsResponse? hashDetails;

    try {
      final res = await identityLookupManager.getHashDetails(
        federationUrl: argument.homeServerUrl,
        registeredToken: argument.withAccessToken,
      );

      Logs().d(
        'FederationLookUpPhonebookContactInteractor::execute: hashDetails: $hashDetails',
      );

      if (res.lookupPepper?.isEmpty == true &&
          res.algorithms?.isEmpty == true) {
        yield const Left(
          GetHashDetailsFailure(
            exception: 'Hash details is empty',
          ),
        );
        return;
      }

      hashDetails = res;
    } catch (e) {
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::execute: GetHashDetails: $e',
      );
      yield Left(
        GetHashDetailsFailure(
          exception: e,
        ),
      );
      return;
    }

    final contactIdToHashMap = {
      for (final contact in contacts) contact.id: contact,
    };

    final chunks = contactIdToHashMap.values.slices(lookupChunkSize);

    for (final chunkContacts in chunks) {
      final Map<String, List<String>> hashToContactIdMappings = {};
      final Map<String, Contact> contactIdToHashMap = {};

      for (final chunkContact in chunkContacts) {
        final phoneToHashMap = <String, List<String>>{};
        final emailToHashMap = <String, List<String>>{};
        if (chunkContact.phoneNumbers != null &&
            chunkContact.phoneNumbers!.isNotEmpty) {
          phoneToHashMap.addAll(
            chunkContact.phoneNumbers!.calculateHashesForPhoneNumbers(
              hashDetails,
            ),
          );

          hashToContactIdMappings.putIfAbsent(chunkContact.id, () => []).addAll(
                phoneToHashMap.values.expand((hash) => hash),
              );
        }

        if (chunkContact.emails != null && chunkContact.emails!.isNotEmpty) {
          emailToHashMap.addAll(
            chunkContact.emails!.calculateHashesForEmails(
              hashDetails,
            ),
          );

          hashToContactIdMappings.putIfAbsent(chunkContact.id, () => []).addAll(
                emailToHashMap.values.expand((hash) => hash),
              );
        }

        final updatedContact = chunkContact.updateContactWithHashes(
          phoneToHashMap: phoneToHashMap,
          emailToHashMap: emailToHashMap,
        );

        contactIdToHashMap[chunkContact.id] = updatedContact;
      }

      final request = FederationLookupMxidRequest(
        addresses:
            hashToContactIdMappings.values.expand((hash) => hash).toSet(),
        algorithm: hashDetails.algorithms?.firstOrNull,
        pepper: hashDetails.lookupPepper,
      );
      FederationLookupMxidResponse? response;
      try {
        response = await identityLookupManager.lookupMxid(
          federationUrl: argument.homeServerUrl,
          request: request,
          registeredToken: argument.withAccessToken,
        );
      } catch (e) {
        Logs().e(
          'FederationLookUpPhonebookContactInteractor::execute: LookupMxid: $e',
        );
        yield Left(
          LookUpContactFailure(
            exception: e,
          ),
        );
        return;
      }

      final Set<Contact> contactsFromMappings = {};

      if (response.inactiveMappings != null &&
          response.inactiveMappings!.isNotEmpty) {
        final newContact =
            contactIdToHashMap.values.toSet().handleLookupMappings(
                  mappings: response.inactiveMappings ?? {},
                  hashToContactIdMappings: hashToContactIdMappings,
                );

        contactsFromMappings.addAll(newContact);
      }

      final combinedContacts = chunkContacts.toSet().combineContacts(
        contactsFromMappings: contactsFromMappings,
        contactsFromThirdParty: {},
      );

      updatedContact.addAll(combinedContacts);

      progress++;

      final progressStep = (progress / chunks.length * 100).toInt();

      yield Right(
        GetPhonebookContactsSuccess(
          progress: progressStep,
          contacts: updatedContact.toList(),
        ),
      );
    }
  }
}
