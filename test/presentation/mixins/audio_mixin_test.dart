import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluffychat/presentation/mixins/audio_mixin.dart';

class MockAudioMixin with AudioMixin {}

void main() {
  late MockAudioMixin audioMixin;

  setUp(() {
    audioMixin = MockAudioMixin();
  });

  group('calculateWaveCountAuto', () {
    test('should return minWaves for invalid duration (<= 0)', () {
      // Arrange
      const minWaves = 5;
      const maxWaves = 20;
      const duration = 0;

      // Act
      final result = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: duration,
      );

      // Assert
      expect(result, minWaves);
    });

    test('should return minWaves for negative duration', () {
      // Arrange
      const minWaves = 5;
      const maxWaves = 20;
      const duration = -5;

      // Act
      final result = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: duration,
      );

      // Assert
      expect(result, minWaves);
    });

    test('should return minWaves for very short duration (<= 2 seconds)', () {
      // Arrange
      const minWaves = 5;
      const maxWaves = 20;

      // Act & Assert
      expect(
        audioMixin.calculateWaveCountAuto(
          minWaves: minWaves,
          maxWaves: maxWaves,
          durationInSeconds: 1,
        ),
        minWaves,
      );

      expect(
        audioMixin.calculateWaveCountAuto(
          minWaves: minWaves,
          maxWaves: maxWaves,
          durationInSeconds: 2,
        ),
        minWaves,
      );
    });

    test('should calculate wave count for short messages (2-10 seconds)', () {
      // Arrange
      const minWaves = 10;
      const maxWaves = 50;

      // Act & Assert
      // At 2 seconds: should be minWaves
      expect(
        audioMixin.calculateWaveCountAuto(
          minWaves: minWaves,
          maxWaves: maxWaves,
          durationInSeconds: 2,
        ),
        minWaves,
      );

      // At 6 seconds: should be in the middle of the range
      final result6s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 6,
      );
      expect(result6s, greaterThan(minWaves));
      expect(result6s, lessThan(maxWaves));

      // At 10 seconds: should be at 40% of range
      final result10s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 10,
      );
      final expected10s = (minWaves + (maxWaves - minWaves) * 0.4).round();
      expect(result10s, expected10s);
    });

    test('should calculate wave count for medium messages (10-30 seconds)', () {
      // Arrange
      const minWaves = 10;
      const maxWaves = 50;

      // Act & Assert
      // At 10 seconds: should be at 40% of range
      final result10s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 10,
      );
      final expected10s = (minWaves + (maxWaves - minWaves) * 0.4).round();
      expect(result10s, expected10s);

      // At 20 seconds: should be in the middle of medium range
      final result20s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 20,
      );
      expect(result20s, greaterThan(result10s));
      expect(result20s, lessThan(maxWaves));

      // At 30 seconds: should be at 70% of range
      final result30s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 30,
      );
      final expected30s = (minWaves + (maxWaves - minWaves) * 0.7).round();
      expect(result30s, expected30s);
    });

    test('should calculate wave count for long messages (> 30 seconds)', () {
      // Arrange
      const minWaves = 10;
      const maxWaves = 50;

      // Act & Assert
      // At 30 seconds: should be at 70% of range
      final result30s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 30,
      );
      final expected30s = (minWaves + (maxWaves - minWaves) * 0.7).round();
      expect(result30s, expected30s);

      // At 60 seconds: should be higher
      final result60s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 60,
      );
      expect(result60s, greaterThan(result30s));

      // At 120 seconds: should be at max range
      final result120s = audioMixin.calculateWaveCountAuto(
        minWaves: minWaves,
        maxWaves: maxWaves,
        durationInSeconds: 120,
      );
      expect(result120s, maxWaves);
    });

    test('should handle edge case with same min and max waves', () {
      // Arrange
      const minWaves = 20;
      const maxWaves = 20;

      // Act & Assert
      expect(
        audioMixin.calculateWaveCountAuto(
          minWaves: minWaves,
          maxWaves: maxWaves,
          durationInSeconds: 5,
        ),
        minWaves,
      );

      expect(
        audioMixin.calculateWaveCountAuto(
          minWaves: minWaves,
          maxWaves: maxWaves,
          durationInSeconds: 60,
        ),
        minWaves,
      );
    });
  });

  group('calculateWaveForm', () {
    test('should return null for null waveform', () {
      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: null,
        waveCount: 10,
      );

      // Assert
      expect(result, null);
    });

    test('should return null for empty waveform', () {
      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: [],
        waveCount: 10,
      );

      // Assert
      expect(result, null);
    });

    test('should return null for invalid wave count (<= 0)', () {
      // Arrange
      const waveform = [100, 200, 150, 300];

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 0,
      );

      // Assert
      expect(result, null);
    });

    test('should return middle value for waveCount = 1', () {
      // Arrange
      const waveform = [100, 200, 150, 300, 250];

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 1,
      );

      // Assert
      expect(result, [150]); // Middle value at index 2
    });

    test('should return original waveform when waveCount equals length', () {
      // Arrange
      const waveform = [100, 200, 150, 300];

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 4,
      );

      // Assert
      expect(result, waveform);
    });

    test('should interpolate waveform for downsampling', () {
      // Arrange
      const waveform = [0, 100, 200, 300, 400]; // 5 points

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 3,
      );

      // Assert
      expect(result!.length, 3);
      expect(result[0], 1); // First point gets clamped from 0 to 1
      expect(result[2], 400); // Last point
      // Middle point should be interpolated
      expect(result[1], greaterThan(1));
      expect(result[1], lessThan(400));
    });

    test(
        'should interpolate to generate waveCount values when waveCount exceeds input length',
        () {
      // Arrange
      const waveform = [100, 200, 300, 400, 500]; // 5 elements

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 10, // Request 10 from 5 input values
      );

      // Assert
      expect(result!.length, 10); // Should interpolate to 10 values
      // First and last should match input
      expect(result.first, 100);
      expect(result.last, 500);
      // Middle values should be interpolated
      expect(result[5], closeTo(300, 50)); // ~middle value
    });

    test('should clamp values correctly', () {
      // Arrange
      const waveform = [0, 1500, 2000, 500]; // Contains values > 1024 and 0

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 4,
      );

      // Assert
      expect(result!.length, 4);
      expect(result[0], 1); // 0 should become 1
      expect(result[1], 1024); // 1500 should become 1024
      expect(result[2], 1024); // 2000 should become 1024
      expect(result[3], 500); // 500 should remain 500
    });

    test('should handle single point waveform', () {
      // Arrange
      const waveform = [300];

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 3,
      );

      // Assert
      // With 1 input value, all output values will be the same
      expect(result, [300, 300, 300]);
    });

    test('should downsample correctly', () {
      // Arrange
      const waveform = [100, 200, 300, 400, 500, 600, 700, 800, 900];

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: 3,
      );

      // Assert
      expect(result!.length, 3);
      expect(result[0], 100); // First value
      expect(result[2], 900); // Last value
    });

    test('should cap waveCount when maxBubbleWaveCount is exceeded', () {
      // Arrange
      const waveform = [100, 200, 300, 400, 500, 600, 700, 800];
      const requestedWaveCount = 10;
      const maxBubbleWaveCount = 5;

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: requestedWaveCount,
        maxBubbleWaveCount: maxBubbleWaveCount,
      );

      // Assert
      expect(result!.length, maxBubbleWaveCount);
    });

    test('should not cap waveCount when below maxBubbleWaveCount', () {
      // Arrange
      const waveform = [100, 200, 300, 400, 500, 600, 700, 800];
      const requestedWaveCount = 3;
      const maxBubbleWaveCount = 5;

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: requestedWaveCount,
        maxBubbleWaveCount: maxBubbleWaveCount,
      );

      // Assert
      expect(result!.length, requestedWaveCount);
    });

    test('should use exact maxBubbleWaveCount when requested equals max', () {
      // Arrange
      const waveform = [100, 200, 300, 400, 500, 600, 700, 800];
      const requestedWaveCount = 5;
      const maxBubbleWaveCount = 5;

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: requestedWaveCount,
        maxBubbleWaveCount: maxBubbleWaveCount,
      );

      // Assert
      expect(result!.length, 5);
    });

    test('should ignore maxBubbleWaveCount when null', () {
      // Arrange
      const waveform = [100, 200, 300, 400, 500];
      const requestedWaveCount = 10;

      // Act
      final result = audioMixin.calculateWaveForm(
        eventWaveForm: waveform,
        waveCount: requestedWaveCount,
        maxBubbleWaveCount: null,
      );

      // Assert
      // Should interpolate to requested count when no max is set
      expect(result!.length, requestedWaveCount);
    });
  });

  group('calculateWaveHeight', () {
    test('should return empty list for empty waveform', () {
      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: [],
        minHeight: 10.0,
        maxHeight: 50.0,
      );

      // Assert
      expect(result, []);
    });

    test('should return average height when all values are equal', () {
      // Arrange
      const waveform = [100, 100, 100, 100];
      const minHeight = 10.0;
      const maxHeight = 50.0;
      const expectedHeight = (maxHeight + minHeight) / 2;

      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: waveform,
        minHeight: minHeight,
        maxHeight: maxHeight,
      );

      // Assert
      expect(result.length, 4);
      expect(result.every((height) => height == expectedHeight), true);
    });

    test('should scale values correctly with different ranges', () {
      // Arrange
      const waveform = [0, 50, 100]; // min=0, max=100
      const minHeight = 20.0;
      const maxHeight = 80.0;

      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: waveform,
        minHeight: minHeight,
        maxHeight: maxHeight,
      );

      // Assert
      expect(result.length, 3);
      expect(result[0], minHeight); // 0 maps to minHeight
      expect(result[2], maxHeight); // 100 maps to maxHeight
      expect(result[1], 50.0); // 50 maps to middle
    });

    test('should handle negative values in waveform', () {
      // Arrange
      const waveform = [-50, 0, 50, 100];
      const minHeight = 10.0;
      const maxHeight = 60.0;

      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: waveform,
        minHeight: minHeight,
        maxHeight: maxHeight,
      );

      // Assert
      expect(result.length, 4);
      expect(result[0], minHeight); // -50 maps to minHeight
      expect(result[1], closeTo(26.67, 0.01)); // 0 maps to ~26.67
      expect(result[2], closeTo(43.33, 0.01)); // 50 maps to ~43.33
      expect(result[3], maxHeight); // 100 maps to maxHeight
    });

    test('should handle single value waveform', () {
      // Arrange
      const waveform = [75];
      const minHeight = 15.0;
      const maxHeight = 45.0;
      const expectedHeight = (maxHeight + minHeight) / 2;

      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: waveform,
        minHeight: minHeight,
        maxHeight: maxHeight,
      );

      // Assert
      expect(result, [expectedHeight]);
    });

    test('should handle large waveform arrays', () {
      // Arrange
      final waveform = List.generate(1000, (index) => index);
      const minHeight = 5.0;
      const maxHeight = 25.0;

      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: waveform,
        minHeight: minHeight,
        maxHeight: maxHeight,
      );

      // Assert
      expect(result.length, 1000);
      expect(result[0], minHeight); // First value (0) maps to minHeight
      expect(result.last, maxHeight); // Last value (999) maps to maxHeight
      expect(
        result.every((height) => height >= minHeight && height <= maxHeight),
        true,
      );
    });

    test('should handle decimal height values', () {
      // Arrange
      const waveform = [25, 75];
      const minHeight = 12.5;
      const maxHeight = 37.5;

      // Act
      final result = audioMixin.calculateWaveHeight(
        waveform: waveform,
        minHeight: minHeight,
        maxHeight: maxHeight,
      );

      // Assert
      expect(result.length, 2);
      expect(result[0], 12.5); // 25 (min value) maps to minHeight
      expect(result[1], 37.5); // 75 (max value) maps to maxHeight
    });
  });

  group('Audio LRU Cache', () {
    test('should cache and retrieve audio data', () {
      // Arrange
      // Create data larger than 1KB minimum
      final testData = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      const eventId = 'test_event_1';

      // Act
      audioMixin.putInAudioCache(eventId, testData);
      final result = audioMixin.getFromAudioCache(eventId);

      // Assert
      expect(result, testData);
    });

    test('should return null for non-existent cache key', () {
      // Act
      final result = audioMixin.getFromAudioCache('non_existent');

      // Assert
      expect(result, null);
    });

    test('should update access order when retrieving cached data', () {
      // Arrange
      final data1 = Uint8List.fromList(List.generate(2048, (i) => 1));
      final data2 = Uint8List.fromList(List.generate(2048, (i) => 2));
      final data3 = Uint8List.fromList(List.generate(2048, (i) => 3));

      // Act
      audioMixin.putInAudioCache('event1', data1);
      audioMixin.putInAudioCache('event2', data2);
      audioMixin.putInAudioCache('event3', data3);

      // Access event1 to move it to the end
      audioMixin.getFromAudioCache('event1');

      // Assert - event1 should still be accessible
      expect(audioMixin.getFromAudioCache('event1'), data1);
    });

    test('should evict oldest item when max items limit is reached', () {
      // Arrange - Create valid test data (>1KB)
      final smallData = Uint8List.fromList(List.generate(2048, (i) => i % 256));

      // Act - Add 21 items (max is 20)
      for (var i = 0; i < 21; i++) {
        audioMixin.putInAudioCache('event_$i', smallData);
      }

      // Assert - First item should be evicted
      expect(audioMixin.getFromAudioCache('event_0'), null);
      // Last item should still exist
      expect(audioMixin.getFromAudioCache('event_20'), smallData);
    });

    test('should evict items when memory limit would be exceeded', () {
      // Arrange - Create large data (10MB each)
      final largeData = Uint8List(10 * 1024 * 1024);

      // Act - Add 6 items (6 * 10MB = 60MB, exceeds 50MB limit)
      for (var i = 0; i < 6; i++) {
        audioMixin.putInAudioCache('large_event_$i', largeData);
      }

      // Assert - Early items should be evicted to stay under memory limit
      expect(audioMixin.getFromAudioCache('large_event_0'), null);
      // More recent items should exist
      expect(audioMixin.getFromAudioCache('large_event_5'), isNotNull);
    });

    test('should preserve most recently accessed items during eviction', () {
      // Arrange
      final data = Uint8List.fromList(List.generate(2048, (i) => i % 256));

      // Act - Add enough items to fill cache
      for (var i = 1; i <= 19; i++) {
        audioMixin.putInAudioCache('event_$i', data);
      }

      // Access event_1 to make it most recent
      audioMixin.getFromAudioCache('event_1');

      // Add 2 more items to trigger eviction (total would be 21, max is 20)
      audioMixin.putInAudioCache('event_20', data);
      audioMixin.putInAudioCache('event_21', data);

      // Assert - event_1 should be preserved as it was accessed recently
      // event_2 should be evicted as it was least recent
      // event_3 should still be in cache (only one eviction needed)
      expect(audioMixin.getFromAudioCache('event_2'), null);
      expect(audioMixin.getFromAudioCache('event_3'), isNotNull);
      expect(audioMixin.getFromAudioCache('event_1'), isNotNull);
      expect(audioMixin.getFromAudioCache('event_20'), isNotNull);
      expect(audioMixin.getFromAudioCache('event_21'), isNotNull);
    });

    test('should update existing cache entry without duplication', () {
      // Arrange
      final data1 = Uint8List.fromList(List.generate(2048, (i) => 1));
      final data2 = Uint8List.fromList(List.generate(3072, (i) => 2));
      const eventId = 'same_event';

      // Act
      audioMixin.putInAudioCache(eventId, data1);
      audioMixin.putInAudioCache(eventId, data2); // Update with new data

      // Assert - Should have the updated data
      final result = audioMixin.getFromAudioCache(eventId);
      expect(result, data2);
      expect(result!.length, 3072);
    });

    test('should reject cache entries that are too small', () {
      // Arrange
      final tooSmallData = Uint8List.fromList([1, 2, 3, 4, 5]); // Only 5 bytes
      const eventId = 'small_event';

      // Act
      audioMixin.putInAudioCache(eventId, tooSmallData);
      final result = audioMixin.getFromAudioCache(eventId);

      // Assert - Should not be cached (getFromAudioCache rejects it)
      expect(result, null);
    });

    test('should clear all cache data on cleanup', () async {
      // Arrange
      final data = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      audioMixin.putInAudioCache('event_1', data);
      audioMixin.putInAudioCache('event_2', data);
      audioMixin.putInAudioCache('event_3', data);

      // Act
      await audioMixin.cleanupAudioPlayer();

      // Assert - All cache should be cleared
      expect(audioMixin.getFromAudioCache('event_1'), null);
      expect(audioMixin.getFromAudioCache('event_2'), null);
      expect(audioMixin.getFromAudioCache('event_3'), null);
    });
  });
}
