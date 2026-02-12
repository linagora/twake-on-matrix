// lib/data/cache/database/cache_database_web_stub.dart
import 'cache_database_interface.dart';

/// Stub for non-web platforms
/// This file is used when compiling for mobile/desktop
CacheDatabaseInterface createCacheDatabaseWebImpl() {
  throw UnsupportedError('Web database only available on web platform');
}
