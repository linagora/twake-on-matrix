import 'dart:io' show ProcessInfo;
import 'dart:ui' show FramePhase, FrameTiming;

import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

const _frameBudgetUs60Fps = 16667;

/// Computes frame metrics for an active rendering window.
///
/// Effective FPS uses the time between the first and last reported vsync.
/// Idle time before the first or after the last rendered frame is intentionally
/// excluded. Consumers must still reject small samples because a handful of
/// frames cannot represent sustained fluidity.
Map<String, dynamic> computeFrameStats(List<FrameTiming> frames) {
  if (frames.isEmpty) return {'frame_count': 0};

  final buildUs =
      frames.map((frame) => frame.buildDuration.inMicroseconds).toList()
        ..sort();
  final rasterUs =
      frames.map((frame) => frame.rasterDuration.inMicroseconds).toList()
        ..sort();
  final vsyncUs =
      frames
          .map((frame) => frame.timestampInMicroseconds(FramePhase.vsyncStart))
          .toList()
        ..sort();

  // Flutter pipelines the UI and raster threads. A frame misses the 60 FPS
  // budget when either phase exceeds 16.7 ms, not when both durations are added.
  final jankCount = frames
      .where(
        (frame) =>
            frame.buildDuration.inMicroseconds > _frameBudgetUs60Fps ||
            frame.rasterDuration.inMicroseconds > _frameBudgetUs60Fps,
      )
      .length;
  final frameWindowUs = vsyncUs.last - vsyncUs.first;
  final fps = frameWindowUs > 0
      ? (frames.length - 1) * Duration.microsecondsPerSecond / frameWindowUs
      : 0.0;

  return {
    'frame_count': frames.length,
    'frame_window_ms': frameWindowUs / Duration.microsecondsPerMillisecond,
    'fps': fps.toStringAsFixed(2),
    'build_p50_us': _percentile(buildUs, 50),
    'build_p95_us': _percentile(buildUs, 95),
    'build_p99_us': _percentile(buildUs, 99),
    'raster_p50_us': _percentile(rasterUs, 50),
    'raster_p95_us': _percentile(rasterUs, 95),
    'jank_count': jankCount,
    'jank_rate': (jankCount / frames.length).toStringAsFixed(3),
  };
}

int _percentile(List<int> sorted, int percentile) {
  if (sorted.isEmpty) return 0;
  final index = ((percentile / 100) * (sorted.length - 1)).round();
  return sorted[index];
}

/// Collects performance metrics during a Patrol test scenario.
///
/// Usage:
/// ```dart
/// final perf = PerfCollector('scroll_room');
/// perf.start();
/// // ... navigate, interact ...
/// perf.checkpoint('room_entered');
/// // ... scroll ...
/// perf.checkpoint('after_30s_scroll');
/// perf.stop();
/// await perf.flush();
/// ```
///
/// Each checkpoint emits a `PERF_METRIC` line capturing:
/// - RSS process memory
/// - Flutter imageCache state
/// - Frame timing percentiles (p50/p95/p99) and jank rate since last checkpoint
class PerfCollector {
  final String scenario;
  final String _runId;
  int _seq = 0;
  final List<String> _pending = [];
  final List<FrameTiming> _frameBuffer = [];
  TimingsCallback? _timingsCallback;

  PerfCollector(this.scenario)
    : _runId = DateTime.now().millisecondsSinceEpoch.toString();

  /// Starts accumulating frame timings. Call before the first action to measure.
  void start() {
    _timingsCallback = (timings) => _frameBuffer.addAll(timings);
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback!);
  }

  /// Stops accumulating frame timings.
  void stop() {
    if (_timingsCallback != null) {
      SchedulerBinding.instance.removeTimingsCallback(_timingsCallback!);
      _timingsCallback = null;
    }
  }

  /// Records a checkpoint with current memory state and frame stats since the
  /// previous checkpoint.
  ///
  /// [extra] allows adding arbitrary key=value metrics (e.g. latency_ms).
  void checkpoint(String label, {Map<String, dynamic> extra = const {}}) {
    final rss = ProcessInfo.currentRss;
    final cache = PaintingBinding.instance.imageCache;
    final frames = List<FrameTiming>.from(_frameBuffer);
    _frameBuffer.clear();

    final metrics = <String, dynamic>{
      'rss_bytes': rss,
      'cache_bytes': cache.currentSizeBytes,
      'cache_count': cache.currentSize,
      'cache_live': cache.liveImageCount,
      'cache_pending': cache.pendingImageCount,
      ...computeFrameStats(frames),
      ...extra,
    };

    final kvs = metrics.entries.map((e) => '${e.key}=${e.value}').join(' | ');
    _pending.add(
      'PERF_METRIC | $scenario | $label'
      ' | run=$_runId | seq=${_seq++}'
      ' | ts=${DateTime.now().millisecondsSinceEpoch}'
      ' | $kvs',
    );
  }

  /// Prints all accumulated metrics with 200ms spacing so the device logger
  /// keeps up (required for reliable idevicesyslog / logcat capture).
  Future<void> flush() async {
    for (final line in _pending) {
      // ignore: avoid_print
      print(line);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    _pending.clear();
  }
}
