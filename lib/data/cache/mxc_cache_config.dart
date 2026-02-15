// lib/data/cache/mxc_cache_config.dart
import 'package:flutter/foundation.dart';

/// Configuration for MXC cache system
///
/// Defines memory limits, disk limits, and cache expiration policies.
/// Use named constructors to get preset configurations for different device tiers.
class MxcCacheConfig {
  final int memoryMaxBytes;
  final int memoryMaxItems;
  final int diskMaxBytes;
  final Duration staleThreshold;
  final Duration maxAge;

  const MxcCacheConfig({
    required this.memoryMaxBytes,
    required this.memoryMaxItems,
    required this.diskMaxBytes,
    required this.staleThreshold,
    required this.maxAge,
  });

  /// Default adaptive config
  ///
  /// Uses web preset for web platform, medium preset for native platforms.
  /// For device-specific tuning, use [low], [medium], or [high] constructors.
  factory MxcCacheConfig.adaptive() {
    return kIsWeb ? MxcCacheConfig.web() : MxcCacheConfig.medium();
  }

  /// Web platform config (conservative due to IndexedDB limits)
  ///
  /// Memory: 25MB / 100 items
  /// Disk: 100MB
  /// Max age: 7 days
  factory MxcCacheConfig.web() {
    return const MxcCacheConfig(
      memoryMaxBytes: 25 * 1024 * 1024,
      memoryMaxItems: 100,
      diskMaxBytes: 100 * 1024 * 1024,
      staleThreshold: Duration(hours: 1),
      maxAge: Duration(days: 7),
    );
  }

  /// Low memory config for <= 2GB RAM devices
  ///
  /// Memory: 25MB / 100 items
  /// Disk: 200MB
  /// Max age: 14 days
  factory MxcCacheConfig.low() {
    return const MxcCacheConfig(
      memoryMaxBytes: 25 * 1024 * 1024,
      memoryMaxItems: 100,
      diskMaxBytes: 200 * 1024 * 1024,
      staleThreshold: Duration(hours: 1),
      maxAge: Duration(days: 14),
    );
  }

  /// Medium memory config for 2-4GB RAM devices
  ///
  /// Memory: 50MB / 300 items
  /// Disk: 500MB
  /// Max age: 30 days
  factory MxcCacheConfig.medium() {
    return const MxcCacheConfig(
      memoryMaxBytes: 50 * 1024 * 1024,
      memoryMaxItems: 300,
      diskMaxBytes: 500 * 1024 * 1024,
      staleThreshold: Duration(hours: 1),
      maxAge: Duration(days: 30),
    );
  }

  /// High memory config for >= 4GB RAM devices
  ///
  /// Memory: 100MB / 1000 items
  /// Disk: 1GB
  /// Max age: 30 days
  factory MxcCacheConfig.high() {
    return const MxcCacheConfig(
      memoryMaxBytes: 100 * 1024 * 1024,
      memoryMaxItems: 1000,
      diskMaxBytes: 1024 * 1024 * 1024,
      staleThreshold: Duration(hours: 1),
      maxAge: Duration(days: 30),
    );
  }

  @override
  String toString() =>
      'MxcCacheConfig(memory: ${memoryMaxBytes ~/ 1024 ~/ 1024}MB/'
      '$memoryMaxItems items, disk: ${diskMaxBytes ~/ 1024 ~/ 1024}MB, '
      'stale: $staleThreshold, maxAge: $maxAge)';
}
