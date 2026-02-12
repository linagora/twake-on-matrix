import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_contact.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_hash_details_response.dart';
import 'package:fluffychat/modules/federation_identity_lookup/domain/models/federation_third_party_contact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContactExtension', () {
    test('toFederationContact should convert Contact to FederationContact', () {
      final contact = Contact(
        id: 'contact1',
        displayName: 'Test Contact',
        emails: {Email(address: 'test@example.com')},
        phoneNumbers: {PhoneNumber(number: '+1234567890')},
      );

      final federationContact = contact.toFederationContact();

      expect(federationContact.id, 'contact1');
      expect(federationContact.name, 'Test Contact');
      expect(federationContact.emails?.length, 1);
      expect(federationContact.emails?.first.address, 'test@example.com');
      expect(federationContact.phoneNumbers?.length, 1);
      expect(federationContact.phoneNumbers?.first.number, '+1234567890');
    });

    test(
      'updateContactWithHashes should update contact with hash mappings',
      () {
        final contact = Contact(
          id: 'contact1',
          displayName: 'Test Contact',
          emails: {Email(address: 'test@example.com')},
          phoneNumbers: {PhoneNumber(number: '+1234567890')},
        );

        final phoneToHashMap = {
          '+1234567890': ['phone_hash1', 'phone_hash2'],
        };

        final emailToHashMap = {
          'test@example.com': ['email_hash1', 'email_hash2'],
        };

        final updatedContact = contact.updateContactWithHashes(
          phoneToHashMap: phoneToHashMap,
          emailToHashMap: emailToHashMap,
        );

        expect(updatedContact.id, 'contact1');
        expect(updatedContact.displayName, 'Test Contact');
        expect(updatedContact.emails?.length, 1);
        expect(updatedContact.phoneNumbers?.length, 1);

        // Check that the hash maps were correctly assigned
        final updatedEmail = updatedContact.emails?.first;
        expect(updatedEmail?.thirdPartyIdToHashMap, emailToHashMap);

        final updatedPhone = updatedContact.phoneNumbers?.first;
        expect(updatedPhone?.thirdPartyIdToHashMap, phoneToHashMap);
      },
    );

    test('combine should merge two contacts correctly', () {
      final contact1 = Contact(
        id: 'contact1',
        displayName: 'Contact 1',
        emails: {
          Email(address: 'test@example.com', matrixId: '@user1:example.com'),
        },
        phoneNumbers: {
          PhoneNumber(number: '+1234567890', matrixId: '@user1:example.com'),
        },
      );

      final contact2 = Contact(
        id: 'contact1',
        displayName: 'Contact 2',
        emails: {
          Email(address: 'test@example.com', status: ThirdPartyStatus.active),
          Email(address: 'another@example.com'),
        },
        phoneNumbers: {
          PhoneNumber(number: '+1234567890', status: ThirdPartyStatus.active),
          PhoneNumber(number: '+9876543210'),
        },
      );

      final combinedContact = contact1.combine(contact2);

      expect(combinedContact.id, 'contact1');
      expect(
        combinedContact.displayName,
        'Contact 1',
      ); // Should keep contact1's name

      // Should have merged emails
      expect(combinedContact.emails?.length, 2);
      final mergedEmail = combinedContact.emails?.firstWhere(
        (email) => email.address == 'test@example.com',
      );
      expect(mergedEmail?.matrixId, '@user1:example.com');
      expect(mergedEmail?.status, ThirdPartyStatus.active);

      // Should have merged phone numbers
      expect(combinedContact.phoneNumbers?.length, 2);
      final mergedPhone = combinedContact.phoneNumbers?.firstWhere(
        (phone) => phone.number == '+1234567890',
      );
      expect(mergedPhone?.matrixId, '@user1:example.com');
      expect(mergedPhone?.status, ThirdPartyStatus.active);
    });

    test('updateEmails should update emails with matrix IDs from mappings', () {
      final email = Email(
        address: 'test@example.com',
        thirdPartyIdToHashMap: {
          'test@example.com': ['hash1', 'hash2'],
        },
      );

      final contact = Contact(
        id: 'contact1',
        displayName: 'Test Contact',
        emails: {email},
      );

      final mappings = {'hash1': '@user:example.com'};

      final updatedEmails = contact.updateEmails(mappings);

      expect(updatedEmails.length, 1);
      expect(updatedEmails.first.address, 'test@example.com');
      expect(updatedEmails.first.matrixId, '@user:example.com');
    });

    test(
      'updatePhoneNumbers should update phone numbers with matrix IDs from mappings',
      () {
        final phoneNumber = PhoneNumber(
          number: '+1234567890',
          thirdPartyIdToHashMap: {
            '+1234567890': ['hash1', 'hash2'],
          },
        );

        final contact = Contact(
          id: 'contact1',
          displayName: 'Test Contact',
          phoneNumbers: {phoneNumber},
        );

        final mappings = {'hash1': '@user:example.com'};

        final updatedPhoneNumbers = contact.updatePhoneNumbers(mappings);

        expect(updatedPhoneNumbers.length, 1);
        expect(updatedPhoneNumbers.first.number, '+1234567890');
        expect(updatedPhoneNumbers.first.matrixId, '@user:example.com');
      },
    );

    test('updateContact should return a new contact with updated fields', () {
      const contact = Contact(id: 'contact1', displayName: 'Test Contact');

      final updatedPhoneNumbers = {
        PhoneNumber(number: '+1234567890', matrixId: '@user:example.com'),
      };

      final updatedEmails = {
        Email(address: 'test@example.com', matrixId: '@user:example.com'),
      };

      final updatedContact = contact.updateContact(
        updatedPhoneNumbers,
        updatedEmails,
      );

      expect(updatedContact.id, 'contact1');
      expect(updatedContact.displayName, 'Test Contact');
      expect(updatedContact.phoneNumbers, updatedPhoneNumbers);
      expect(updatedContact.emails, updatedEmails);
    });
  });

  group('SetContactExtension', () {
    test('findContactWithHash should find contact by hash', () {
      const contact1 = Contact(id: 'contact1');
      const contact2 = Contact(id: 'contact2');

      final contacts = {contact1, contact2};

      final hashToContactIdMappings = {
        'contact1': ['hash1'],
      };

      final foundContact = contacts.findContactWithHash(
        hash: 'hash1',
        hashToContactIdMappings: hashToContactIdMappings,
      );

      expect(foundContact, contact1);
    });

    test('findContacts should find contacts by hash mappings', () {
      const contact1 = Contact(id: 'contact1');
      const contact2 = Contact(id: 'contact2');

      final contacts = {contact1, contact2};

      final mappings = {
        'hash1': '@user1:example.com',
        'hash2': '@user2:example.com',
      };

      final hashToContactIdMappings = {
        'contact1': ['hash1'],
        'contact2': ['hash2'],
      };

      final foundContacts = contacts.findContacts(
        mappings,
        hashToContactIdMappings,
      );

      expect(foundContacts.length, 2);
      expect(foundContacts.contains(contact1), true);
      expect(foundContacts.contains(contact2), true);
    });

    test(
      'updateContacts should update contacts with matrix IDs from mappings',
      () {
        final phoneNumber = PhoneNumber(
          number: '+1234567890',
          thirdPartyIdToHashMap: {
            '+1234567890': ['hash1'],
          },
        );

        final contact = Contact(id: 'contact1', phoneNumbers: {phoneNumber});

        final contacts = {contact};

        final mappings = {'hash1': '@user:example.com'};

        final updatedContacts = contacts.updateContacts(mappings: mappings);

        expect(updatedContacts.length, 1);
        final updatedContact = updatedContacts.first;
        expect(
          updatedContact.phoneNumbers?.first.matrixId,
          '@user:example.com',
        );
      },
    );

    test('handleLookupMappings should update contacts based on mappings', () {
      final phoneNumber = PhoneNumber(
        number: '+1234567890',
        thirdPartyIdToHashMap: {
          '+1234567890': ['hash1'],
        },
      );

      final contact = Contact(id: 'contact1', phoneNumbers: {phoneNumber});

      final contacts = {contact};

      final mappings = {'hash1': '@user:example.com'};

      final hashToContactIdMappings = {
        'contact1': ['hash1'],
      };

      final updatedContacts = contacts.handleLookupMappings(
        mappings: mappings,
        hashToContactIdMappings: hashToContactIdMappings,
      );

      expect(updatedContacts.length, 1);
      final updatedContact = updatedContacts.first;
      expect(updatedContact.phoneNumbers?.first.matrixId, '@user:example.com');
    });

    test('combineContacts should merge contacts from different sources', () {
      const contact1 = Contact(id: 'contact1', displayName: 'Contact 1');

      final contact2 = Contact(
        id: 'contact1',
        emails: {Email(address: 'test@example.com')},
      );

      final contact3 = Contact(
        id: 'contact1',
        phoneNumbers: {PhoneNumber(number: '+1234567890')},
      );

      final contacts = {contact1};
      final contactsFromMappings = {contact2};
      final contactsFromThirdParty = {contact3};

      final combinedContacts = contacts.combineContacts(
        contactsFromMappings: contactsFromMappings,
        contactsFromThirdParty: contactsFromThirdParty,
      );

      expect(combinedContacts.length, 1);
      final combinedContact = combinedContacts.first;
      expect(combinedContact.id, 'contact1');
      expect(combinedContact.displayName, 'Contact 1');
      expect(combinedContact.emails?.length, 1);
      expect(combinedContact.emails?.first.address, 'test@example.com');
      expect(combinedContact.phoneNumbers?.length, 1);
      expect(combinedContact.phoneNumbers?.first.number, '+1234567890');
    });
  });

  group('IterableContactsExtension', () {
    test('searchContacts should filter contacts by keyword', () {
      final contacts = [
        Contact(
          id: 'contact1',
          displayName: 'John Doe',
          emails: {Email(address: 'john@example.com')},
          phoneNumbers: {PhoneNumber(number: '+1234567890')},
        ),
        Contact(
          id: 'contact2',
          displayName: 'Jane Smith',
          emails: {Email(address: 'jane@example.com')},
          phoneNumbers: {PhoneNumber(number: '+9876543210')},
        ),
      ];

      // Search by display name
      var results = contacts.searchContacts('John');
      expect(results.length, 1);
      expect(results.first.id, 'contact1');

      // Search by email
      results = contacts.searchContacts('jane@example');
      expect(results.length, 1);
      expect(results.first.id, 'contact2');

      // Search by phone number
      results = contacts.searchContacts('12345');
      expect(results.length, 1);
      expect(results.first.id, 'contact1');

      // Search by ID
      results = contacts.searchContacts('contact2');
      expect(results.length, 1);
      expect(results.first.id, 'contact2');

      // Empty keyword should return all contacts
      results = contacts.searchContacts('');
      expect(results.length, 2);
    });
  });

  group('PhoneNumbersExtension', () {
    test('calculateHashesForPhoneNumbers should generate hash mappings', () {
      final phoneNumbers = {PhoneNumber(number: '+1234567890')};

      const hashDetails = FederationHashDetailsResponse(
        lookupPepper: 'main_pepper',
        altLookupPeppers: {'alt_pepper1', 'alt_pepper2'},
        algorithms: {'sha256'},
      );

      final phoneToHashMap = phoneNumbers.calculateHashesForPhoneNumbers(
        hashDetails,
      );

      expect(phoneToHashMap.keys.contains('+1234567890'), true);
      expect(phoneToHashMap['+1234567890']?.length, 3); // One for each pepper
    });
  });

  group('EmailsExtension', () {
    test('calculateHashesForEmails should generate hash mappings', () {
      final emails = {Email(address: 'test@example.com')};

      const hashDetails = FederationHashDetailsResponse(
        lookupPepper: 'main_pepper',
        altLookupPeppers: {'alt_pepper1', 'alt_pepper2'},
        algorithms: {'sha256'},
      );

      final emailToHashMap = emails.calculateHashesForEmails(hashDetails);

      expect(emailToHashMap.keys.contains('test@example.com'), true);
      expect(
        emailToHashMap['test@example.com']?.length,
        3,
      ); // One for each pepper
    });
  });

  group('FederationContactExtension', () {
    test('toContact should convert FederationContact to Contact', () {
      final federationContact = FederationContact(
        id: 'contact1',
        name: 'Test Contact',
        emails: {FederationEmail(address: 'test@example.com')},
        phoneNumbers: {FederationPhone(number: '+1234567890')},
      );

      final contact = federationContact.toContact();

      expect(contact.id, 'contact1');
      expect(contact.displayName, 'Test Contact');
      expect(contact.emails?.length, 1);
      expect(contact.emails?.first.address, 'test@example.com');
      expect(contact.phoneNumbers?.length, 1);
      expect(contact.phoneNumbers?.first.number, '+1234567890');
    });
  });

  group('FederationContactsMapExtension', () {
    test(
      'toContacts should convert map of FederationContacts to list of Contacts',
      () {
        final federationContactsMap = {
          'contact1': FederationContact(id: 'contact1', name: 'Contact 1'),
          'contact2': FederationContact(id: 'contact2', name: 'Contact 2'),
        };

        final contacts = federationContactsMap.toContacts();

        expect(contacts.length, 2);
        expect(contacts.any((contact) => contact.id == 'contact1'), true);
        expect(contacts.any((contact) => contact.id == 'contact2'), true);
      },
    );
  });

  group('FederationContactsExtension', () {
    test(
      'toContacts should convert list of FederationContacts to list of Contacts',
      () {
        final federationContacts = [
          FederationContact(id: 'contact1', name: 'Contact 1'),
          FederationContact(id: 'contact2', name: 'Contact 2'),
        ];

        final contacts = federationContacts.toContacts();

        expect(contacts.length, 2);
        expect(contacts.any((contact) => contact.id == 'contact1'), true);
        expect(contacts.any((contact) => contact.id == 'contact2'), true);
      },
    );
  });

  group('FederationPhoneExtension', () {
    test('toPhoneNumber should convert FederationPhone to PhoneNumber', () {
      final federationPhone = FederationPhone(
        number: '+1234567890',
        matrixId: '@user:example.com',
      );

      final phoneNumber = federationPhone.toPhoneNumber();

      expect(phoneNumber.number, '+1234567890');
      expect(phoneNumber.matrixId, '@user:example.com');
    });
  });

  group('FederationEmailExtension', () {
    test('toEmail should convert FederationEmail to Email', () {
      final federationEmail = FederationEmail(
        address: 'test@example.com',
        matrixId: '@user:example.com',
      );

      final email = federationEmail.toEmail();

      expect(email.address, 'test@example.com');
      expect(email.matrixId, '@user:example.com');
    });
  });
}
