// lib/data/cache/database/cache_database_mobile.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'cache_database_interface.dart';
import 'cache_schema.dart';

/// Create mobile cache database implementation
CacheDatabaseInterface createCacheDatabaseMobileImpl() => CacheDatabaseMobile();

/// Mobile/Desktop cache database implementation using sqflite_common_ffi
///
/// Uses native SQLite with persistent storage in app documents directory
class CacheDatabaseMobile implements CacheDatabaseInterface {
  static const String _dbName = 'mxc_cache.db';
  static const int _dbVersion = 1;

  ffi.Database? _database;
  final String? _customDbPath;

  /// Creates a mobile database instance
  ///
  /// [customDbPath] is optional and only used for testing to isolate test databases
  CacheDatabaseMobile({String? customDbPath}) : _customDbPath = customDbPath;

  @override
  Future<void> init() async {
    if (_database != null) return;

    ffi.sqfliteFfiInit();
    ffi.databaseFactory = ffi.databaseFactoryFfi;

    final String dbPath;
    if (_customDbPath != null) {
      dbPath = _customDbPath;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = join(dir.path, _dbName);
    }

    _database = await ffi.openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  @override
  Future<ffi.Database> get database async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  Future<void> _onCreate(ffi.Database db, int version) async {
    await CacheSchema.createTables(db);
  }

  Future<void> _onUpgrade(ffi.Database db, int oldV, int newV) async {
    // Future migrations here
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }

  @override
  bool get isPersistent => true;

  @override
  CacheStorageType get storageType => CacheStorageType.sqfliteFfi;
}
