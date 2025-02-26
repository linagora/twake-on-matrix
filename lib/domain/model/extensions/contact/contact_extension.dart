import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:fluffychat/utils/string_extension.dart';

extension ContactExtension on Contact {
  FederationContact toFederationContact() {
    return FederationContact(
      id: id,
      name: displayName ?? "",
      phoneNumbers: phoneNumbers?.map((phone) => phone.toFedPhone()).toSet(),
      emails: emails?.map((email) => email.toFedEmail()).toSet(),
    );
  }

  Contact updateContactWithHashes({
    required Map<String, List<String>> phoneToHashMap,
    required Map<String, List<String>> emailToHashMap,
  }) {
    final updatedPhoneNumbers = <PhoneNumber>{};
    final updatedEmails = <Email>{};

    for (final phoneNumber in phoneNumbers!) {
      final hashes = phoneToHashMap[phoneNumber.number];
      if (hashes != null) {
        final updatedPhoneNumber = phoneNumber.copyWith(
          thirdPartyIdToHashMap: phoneToHashMap,
        );
        updatedPhoneNumbers.add(updatedPhoneNumber);
      }
    }

    for (final email in emails!) {
      final hashes = emailToHashMap[email.address];
      if (hashes != null) {
        final emailUpdated = email.copyWith(
          thirdPartyIdToHashMap: emailToHashMap,
        );
        updatedEmails.add(emailUpdated);
      }
    }

    return copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }

