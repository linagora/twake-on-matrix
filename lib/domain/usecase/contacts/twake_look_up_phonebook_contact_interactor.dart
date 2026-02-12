import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/local/contact/enum/chunk_federation_contact_error_enum.dart';
import 'package:fluffychat/data/local/contact/enum/contacts_hive_error_enum.dart';
import 'package:fluffychat/data/local/contact/shared_preferences_contact_cache_manager.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/exception/contacts/twake_lookup_exceptions.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/domain/repository/contact/hive_contact_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/twake_look_up_argument.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:matrix/matrix.dart' hide Contact;

class TwakeLookupPhonebookContactInteractor {
  final PhonebookContactRepository _phonebookContactRepository = getIt
      .get<PhonebookContactRepository>();
  final IdentityLookupManager _identityLookupManager = getIt
      .get<IdentityLookupManager>();

  final HiveContactRepository _hiveContactRepository = getIt
      .get<HiveContactRepository>();

  final SharedPreferencesContactCacheManager
  _sharedPreferencesContactCacheManager = getIt
      .get<SharedPreferencesContactCacheManager>();

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
    required TwakeLookUpArgument argument,
  }) async* {
    int progress = 0;
    Exception? chunkError;
    final List<Contact> contacts = [];

    yield const Right(GetPhonebookContactsLoading());

    try {
      final res = await _phonebookContactRepository.fetchContacts();

      if (res.isEmpty) {
        yield const Left(GetPhonebookContactsIsEmpty());
        return;
      }

      contacts.addAll(res);
    } catch (e) {
      Logs().e('TwakeLookupPhonebookContactInteractor::execute: Register: $e');
      yield Left(GetPhoneBookContactFailure(exception: e));
      return;
    }

    final Set<Contact> updatedContact = {};

    FederationHashDetailsResponse? hashDetails;

    try {
      final res = await _identityLookupManager.getHashDetails(
        federationUrl: argument.homeServerUrl,
        registeredToken: argument.withAccessToken,
      );

      Logs().d(
        'FederationLookUpPhonebookContactInteractor::execute: hashDetails: $hashDetails',
      );

      if (res.lookupPepper?.isEmpty == true &&
          res.algorithms?.isEmpty == true) {
        yield const Left(
          GetHashDetailsFailure(exception: 'Hash details is empty'),
        );
        return;
      }

      hashDetails = res;
    } catch (e) {
      Logs().e(
        'FederationLookUpPhonebookContactInteractor::execute: GetHashDetails: $e',
      );
      yield Left(GetHashDetailsFailure(exception: e));
      return;
    }

    final contactIdToHashMap = {
      for (final contact in contacts) contact.id: contact,
    };

    final chunks = contactIdToHashMap.values.slices(lookupChunkSize);

    for (final chunkContacts in chunks) {
      final Map<String, List<String>> hashToContactIdMappings = {};
      final Map<String, Contact> contactIdToHashMap = {};
      try {
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

            hashToContactIdMappings
                .putIfAbsent(chunkContact.id, () => [])
                .addAll(phoneToHashMap.values.expand((hash) => hash));
          }

          if (chunkContact.emails != null && chunkContact.emails!.isNotEmpty) {
            emailToHashMap.addAll(
              chunkContact.emails!.calculateHashesForEmails(hashDetails),
            );

            hashToContactIdMappings
                .putIfAbsent(chunkContact.id, () => [])
                .addAll(emailToHashMap.values.expand((hash) => hash));
          }

          final updatedContact = chunkContact.updateContactWithHashes(
            phoneToHashMap: phoneToHashMap,
            emailToHashMap: emailToHashMap,
          );

          contactIdToHashMap[chunkContact.id] = updatedContact;
        }

        final request = FederationLookupMxidRequest(
          addresses: hashToContactIdMappings.values
              .expand((hash) => hash)
              .toSet(),
          algorithm: hashDetails.algorithms?.firstOrNull,
          pepper: hashDetails.lookupPepper,
        );
        FederationLookupMxidResponse? response;

        response = await _identityLookupManager.lookupMxid(
          federationUrl: argument.homeServerUrl,
          request: request,
          registeredToken: argument.withAccessToken,
        );

        final Set<Contact> contactsFromMappings = {};

        final mappingsFound = _handleMappings(
          response.mappings,
          hashToContactIdMappings,
          contactIdToHashMap,
        );
        contactsFromMappings.addAll(mappingsFound);

        final inActiveMappingFound = _handleMappings(
          response.inactiveMappings,
          hashToContactIdMappings,
          contactIdToHashMap,
        );
        contactsFromMappings.addAll(inActiveMappingFound);

        final combinedContacts = chunkContacts.toSet().combineContacts(
          contactsFromMappings: contactsFromMappings,
          contactsFromThirdParty: {},
        );

        _storeContactsInHive(
          contacts: combinedContacts,
          userId: argument.withAccessToken,
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
      } catch (e) {
        Logs().e('TwakeLookupPhonebookContactInteractor::execute: $e');
        updatedContact.addAll(chunkContacts);
        chunkError = TwakeLookupChunkException(e.toString());
        continue;
      }
    }

    // finalize the process
    if (chunkError != null) {
      await _sharedPreferencesContactCacheManager
          .storeChunkFederationLookUpError(
            ChunkLookUpContactErrorEnum.chunkError,
          );
      yield Left(
        LookUpPhonebookContactPartialFailed(
          exception: chunkError,
          contacts: updatedContact.toList(),
        ),
      );
      return;
    } else {
      await _sharedPreferencesContactCacheManager
          .deleteChunkFederationLookUpError();
      yield Right(
        GetPhonebookContactsSuccess(
          progress: 100,
          contacts: updatedContact.toList(),
        ),
      );
    }
  }

  Set<Contact> _handleMappings(
    Map<String, String>? mappings,
    Map<String, List<String>> hashToContactIdMappings,
    Map<String, Contact> contactIdToHashMap,
  ) {
    try {
      if (mappings != null && mappings.isNotEmpty) {
        return contactIdToHashMap.values.toSet().handleLookupMappings(
          mappings: mappings,
          hashToContactIdMappings: hashToContactIdMappings,
        );
      }
      return {};
    } catch (e) {
      Logs().e('TwakeLookupPhonebookContactInteractor::handleMappings: $e');
      return {};
    }
  }

  Future<void> _storeContactsInHive({
    required Set<Contact> contacts,
    required String userId,
  }) async {
    try {
      await _hiveContactRepository.saveThirdPartyContactsForUser(
        userId,
        contacts.toList(),
      );
      await _sharedPreferencesContactCacheManager.deleteContactsHiveError();
    } catch (e) {
      await _sharedPreferencesContactCacheManager.storeContactsHiveError(
        ContactsHiveErrorEnum.storeError,
      );
      Logs().e(
        'TwakeLookupPhonebookContactInteractor::storeContactsInHive: $e',
      );
    }
  }
}
