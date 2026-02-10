import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/contact/third_party_status.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Contact', () {
    test('should create a Contact instance with required fields', () {
      const contact = Contact(id: 'contact1');

      expect(contact.id, 'contact1');
      expect(contact.displayName, null);
      expect(contact.emails, null);
      expect(contact.phoneNumbers, null);
    });

    test('should create a Contact instance with all fields', () {
      final emails = {Email(address: 'test@example.com')};
      final phoneNumbers = {PhoneNumber(number: '+1234567890')};

      const displayName = 'Test Contact';

      final contact = Contact(
        id: 'contact1',
        displayName: displayName,
        emails: emails,
        phoneNumbers: phoneNumbers,
      );

      expect(contact.id, 'contact1');
      expect(contact.displayName, displayName);
      expect(contact.emails, emails);
      expect(contact.phoneNumbers, phoneNumbers);
    });

    test('copyWith should return a new instance with updated fields', () {
      const contact = Contact(id: 'contact1');

      final updatedContact = contact.copyWith(
        displayName: 'Updated Name',
        emails: {Email(address: 'updated@example.com')},
        phoneNumbers: {PhoneNumber(number: '+9876543210')},
      );

      expect(updatedContact.id, 'contact1');
      expect(updatedContact.displayName, 'Updated Name');
      expect(updatedContact.emails?.first.address, 'updated@example.com');
      expect(updatedContact.phoneNumbers?.first.number, '+9876543210');

      // Original contact should remain unchanged
      expect(contact.displayName, null);
      expect(contact.emails, null);
      expect(contact.phoneNumbers, null);
    });

    test('equals should compare all properties', () {
      final contact1 = Contact(
        id: 'contact1',
        displayName: 'Test Contact',
        emails: {Email(address: 'test@example.com')},
        phoneNumbers: {PhoneNumber(number: '+1234567890')},
      );

      final contact2 = Contact(
        id: 'contact1',
        displayName: 'Test Contact',
        emails: {Email(address: 'test@example.com')},
        phoneNumbers: {PhoneNumber(number: '+1234567890')},
      );

      final contact3 = Contact(
        id: 'contact2',
        displayName: 'Test Contact',
        emails: {Email(address: 'test@example.com')},
        phoneNumbers: {PhoneNumber(number: '+1234567890')},
      );

      expect(contact1, contact2);
      expect(contact1, isNot(contact3));
    });
  });

  group('PhoneNumber', () {
    test('should create a PhoneNumber instance with required fields', () {
      final phoneNumber = PhoneNumber(number: '+1234567890');

      expect(phoneNumber.number, '+1234567890');
      expect(phoneNumber.thirdPartyId, '1234567890');
      expect(phoneNumber.thirdPartyIdType, ThirdPartyIdType.msisdn);
      expect(phoneNumber.matrixId, null);
      expect(phoneNumber.status, null);
      expect(phoneNumber.thirdPartyIdToHashMap, null);
    });

    test('should create a PhoneNumber instance with all fields', () {
      final thirdPartyIdToHashMap = {
        'phone': ['hash1', 'hash2'],
      };

      final phoneNumber = PhoneNumber(
        number: '+1234567890',
        matrixId: '@user:example.com',
        status: ThirdPartyStatus.active,
        thirdPartyIdToHashMap: thirdPartyIdToHashMap,
      );

      expect(phoneNumber.number, '+1234567890');
      expect(phoneNumber.thirdPartyId, '1234567890');
      expect(phoneNumber.thirdPartyIdType, ThirdPartyIdType.msisdn);
      expect(phoneNumber.matrixId, '@user:example.com');
      expect(phoneNumber.status, ThirdPartyStatus.active);
      expect(phoneNumber.thirdPartyIdToHashMap, thirdPartyIdToHashMap);
    });

    test('copyWith should return a new instance with updated fields', () {
      final phoneNumber = PhoneNumber(number: '+1234567890');

      final updatedPhoneNumber = phoneNumber.copyWith(
        matrixId: '@user:example.com',
        status: ThirdPartyStatus.active,
        thirdPartyIdToHashMap: {
          'phone': ['hash1', 'hash2'],
        },
      );

      expect(updatedPhoneNumber.number, '+1234567890');
      expect(updatedPhoneNumber.matrixId, '@user:example.com');
      expect(updatedPhoneNumber.status, ThirdPartyStatus.active);
      expect(updatedPhoneNumber.thirdPartyIdToHashMap, {
        'phone': ['hash1', 'hash2'],
      });

      // Original phoneNumber should remain unchanged
      expect(phoneNumber.matrixId, null);
      expect(phoneNumber.status, null);
      expect(phoneNumber.thirdPartyIdToHashMap, null);
    });

    test('calculateHashWithAlgorithmSha256 should return correct hash', () {
      final phoneNumber = PhoneNumber(number: '+1234567890');

      final hash = phoneNumber.calculateHashWithAlgorithmSha256(
        pepper: 'test_pepper',
      );

      // The hash is a base64 encoded string, so it should be a non-empty string
      expect(hash, isA<String>());
      expect(hash.isNotEmpty, true);
    });

    test('calculateHashWithoutAlgorithm should return correct format', () {
      final phoneNumber = PhoneNumber(number: '+1234567890');

      final hash = phoneNumber.calculateHashWithoutAlgorithm();

      expect(hash, '1234567890 msisdn');
    });

    test('calculateHashUsingAllPeppers should return list of hashes', () {
      final phoneNumber = PhoneNumber(number: '+1234567890');

      final hashes = phoneNumber.calculateHashUsingAllPeppers(
        lookupPepper: 'main_pepper',
        altLookupPeppers: {'alt_pepper1', 'alt_pepper2'},
        algorithms: {'sha256'},
      );

      expect(hashes, isA<List<String>>());
      expect(hashes.length, 3); // One for each pepper
    });
  });

  group('Email', () {
    test('should create an Email instance with required fields', () {
      final email = Email(address: 'test@example.com');

      expect(email.address, 'test@example.com');
      expect(email.thirdPartyId, 'test@example.com');
      expect(email.thirdPartyIdType, ThirdPartyIdType.email);
      expect(email.matrixId, null);
      expect(email.status, null);
      expect(email.thirdPartyIdToHashMap, null);
    });

    test('should create an Email instance with all fields', () {
      final thirdPartyIdToHashMap = {
        'email': ['hash1', 'hash2'],
      };

      final email = Email(
        address: 'test@example.com',
        matrixId: '@user:example.com',
        status: ThirdPartyStatus.active,
        thirdPartyIdToHashMap: thirdPartyIdToHashMap,
      );

      expect(email.address, 'test@example.com');
      expect(email.thirdPartyId, 'test@example.com');
      expect(email.thirdPartyIdType, ThirdPartyIdType.email);
      expect(email.matrixId, '@user:example.com');
      expect(email.status, ThirdPartyStatus.active);
      expect(email.thirdPartyIdToHashMap, thirdPartyIdToHashMap);
    });

    test('copyWith should return a new instance with updated fields', () {
      final email = Email(address: 'test@example.com');

      final updatedEmail = email.copyWith(
        matrixId: '@user:example.com',
        status: ThirdPartyStatus.active,
        thirdPartyIdToHashMap: {
          'email': ['hash1', 'hash2'],
        },
      );

      expect(updatedEmail.address, 'test@example.com');
      expect(updatedEmail.matrixId, '@user:example.com');
      expect(updatedEmail.status, ThirdPartyStatus.active);
      expect(updatedEmail.thirdPartyIdToHashMap, {
        'email': ['hash1', 'hash2'],
      });

      // Original email should remain unchanged
      expect(email.matrixId, null);
      expect(email.status, null);
      expect(email.thirdPartyIdToHashMap, null);
    });

    test('calculateHashWithAlgorithmSha256 should return correct hash', () {
      final email = Email(address: 'test@example.com');

      final hash = email.calculateHashWithAlgorithmSha256(
        pepper: 'test_pepper',
      );

      // The hash is a base64 encoded string, so it should be a non-empty string
      expect(hash, isA<String>());
      expect(hash.isNotEmpty, true);
    });

    test('calculateHashWithoutAlgorithm should return correct format', () {
      final email = Email(address: 'test@example.com');

      final hash = email.calculateHashWithoutAlgorithm();

      expect(hash, 'test@example.com email');
    });

    test('calculateHashUsingAllPeppers should return list of hashes', () {
      final email = Email(address: 'test@example.com');

      final hashes = email.calculateHashUsingAllPeppers(
        lookupPepper: 'main_pepper',
        altLookupPeppers: {'alt_pepper1', 'alt_pepper2'},
        algorithms: {'sha256'},
      );

      expect(hashes, isA<List<String>>());
      expect(hashes.length, 3); // One for each pepper
    });
  });

  group('ThirdPartyIdType', () {
    test('toString should return correct string representation', () {
      expect(ThirdPartyIdType.email.toString(), 'email');
      expect(ThirdPartyIdType.msisdn.toString(), 'msisdn');
    });
  });

  group('toAddressBooks test', () {
    test('should return empty when contact is empty', () {
      final Set<Contact> contacts = {};

      final result = contacts.toAddressBooks();

      expect(result, contacts);
    });

    test('should return empty when contact has no matrix id', () {
      final contacts = {
        Contact(
          id: 'contact1',
          displayName: 'Alice',
          emails: {Email(address: 'alice@mail.com')},
          phoneNumbers: {PhoneNumber(number: '+1234567890')},
        ),
      };

      final result = contacts.toAddressBooks();

      expect(result, []);
    });

    test('should return empty when contact matrix id is empty', () {
      final contacts = {
        Contact(
          id: 'contact1',
          displayName: 'Alice',
          emails: {Email(address: 'alice@mail.com', matrixId: '')},
          phoneNumbers: {PhoneNumber(number: '+1234567890', matrixId: '')},
        ),
      };

      final result = contacts.toAddressBooks();

      expect(result, []);
    });

    test('should return address books when contact has matrix id', () {
      final contacts = {
        Contact(
          id: 'contact1',
          displayName: 'Alice',
          emails: {
            Email(address: 'alice@mail.com', matrixId: '@alice:example.com'),
          },
          phoneNumbers: {
            PhoneNumber(
              number: '+1234567890',
              matrixId: '@alice_phone:example.com',
            ),
          },
        ),
      };

      final result = contacts.toAddressBooks();

      expect(result.length, 2);
    });

    test(
      'should return address books for multiple contacts with matrix ids',
      () {
        final contacts = {
          Contact(
            id: 'contact1',
            displayName: 'Alice',
            emails: {
              Email(address: 'alice@mail.com', matrixId: '@alice:example.com'),
            },
            phoneNumbers: {
              PhoneNumber(
                number: '+1234567890',
                matrixId: '@alice_phone:example.com',
              ),
            },
          ),
          Contact(
            id: 'contact2',
            displayName: 'Bob',
            emails: {
              Email(address: 'bob@mail.com', matrixId: '@bob:example.com'),
            },
            phoneNumbers: {
              PhoneNumber(
                number: '+0987654321',
                matrixId: '@bob_phone:example.com',
              ),
            },
          ),
        };

        final result = contacts.toAddressBooks();

        expect(result.length, 4);
      },
    );

    test(
      'should return address books for contacts with mixed valid and invalid matrix ids',
      () {
        final contacts = {
          Contact(
            id: 'contact1',
            displayName: 'Alice',
            emails: {
              Email(address: 'alice@mail.com', matrixId: '@alice:example.com'),
            },
            phoneNumbers: {PhoneNumber(number: '+1234567890', matrixId: '')},
          ),
          Contact(
            id: 'contact2',
            displayName: 'Bob',
            emails: {Email(address: 'bob@mail.com', matrixId: '')},
            phoneNumbers: {
              PhoneNumber(
                number: '+0987654321',
                matrixId: '@bob_phone:example.com',
              ),
            },
          ),
        };

        final result = contacts.toAddressBooks();

        expect(result.length, 2);
      },
    );

    test(
      'should return address books for contacts with only email or phone number matrix ids',
      () {
        final contacts = {
          Contact(
            id: 'contact1',
            displayName: 'Alice',
            emails: {
              Email(address: 'alice@mail.com', matrixId: '@alice:example.com'),
            },
          ),
          Contact(
            id: 'contact2',
            displayName: 'Bob',
            phoneNumbers: {
              PhoneNumber(
                number: '+0987654321',
                matrixId: '@bob_phone:example.com',
              ),
            },
          ),
        };

        final result = contacts.toAddressBooks();

        expect(result.length, 2);
      },
    );
  });
}
