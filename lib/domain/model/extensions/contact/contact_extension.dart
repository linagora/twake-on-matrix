import 'package:fluffychat/data/hive/dto/contact/contact_hive_obj.dart';
import 'package:fluffychat/data/hive/dto/contact/third_party_contact_hive_obj.dart';
import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:collection/collection.dart';

extension ContactExtension on Contact {
  FederationContact toFederationContact() {
    return FederationContact(
      id: id,
      name: displayName ?? "",
      phoneNumbers: phoneNumbers?.map((phone) => phone.toFedPhone()).toSet(),
      emails: emails?.map((email) => email.toFedEmail()).toSet(),
    );
  }

  ContactHiveObj toHiveObj() {
    return ContactHiveObj(
      id: id,
      displayName: displayName,
      emails: emails?.map((email) => email.toHiveObj()).toSet(),
      phoneNumbers: phoneNumbers?.map((phone) => phone.toHiveObj()).toSet(),
    );
  }

  Set<AddressBook> toAddressBook() {
    return _addContactsToAddressBook(
      contacts: emails,
    ).union(_addContactsToAddressBook(contacts: phoneNumbers));
  }

  /// Helper method to convert third-party contacts to AddressBook entries.
  ///
  /// This method takes a set of third-party contacts (emails or phone numbers)
  /// and creates AddressBook entries for each contact that has a Matrix ID.
  ///
  /// The resulting AddressBook entries include:
  /// - The contact's Matrix ID
  /// - The display name from this Contact
  /// - All email addresses from this Contact
  /// - All phone numbers from this Contact
  /// - The active status from the third-party contact
  ///
  /// Returns a Set of [AddressBook] objects.
  Set<AddressBook> _addContactsToAddressBook({
    Set<ThirdPartyContact>? contacts,
  }) {
    final Set<AddressBook> addressBooks = {};
    if (contacts?.isNotEmpty == true) {
      for (final contact in contacts!) {
        if (contact.matrixId != null && contact.matrixId!.isNotEmpty) {
          addressBooks.add(
            AddressBook(
              displayName: displayName,
              mxid: contact.matrixId,
              active: contact.status == ThirdPartyStatus.active,
              emails: emails?.map((email) => email.address).toList(),
              phones: phoneNumbers?.map((phone) => phone.number).toList(),
            ),
          );
        }
      }
    }
    return addressBooks;
  }

  Contact updateContactWithHashes({
    required Map<String, List<String>> phoneToHashMap,
    required Map<String, List<String>> emailToHashMap,
  }) {
    final updatedPhoneNumbers = <PhoneNumber>{};
    final updatedEmails = <Email>{};

    if (phoneNumbers != null && phoneNumbers!.isNotEmpty) {
      for (final phoneNumber in phoneNumbers!) {
        final hashes = phoneToHashMap[phoneNumber.number];
        if (hashes != null) {
          final updatedPhoneNumber = phoneNumber.copyWith(
            thirdPartyIdToHashMap: phoneToHashMap,
          );
          updatedPhoneNumbers.add(updatedPhoneNumber);
        }
      }
    }

    if (emails != null && emails!.isNotEmpty) {
      for (final email in emails!) {
        final hashes = emailToHashMap[email.address];
        if (hashes != null) {
          final emailUpdated = email.copyWith(
            thirdPartyIdToHashMap: emailToHashMap,
          );
          updatedEmails.add(emailUpdated);
        }
      }
    }

    return copyWith(phoneNumbers: updatedPhoneNumbers, emails: updatedEmails);
  }

  Set<Email> _mergeEmails(Set<Email>? emails1, Set<Email>? emails2) {
    final mergedEmails = <Email>{};
    final allEmails = [...?emails1, ...?emails2];

    final emailMap = <String, Email>{};
    for (final email in allEmails) {
      if (emailMap.containsKey(email.address)) {
        // Merge with the existing email
        emailMap[email.address] = emailMap[email.address]!.copyWith(
          matrixId: email.matrixId,
          status: email.status,
        );
      } else {
        // Add to the map
        emailMap[email.address] = email;
      }
    }

    mergedEmails.addAll(emailMap.values);
    return mergedEmails;
  }

  // Merge two sets of phone numbers, combining properties
  Set<PhoneNumber> _mergePhoneNumbers(
    Set<PhoneNumber>? phones1,
    Set<PhoneNumber>? phones2,
  ) {
    final mergedPhones = <PhoneNumber>{};
    final allPhones = [...?phones1, ...?phones2];

    final phoneMap = <String, PhoneNumber>{};
    for (final phone in allPhones) {
      if (phoneMap.containsKey(phone.number)) {
        // Merge with the existing phone number
        phoneMap[phone.number] = phoneMap[phone.number]!.copyWith(
          matrixId: phone.matrixId,
          status: phone.status,
        );
      } else {
        // Add to the map
        phoneMap[phone.number] = phone;
      }
    }

    mergedPhones.addAll(phoneMap.values);
    return mergedPhones;
  }

  Contact combine(Contact other) {
    return Contact(
      id: id,
      displayName: displayName ?? other.displayName,
      emails: _mergeEmails(emails, other.emails),
      phoneNumbers: _mergePhoneNumbers(phoneNumbers, other.phoneNumbers),
    );
  }

