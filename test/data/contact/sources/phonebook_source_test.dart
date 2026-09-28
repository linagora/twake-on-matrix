import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/sources/phonebook_source.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/model/contact/contact.dart';
import 'package:twake_chat/domain/repository/contact/hive_contact_repository.dart';

class _FakeHiveContactRepository implements HiveContactRepository {
  _FakeHiveContactRepository(this._byUser);

  final Map<String, List<Contact>> _byUser;
  String? lastUserId;

  @override
  Future<List<Contact>> getThirdPartyContactByUserId(String userId) async {
    lastUserId = userId;
    return _byUser[userId] ?? const <Contact>[];
  }

  @override
  Future<void> saveThirdPartyContactsForUser(
    String userId,
    List<Contact> contacts,
  ) async {}

  @override
  Future<void> deleteThirdPartyContactBox() async {}
}

void main() {
  const userId = '@me:server';

  PhonebookSource sourceWith(List<Contact> contacts) =>
      PhonebookSource(_FakeHiveContactRepository({userId: contacts}));

  test('maps resolved phonebook contacts to sourced values', () async {
    final source = sourceWith([
      Contact(
        id: 'contact-1',
        displayName: 'Jean Travail',
        phoneNumbers: {
          PhoneNumber(number: '+33123456789', matrixId: '@jean:server'),
        },
        emails: {Email(address: 'jean@company.com', matrixId: '@jean:server')},
      ),
    ]);

    final sourced = await source.fetch(userId);

    expect(sourced, hasLength(1));
    expect(sourced.single.matrixId, '@jean:server');
    expect(sourced.single.value.kind, ContactSourceKind.phonebook);
    expect(sourced.single.value.displayName, 'Jean Travail');
    expect(sourced.single.value.phones, ['+33123456789']);
    expect(sourced.single.value.emails, ['jean@company.com']);
  });

  test('drops contacts whose third-party ids carry no Matrix ID', () async {
    final source = sourceWith([
      Contact(
        id: 'contact-2',
        displayName: 'Unresolved',
        phoneNumbers: {PhoneNumber(number: '+33999999999')},
      ),
    ]);

    expect(await source.fetch(userId), isEmpty);
  });

  test('reads the contacts of the synced account', () async {
    final repository = _FakeHiveContactRepository({
      userId: const <Contact>[],
      '@other:server': [
        Contact(
          id: 'contact-3',
          displayName: 'Other',
          phoneNumbers: {
            PhoneNumber(number: '+33000000000', matrixId: '@other:server'),
          },
        ),
      ],
    });

    final sourced = await PhonebookSource(repository).fetch(userId);

    expect(repository.lastUserId, userId);
    expect(sourced, isEmpty);
  });
}
