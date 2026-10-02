import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/presentation/extensions/contact/unified_contact_search_extension.dart';

void main() {
  const elise = UnifiedContact(
    matrixId: '@elise:server',
    canonicalDisplayName: 'Élise Martin',
    emails: ['elise@company.com'],
    phones: ['+33611111111'],
  );
  const bob = UnifiedContact(
    matrixId: '@bob:server',
    canonicalDisplayName: 'Bob',
  );
  const contacts = [elise, bob];

  group('UnifiedContactsSearch', () {
    test('an empty or blank keyword returns every contact', () {
      expect(contacts.searchContacts(''), contacts);
      expect(contacts.searchContacts('   '), contacts);
    });

    test('ignores diacritics in the name, whichever side carries them', () {
      expect(contacts.searchContacts('elise'), [elise]);
      expect(contacts.searchContacts('Élise'), [elise]);
      expect(contacts.searchContacts('ÉLISE'), [elise]);
      expect(
        [
          const UnifiedContact(
            matrixId: '@a:server',
            canonicalDisplayName: 'Alice',
          ),
        ].searchContacts('àlice'),
        hasLength(1),
      );
    });

    test('matches decomposed (NFD) and composed (NFC) forms alike', () {
      const decomposed = 'Élise';
      expect(contacts.searchContacts(decomposed), [elise]);
      expect(contacts.searchContacts('Élise'), [elise]);
    });

    test('is case-insensitive', () {
      expect(contacts.searchContacts('BOB'), [bob]);
    });

    test('matches the Matrix ID, the email and the phone', () {
      expect(contacts.searchContacts('@elise:server'), [elise]);
      expect(contacts.searchContacts('elise@company'), [elise]);
      expect(contacts.searchContacts('611111'), [elise]);
    });

    test('trims the keyword', () {
      expect(contacts.searchContacts('  bob  '), [bob]);
    });

    test('returns nothing when no field matches', () {
      expect(contacts.searchContacts('zzz'), isEmpty);
    });

    test('a contact without a name is still found by its Matrix ID', () {
      const anonymous = UnifiedContact(matrixId: '@anon:server');

      expect([anonymous].searchContacts('anon'), [anonymous]);
    });
  });
}
