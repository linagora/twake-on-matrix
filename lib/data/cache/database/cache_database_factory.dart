// lib/data/cache/database/cache_database_factory.dart
import 'package:flutter/foundation.dart';
import 'cache_database_interface.dart';
import 'cache_database_web.dart'
    if (dart.library.io) 'cache_database_web_stub.dart';
import 'cache_database_mobile_stub.dart'
    if (dart.library.io) 'cache_database_mobile.dart';

/// Factory for creating platform-specific cache database implementations
class CacheDatabaseFactory {
  /// Create the appropriate cache database for the current platform
  ///
  /// - Web: CacheDatabaseWeb (cascading fallback)
  /// - Mobile/Desktop: CacheDatabaseMobile (sqflite_ffi)
  static CacheDatabaseInterface create() {
    if (kIsWeb) {
      return createCacheDatabaseWebImpl();
    }
    return createCacheDatabaseMobileImpl();
  }
}
