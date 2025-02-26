import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';
import 'package:fluffychat/domain/usecase/contacts/federation_look_up_argument.dart';

import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_request.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_lookup_mxid_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_register_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/federation_identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_request.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/state/federation_identity_request_token_state.dart';
import 'package:fluffychat/modules/federation_identity_request_token/manager/federation_identity_request_token_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:matrix/matrix.dart';

class PhonebookContactInteractor {
  final PhonebookContactRepository _phonebookContactRepository =
      getIt.get<PhonebookContactRepository>();

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
    required FederationLookUpArgument argument,
  }) async* {
    try {
      int progress = 0;
      yield const Right(GetPhonebookContactsLoading());

      FederationTokenInformation? federationIdentityRequestTokenRes;

      FederationRegisterResponse? federationRegisterToken;

      final List<Contact> contacts = [];

      await FederationIdentityRequestTokenManager()
          .execute(
            federationTokenRequest: FederationTokenRequest(
              federationUrl: "${argument.homeServerUrl}/",
              mxid: argument.withMxId,
              token: argument.withAccessToken,
            ),
          )
          .then(
            (state) => state.fold(
              (failure) {},
              (success) {
                if (success is FederationIdentityRequestTokenSuccess) {
                  federationIdentityRequestTokenRes = success.tokenInformation;
                }
              },
            ),
          );

      Logs().d(
        'PhonebookContactInteractor::execute: federationIdentityRequestTokenRes: $federationIdentityRequestTokenRes',
      );

      if (federationIdentityRequestTokenRes == null) {
        yield const Left(RequestTokenFailure(exception: 'Token is empty'));
        return;
      }

      try {
        final res = await IdentityLookupManager().register(
          federationUrl: argument.federationUrl,
          tokenInformation: federationIdentityRequestTokenRes!,
        );
        if (res.token == null || res.token!.isEmpty) {
          yield const Left(RegisterTokenFailure(exception: 'Token is empty'));
          return;
        }

        federationRegisterToken = res;
      } catch (e) {
        Logs().e(
          'PhonebookContactInteractor::execute: Register: $e',
        );
        yield const Left(RegisterTokenFailure(exception: 'Register failed'));
        return;
      }

      Logs().d(
        'PhonebookContactInteractor::execute: federationRegisterToken: $federationRegisterToken',
      );

      try {
        final res = await _phonebookContactRepository.fetchContacts();

        if (res.isEmpty) {
          yield const Right(GetPhonebookContactsIsEmpty());
          return;
        }

        contacts.addAll(res);
      } catch (e) {
        Logs().e(
          'PhonebookContactInteractor::execute: Register: $e',
        );
        yield Left(
          GetPhoneBookContactFailure(exception: e),
        );
        return;
      }

      final Set<Contact> updatedContact = {};

      FederationHashDetailsResponse? hashDetails;

      try {
        final res = await IdentityLookupManager().getHashDetails(
          federationUrl: argument.federationUrl,
          registeredToken: federationRegisterToken.token!,
        );

        Logs().d(
          'PhonebookContactInteractor::execute: hashDetails: $hashDetails',
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
          'PhonebookContactInteractor::execute: GetHashDetails: $e',
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
              calculateHashesForPhoneNumbers(
                chunkContact.phoneNumbers!,
                hashDetails,
              ),
            );

            hashToContactIdMappings
                .putIfAbsent(chunkContact.id, () => [])
                .addAll(
                  phoneToHashMap.values.expand((hash) => hash),
                );
          }

          if (chunkContact.emails != null && chunkContact.emails!.isNotEmpty) {
            emailToHashMap.addAll(
              calculateHashesForEmails(
                chunkContact.emails!,
                hashDetails,
              ),
            );

            hashToContactIdMappings
                .putIfAbsent(chunkContact.id, () => [])
                .addAll(
                  emailToHashMap.values.expand((hash) => hash),
                );
          }

          final updatedContact = updateContactWithHashes(
            chunkContact,
            phoneToHashMap,
            emailToHashMap,
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
          response = await IdentityLookupManager().lookupMxid(
            federationUrl: argument.federationUrl,
            request: request,
            registeredToken: federationRegisterToken.token!,
          );
        } catch (e) {
          Logs().e(
            'PhonebookContactInteractor::execute: LookupMxid: $e',
          );
          yield Left(
            LookUpContactFailure(
              exception: e,
            ),
          );
          return;
        }
        final Set<Contact> contactsFromMappings = {};

        final Set<Contact> contactsFromThirdParty = {};

        if (response.mappings != null && response.mappings!.isNotEmpty) {
          final updatedContact = _handleLookupMappings(
            mappings: response.mappings ?? {},
            hashToContactIdMappings: hashToContactIdMappings,
            chunkContacts: contactIdToHashMap.values.toList(),
          );

          contactsFromMappings.addAll(updatedContact);
        }

        if (response.thirdPartyMappings != null &&
            response.thirdPartyMappings!.isNotEmpty) {
          final newContactsThirparty = await _handleThirdPartyMappings(
            thirdPartyToHashes: response.thirdPartyMappings ?? {},
            hashToContactIdMappings: hashToContactIdMappings,
            newContacts: contactIdToHashMap.values.toList(),
            argument: argument,
          );

          Logs().d(
            'PhonebookContactInteractor::execute: newContacts: $newContactsThirparty',
          );

          contactsFromThirdParty.addAll(newContactsThirparty);
        }

        final combinedContacts = _combineContacts(
          chunkContacts.toSet(),
          contactsFromMappings,
          contactsFromThirdParty,
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
    } catch (e) {
      yield Left(GetPhonebookContactsFailure(exception: e));
    }
  }

  List<Contact> _combineContacts(
    Set<Contact> chunkContacts,
    Set<Contact> contactsFromMappings,
    Set<Contact> contactsFromThirdParty,
  ) {
    final Map<String, Contact> uniqueContactsById = {};

    for (final contact in [
      ...chunkContacts,
      ...contactsFromMappings,
      ...contactsFromThirdParty,
    ]) {
      uniqueContactsById[contact.id] = contact;
    }

    return uniqueContactsById.values.toList();
  }

  Map<String, List<String>> calculateHashesForPhoneNumbers(
    Set<PhoneNumber> phoneNumbers,
    FederationHashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> phoneToHashMap = {};
    for (final phoneNumber in phoneNumbers) {
      final hashes = phoneNumber.calculateHashUsingAllPeppers(
        lookupPepper: hashDetails.lookupPepper,
        altLookupPeppers: hashDetails.altLookupPeppers,
        algorithms: hashDetails.algorithms,
      );
      phoneToHashMap[phoneNumber.number] = hashes;
    }

    return phoneToHashMap;
  }

  Map<String, List<String>> calculateHashesForEmails(
    Set<Email> emails,
    FederationHashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> emailToHashMap = {};
    for (final email in emails) {
      final hashes = email.calculateHashUsingAllPeppers(
        lookupPepper: hashDetails.lookupPepper,
        altLookupPeppers: hashDetails.altLookupPeppers,
        algorithms: hashDetails.algorithms,
      );
      emailToHashMap[email.address] = hashes;
    }
    return emailToHashMap;
  }

  Contact updateContactWithHashes(
    Contact contact,
    Map<String, List<String>> phoneToHashMap,
    Map<String, List<String>> emailToHashMap,
  ) {
    final updatedPhoneNumbers = <PhoneNumber>{};
    final updatedEmails = <Email>{};

    for (final phoneNumber in contact.phoneNumbers!) {
      final hashes = phoneToHashMap[phoneNumber.number];
      if (hashes != null) {
        final updatedPhoneNumber = phoneNumber.copyWith(
          thirdPartyIdToHashMap: phoneToHashMap,
        );
        updatedPhoneNumbers.add(updatedPhoneNumber);
      }
    }

    for (final email in contact.emails!) {
      final hashes = emailToHashMap[email.address];
      if (hashes != null) {
        final emailUpdated = email.copyWith(
          thirdPartyIdToHashMap: emailToHashMap,
        );
        updatedEmails.add(emailUpdated);
      }
    }

    return contact.copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }

  Set<Contact> _handleLookupMappings({
    required Map<String, String> mappings,
    required Map<String, List<String>> hashToContactIdMappings,
    required List<Contact> chunkContacts,
  }) {
    final Set<Contact> currentContacts = chunkContacts.toSet();

    final Set<Contact> foundContact = _findContacts(
      mappings,
      hashToContactIdMappings,
      chunkContacts,
    );

    final updatedContacts = _updateContacts(foundContact, mappings);

    currentContacts.removeAll(foundContact);
    currentContacts.addAll(updatedContacts);

    return currentContacts;
  }

  Set<Contact> _findContacts(
    Map<String, String> mappings,
    Map<String, List<String>> hashToContactIdMappings,
    List<Contact> chunkContacts,
  ) {
    final Set<Contact> foundContact = {};
    for (final entry in mappings.entries) {
      final hash = entry.key;
      final contactIds = findContactIdByHash(
        hashToContactIdMappings: hashToContactIdMappings,
        hash: hash,
      );

      if (contactIds != null) {
        foundContact.addAll(
          chunkContacts.where(
            (contact) => contactIds.contains(contact.id),
          ),
        );
      }
    }
    return foundContact;
  }

  String? findContactIdByHash({
    required Map<String, List<String>> hashToContactIdMappings,
    required String hash,
  }) {
    for (final entry in hashToContactIdMappings.entries) {
      if (entry.value.contains(hash)) {
        return entry.key;
      }
    }
    return null;
  }

  Set<Contact> _updateContacts(
    Set<Contact> foundContact,
    Map<String, String> mappings,
  ) {
    final Set<Contact> updatedContacts = {};
    for (final contact in foundContact) {
      final updatedPhoneNumbers = _updatePhoneNumbers(contact, mappings);
      final updatedEmails = _updateEmails(contact, mappings);
      final updatedContact = _updateContact(
        contact,
        updatedPhoneNumbers,
        updatedEmails,
      );
      updatedContacts.add(updatedContact);
    }
    return updatedContacts;
  }

  Set<PhoneNumber> _updatePhoneNumbers(
    Contact contact,
    Map<String, String> mappings,
  ) {
    final updatedPhoneNumbers = <PhoneNumber>{};
    for (final phoneNumber in contact.phoneNumbers!) {
      final thirdPartyIdToHashMap = phoneNumber.thirdPartyIdToHashMap ?? {};

      if (thirdPartyIdToHashMap.values
          .expand((hashes) => hashes)
          .any((hash) => mappings.containsKey(hash))) {
        final hash = thirdPartyIdToHashMap.values
            .expand((hashes) => hashes)
            .firstWhere((hash) => mappings.containsKey(hash));

        final updatePhoneNumber = phoneNumber.copyWith(
          matrixId: mappings[hash],
        );
        updatedPhoneNumbers.add(updatePhoneNumber);
      }
    }
    return updatedPhoneNumbers;
  }

  Set<Email> _updateEmails(Contact contact, Map<String, String> mappings) {
    final updatedEmails = <Email>{};
    for (final email in contact.emails!) {
      final thirdPartyIdToHashMap = email.thirdPartyIdToHashMap ?? {};
      if (thirdPartyIdToHashMap.values
          .expand((hashes) => hashes)
          .any((hash) => mappings.containsKey(hash))) {
        final hash = thirdPartyIdToHashMap.values
            .expand((hashes) => hashes)
            .firstWhere((hash) => mappings.containsKey(hash));
        final updatedEmail = email.copyWith(
          matrixId: mappings[hash],
        );
        updatedEmails.add(updatedEmail);
      }
    }
    return updatedEmails;
  }

  Contact _updateContact(
    Contact contact,
    Set<PhoneNumber> updatedPhoneNumbers,
    Set<Email> updatedEmails,
  ) {
    return contact.copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }

  Future<List<Contact>> _handleThirdPartyMappings({
    required Map<String, Set<String>> thirdPartyToHashes,
    required Map<String, List<String>> hashToContactIdMappings,
    required List<Contact> newContacts,
    required FederationLookUpArgument argument,
  }) async {
    final List<Contact> updatedContact = [];
    for (final server in thirdPartyToHashes.keys) {
      final hashes = thirdPartyToHashes[server]!;
      final Map<String, Contact> contactsNeedToCalculate = {};
      for (final hash in hashes) {
        final contact = findContactWithHash(
          hashToContactIdMappings: hashToContactIdMappings,
          hash: hash,
          chunkContacts: newContacts,
        );

        if (contact == null) {
          continue;
        }

        contactsNeedToCalculate[contact.id] = contact;
      }

      FederationTokenInformation? federationIdentityRequestTokenRes;

      await FederationIdentityRequestTokenManager()
          .execute(
            federationTokenRequest: FederationTokenRequest(
              federationUrl: "${argument.homeServerUrl}/",
              mxid: argument.withMxId,
              token: argument.withAccessToken,
            ),
          )
          .then(
            (state) => state.fold(
              (failure) {},
              (success) {
                if (success is FederationIdentityRequestTokenSuccess) {
                  federationIdentityRequestTokenRes = success.tokenInformation;
                }
              },
            ),
          );

      if (federationIdentityRequestTokenRes == null) {
        return [];
      }

      final arguments = FederationArguments(
        federationUrl: server.convertToHttps,
        tokenInformation: federationIdentityRequestTokenRes!,
        contactMaps: contactsNeedToCalculate.toFederationContactMap(),
      );
      final manager = FederationIdentityLookupManager();
      final result = await manager.execute(arguments: arguments);
      result.fold(
        (failure) {
          Logs().e(
            'PhonebookContactInteractor::_handleThirdPartyMappings: failure: $failure',
          );
        },
        (success) {
          Logs().d(
            'PhonebookContactInteractor::_handleThirdPartyMappings: success: $success',
          );

          if (success is FederationIdentityLookupSuccess) {
            updatedContact.addAll(success.newContacts.toContacts());
          }
        },
      );
    }
    return updatedContact;
  }

  Contact? findContactWithHash({
    required String hash,
    required Map<String, List<String>> hashToContactIdMappings,
    required List<Contact> chunkContacts,
  }) {
    final contactId = findContactIdByHash(
      hashToContactIdMappings: hashToContactIdMappings,
      hash: hash,
    );
    if (contactId == null) {
      return null;
    }
    final contact = chunkContacts.firstWhere(
      (contact) => contact.id == contactId,
    );
    return contact;
  }
}
