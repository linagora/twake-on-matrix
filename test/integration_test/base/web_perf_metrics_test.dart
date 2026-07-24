import 'package:flutter_test/flutter_test.dart';

import '../../../integration_test/base/web_perf_metrics.dart';

void main() {
  test(
    'computes FPS and percentiles from requestAnimationFrame timestamps',
    () {
      final timestamps = List.generate(31, (index) => index * 16.667);

      final metrics = computeWebPerfMetrics(frameTimestampsMs: timestamps);

      expect(metrics['frame_count'], 31);
      expect(metrics['fps'], closeTo(60, 0.1));
      expect(metrics['frame_interval_p50_ms'], closeTo(16.667, 0.001));
      expect(metrics['frame_interval_p95_ms'], closeTo(16.667, 0.001));
      expect(metrics['frame_interval_p99_ms'], closeTo(16.667, 0.001));
      expect(metrics['slow_frame_count'], 0);
    },
  );

  test('uses the median interval to classify slow browser frames', () {
    final metrics = computeWebPerfMetrics(frameTimestampsMs: [0, 16, 32, 72]);

    expect(metrics['expected_frame_interval_ms'], 16);
    expect(metrics['slow_frame_count'], 1);
    expect(metrics['slow_frame_rate'], closeTo(1 / 3, 0.001));
  });

  test('records long tasks and optional Chrome JS heap', () {
    final metrics = computeWebPerfMetrics(
      frameTimestampsMs: [0, 16],
      longTaskDurationsMs: [51, 75],
      jsHeapUsedBytes: 123456,
    );

    expect(metrics['long_task_count'], 2);
    expect(metrics['long_task_total_ms'], 126);
    expect(metrics['long_task_max_ms'], 75);
    expect(metrics['js_heap_used_bytes'], 123456);
  });

  test('omits unavailable JS heap and handles an empty frame window', () {
    final metrics = computeWebPerfMetrics(frameTimestampsMs: const []);

    expect(metrics['frame_count'], 0);
    expect(metrics['fps'], 0);
    expect(metrics.containsKey('js_heap_used_bytes'), isFalse);
  });
}
