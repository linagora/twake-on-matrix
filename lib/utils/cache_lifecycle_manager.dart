// lib/utils/cache_lifecycle_manager.dart
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:matrix/matrix.dart';
import '../data/cache/mxc_cache_manager.dart';

class CacheLifecycleManager with WidgetsBindingObserver {
  final MxcCacheManager _cacheManager;

  bool _isRegistered = false;
  bool _disposed = false;

  CacheLifecycleManager(this._cacheManager);

  /// Register lifecycle observer
  void register() {
    if (_isRegistered) return;
    WidgetsBinding.instance.addObserver(this);
    _isRegistered = true;
    Logs().d('CacheLifecycleManager: registered');
  }

  /// Unregister lifecycle observer
  void unregister() {
    if (!_isRegistered) return;
    WidgetsBinding.instance.removeObserver(this);
    _isRegistered = false;
    Logs().d('CacheLifecycleManager: unregistered');
  }

  /// Called on app startup
  Future<void> onAppStart() async {
    await _cacheManager.init();
    await _cleanupIfNeeded();
    register();
    Logs().d('CacheLifecycleManager: app started');
  }

  /// Called on user logout
  Future<void> onLogout() async {
    await _cacheManager.clearAll();
    Logs().d('CacheLifecycleManager: cleared cache on logout');
  }

  /// Called when app goes to background
  Future<void> onAppBackground() async {
    // Persist any pending writes
    await _cacheManager.evictIfNeeded();
  }

  @override
  void didHaveMemoryPressure() {
    Logs().w('CacheLifecycleManager: low memory - clearing memory cache');
    _cacheManager.clearMemory();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        unawaited(onAppBackground());
        break;
      case AppLifecycleState.detached:
        unawaited(dispose());
        break;
      default:
        break;
    }
  }

  Future<void> _cleanupIfNeeded() async {
    final stats = await _cacheManager.getStats();
    if (stats.diskUtilization > 90) {
      Logs().w(
        'CacheLifecycleManager: disk cache at ${stats.diskUtilization}%, '
        'evicting',
      );
      await _cacheManager.evictIfNeeded();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    unregister();
    await _cacheManager.dispose();
  }
}
