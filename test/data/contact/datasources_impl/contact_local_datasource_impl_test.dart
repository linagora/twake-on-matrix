import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/contact/datasources_impl/contact_local_datasource_impl.dart';
import 'package:twake_chat/data/hive/hive_collection_tom_database.dart';
import 'package:twake_chat/domain/contact/entities/unified_contact.dart';

void main() {
  late Directory tempDir;
  late HiveCollectionToMDatabase database;
  late ContactLocalDataSourceImpl dataSource;

  const owner = '@me:server';
  const otherOwner = '@other:server';

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('unified_contact_test');
    database = HiveCollectionToMDatabase(
      'unit_test_unified_contact',
      tempDir.path,
    );
    await database.open();
    dataSource = ContactLocalDataSourceImpl(database: database);
  });

  tearDownAll(() async {
    dataSource.dispose();
    await tempDir.delete(recursive: true);
  });

  tearDown(() async {
    await database.unifiedContactsBox.clear();
  });

  test(
    'entries of different accounts are isolated even with the same matrixId',
    () async {
      await dataSource.upsert(
        owner,
        const UnifiedContact(
          matrixId: '@jean:server',
          canonicalDisplayName: 'Mine',
        ),
      );
      await dataSource.upsert(
        otherOwner,
        const UnifiedContact(
          matrixId: '@jean:server',
          canonicalDisplayName: 'Theirs',
        ),
      );

      final mine = await dataSource.getAll(owner);
      final theirs = await dataSource.getAll(otherOwner);

      expect(mine, hasLength(1));
      expect(mine.single.canonicalDisplayName, 'Mine');
      expect(theirs, hasLength(1));
      expect(theirs.single.canonicalDisplayName, 'Theirs');

      expect(
        (await dataSource.getByMatrixId(
          owner,
          '@jean:server',
        ))!.canonicalDisplayName,
        'Mine',
      );
      expect(
        (await dataSource.getByMatrixId(
          otherOwner,
          '@jean:server',
        ))!.canonicalDisplayName,
        'Theirs',
      );
    },
  );

  test('clear only wipes the given account', () async {
    await dataSource.upsert(owner, const UnifiedContact(matrixId: '@a:server'));
    await dataSource.upsert(
      otherOwner,
      const UnifiedContact(matrixId: '@b:server'),
    );

    await dataSource.clear(owner);

    expect(await dataSource.getAll(owner), isEmpty);
    expect(await dataSource.getAll(otherOwner), hasLength(1));
  });

  test('delete only removes the targeted account entry', () async {
    await dataSource.upsert(owner, const UnifiedContact(matrixId: '@a:server'));
    await dataSource.upsert(
      otherOwner,
      const UnifiedContact(matrixId: '@a:server'),
    );

    await dataSource.delete(owner, '@a:server');

    expect(await dataSource.getByMatrixId(owner, '@a:server'), isNull);
    expect(await dataSource.getByMatrixId(otherOwner, '@a:server'), isNotNull);
  });

  test('watch only emits updates of the watched account', () async {
    final iterator = StreamIterator(dataSource.watch(owner));

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current, isEmpty);

    await dataSource.upsert(
      otherOwner,
      const UnifiedContact(matrixId: '@other-contact:server'),
    );
    await dataSource.upsert(owner, const UnifiedContact(matrixId: '@a:server'));

    expect(await iterator.moveNext(), isTrue);
    expect(iterator.current.map((c) => c.matrixId), ['@a:server']);

    await iterator.cancel();
  });
}
