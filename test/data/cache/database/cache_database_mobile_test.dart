// test/data/cache/database/cache_database_mobile_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/data/cache/database/cache_database_interface.dart';
import 'package:fluffychat/data/cache/database/cache_database_mobile.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CacheDatabaseMobile', () {
    late CacheDatabaseMobile database;
    late String dbPath;

    setUp(() {
      // Create unique database path for each test to avoid conflicts
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      dbPath = '${Directory.systemTemp.path}/mxc_cache_test_$timestamp.db';
      database = CacheDatabaseMobile(customDbPath: dbPath);
    });

    tearDown(() async {
      await database.close();

      // Delete test database file
      try {
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
        }
      } catch (_) {
        // Ignore cleanup errors
      }
    });

    test('storage type is sqfliteFfi', () async {
      expect(database.storageType, CacheStorageType.sqfliteFfi);
    });

    test('is persistent', () {
      expect(database.isPersistent, true);
    });

    test('initializes successfully', () async {
      await database.init();
      final db = await database.database;
      expect(db, isNotNull);
    });

    test('multiple init calls are idempotent', () async {
      await database.init();
      await database.init();
      final db = await database.database;
      expect(db, isNotNull);
    });

    test('database getter initializes if not initialized', () async {
      final db = await database.database;
      expect(db, isNotNull);
      expect(database.storageType, CacheStorageType.sqfliteFfi);
    });

    test('close cleans up database instance', () async {
      await database.init();
      await database.close();
      // After close, should be able to init again
      await database.init();
      expect(database.storageType, CacheStorageType.sqfliteFfi);
    });
  });
}
