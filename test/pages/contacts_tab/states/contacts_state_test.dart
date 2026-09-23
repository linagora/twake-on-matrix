import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/pages/contacts_tab/states/contacts_state.dart';

void main() {
  const alice = UnifiedContact(
    matrixId: '@alice:server',
    canonicalDisplayName: 'Alice Martin',
    emails: ['alice@company.com'],
    phones: ['+33111111111'],
  );
  const bob = UnifiedContact(
    matrixId: '@bob:server',
    canonicalDisplayName: 'Bob',
  );

  ContactsState stateWith(String keyword) => ContactsState(
    contacts: const AsyncData<List<UnifiedContact>>([alice, bob]),
    keyword: keyword,
  );

  test('an empty keyword returns every contact', () {
    expect(stateWith('').visibleContacts, [alice, bob]);
    expect(stateWith('').isSearching, isFalse);
  });

  test('filters by display name, case-insensitively', () {
    expect(stateWith('alice').visibleContacts, [alice]);
    expect(stateWith('BOB').visibleContacts, [bob]);
  });

  test('filters by matrixId, email and phone', () {
    expect(stateWith('alice:server').visibleContacts, [alice]);
    expect(stateWith('alice@company').visibleContacts, [alice]);
    expect(stateWith('1111').visibleContacts, [alice]);
  });

  test('isSearching reflects a non-blank keyword', () {
    expect(stateWith('   ').isSearching, isFalse);
    expect(stateWith(' a ').isSearching, isTrue);
  });

  test('loading state exposes no contacts', () {
    const state = ContactsState();
    expect(state.visibleContacts, isEmpty);
  });
}
