import 'package:collection/collection.dart';
import 'package:dartz/dartz.dart';
import 'package:fluffychat/app_state/failure.dart';
import 'package:fluffychat/app_state/success.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/app_state/contact/get_phonebook_contact_state_v2.dart';
import 'package:fluffychat/domain/model/contact/contact_v2.dart';
import 'package:fluffychat/domain/model/contact/hash_details_response.dart';
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
    yield const Right(GetPhonebookContactsLoading(progress: 0));
    final contacts = await _phonebookContactRepository.fetchContacts();

    if (contacts.isEmpty) {
      return;
    }

    final hashDetails = await _lookupRepository.getHashDetails();

    final contactIdToHashMap = {
      for (final contact in contacts) contact.id: contact,
    };

    final chunks = contactIdToHashMap.values.slices(lookupChunkSize);

    for (final chunkContacts in chunks) {
      final Map<String, List<String>> hashToContactIdMappings = {};
      for (final contact in chunkContacts) {
        final updatedContact = processContacts(
          chunkContacts,
          hashDetails,
          hashToContactIdMappings,
          contactIdToHashMap,
        );

        if (updatedContact == null) continue;

        contactIdToHashMap[contact.id] = updatedContact;
      }

      final response = await _lookupRepository.lookupListMxid(
        LookupListMxidRequest(
          addresses:
              hashToContactIdMappings.values.expand((hash) => hash).toSet(),
          algorithm: hashDetails.algorithms?.firstOrNull,
          pepper: hashDetails.lookupPepper,
        ),
      );

      final totalChunks = chunks.length;

      yield await _handleLookupMappings(
        progress: lookupChunkSize ~/ totalChunks,
        chunkSize: lookupChunkSize,
        totalChunks: totalChunks,
        mappings: response.mappings ?? {},
        hashToContactIdMappings: hashToContactIdMappings,
        chunkContacts: chunkContacts,
      );
      _handleLookupThirdPartyId(
        thirdPartyMappings: response.thirdPartyMappings ?? {},
      );
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
      phoneNumber.setThirdPartyIdToHashMap(hashes);
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
      email.setThirdPartyIdToHashMap(hashes);
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
      updatedPhoneNumbers.add(phoneNumber);
    }

    for (final email in contact.emails!) {
      updatedEmails.add(email);
    }

    return contact.copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }

  Contact? processContacts(
    List<Contact> chunkContacts,
    HashDetailsResponse hashDetails,
    Map<String, List<String>> hashToContactIdMappings,
    Map<String, Contact> contactIdToHashMap,
  ) {
    for (final contact in chunkContacts) {
      if (contact.phoneNumbers == null && contact.phoneNumbers!.isEmpty) {
        continue;
      }

      if (contact.emails == null && contact.emails!.isEmpty) {
        continue;
      }

      final phoneToHashMap =
          calculateHashesForPhoneNumbers(contact.phoneNumbers!, hashDetails);

      final emailToHashMap =
          calculateHashesForEmails(contact.emails!, hashDetails);

      hashToContactIdMappings[contact.id]?.addAll(
        phoneToHashMap.values.expand((hash) => hash),
      );

      hashToContactIdMappings[contact.id]?.addAll(
        emailToHashMap.values.expand((hash) => hash),
      );

      final updatedContact = updateContactWithHashes(
        contact,
        phoneToHashMap,
        emailToHashMap,
      );

      return updatedContact;
    }
    return null;
  }

  Future<Either<Failure, Success>> _handleLookupMappings({
    required Map<String, String> mappings,
    required Map<String, List<String>> hashToContactIdMappings,
    required List<Contact> chunkContacts,
    required int progress,
    required int chunkSize,
    required int totalChunks,
  }) async {
    final Set<Contact> foundContact =
        _findContacts(mappings, hashToContactIdMappings, chunkContacts);
    final Set<Contact> notFoundContact =
        _findNotFoundContacts(chunkContacts, foundContact);

    final updatedContacts = _updateContacts(foundContact, mappings);

    return Right(
      GetPhonebookContactsSuccess(
        progress: progress,
        chunkSize: chunkSize,
        totalChunks: totalChunks,
        foundContacts: updatedContacts.toList(),
        notFoundContacts: notFoundContact.toList(),
      ),
    );
  }

  Set<Contact> _findContacts(
    Map<String, String> mappings,
    Map<String, List<String>> hashToContactIdMappings,
    List<Contact> chunkContacts,
  ) {
    final Set<Contact> foundContact = {};
    for (final entry in mappings.entries) {
      final hash = entry.key;
      final contactIds = hashToContactIdMappings[hash];
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

  Set<Contact> _findNotFoundContacts(
    List<Contact> chunkContacts,
    Set<Contact> foundContact,
  ) {
    return chunkContacts
        .where((contact) => !foundContact.contains(contact))
        .toSet();
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
      final thirdPartyIdToHashMap = phoneNumber.getThirdPartyIdToHashMap();
      if (thirdPartyIdToHashMap.containsKey(mappings[contact.id])) {
        final updatePhoneNumber = phoneNumber.copyWith(
          matrixId: mappings[contact.id],
        );
        updatedPhoneNumbers.add(updatePhoneNumber);
      }
    }
    return updatedPhoneNumbers;
  }

  Set<Email> _updateEmails(Contact contact, Map<String, String> mappings) {
    final updatedEmails = <Email>{};
    for (final email in contact.emails!) {
      final thirdPartyIdToHashMap = email.getThirdPartyIdToHashMap();
      if (thirdPartyIdToHashMap.containsKey(mappings[contact.id])) {
        final updatedEmail = email.copyWith(
          matrixId: mappings[contact.id],
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

  void _handleLookupThirdPartyId({
    required Map<String, ThirdPartyMappingsData> thirdPartyMappings,
  }) {}
}
