// lib/data/cache/tier/disk_cache_tier_indexeddb_web.dart
import 'package:idb_shim/idb_browser.dart';
import 'disk_cache_tier_indexeddb.dart';

/// Create IndexedDB tier for web platform
DiskCacheTierIndexedDb createIndexedDbTierImpl() {
  return DiskCacheTierIndexedDb(idbFactoryBrowser);
}
