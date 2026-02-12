// test/data/cache/database/cache_database_web_test.dart
@TestOn('browser')
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/cache/database/cache_database_interface.dart';
import 'package:fluffychat/data/cache/database/cache_database_web.dart';

void main() {
  group('CacheDatabaseWeb', () {
    late CacheDatabaseWeb database;

    setUp(() {
      database = CacheDatabaseWeb();
    });

    tearDown(() async {
      await database.close();
    });

    test('initializes successfully', () async {
      await database.init();
      expect(database.storageType, isNotNull);
      expect(database.isPersistent, anyOf(isTrue, isFalse));
    });

    test('database getter returns valid database', () async {
      await database.init();
      final db = await database.database;
      expect(db, isNotNull);
    });

    test('storage type is one of supported types', () async {
      await database.init();
      expect(
        database.storageType,
        anyOf(
          CacheStorageType.sqfliteWasm,
          CacheStorageType.indexedDb,
          CacheStorageType.memoryOnly,
        ),
      );
    });

    test('memory-only storage is not persistent', () async {
      await database.init();
      if (database.storageType == CacheStorageType.memoryOnly) {
        expect(database.isPersistent, false);
      }
    });

    test('wasm and IndexedDB storage are persistent', () async {
      await database.init();
      if (database.storageType == CacheStorageType.sqfliteWasm ||
          database.storageType == CacheStorageType.indexedDb) {
        expect(database.isPersistent, true);
      }
    });

    test('multiple init calls are idempotent', () async {
      await database.init();
      final firstStorageType = database.storageType;

      await database.init();
      expect(database.storageType, equals(firstStorageType));
    });

    test('close cleans up database instance', () async {
      await database.init();
      await database.close();
      // After close, should be able to init again
      await database.init();
      expect(database.storageType, isNotNull);
    });
  });
}
