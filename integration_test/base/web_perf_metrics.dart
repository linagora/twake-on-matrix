const _slowFrameMultiplier = 1.5;

/// Computes browser frame and long-task metrics from a measured interaction.
///
/// [frameTimestampsMs] contains consecutive requestAnimationFrame timestamps.
/// The median interval is used as the local refresh-rate baseline so headless
/// runners are not incorrectly judged against an assumed 60 Hz display.
Map<String, dynamic> computeWebPerfMetrics({
  required List<double> frameTimestampsMs,
  List<double> longTaskDurationsMs = const [],
  double? jsHeapUsedBytes,
}) {
  final intervals = <double>[];
  for (var index = 1; index < frameTimestampsMs.length; index++) {
    final interval = frameTimestampsMs[index] - frameTimestampsMs[index - 1];
    if (interval > 0) intervals.add(interval);
  }
  intervals.sort();

  final expectedInterval = _median(intervals) ?? 0;
  final slowFrameThreshold = expectedInterval * _slowFrameMultiplier;
  final slowFrameCount = intervals
      .where((interval) => interval > slowFrameThreshold)
      .length;
  final frameWindow = frameTimestampsMs.length >= 2
      ? frameTimestampsMs.last - frameTimestampsMs.first
      : 0.0;
  final fps = frameWindow > 0 ? intervals.length * 1000 / frameWindow : 0.0;
  final longTaskTotal = longTaskDurationsMs.fold<double>(
    0,
    (total, duration) => total + duration,
  );

  final metrics = <String, dynamic>{
    'frame_count': frameTimestampsMs.length,
    'frame_window_ms': _rounded(frameWindow),
    'expected_frame_interval_ms': _rounded(expectedInterval),
    'frame_interval_p50_ms': _rounded(_percentile(intervals, 50)),
    'frame_interval_p95_ms': _rounded(_percentile(intervals, 95)),
    'frame_interval_p99_ms': _rounded(_percentile(intervals, 99)),
    'fps': _rounded(fps),
    'slow_frame_count': slowFrameCount,
    'slow_frame_rate': intervals.isEmpty
        ? 0.0
        : _rounded(slowFrameCount / intervals.length),
    'long_task_count': longTaskDurationsMs.length,
    'long_task_total_ms': _rounded(longTaskTotal),
    'long_task_max_ms': _rounded(
      longTaskDurationsMs.isEmpty
          ? 0
          : longTaskDurationsMs.reduce(
              (left, right) => left > right ? left : right,
            ),
    ),
  };
  if (jsHeapUsedBytes != null) {
    metrics['js_heap_used_bytes'] = _rounded(jsHeapUsedBytes);
  }
  return metrics;
}

double _percentile(List<double> sorted, int percentile) {
  if (sorted.isEmpty) return 0;
  final index = ((percentile / 100) * (sorted.length - 1)).round();
  return sorted[index];
}

double? _median(List<double> sorted) {
  if (sorted.isEmpty) return null;
  final middle = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[middle]
      : (sorted[middle - 1] + sorted[middle]) / 2;
}

double _rounded(num value) => double.parse(value.toStringAsFixed(3));
