import 'dart:async';
import 'package:fluffychat/utils/stream_sync_update_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import 'mock_sync_update.dart';

void main() {
  group('rateLimitWithSyncUpdate', () {
    test(
        'WHEN two updates are added within the rate limit duration THEN only the first update is emitted',
        () async {
      // GIVEN
      final controller = StreamController<SyncUpdate>();
      const duration = Duration(milliseconds: 100);
      final rateLimitedStream =
          controller.stream.rateLimitWithSyncUpdate(duration);

      final results = <SyncUpdate>[];
      final subscription = rateLimitedStream.listen(results.add);

      // WHEN
      // Add two updates in quick succession
      controller.add(MockSyncUpdate(nextBatch: '1'));
      controller.add(MockSyncUpdate(nextBatch: '2'));

      // Wait for slightly less than the rate limit duration
      await Future.delayed(duration - const Duration(milliseconds: 10));

      // THEN
      expect(results.length, 1);
      expect(results.first.nextBatch, '1');

      // CLEANUP
      await subscription.cancel();
      await controller.close();
    });

    test(
        'WHEN two updates are added with a delay greater than the rate limit duration THEN both updates are emitted',
        () async {
      // GIVEN
      final controller = StreamController<SyncUpdate>();
      const duration = Duration(milliseconds: 100);
      final rateLimitedStream =
          controller.stream.rateLimitWithSyncUpdate(duration);

      final results = <SyncUpdate>[];
      final subscription = rateLimitedStream.listen(results.add);

      // WHEN
      controller.add(MockSyncUpdate(nextBatch: '1'));
      await Future.delayed(duration);
      controller.add(MockSyncUpdate(nextBatch: '2'));

      // Wait for slightly more than the rate limit duration to ensure processing
      await Future.delayed(duration + const Duration(milliseconds: 10));

      // THEN
      expect(results.length, 2, reason: 'Two updates should be emitted');
      expect(
        results.map((update) => update.nextBatch).toList(),
        ['1', '2'],
        reason: 'Both updates should be emitted in order',
      );

      // Clean up
      await subscription.cancel();
      await controller.close();
    });

    test(
        'WHEN many updates occur rapidly THEN only first and last updates within each rate limit duration are emitted',
        () async {
      // GIVEN
      final controller = StreamController<SyncUpdate>();
      const duration = Duration(milliseconds: 100);
      final rateLimitedStream =
          controller.stream.rateLimitWithSyncUpdate(duration);

      final results = <SyncUpdate>[];
      final subscription = rateLimitedStream.listen(results.add);

      // WHEN
      for (int i = 1; i <= 10; i++) {
        controller.add(MockSyncUpdate(nextBatch: i.toString()));
      }

      // Wait for slightly more than the rate limit duration
      await Future.delayed(duration);

      expect(
        results.length,
        1,
        reason: 'Only the first update should be emitted initially',
      );
      expect(
        results.first.nextBatch,
        '1',
        reason: 'The first update should be "1"',
      );

      // Wait for another rate limit duration
      await Future.delayed(duration);

      // THEN
      expect(
        results.length,
        2,
        reason: 'Two updates should be emitted after waiting',
      );
      expect(
        results.first.nextBatch,
        '1',
        reason: 'The first update should still be "1"',
      );
      expect(
        results.last.nextBatch,
        '10',
        reason: 'The last update should be "10"',
      );

      // Clean up
      await subscription.cancel();
      await controller.close();
    });

    test(
        'WHEN multiple updates are added rapidly THEN the first update is emitted',
        () async {
      // GIVEN
      final controller = StreamController<SyncUpdate>();
      final rateLimitedStream = controller.stream
          .rateLimitWithSyncUpdate(const Duration(milliseconds: 100));

      // WHEN
      controller.add(MockSyncUpdate(nextBatch: '1'));
      controller.add(MockSyncUpdate(nextBatch: '2'));
      controller.add(MockSyncUpdate(nextBatch: '3'));

      // THEN
      final result = await rateLimitedStream.first;
      expect(
        result.nextBatch,
        '1',
        reason: 'The first update should be emitted',
      );

      // Clean up
      await controller.close();
    });

    test(
        'WHEN the input stream is done THEN the rate-limited stream should close',
        () async {
      // GIVEN
      final inputStream =
          Stream<SyncUpdate>.fromIterable([MockSyncUpdate(nextBatch: '1')]);

      // WHEN
      final rateLimitedStream = inputStream
          .rateLimitWithSyncUpdate(const Duration(milliseconds: 100));

      // THEN
      await expectLater(
        rateLimitedStream,
        emitsInOrder([isA<MockSyncUpdate>(), emitsDone]),
        reason: 'Should emit one update and then close',
      );
    });

    test(
        'WHEN an error is added to the input stream THEN it should be propagated to the rate-limited stream',
        () async {
      // GIVEN
      final controller = StreamController<SyncUpdate>();
      final rateLimitedStream = controller.stream
          .rateLimitWithSyncUpdate(const Duration(milliseconds: 100));

      // WHEN
      controller.addError('Test error');

      // THEN
      await expectLater(
        rateLimitedStream,
        emitsError('Test error'),
        reason: 'The error should be propagated to the rate-limited stream',
      );

      // Clean up
      await controller.close();
    });
  });
}
