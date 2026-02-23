// lib/data/cache/tier/disk_cache_tier_indexeddb_stub.dart
import 'disk_cache_tier_indexeddb.dart';

/// Stub for non-web platforms
/// This file is used when compiling for mobile/desktop
DiskCacheTierIndexedDb createIndexedDbTierImpl() {
  throw UnsupportedError('IndexedDB tier only available on web platform');
}
