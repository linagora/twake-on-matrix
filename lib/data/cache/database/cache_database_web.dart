// lib/data/cache/database/cache_database_web.dart
import 'package:idb_shim/idb_browser.dart';
import 'package:matrix/matrix.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'cache_database_interface.dart';
import 'cache_schema.dart';

/// Web cache database implementation with cascading fallback
///
/// Tries in order:
/// 1. sqflite_common_ffi_web (wasm SQLite, best performance & persistence)
/// 2. IndexedDB (native browser storage, no wasm dependency)
/// 3. Memory-only (guaranteed to work, no persistence)
///
/// Note: IndexedDB uses separate tier implementation (DiskCacheTierIndexedDb)
/// with native IndexedDB API instead of SQL.
/// Create web cache database implementation
CacheDatabaseInterface createCacheDatabaseWebImpl() => CacheDatabaseWeb();

class CacheDatabaseWeb implements CacheDatabaseInterface {
  static const String _dbName = 'mxc_cache.db';
  static const int _dbVersion = 1;

  ffi.Database? _database;
  CacheStorageType _activeStorageType = CacheStorageType.sqfliteWasm;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;

    // Cascading fallback: wasm -> IndexedDB -> memory-only
    if (await _tryWasmSqlite()) return;
    if (await _tryIndexedDb()) return;
    await _useMemoryOnly();
  }

  /// Try sqflite_common_ffi_web (wasm SQLite)
  Future<bool> _tryWasmSqlite() async {
    try {
      ffi.databaseFactory = databaseFactoryFfiWeb;
      await _initDatabase();
      _activeStorageType = CacheStorageType.sqfliteWasm;
      _initialized = true;
      Logs().i('Cache database initialized with wasm SQLite');
      return true;
    } catch (e, s) {
      Logs().w('Web SQLite wasm initialization failed: $e', s);
      return false;
    }
  }

  /// Try IndexedDB (native browser storage)
  ///
  /// Validates IndexedDB availability by attempting to open a test database
  /// This ensures IndexedDB works before committing to use it
  Future<bool> _tryIndexedDb() async {
    try {
      // Attempt to open a test database to validate IndexedDB
      final testDb = await idbFactoryBrowser.open(
        'mxc_cache_test',
        version: 1,
        onUpgradeNeeded: (VersionChangeEvent event) {
          // Create minimal test store
          if (!event.database.objectStoreNames.contains('test')) {
            event.database.createObjectStore('test');
          }
        },
      );

      // Verify we can perform basic operations
      final txn = testDb.transaction('test', idbModeReadWrite);
      await txn.objectStore('test').put('validated', 'status');
      await txn.completed;

      // Clean up test database
      testDb.close();
      await idbFactoryBrowser.deleteDatabase('mxc_cache_test');

      _activeStorageType = CacheStorageType.indexedDb;
      _initialized = true;
      Logs().i('Cache using IndexedDB storage (validated)');
      return true;
    } catch (e, s) {
      Logs().w('IndexedDB validation failed: $e', s);
      return false;
    }
  }

  /// Fallback to memory-only cache (no persistence)
  Future<void> _useMemoryOnly() async {
    try {
      // Use web-safe database factory with in-memory database
      ffi.databaseFactory = databaseFactoryFfiWeb;
      _database = await ffi.openDatabase(
        ffi.inMemoryDatabasePath,
        version: _dbVersion,
        onCreate: _onCreate,
      );
      _activeStorageType = CacheStorageType.memoryOnly;
      _initialized = true;
      Logs().w(
        'Using memory-only cache (no persistence). '
        'Images will be re-downloaded each session.',
      );
    } catch (e, s) {
      Logs().e('Failed to initialize memory-only cache: $e', e, s);
      rethrow;
    }
  }

  Future<void> _initDatabase() async {
    _database = await ffi.openDatabase(
      _dbName,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(ffi.Database db, int version) async {
    await CacheSchema.createTables(db);
  }

  Future<void> _onUpgrade(ffi.Database db, int oldV, int newV) async {
    // Future migrations here
  }

  @override
  Future<ffi.Database> get database async {
    if (!_initialized) {
      await init();
    }

    // IndexedDB mode doesn't use SQL database
    // This should not be called when using IndexedDB tier
    if (_activeStorageType == CacheStorageType.indexedDb) {
      throw UnsupportedError(
        'Database accessor not available for IndexedDB storage. '
        'Use DiskCacheTierIndexedDb instead.',
      );
    }

    return _database!;
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
    _initialized = false;
  }

  @override
  bool get isPersistent => _activeStorageType != CacheStorageType.memoryOnly;

  @override
  CacheStorageType get storageType => _activeStorageType;
}