  Set<Email> updateEmails(Map<String, String> mappings) {
    final updatedEmails = <Email>{};
    for (final email in emails!) {
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

  Set<PhoneNumber> updatePhoneNumbers(
    Map<String, String> mappings,
  ) {
    final updatedPhoneNumbers = <PhoneNumber>{};
    for (final phoneNumber in phoneNumbers!) {
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

  Contact updateContact(
    Set<PhoneNumber> updatedPhoneNumbers,
    Set<Email> updatedEmails,
  ) {
    return copyWith(
      phoneNumbers: updatedPhoneNumbers,
      emails: updatedEmails,
    );
  }
}

extension SetContactExtension on Set<Contact> {
  Contact? findContactWithHash({
    required String hash,
    required Map<String, List<String>> hashToContactIdMappings,
  }) {
    final contactId = hash.findContactIdByHash(
      hashToContactIdMappings: hashToContactIdMappings,
    );
    if (contactId == null) {
      return null;
    }
    final contact = firstWhere(
      (contact) => contact.id == contactId,
    );
    return contact;
  }

  Set<Contact> findContacts(
    Map<String, String> mappings,
    Map<String, List<String>> hashToContactIdMappings,
  ) {
    final Set<Contact> foundContact = {};
    for (final entry in mappings.entries) {
      final hash = entry.key;
      final contactIds = hash.findContactIdByHash(
        hashToContactIdMappings: hashToContactIdMappings,
      );

      if (contactIds != null) {
        foundContact.addAll(
          where(
            (contact) => contactIds.contains(contact.id),
          ),
        );
      }
    }
    return foundContact;
  }

  Set<Contact> updateContacts({
    required Map<String, String> mappings,
  }) {
    final Set<Contact> updatedContacts = {};
    for (final contact in this) {
      final updatedPhoneNumbers = contact.updatePhoneNumbers(mappings);
      final updatedEmails = contact.updateEmails(mappings);
      final updatedContact = contact.updateContact(
        updatedPhoneNumbers,
        updatedEmails,
      );
      updatedContacts.add(updatedContact);
    }
    return updatedContacts;
  }

  Set<Contact> handleLookupMappings({
    required Map<String, String> mappings,
    required Map<String, List<String>> hashToContactIdMappings,
  }) {
    final Set<Contact> currentContacts = this;

    final Set<Contact> foundContact = findContacts(
      mappings,
      hashToContactIdMappings,
    );

    final updatedContacts = foundContact.updateContacts(
      mappings: mappings,
    );

    currentContacts.removeAll(foundContact);
    currentContacts.addAll(updatedContacts);

    return currentContacts;
  }

  Set<Contact> combineContacts({
    required Set<Contact> contactsFromMappings,
    required Set<Contact> contactsFromThirdParty,
  }) {
    final Map<String, Contact> uniqueContactsById = {};

    for (final contact in [
      ...this,
      ...contactsFromMappings,
      ...contactsFromThirdParty,
    ]) {
      uniqueContactsById[contact.id] = contact;
    }

    return uniqueContactsById.values.toSet();
  }
}

extension IterableContactsExtension on Iterable<Contact> {
  Iterable<Contact> searchContacts(String keyword) {
    if (keyword.isEmpty) {
      return this;
    }
    final contactsMatched = where((contact) {
      final supportedFields = [
        contact.displayName,
        contact.id,
      ];
      final plainTextContains = supportedFields.any(
        (field) =>
            field?.toLowerCase().contains(keyword.toLowerCase()) ?? false,
      );
      final phoneNumberContains = contact.phoneNumbers?.any(
            (phoneNumber) => phoneNumber.number.contains(keyword),
          ) ??
          false;

      final emailContains = contact.emails?.any(
            (email) => email.address.contains(keyword),
          ) ??
          false;
      return plainTextContains ||
          phoneNumberContains ||
          emailContains ||
          contact.id.contains(keyword);
    });
    return contactsMatched;
  }
}

extension ContactsExtension on Map<String, Contact> {
  Map<String, FederationContact> toFederationContactMap() {
    return map(
      (key, value) => MapEntry(key, value.toFederationContact()),
    );
  }
}

extension PhoneNumberExtension on PhoneNumber {
  FederationPhone toFedPhone() {
    return FederationPhone(
      number: number,
    );
  }
}

extension EmailExtension on Email {
  FederationEmail toFedEmail() {
    return FederationEmail(
      address: address,
    );
  }
}

extension FederationContactExtension on FederationContact {
  Contact toContact() {
    return Contact(
      id: id,
      displayName: name,
      phoneNumbers: phoneNumbers?.map((phone) => phone.toPhoneNumber()).toSet(),
      emails: emails?.map((email) => email.toEmail()).toSet(),
    );
  }
}

extension FederationContactsMapExtension on Map<String, FederationContact> {
  List<Contact> toContacts() {
    return values.map((contact) => contact.toContact()).toList();
  }
}

extension FederationContactsExtension on List<FederationContact> {
  List<Contact> toContacts() {
    return map((contact) => contact.toContact()).toList();
  }
}

extension FederationPhoneExtension on FederationPhone {
  PhoneNumber toPhoneNumber() {
    return PhoneNumber(
      number: number,
      matrixId: matrixId,
    );
  }
}

extension FederationEmailExtension on FederationEmail {
  Email toEmail() {
    return Email(
      address: address,
      matrixId: matrixId,
    );
  }
}

extension PhoneNumbersExtension on Set<PhoneNumber> {
  Map<String, List<String>> calculateHashesForPhoneNumbers(
    FederationHashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> phoneToHashMap = {};
    for (final phoneNumber in this) {
      final hashes = phoneNumber.calculateHashUsingAllPeppers(
        lookupPepper: hashDetails.lookupPepper,
        altLookupPeppers: hashDetails.altLookupPeppers,
        algorithms: hashDetails.algorithms,
      );
      phoneToHashMap[phoneNumber.number] = hashes;
    }

    return phoneToHashMap;
  }
}

extension EmailsExtension on Set<Email> {
  Map<String, List<String>> calculateHashesForEmails(
    FederationHashDetailsResponse hashDetails,
  ) {
    final Map<String, List<String>> emailToHashMap = {};
    for (final email in this) {
      final hashes = email.calculateHashUsingAllPeppers(
        lookupPepper: hashDetails.lookupPepper,
        altLookupPeppers: hashDetails.altLookupPeppers,
        algorithms: hashDetails.algorithms,
      );
      emailToHashMap[email.address] = hashes;
    }

    return emailToHashMap;
  }
}
