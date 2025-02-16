import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/data/network/interceptor/authorization_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:fluffychat/data/network/interceptor/federation_authorization_interceptor.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/model/extensions/string_extension.dart';
import 'package:fluffychat/domain/repository/federation_configurations_repository.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';
import 'package:fluffychat/domain/repository/phonebook_contact_repository.dart';

import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_arguments.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/state/federation_identity_lookup_state.dart';
import 'package:fluffychat/modules/federation_identity_lookup/manager/federation_identity_lookup_manager.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_information.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/models/federation_token_request.dart';
import 'package:fluffychat/modules/federation_identity_request_token/domain/state/federation_identity_request_token_state.dart';
import 'package:fluffychat/modules/federation_identity_request_token/manager/federation_identity_request_token_manager.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:flutter/cupertino.dart';

class PhonebookContactInteractor {
  final PhonebookContactRepository _phonebookContactRepository =
      getIt.get<PhonebookContactRepository>();

  final LookupRepository _lookupRepository = getIt.get<LookupRepository>();

  final federationConfigurationRepository =
      getIt.get<FederationConfigurationsRepository>();

  final federationAuthorizationInterceptor =
      getIt.get<FederationAuthorizationInterceptor>();

  final authorizationInterceptor = getIt.get<AuthorizationInterceptor>();

