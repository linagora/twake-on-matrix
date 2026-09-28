import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';
import 'package:twake_chat/domain/contact/policy/contact_resolution_policy.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/usecases/sync_contacts.dart';

import '../fakes/fake_unified_contact_repository.dart';

class _FakeSource implements ContactSource {
  _FakeSource(this.kind, this._contacts, {this.throws = false});

  @override
  final ContactSourceKind kind;

  final List<SourcedContact> _contacts;
  final bool throws;

  @override
  Future<List<SourcedContact>> fetch() async {
    if (throws) throw Exception('source unavailable');
    return _contacts;
  }
}

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;

  setUp(() => repository = FakeUnifiedContactRepository());
  tearDown(() => repository.dispose());

  test(
    'merges sources by matrixId and persists the resolved contacts',
    () async {
      const matrixId = '@jean:server';
      final useCase = SyncContactsUseCase(
        repository: repository,
        policy: const ContactResolutionPolicy(),
        sources: [
          _FakeSource(ContactSourceKind.tomAddressBook, const [
            SourcedContact(
              matrixId: matrixId,
              value: ContactSourceValue(
                kind: ContactSourceKind.tomAddressBook,
                displayName: 'Jean Dupont',
                emails: ['jean@company.com'],
              ),
            ),
          ]),
          _FakeSource(ContactSourceKind.phonebook, const [
            SourcedContact(
              matrixId: matrixId,
              value: ContactSourceValue(
                kind: ContactSourceKind.phonebook,
                displayName: 'Jean Travail',
                phones: ['+33123456789'],
              ),
            ),
          ]),
        ],
      );

      final contacts = await useCase.execute(userId);

      expect(contacts, hasLength(1));
      expect(contacts.single.canonicalDisplayName, 'Jean Dupont');
      expect(contacts.single.resolvedDisplayName, 'Jean Travail');
      expect(contacts.single.emails, ['jean@company.com']);
      expect(contacts.single.phones, ['+33123456789']);

      expect(repository.store[matrixId], contacts.single);
    },
  );

  test(
    'a failing source does not prevent the others from being merged',
    () async {
      final useCase = SyncContactsUseCase(
        repository: repository,
        policy: const ContactResolutionPolicy(),
        sources: [
          _FakeSource(ContactSourceKind.tomAddressBook, const [], throws: true),
          _FakeSource(ContactSourceKind.matrixProfile, const [
            SourcedContact(
              matrixId: '@a:server',
              value: ContactSourceValue(
                kind: ContactSourceKind.matrixProfile,
                displayName: 'A',
              ),
            ),
          ]),
        ],
      );

      final contacts = await useCase.execute(userId);

      expect(contacts, hasLength(1));
      expect(contacts.single.matrixId, '@a:server');
    },
  );

  test('empty sources do not write to the repository', () async {
    final useCase = SyncContactsUseCase(
      repository: repository,
      policy: const ContactResolutionPolicy(),
      sources: [_FakeSource(ContactSourceKind.tomAddressBook, const [])],
    );

    await useCase.execute(userId);

    expect(repository.store, isEmpty);
  });

  test('drops stored values from a source that succeeded but no longer returns '
      'the contact', () async {
    const matrixId = '@jean:server';
    await repository.upsert(
      userId,
      const UnifiedContact(
        matrixId: matrixId,
        canonicalDisplayName: 'Jean Dupont',
        localAlias: 'Jean Travail',
        sources: [
          ContactSourceValue(
            kind: ContactSourceKind.tomAddressBook,
            displayName: 'Jean Dupont',
          ),
          ContactSourceValue(
            kind: ContactSourceKind.phonebook,
            displayName: 'Jean Travail',
          ),
        ],
      ),
    );

    final useCase = SyncContactsUseCase(
      repository: repository,
      policy: const ContactResolutionPolicy(),
      sources: [
        _FakeSource(ContactSourceKind.tomAddressBook, const [
          SourcedContact(
            matrixId: matrixId,
            value: ContactSourceValue(
              kind: ContactSourceKind.tomAddressBook,
              displayName: 'Jean Dupont',
            ),
          ),
        ]),
        _FakeSource(ContactSourceKind.phonebook, const []),
      ],
    );

    final contacts = await useCase.execute(userId);

    expect(contacts, hasLength(1));
    expect(contacts.single.localAlias, isNull);
    expect(contacts.single.resolvedDisplayName, 'Jean Dupont');
    expect(repository.store[matrixId]!.sources.map((value) => value.kind), [
      ContactSourceKind.tomAddressBook,
    ]);
  });

  test(
    'deletes a stored contact that no successful source returns anymore',
    () async {
      const matrixId = '@jean:server';
      await repository.upsert(
        userId,
        const UnifiedContact(
          matrixId: matrixId,
          canonicalDisplayName: 'Jean Dupont',
          sources: [
            ContactSourceValue(
              kind: ContactSourceKind.tomAddressBook,
              displayName: 'Jean Dupont',
            ),
          ],
        ),
      );

      final useCase = SyncContactsUseCase(
        repository: repository,
        policy: const ContactResolutionPolicy(),
        sources: [_FakeSource(ContactSourceKind.tomAddressBook, const [])],
      );

      final contacts = await useCase.execute(userId);

      expect(contacts, isEmpty);
      expect(repository.store, isEmpty);
    },
  );

  test('keeps the last known values of a source that failed', () async {
    const matrixId = '@jean:server';
    await repository.upsert(
      userId,
      const UnifiedContact(
        matrixId: matrixId,
        canonicalDisplayName: 'Jean Dupont',
        localAlias: 'Jean Travail',
        sources: [
          ContactSourceValue(
            kind: ContactSourceKind.tomAddressBook,
            displayName: 'Jean Dupont',
          ),
          ContactSourceValue(
            kind: ContactSourceKind.phonebook,
            displayName: 'Jean Travail',
          ),
        ],
      ),
    );

    final useCase = SyncContactsUseCase(
      repository: repository,
      policy: const ContactResolutionPolicy(),
      sources: [
        _FakeSource(ContactSourceKind.tomAddressBook, const [
          SourcedContact(
            matrixId: matrixId,
            value: ContactSourceValue(
              kind: ContactSourceKind.tomAddressBook,
              displayName: 'Jean Dupont',
            ),
          ),
        ]),
        _FakeSource(ContactSourceKind.phonebook, const [], throws: true),
      ],
    );

    final contacts = await useCase.execute(userId);

    expect(contacts.single.localAlias, 'Jean Travail');
    expect(repository.store[matrixId]!.localAlias, 'Jean Travail');
  });

  test('preserves a manual-only contact that no source returns', () async {
    const matrixId = '@manual:server';
    await repository.upsert(
      userId,
      const UnifiedContact(
        matrixId: matrixId,
        canonicalDisplayName: 'Manual Entry',
        sources: [
          ContactSourceValue(
            kind: ContactSourceKind.manual,
            displayName: 'Manual Entry',
          ),
        ],
      ),
    );

    final useCase = SyncContactsUseCase(
      repository: repository,
      policy: const ContactResolutionPolicy(),
      sources: [_FakeSource(ContactSourceKind.tomAddressBook, const [])],
    );

    final contacts = await useCase.execute(userId);

    expect(contacts, hasLength(1));
    expect(contacts.single.matrixId, matrixId);
    expect(repository.store.containsKey(matrixId), isTrue);
  });
}
