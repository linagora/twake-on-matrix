import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
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
  late FakeUnifiedContactRepository repository;
  const policy = ContactResolutionPolicy();

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

      final contacts = await useCase.execute();

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

      final contacts = await useCase.execute();

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

    await useCase.execute();

    expect(repository.store, isEmpty);
  });

  test('preserves persisted contributions from a failing source', () async {
    const previous = ContactSourceValue(
      kind: ContactSourceKind.tomAddressBook,
      displayName: 'Directory name',
      emails: ['directory@company.com'],
    );
    await repository.upsertAll([
      policy.resolve(matrixId: '@a:server', values: [previous]),
      policy.resolve(matrixId: '@b:server', values: [previous]),
    ]);
    final useCase = SyncContactsUseCase(
      repository: repository,
      policy: policy,
      sources: [
        _FakeSource(ContactSourceKind.tomAddressBook, const [], throws: true),
        _FakeSource(ContactSourceKind.phonebook, const [
          SourcedContact(
            matrixId: '@a:server',
            value: ContactSourceValue(
              kind: ContactSourceKind.phonebook,
              displayName: 'Local alias',
              phones: ['+33123456789'],
            ),
          ),
        ]),
      ],
    );

    final contacts = await useCase.execute();

    expect(contacts, hasLength(2));
    final updated = repository.store['@a:server']!;
    expect(updated.canonicalDisplayName, 'Directory name');
    expect(updated.resolvedDisplayName, 'Local alias');
    expect(updated.emails, ['directory@company.com']);
    expect(updated.phones, ['+33123456789']);
    expect(updated.sources, contains(previous));
    expect(repository.store['@b:server']!.sources, [previous]);
  });

  test(
    'replaces a source snapshot and preserves uncollected sources',
    () async {
      const manual = ContactSourceValue(
        kind: ContactSourceKind.manual,
        emails: ['manual@company.com'],
      );
      const tom = ContactSourceValue(
        kind: ContactSourceKind.tomUserInfo,
        displayName: 'Canonical name',
        avatarUrl: 'mxc://server/avatar',
      );
      await repository.upsert(
        policy.resolve(
          matrixId: '@a:server',
          values: const [
            manual,
            tom,
            ContactSourceValue(
              kind: ContactSourceKind.phonebook,
              displayName: 'Old alias',
              phones: ['+33111111111'],
              emails: ['old@company.com'],
              active: true,
            ),
          ],
        ),
      );
      const replacement = ContactSourceValue(
        kind: ContactSourceKind.phonebook,
        displayName: 'New alias',
        phones: ['+33222222222'],
      );
      final useCase = SyncContactsUseCase(
        repository: repository,
        policy: policy,
        sources: [
          _FakeSource(ContactSourceKind.phonebook, const [
            SourcedContact(matrixId: '@a:server', value: replacement),
          ]),
        ],
      );

      final first = await useCase.execute();
      final second = await useCase.execute();

      expect(second, first);
      expect(repository.store.values.toList(), first);
      final updated = second.single;
      expect(updated.sources, [manual, tom, replacement]);
      expect(updated.canonicalDisplayName, 'Canonical name');
      expect(updated.avatarUrl, 'mxc://server/avatar');
      expect(updated.resolvedDisplayName, 'New alias');
      expect(updated.phones, ['+33222222222']);
      expect(updated.emails, ['manual@company.com']);
      expect(updated.active, isFalse);
    },
  );

  for (final fails in [false, true]) {
    test(
      'empty snapshot removes old contributions only on success: $fails',
      () async {
        const phonebook = ContactSourceValue(
          kind: ContactSourceKind.phonebook,
          displayName: 'Local alias',
          phones: ['+33123456789'],
        );
        const manual = ContactSourceValue(
          kind: ContactSourceKind.manual,
          displayName: 'Manual name',
        );
        await repository.upsertAll([
          policy.resolve(matrixId: '@a:server', values: [phonebook]),
          policy.resolve(matrixId: '@b:server', values: [manual, phonebook]),
        ]);
        final useCase = SyncContactsUseCase(
          repository: repository,
          policy: policy,
          sources: [
            _FakeSource(ContactSourceKind.phonebook, const [], throws: fails),
          ],
        );

        final contacts = await useCase.execute();

        expect(contacts, hasLength(fails ? 2 : 1));
        expect(repository.store.containsKey('@a:server'), fails);
        final retained = repository.store['@b:server']!;
        expect(retained.sources, fails ? [manual, phonebook] : [manual]);
        expect(retained.phones, fails ? ['+33123456789'] : isEmpty);
        expect(
          retained.resolvedDisplayName,
          fails ? 'Local alias' : 'Manual name',
        );
      },
    );
  }

  test('no collected source keeps the existing contacts', () async {
    final previous = policy.resolve(
      matrixId: '@a:server',
      values: const [
        ContactSourceValue(kind: ContactSourceKind.manual, displayName: 'A'),
      ],
    );
    await repository.upsert(previous);
    final useCase = SyncContactsUseCase(
      repository: repository,
      policy: policy,
      sources: const [],
    );

    expect(await useCase.execute(), [previous]);
    expect(repository.store.values.toList(), [previous]);
  });
}