  final homeServerUrlInterceptor = getIt.get<DynamicUrlInterceptors>(
    instanceName: NetworkDI.homeServerUrlInterceptorName,
  );

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
    required String mxid,
  }) async* {
    try {
      int progress = 0;
      yield const Right(GetPhonebookContactsLoading());

      FederationTokenInformation? federationIdentityRequestTokenRes;

      await FederationIdentityRequestTokenManager()
          .execute(
            federationTokenRequest: FederationTokenRequest(
              federationUrl: "${homeServerUrlInterceptor.baseUrl ?? ''}/",
              mxid: mxid,
              token: authorizationInterceptor.getAccessToken ?? '',
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

      debugPrint(
        'DEBUG::execute: federationIdentityRequestTokenRes: $federationIdentityRequestTokenRes',
      );

      if (federationIdentityRequestTokenRes == null) {
        return;
      }

      final federationRegisterToken =
          await _lookupRepository.federationIdentityRegister(
        data: federationIdentityRequestTokenRes?.toJson(),
      );

      debugPrint(
        'DEBUG::execute: federationRegisterToken: $federationRegisterToken',
      );

      if (federationRegisterToken.token == null ||
          federationRegisterToken.token!.isEmpty) {
        return;
      }

      federationAuthorizationInterceptor.accessToken =
          federationRegisterToken.token;

      final contacts = await _phonebookContactRepository.fetchContacts();

      if (contacts.isEmpty) {
        return;
      }

      final Set<Contact> updatedContact = {};

      final hashDetails = await _lookupRepository.getHashDetails();

      debugPrint('DEBUG::execute: hashDetails: $hashDetails');

      final contactIdToHashMap = {
        for (final contact in contacts) contact.id: contact,
      };

      debugPrint('DEBUG::execute: contactIdToHashMap: $contactIdToHashMap');

      final chunks = contactIdToHashMap.values.slices(lookupChunkSize);

      debugPrint('DEBUG::execute: chunks: ${chunks.length}');

      for (final chunkContacts in chunks) {
        final Map<String, List<String>> hashToContactIdMappings = {};
        final Map<String, Contact> contactIdToHashMap = {};

        debugPrint(
          'DEBUG::execute: progress: $progress',
        );

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

            debugPrint('DEBUG::execute: phoneToHashMap: $phoneToHashMap');

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

            debugPrint('DEBUG::execute: emailToHashMap: $emailToHashMap');

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

        debugPrint(
          'DEBUG::execute: hashToContactIdMappings: $hashToContactIdMappings',
        );

        final request = LookupListMxidRequest(
          addresses:
              hashToContactIdMappings.values.expand((hash) => hash).toSet(),
          algorithm: hashDetails.algorithms?.firstOrNull,
          pepper: hashDetails.lookupPepper,
        );

        debugPrint('DEBUG::execute: LookupListMxidRequest: $request');

        final response = await _lookupRepository.lookupListMxid(request);

        debugPrint('DEBUG::execute: response lookupListMxid: $response');

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
            mxid: mxid,
          );

          debugPrint('DEBUG::execute: newContacts: $newContactsThirparty');

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
    HashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> phoneToHashMap = {};
    for (final phoneNumber in phoneNumbers) {
      final hashes = phoneNumber.calculateHashUsingAllPeppers(
        hashDetails: hashDetails,
      );
      phoneToHashMap[phoneNumber.number] = hashes;
    }

    return phoneToHashMap;
  }

  Map<String, List<String>> calculateHashesForEmails(
    Set<Email> emails,
    HashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> emailToHashMap = {};
    for (final email in emails) {
      final hashes = email.calculateHashUsingAllPeppers(
        hashDetails: hashDetails,
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
      debugPrint(
        'DEBUG::updateContactWithHashes: phoneNumber ${phoneNumber.number} hashes: $hashes',
      );
      if (hashes != null) {
        final updatedPhoneNumber = phoneNumber.copyWith(
          thirdPartyIdToHashMap: phoneToHashMap,
        );
        updatedPhoneNumbers.add(updatedPhoneNumber);
      }
    }

    for (final email in contact.emails!) {
      final hashes = emailToHashMap[email.address];
      debugPrint(
        'DEBUG::updateContactWithHashes: email ${email.address} hashes: $hashes',
      );
      if (hashes != null) {
        final emailUpdated = email.copyWith(
          thirdPartyIdToHashMap: emailToHashMap,
        );
        updatedEmails.add(emailUpdated);
      }
    }

    debugPrint(
      'DEBUG::updateContactWithHashes: updatedPhoneNumbers: $updatedPhoneNumbers',
    );

    debugPrint(
      'DEBUG::updateContactWithHashes: updatedEmails: $updatedEmails',
    );

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
    debugPrint(
      'DEBUG::_handleLookupMappings: hashToContactIdMappings: $hashToContactIdMappings',
    );

    final Set<Contact> currentContacts = chunkContacts.toSet();

    final Set<Contact> foundContact = _findContacts(
      mappings,
      hashToContactIdMappings,
      chunkContacts,
    );

    debugPrint(
      'DEBUG::_handleLookupMappings: foundContact: $foundContact',
    );

    final updatedContacts = _updateContacts(foundContact, mappings);

    debugPrint(
      'DEBUG::_handleLookupMappings: updatedContacts: $updatedContacts',
    );

    currentContacts.removeAll(foundContact);
    currentContacts.addAll(updatedContacts);

    debugPrint(
      'DEBUG:: ==================DONE==================',
    );

    return currentContacts;
  }

  Set<Contact> _findContacts(
    Map<String, String> mappings,
    Map<String, List<String>> hashToContactIdMappings,
    List<Contact> chunkContacts,
  ) {
    final Set<Contact> foundContact = {};
    for (final entry in mappings.entries) {
      debugPrint(
        'DEBUG::_findContacts: entry: ${entry.key}',
      );

      final hash = entry.key;
      final contactIds = findContactIdByHash(
        hashToContactIdMappings: hashToContactIdMappings,
        hash: hash,
      );
      debugPrint(
        'DEBUG::_findContacts: contactIds: $contactIds',
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
      debugPrint(
        'DEBUG::_updatePhoneNumbers: thirdPartyIdToHashMap: $thirdPartyIdToHashMap',
      );
      debugPrint(
        'DEBUG::_updatePhoneNumbers: mappings: $mappings',
      );
      if (thirdPartyIdToHashMap.values
          .expand((hashes) => hashes)
          .any((hash) => mappings.containsKey(hash))) {
        final hash = thirdPartyIdToHashMap.values
            .expand((hashes) => hashes)
            .firstWhere((hash) => mappings.containsKey(hash));
        debugPrint(
          'DEBUG::_updatePhoneNumbers: matrixID: ${mappings[hash]}',
        );
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
    required String mxid,
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
              federationUrl: "${homeServerUrlInterceptor.baseUrl ?? ''}/",
              mxid: mxid,
              token: authorizationInterceptor.getAccessToken ?? '',
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
          debugPrint(
            'DEBUG::_handleThirdPartyMappings: failure: $failure',
          );
        },
        (success) {
          debugPrint(
            'DEBUG::_handleThirdPartyMappings: success: $success',
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
