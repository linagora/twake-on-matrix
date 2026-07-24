import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'web_perf_metrics.dart';

bool _environmentEmitted = false;

/// Collects browser frame cadence, long tasks and optional Chrome JS heap.
class WebPerfCollector {
  WebPerfCollector(this.scenario)
    : _runId = DateTime.now().microsecondsSinceEpoch.toString();

  final String scenario;
  final String _runId;
  final List<double> _frameTimestampsMs = [];
  final List<double> _longTaskDurationsMs = [];
  final List<String> _pending = [];

  JSFunction? _frameCallback;
  web.PerformanceObserver? _longTaskObserver;
  int? _frameHandle;
  int _sequence = 0;
  bool _active = false;

  /// Starts an isolated browser measurement window.
  void start() {
    if (_active) {
      throw StateError('WebPerfCollector is already active');
    }
    _frameTimestampsMs.clear();
    _longTaskDurationsMs.clear();
    _active = true;
    _startLongTaskObserver();
    _frameCallback = ((double timestamp) {
      if (!_active) return;
      _frameTimestampsMs.add(timestamp);
      _frameHandle = web.window.requestAnimationFrame(_frameCallback!);
    }).toJS;
    _frameHandle = web.window.requestAnimationFrame(_frameCallback!);
  }

  /// Captures the current measurement window as one PERF_METRIC checkpoint.
  void checkpoint(String label, {Map<String, dynamic> extra = const {}}) {
    _drainLongTasks();
    final metrics = <String, dynamic>{
      ...computeWebPerfMetrics(
        frameTimestampsMs: List<double>.from(_frameTimestampsMs),
        longTaskDurationsMs: List<double>.from(_longTaskDurationsMs),
        jsHeapUsedBytes: _readJsHeapUsedBytes(),
      ),
      ...extra,
    };
    final values = metrics.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' | ');
    _pending.add(
      'PERF_METRIC | $scenario | $label'
      ' | run=$_runId | seq=${_sequence++}'
      ' | ts=${DateTime.now().millisecondsSinceEpoch}'
      ' | $values',
    );
    _frameTimestampsMs.clear();
    _longTaskDurationsMs.clear();
  }

  /// Stops requestAnimationFrame sampling and long-task observation.
  void stop() {
    _active = false;
    final frameHandle = _frameHandle;
    if (frameHandle != null) {
      web.window.cancelAnimationFrame(frameHandle);
    }
    _frameHandle = null;
    _drainLongTasks();
    _longTaskObserver?.disconnect();
    _longTaskObserver = null;
  }

  /// Emits environment metadata once and flushes queued metric lines.
  Future<void> flush([void Function(String)? logger]) async {
    void emit(String line) {
      if (logger != null) {
        logger(line);
      } else {
        // ignore: avoid_print
        print(line);
      }
    }

    if (!_environmentEmitted) {
      _environmentEmitted = true;
      emit('PERF_WEB_ENV | ${jsonEncode(_browserEnvironment())}');
    }
    for (final line in _pending) {
      emit(line);
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    _pending.clear();
  }

  void _startLongTaskObserver() {
    final supportsLongTasks = web.PerformanceObserver.supportedEntryTypes.toDart
        .any((entryType) => entryType.toDart == 'longtask');
    if (!supportsLongTasks) return;

    _longTaskObserver = web.PerformanceObserver(
      ((
            web.PerformanceObserverEntryList entries,
            web.PerformanceObserver observer,
          ) {
            _appendLongTasks(entries.getEntries());
          })
          .toJS,
    );
    _longTaskObserver!.observe(
      web.PerformanceObserverInit(entryTypes: <JSString>['longtask'.toJS].toJS),
    );
  }

  void _drainLongTasks() {
    final observer = _longTaskObserver;
    if (observer != null) {
      _appendLongTasks(observer.takeRecords());
    }
  }

  void _appendLongTasks(web.PerformanceEntryList entries) {
    for (final entry in entries.toDart) {
      if (entry.duration >= 50) {
        _longTaskDurationsMs.add(entry.duration);
      }
    }
  }

  double? _readJsHeapUsedBytes() {
    final memory = web.window.performance.getProperty<JSObject?>('memory'.toJS);
    final usedHeap = memory?.getProperty<JSNumber?>('usedJSHeapSize'.toJS);
    return usedHeap?.toDartDouble;
  }

  Map<String, dynamic> _browserEnvironment() => {
    'user_agent': web.window.navigator.userAgent,
    'viewport': {
      'width': web.window.innerWidth,
      'height': web.window.innerHeight,
      'device_pixel_ratio': web.window.devicePixelRatio,
    },
    'renderer': web.document.querySelector('canvas') == null ? 'dom' : 'canvas',
  };
}
