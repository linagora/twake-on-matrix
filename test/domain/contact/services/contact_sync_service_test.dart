import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_kind.dart';
import 'package:twake_chat/domain/contact/entities/contact_source_value.dart';
import 'package:twake_chat/domain/contact/services/contact_sync_service.dart';
import 'package:twake_chat/domain/contact/sources/contact_enricher.dart';
import 'package:twake_chat/domain/contact/sources/contact_source.dart';
import 'package:twake_chat/domain/contact/sources/phonebook_resolver.dart';

import '../fakes/build_contact_sync_service.dart';
import '../fakes/fake_unified_contact_repository.dart';

class _FakeSource implements ContactSource {
  _FakeSource(this.kind, this.contacts);

  @override
  final ContactSourceKind kind;
  final List<SourcedContact> contacts;

  @override
  Future<List<SourcedContact>> fetch(String userId) async => contacts;
}

class _FakeEnricher implements ContactEnricher {
  _FakeEnricher({this.throws = false});

  final bool throws;
  final List<String> enrichedUserIds = <String>[];

  @override
  Future<void> enrich(String userId) async {
    if (throws) throw Exception('enricher down');
    enrichedUserIds.add(userId);
  }
}

class _FakePhonebookResolver implements PhonebookResolver {
  _FakePhonebookResolver(this.events, {this.throws = false});

  final List<String> events;
  final bool throws;

  @override
  Future<void> resolve(String userId) async {
    events.add('resolve:$userId');
    if (throws) throw Exception('lookup down');
  }

  @override
  Future<void> cancel() async {}
}

/// Records when it is fetched, to assert the phonebook is resolved first.
class _RecordingSource implements ContactSource {
  _RecordingSource(this.events);

  final List<String> events;

  @override
  ContactSourceKind get kind => ContactSourceKind.phonebook;

  @override
  Future<List<SourcedContact>> fetch(String userId) async {
    events.add('fetch');
    return const [];
  }
}

/// A source that answers only once the test opens its gate.
class _GatedSource implements ContactSource {
  _GatedSource(this.contacts);

  final List<SourcedContact> contacts;
  final Completer<void> gate = Completer<void>();
  int fetchCount = 0;

  @override
  ContactSourceKind get kind => ContactSourceKind.tomAddressBook;

  @override
  Future<List<SourcedContact>> fetch(String userId) async {
    fetchCount++;
    await gate.future;
    return contacts;
  }
}

