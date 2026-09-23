import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:twake_chat/data/contact/datasources_impl/contact_local_datasource_impl.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

class _ReadBarrier {
  final captured = Completer<void>();
  final release = Completer<void>();
}

// Keep the real Hive read and stream; control only when one read returns.
class _DelayedReadDataSource extends ContactLocalDataSourceImpl {
  _DelayedReadDataSource({required super.database});

  _ReadBarrier? nextRead;

  @override
  Future<List<UnifiedContact>> getAll() async {
    final barrier = nextRead;
    nextRead = null;
    final contacts = await super.getAll();
    if (barrier != null) {
      barrier.captured.complete();
      await barrier.release.future;
    }
    return contacts;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late _DelayedReadDataSource local;

  const alice = UnifiedContact(matrixId: '@alice:server');
  const bob = UnifiedContact(matrixId: '@bob:server');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('contact_local_test_');
    Hive.init(directory.path);
    final database = HiveCollectionToMDatabase('contacts_test', directory.path);
    await database.open();
    local = _DelayedReadDataSource(database: database);
  });

  tearDown(() async {
    local.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('listeners of the same stream cancel independently', () async {
    await local.upsert(alice);
    final stream = local.watch();
    final firstEvents = <List<UnifiedContact>>[];
    final secondEvents = <List<UnifiedContact>>[];
    final firstReady = Completer<void>();
    final secondReady = Completer<void>();
    final first = stream.listen((contacts) {
      firstEvents.add(contacts);
      if (!firstReady.isCompleted) firstReady.complete();
    });
    final second = stream.listen((contacts) {
      secondEvents.add(contacts);
      if (!secondReady.isCompleted) secondReady.complete();
    });
    addTearDown(first.cancel);
    addTearDown(second.cancel);
    await Future.wait([firstReady.future, secondReady.future]);

    await first.cancel();
    await local.upsert(bob);
    await Future<void>.delayed(Duration.zero);

    expect(firstEvents, [
      [alice],
    ]);
    expect(secondEvents, hasLength(2));
    expect(secondEvents.first, [alice]);
    expect(secondEvents.last, unorderedEquals([alice, bob]));
  });

  test('a delayed initial snapshot cannot replace a newer write', () async {
    await local.upsert(alice);
    final barrier = _ReadBarrier();
    local.nextRead = barrier;
    final events = <List<UnifiedContact>>[];
    final subscription = local.watch().listen(events.add);
    addTearDown(subscription.cancel);
    await barrier.captured.future;

    await local.upsert(bob);
    await Future<void>.delayed(Duration.zero);
    expect(events, hasLength(1));
    expect(events.single, unorderedEquals([alice, bob]));

    barrier.release.complete();
    await Future<void>.delayed(Duration.zero);

    expect(events, hasLength(1));
    expect(events.single, unorderedEquals([alice, bob]));
  });

  test(
    'dispose during an emission closes listeners without late data',
    () async {
      final events = <List<UnifiedContact>>[];
      final ready = Completer<void>();
      var done = false;
      final subscription = local.watch().listen((contacts) {
        events.add(contacts);
        if (!ready.isCompleted) ready.complete();
      }, onDone: () => done = true);
      addTearDown(subscription.cancel);
      await ready.future;
      final barrier = _ReadBarrier();
      local.nextRead = barrier;
      final write = local.upsert(alice);
      await barrier.captured.future;

      local.dispose();
      barrier.release.complete();
      await write;
      await Future<void>.delayed(Duration.zero);

      expect(done, isTrue);
      expect(events, [<UnifiedContact>[]]);
      expect(await local.getByMatrixId(alice.matrixId), alice);
    },
  );
}
