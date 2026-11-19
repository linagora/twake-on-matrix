import 'dart:async';

import 'package:matrix/matrix.dart';

/// Loads one room [Timeline] for callers that ask for it at the same time,
/// and cancels its subscriptions on [dispose].
///
/// A [Timeline] listens to client-wide streams until
/// [Timeline.cancelSubscriptions] runs, so a timeline that is never cancelled
/// keeps itself, its events and its `onUpdate` closure alive for the session.
class SharedTimelineLoader {
  SharedTimelineLoader(this._load);

  final Future<Timeline> Function() _load;

  Future<Timeline>? _timeline;

  bool _disposed = false;

  /// Starts the load on the first call; later calls share it. A failed load
  /// is forgotten so the next call retries.
  Future<Timeline> get() => _timeline ??= _loadOnce();

  Future<Timeline> _loadOnce() async {
    try {
      // Future.sync turns a synchronous throw into a failed future, so the
      // reset below runs after get() has stored it.
      return await Future<Timeline>.sync(_load);
    } catch (_) {
      if (!_disposed) _timeline = null;
      rethrow;
    }
  }

  /// Cancels the timeline now, or when a load still in flight completes.
  void dispose() {
    _disposed = true;
    unawaited(
      _timeline?.then(
        (timeline) => timeline.cancelSubscriptions(),
        onError: (Object _) {},
      ),
    );
  }
}
