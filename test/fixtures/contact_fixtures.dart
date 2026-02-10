import 'package:fluffychat/data/model/addressbook/address_book.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';

class ContactFixtures {
  static Contact contact1 = Contact(
    id: 'id_1',
    displayName: 'Alice',
    phoneNumbers: {PhoneNumber(number: '(212)555-6789')},
    emails: {Email(address: 'alice@gmail.com')},
  );

  static Contact contact2 = Contact(
    id: 'id_2',
    displayName: 'Bob',
    phoneNumbers: {PhoneNumber(number: '(212)555-1234')},
    emails: {Email(address: 'bob@gmail.com')},
  );

  static Contact contact3 = Contact(
    id: 'id_3',
    displayName: 'Charlie',
    phoneNumbers: {PhoneNumber(number: '(212)555-2345')},
  );

  static Contact contact4 = Contact(
    id: 'id_4',
    displayName: 'Diana',
    emails: {Email(address: 'diana@gmail.com')},
  );

  static Contact contact5 = Contact(
    id: 'id_5',
    displayName: 'Eve',
    phoneNumbers: {PhoneNumber(number: '(212)555-4567')},
  );

  static Contact contact6 = Contact(
    id: 'id_6',
    displayName: 'Frank',
    emails: {Email(address: 'frank@gmail.com')},
  );

  static List<AddressBook> addressBooks = [
    AddressBook(displayName: 'Alice', mxid: '@alice123.com'),
    AddressBook(displayName: 'Bob', mxid: '@bob456.com'),
  ];
}
