import 'settings_data_and_storage_constants.dart';

class StorageScanResult {
  final Map<StorageCategory, int> _bytes;

  const StorageScanResult([this._bytes = const <StorageCategory, int>{}]);

  int bytesFor(StorageCategory category) => _bytes[category] ?? 0;

  int get totalBytes => _bytes.values.fold(0, (sum, v) => sum + v);
}

class StorageCalculator {
  const StorageCalculator._();

  static String formatBytes(double bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    if (bytes >= 1024) {
      return '${(bytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${bytes.toStringAsFixed(0)} B';
  }

  /// Ratio of [cacheBytes] to device [totalStorageBytes], clamped to [0, 1].
  ///
  /// Returns 0.0 when [totalStorageBytes] is unknown (≤ 0) to avoid
  /// division-by-zero or a ratio > 1.
  static double usageRatio(double cacheBytes, double totalStorageBytes) {
    if (totalStorageBytes <= 0) return 0.0;
    return (cacheBytes / totalStorageBytes).clamp(0.0, 1.0);
  }

  static String usagePercent(double cacheBytes, double totalStorageBytes) {
    final ratio = usageRatio(cacheBytes, totalStorageBytes);
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }
}
