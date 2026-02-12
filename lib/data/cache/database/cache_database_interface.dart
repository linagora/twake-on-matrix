// lib/data/cache/database/cache_database_interface.dart
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

/// Storage type used by the cache database
enum CacheStorageType {
  /// Native SQLite on mobile/desktop (sqflite_common_ffi)
  sqfliteFfi,

  /// WebAssembly SQLite on web (sqflite_common_ffi_web)
  sqfliteWasm,

  /// IndexedDB-backed SQLite on web (idb_sqflite)
  indexedDb,

  /// Memory-only cache (no persistence)
  memoryOnly,
}

/// Abstract interface for cache database implementations
///
/// Allows platform-specific implementations with graceful fallbacks
/// on web (wasm -> IndexedDB -> memory-only)
abstract class CacheDatabaseInterface {
  /// Initialize the database
  Future<void> init();

  /// Get the database instance
  Future<ffi.Database> get database;

  /// Close the database connection
  Future<void> close();

  /// True if data persists across sessions
  bool get isPersistent;

  /// Storage type for diagnostics and monitoring
  CacheStorageType get storageType;
}
