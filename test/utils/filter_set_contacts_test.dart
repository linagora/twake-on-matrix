import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/pages/contacts/presentation/extension/list_contact_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('filter returns contacts and emails with "Doe" last name', () {
    final contacts = {
      Contact(emails: {'john.doe@example.com'}, displayName: 'John Doe'),
      Contact(emails: {'jane.doe@example.com'}, displayName: 'Jane Doe'),
      Contact(emails: {'bob.smith@example.com', 'bobby.smith@example.com'}, displayName: 'Bob Smith'),
    };

    final filteredContacts = contacts.filter(searchKey: 'doe');

    expect(filteredContacts, equals({
      Contact(emails: {'john.doe@example.com'}, displayName: 'John Doe'),
      Contact(emails: {'jane.doe@example.com'}, displayName: 'Jane Doe'),
    }));
  });

  test('filter returns contact and emails with "Smith" last name', () {
    final contacts = {
      Contact(emails: {'john.doe@example.com'}, displayName: 'John Doe'),
      Contact(emails: {'jane.doe@example.com'}, displayName: 'Jane Doe'),
      Contact(emails: {'bob.smith@example.com', 'bobby.smith@example.com'}, displayName: 'Bob Smith'),
    };

    final filteredContacts = contacts.filter(searchKey: 'smith');

    expect(filteredContacts, equals({
      Contact(emails: {'bob.smith@example.com', 'bobby.smith@example.com'}, displayName: 'Bob Smith'),
    }));
  });

  test('filter returns empty Set for unknown search key', () {
    final contacts = {
      Contact(emails: {'john.doe@example.com'}, displayName: 'John Doe'),
      Contact(emails: {'jane.doe@example.com'}, displayName: 'Jane Doe'),
      Contact(emails: {'bob.smith@example.com', 'bobby.smith@example.com'}, displayName: 'Bob Smith'),
    };

    final filteredContacts = contacts.filter(searchKey: 'jim');

    expect(filteredContacts, equals(<Contact>{}));
  });

  test('filter returns original Set when searchKey is empty', () {
    final contacts = {
      Contact(emails: {'john.doe@example.com'}, displayName: 'John Doe'),
      Contact(emails: {'jane.doe@example.com'}, displayName: 'Jane Doe'),
      Contact(emails: {'bob.smith@example.com', 'bobby.smith@example.com'}, displayName: 'Bob Smith'),
    };

    final filteredContacts = contacts.filter(searchKey: '');

    expect(filteredContacts, equals(contacts));
  });
}
