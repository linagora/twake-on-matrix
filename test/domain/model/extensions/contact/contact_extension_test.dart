import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:fluffychat/domain/model/extensions/contact/contact_extension.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('searchContacts', () {
    const contacts = [
      Contact(id: '@alice:localhost', displayName: 'alice'),
      Contact(id: '@bob:localhost', displayName: 'bob'),
    ];

    test('matches display names without diacritics', () {
      expect(contacts.searchContacts('àlice').map((contact) => contact.id), [
        '@alice:localhost',
      ]);
    });
  });
}
