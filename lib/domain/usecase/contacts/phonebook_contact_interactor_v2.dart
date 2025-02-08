import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state_v2.dart';
import 'package:fluffychat/domain/model/contact/contact_new.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
import 'package:fluffychat/domain/model/contact/lookup_list_mxid_request.dart';
import 'package:fluffychat/domain/repository/lookup_repository.dart';

// import 'package:fluffychat/domain/repository/phonebook_contact_repository_v2.dart';
import 'package:fluffychat/domain/usecase/contacts/mock_contacts_list.dart';
import 'package:flutter/cupertino.dart';

class PhonebookContactInteractorV2 {
  // final PhonebookContactRepositoryV2 _phonebookContactRepository =
  //     getIt.get<PhonebookContactRepositoryV2>();

  final LookupRepository _lookupRepository = getIt.get<LookupRepository>();

  Stream<Either<Failure, Success>> execute({
    int lookupChunkSize = 10,
  }) async* {
    try {
      int progress = 0;
      yield const Right(GetPhonebookContactsV2Loading());

      //TODO: Replace this with actual contacts
      // final contacts = await _phonebookContactRepository.fetchContacts();

      final contacts = mockContacts;

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

        final newContacts = _handleLookupMappings(
          mappings: response.mappings ?? {},
          hashToContactIdMappings: hashToContactIdMappings,
          chunkContacts: contactIdToHashMap.values.toList(),
        );

        progress++;

        final progressStep = (progress / chunks.length * 100).toInt();

        updatedContact.addAll(newContacts);

        yield Right(
          GetPhonebookContactsV2Success(
            progress: progressStep,
            contacts: updatedContact.toList(),
          ),
        );
      }
    } catch (e) {
      yield Left(GetPhonebookContactsV2Failure(exception: e));
    }
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

// void _handleLookupThirdPartyId({
//   required Map<String, ThirdPartyMappingsData> thirdPartyMappings,
// }) {}
}