  Set<Email> updateEmails(Map<String, String> mappings) {
    final updatedEmails = <Email>{};

    if (emails == null || emails!.isEmpty) {
      return updatedEmails;
    }

    for (final email in emails!) {
      final thirdPartyIdToHashMap = email.thirdPartyIdToHashMap ?? {};
      if (thirdPartyIdToHashMap.values
          .expand((hashes) => hashes)
          .any((hash) => mappings.containsKey(hash))) {
        final hash = thirdPartyIdToHashMap.values
            .expand((hashes) => hashes)
            .firstWhere((hash) => mappings.containsKey(hash));
        final updatedEmail = email.copyWith(matrixId: mappings[hash]);
        updatedEmails.add(updatedEmail);
      }
    }
    return updatedEmails.isEmpty ? emails ?? {} : updatedEmails;
  }

  Set<PhoneNumber> updatePhoneNumbers(Map<String, String> mappings) {
    final updatedPhoneNumbers = <PhoneNumber>{};

    if (phoneNumbers == null || phoneNumbers!.isEmpty) {
      return updatedPhoneNumbers;
    }

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
    return updatedPhoneNumbers.isEmpty
        ? phoneNumbers ?? {}
        : updatedPhoneNumbers;
  }

  Contact updateContact(
    Set<PhoneNumber> updatedPhoneNumbers,
    Set<Email> updatedEmails,
  ) {
    return copyWith(phoneNumbers: updatedPhoneNumbers, emails: updatedEmails);
  }

  bool inTomAddressBook(String matrixId) {
    return emails?.any((email) => email.matrixId == matrixId) == true ||
        phoneNumbers?.any((phone) => phone.matrixId == matrixId) == true;
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
    final contact = firstWhere((contact) => contact.id == contactId);
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
          where((contact) => contactIds.contains(contact.id)),
        );
      }
    }
    return foundContact;
  }

  Set<Contact> updateContacts({required Map<String, String> mappings}) {
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

    final updatedContacts = foundContact.updateContacts(mappings: mappings);

    currentContacts.removeAll(foundContact);
    currentContacts.addAll(updatedContacts);

    return currentContacts;
  }

  Set<Contact> combineContacts({
    required Set<Contact> contactsFromMappings,
    required Set<Contact> contactsFromThirdParty,
  }) {
    final Map<String, Contact> uniqueContactsById = {};

    // Combine all contacts into a single list
    final allContacts = [
      ...this,
      ...contactsFromMappings,
      ...contactsFromThirdParty,
    ];

    for (final contact in allContacts) {
      if (uniqueContactsById.containsKey(contact.id)) {
        // If the contact already exists, combine the properties
        uniqueContactsById[contact.id] = uniqueContactsById[contact.id]!
            .combine(contact);
      } else {
        // Otherwise, add the contact to the map
        uniqueContactsById[contact.id] = contact;
      }
    }

    return uniqueContactsById.values.toSet();
  }

  Set<AddressBook> toAddressBooks() {
    final Set<AddressBook> addressBooks = {};
    for (final contact in this) {
      addressBooks.addAll(contact.toAddressBook());
    }
    return addressBooks;
  }
}

extension IterableContactsExtension on Iterable<Contact> {
  Iterable<Contact> searchContacts(String keyword) {
    if (keyword.isEmpty) {
      return this;
    }
    final contactsMatched = where((contact) {
      final supportedFields = [contact.displayName, contact.id];
      final plainTextContains = supportedFields.any(
        (field) =>
            field?.toLowerCase().contains(keyword.toLowerCase()) ?? false,
      );
      final phoneNumberContains =
          contact.phoneNumbers?.any(
            (phoneNumber) =>
                phoneNumber.number.replaceAll(" ", "").contains(keyword),
          ) ??
          false;

      final emailContains =
          contact.emails?.any((email) => email.address.contains(keyword)) ??
          false;

      final emailMatrixIdContains =
          contact.emails
              ?.firstWhereOrNull(
                (email) => email.matrixId?.contains(keyword) == true,
              )
              ?.matrixId !=
          null;

      final phoneMatrixIdContains =
          contact.phoneNumbers
              ?.firstWhereOrNull(
                (phone) => phone.matrixId?.contains(keyword) == true,
              )
              ?.matrixId !=
          null;

      return plainTextContains ||
          phoneNumberContains ||
          emailContains ||
          emailMatrixIdContains ||
          phoneMatrixIdContains ||
          contact.id.contains(keyword);
    });
    return contactsMatched;
  }
}

extension ContactsExtension on Map<String, Contact> {
  Map<String, FederationContact> toFederationContactMap() {
    return map((key, value) => MapEntry(key, value.toFederationContact()));
  }
}

extension PhoneNumberExtension on PhoneNumber {
  FederationPhone toFedPhone() {
    return FederationPhone(number: number);
  }

  PhoneNumberHiveObject toHiveObj() {
    return PhoneNumberHiveObject(number: number, matrixId: matrixId ?? '');
  }
}

extension EmailExtension on Email {
  FederationEmail toFedEmail() {
    return FederationEmail(address: address);
  }

  EmailHiveObject toHiveObj() {
    return EmailHiveObject(email: address, matrixId: matrixId ?? '');
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
    return PhoneNumber(number: number, matrixId: matrixId);
  }
}

extension FederationEmailExtension on FederationEmail {
  Email toEmail() {
    return Email(address: address, matrixId: matrixId);
  }
}

extension PhoneNumbersExtension on Set<PhoneNumber> {
  Map<String, List<String>> calculateHashesForPhoneNumbers(
    FederationHashDetailsResponse? hashDetails,
  ) {
    if (hashDetails == null) {
      return {};
    }
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
    FederationHashDetailsResponse? hashDetails,
  ) {
    if (hashDetails == null) {
      return {};
    }
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