void main() {
  const userId = '@me:server';
  late FakeUnifiedContactRepository repository;
  late ContactSyncService service;

  ContactSyncService buildService(
    List<ContactSource> sources, {
    PhonebookResolver? phonebookResolver,
    List<ContactEnricher> enrichers = const [],
    bool Function()? isAccountActive,
  }) => buildContactSyncService(
    userId: userId,
    repository: repository,
    sources: sources,
    options: ContactSyncOptions(
      enrichers: enrichers,
      phonebookResolver: phonebookResolver,
      isAccountActive: isAccountActive,
    ),
  );

  setUp(() {
    repository = FakeUnifiedContactRepository();
    service = buildService(const []);
  });

  tearDown(() => repository.dispose());

  test('refresh merges the sources into the store', () async {
    service = buildService([
      _FakeSource(ContactSourceKind.tomAddressBook, const [
        SourcedContact(
          matrixId: '@a:server',
          value: ContactSourceValue(
            kind: ContactSourceKind.tomAddressBook,
            displayName: 'Alice',
          ),
        ),
      ]),
    ]);

    await service.refresh();

    expect(
      (await service.getContact('@a:server'))?.resolvedDisplayName,
      'Alice',
    );
  });

  test('addContact persists a manual contact', () async {
    await service.addContact(
      matrixId: '@b:server',
      displayName: 'Bob',
      emails: ['bob@server.com'],
    );

    final contact = await service.getContact('@b:server');
    expect(contact, isNotNull);
    expect(contact!.resolvedDisplayName, 'Bob');
    expect(contact.emails, ['bob@server.com']);
  });

  test('watchContacts emits the store content', () async {
    await service.addContact(matrixId: '@d:server', displayName: 'Dave');

    final iterator = StreamIterator(service.watchContacts());
    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.single.matrixId, '@d:server');
    await iterator.cancel();
  });

  test(
    'a throwing enricher does not abort the refresh nor the other enrichers',
    () async {
      final failing = _FakeEnricher(throws: true);
      final healthy = _FakeEnricher();
      service = buildService(
        [
          _FakeSource(ContactSourceKind.tomAddressBook, const [
            SourcedContact(
              matrixId: '@a:server',
              value: ContactSourceValue(
                kind: ContactSourceKind.tomAddressBook,
                displayName: 'Alice',
              ),
            ),
          ]),
        ],
        enrichers: [failing, healthy],
      );

      await service.refresh();

      expect(healthy.enrichedUserIds, [userId]);
      expect(
        (await service.getContact('@a:server'))?.resolvedDisplayName,
        'Alice',
      );
    },
  );

  test('clear empties the store', () async {
    await service.addContact(matrixId: '@e:server', displayName: 'Eve');

    await service.clear();

    expect(await repository.getContacts(userId), isEmpty);
  });

  group('phonebook resolution', () {
    test('is skipped unless the caller asks for it', () async {
      final events = <String>[];
      service = buildService([
        _RecordingSource(events),
      ], phonebookResolver: _FakePhonebookResolver(events));

      await service.refresh();

      expect(events, ['fetch']);
    });

    test('runs before the sources are fetched when asked', () async {
      final events = <String>[];
      service = buildService([
        _RecordingSource(events),
      ], phonebookResolver: _FakePhonebookResolver(events));

      await service.refresh(resolvePhonebook: true);

      expect(events, ['resolve:$userId', 'fetch']);
    });

    test('a failing resolution does not abort the refresh', () async {
      final events = <String>[];
      service = buildService([
        _RecordingSource(events),
      ], phonebookResolver: _FakePhonebookResolver(events, throws: true));

      await service.refresh(resolvePhonebook: true);

      expect(events, ['resolve:$userId', 'fetch']);
    });

    test('is a no-op when no resolver is wired', () async {
      final events = <String>[];
      service = buildService([_RecordingSource(events)]);

      await service.refresh(resolvePhonebook: true);

      expect(events, ['fetch']);
    });
  });

  group('refresh concurrency', () {
    const alice = SourcedContact(
      matrixId: '@a:server',
      value: ContactSourceValue(
        kind: ContactSourceKind.tomAddressBook,
        displayName: 'Alice',
      ),
    );

    test('concurrent refreshes share a single run', () async {
      final source = _GatedSource(const [alice]);
      service = buildService([source]);

      final first = service.refresh();
      final second = service.refresh();
      source.gate.complete();
      await Future.wait([first, second]);

      expect(source.fetchCount, 1);
      expect(repository.store.keys, ['@a:server']);
    });

    test(
      'a phonebook refresh asked during a plain one runs after it',
      () async {
        final events = <String>[];
        final source = _GatedSource(const [alice]);
        service = buildService([
          source,
        ], phonebookResolver: _FakePhonebookResolver(events));

        final plain = service.refresh();
        final withPhonebook = service.refresh(resolvePhonebook: true);
        source.gate.complete();
        await Future.wait([plain, withPhonebook]);

        expect(events, ['resolve:$userId']);
        expect(source.fetchCount, 2);
      },
    );

    test('clear wins over the refresh it interrupts', () async {
      final source = _GatedSource(const [alice]);
      service = buildService([source]);

      final refresh = service.refresh();
      await pumpEventQueue();
      final clear = service.clear();
      source.gate.complete();
      await Future.wait([refresh, clear]);

      expect(repository.store, isEmpty);
    });

    test('a refresh asked after clear starts from the empty store', () async {
      final source = _GatedSource(const [alice]);
      source.gate.complete();
      service = buildService([source]);

      await service.clear();
      await service.refresh();

      expect(repository.store.keys, ['@a:server']);
    });

    test('a refresh outliving its account writes nothing', () async {
      var active = true;
      final source = _GatedSource(const [alice]);
      service = buildService([source], isAccountActive: () => active);

      final refresh = service.refresh();
      await pumpEventQueue();
      active = false;
      source.gate.complete();
      await refresh;

      expect(repository.store, isEmpty);
    });

    test('a refresh of an inactive account does not even fetch', () async {
      final source = _GatedSource(const [alice]);
      service = buildService([source], isAccountActive: () => false);

      await service.refresh();

      expect(source.fetchCount, 0);
    });

    test('skips the enrichers once the account is no longer active', () async {
      var active = true;
      final source = _GatedSource(const [alice]);
      final enricher = _FakeEnricher();
      service = buildService(
        [source],
        enrichers: [enricher],
        isAccountActive: () => active,
      );

      final refresh = service.refresh();
      await pumpEventQueue();
      active = false;
      source.gate.complete();
      await refresh;

      expect(enricher.enrichedUserIds, isEmpty);
    });

    test('a manual add waits for the refresh in progress', () async {
      final source = _GatedSource(const [alice]);
      service = buildService([source]);

      final refresh = service.refresh();
      await pumpEventQueue();
      final add = service.addContact(matrixId: '@m:server', displayName: 'Max');
      await pumpEventQueue();

      expect(repository.store, isEmpty);

      source.gate.complete();
      await Future.wait([refresh, add]);

      expect(repository.store.keys, containsAll(['@a:server', '@m:server']));
    });

    test('a failing write does not block the next ones', () async {
      repository.failNextClear = true;
      service = buildService(const []);

      await expectLater(service.clear(), throwsA(isA<StateError>()));
      await service.addContact(matrixId: '@m:server', displayName: 'Max');

      expect(repository.store.keys, ['@m:server']);
    });
  });
}
