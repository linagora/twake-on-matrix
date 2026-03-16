import 'package:fluffychat/pages/settings_dashboard/settings_data_and_storage/settings_data_and_storage_calculator.dart';
import 'package:fluffychat/pages/settings_dashboard/settings_data_and_storage/settings_data_and_storage_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StorageScanResult.totalBytes', () {
    test('sums all category byte counts', () {
      const result = StorageScanResult(<StorageCategory, int>{
        StorageCategory.medias: 100,
        StorageCategory.files: 200,
        StorageCategory.videos: 300,
        StorageCategory.stickers: 50,
        StorageCategory.other: 75,
      });
      expect(result.totalBytes, 725);
    });

    test('defaults to 0 when no categories provided', () {
      expect(const StorageScanResult().totalBytes, 0);
    });

    test('handles single non-zero category', () {
      const result = StorageScanResult(<StorageCategory, int>{
        StorageCategory.videos: 512,
      });
      expect(result.totalBytes, 512);
    });

    test('bytesFor returns 0 for absent category', () {
      const result = StorageScanResult(<StorageCategory, int>{
        StorageCategory.medias: 1024,
      });
      expect(result.bytesFor(StorageCategory.files), 0);
      expect(result.bytesFor(StorageCategory.medias), 1024);
    });
  });

  group('StorageCalculator.formatBytes', () {
    test('formats 0 bytes as "0 B"', () {
      expect(StorageCalculator.formatBytes(0), '0 B');
    });

    test('formats bytes below 1 KB as "X B"', () {
      expect(StorageCalculator.formatBytes(1023), '1023 B');
    });

    test('formats exactly 1 KB as "1 KB"', () {
      expect(StorageCalculator.formatBytes(1024), '1 KB');
    });

    test('formats bytes in KB range (no decimal places)', () {
      expect(StorageCalculator.formatBytes(1536), '2 KB');
    });

    test('formats just below 1 MB as KB', () {
      expect(StorageCalculator.formatBytes(1024 * 1024 - 1), '1024 KB');
    });

    test('formats exactly 1 MB as "1 MB"', () {
      expect(StorageCalculator.formatBytes(1024 * 1024), '1 MB');
    });

    test('formats bytes in MB range (no decimal places)', () {
      expect(StorageCalculator.formatBytes(5 * 1024 * 1024), '5 MB');
    });

    test('formats exactly 1 GB with one decimal place', () {
      expect(StorageCalculator.formatBytes(1024 * 1024 * 1024), '1.0 GB');
    });

    test('formats GB with correct decimal', () {
      expect(StorageCalculator.formatBytes(1.5 * 1024 * 1024 * 1024), '1.5 GB');
    });
  });

  group('StorageCalculator.usageRatio', () {
    test(
      'returns 0.0 when totalStorageBytes is 0 (division-by-zero guard)',
      () {
        expect(StorageCalculator.usageRatio(500, 0), 0.0);
      },
    );

    test('returns 0.0 when totalStorageBytes is negative', () {
      expect(StorageCalculator.usageRatio(500, -1), 0.0);
    });

    test('computes correct ratio', () {
      expect(StorageCalculator.usageRatio(1000, 10000), closeTo(0.1, 1e-10));
    });

    test('returns 0.0 when cache is empty', () {
      expect(StorageCalculator.usageRatio(0, 5000), 0.0);
    });

    test('clamps to 1.0 when cache exceeds total storage', () {
      expect(StorageCalculator.usageRatio(20000, 10000), 1.0);
    });
  });

  group('StorageCalculator.usagePercent', () {
    test('formats ratio as percentage string with one decimal', () {
      expect(StorageCalculator.usagePercent(1000, 10000), '10.0%');
    });

    test('returns "0.0%" when totalStorageBytes is 0', () {
      expect(StorageCalculator.usagePercent(500, 0), '0.0%');
    });
  });
}
