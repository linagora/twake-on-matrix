import 'dart:async';
import 'dart:math' show Random, min;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:matrix/matrix.dart' show Logs, MatrixError, MatrixException;

/// Makes a failure visible: logged and sent to the error reporting.
typedef ReportFailure =
    void Function(Object error, StackTrace stackTrace, String what);

/// What it takes to take an account away. Each step that fails is reported
/// and runs again on its own, so one failing step never repeats one that
/// worked.
class RemovalSteps {
  const RemovalSteps({
    required this.remove,
    required this.hold,
    required this.settle,
    this.persist,
    this.settleOnHold = true,
  });

  /// The removal itself; runs again until it works.
  final Future<void> Function() remove;

  /// After a failed [remove]: keeps the account listed as unavailable. Runs
  /// again until it works, and does not run once the account is removed.
  final Future<void> Function() hold;

  /// After [hold] worked: writes the record that survives a restart. Runs
  /// again until it works, independently of [hold]. Null when there is none.
  final Future<void> Function()? persist;

  /// The effects of the account list having changed, after [hold] or [remove]
  /// worked (the replacement account's effects, the announcement). Runs once
  /// it worked, however many tries it takes.
  final Future<void> Function() settle;

  /// False when [settle] only makes sense once the account is removed (it
  /// clears what [persist] wrote).
  final bool settleOnHold;
}

/// Removals of logged-out accounts. A removal that fails is reported and
/// kept, and runs again with [retryAll] and in the background until it works;
/// until then the account stays listed.
///
/// The background retries are bounded and spread out: after the first failure
/// there are at most [maxRetryRounds] rounds. Each waits a random share
/// ("full jitter") of a ceiling that starts at [retryEvery] and doubles after
/// each round up to [maxRetryEvery]; when the server asked for a longer wait
/// (a Matrix rate limit), that wait is kept. Past the last round the removal
/// stays kept and its record survives a restart. Only a removal that is new,
/// or a new start of the app, starts the count: [retryAll] and a repeated
/// [remove] of a kept removal try once more and leave the count and the
/// backoff as they are, so a screen that asks often cannot keep the
/// background going. While the server asked for a wait, [retryAll] and a
/// repeated [remove] of a kept removal do nothing; the background rounds
/// already wait at least that long. Matrix rate limiting:
/// https://spec.matrix.org/v1.16/client-server-api/#rate-limiting
/// A step is reported on its first failure only; the retries are logged.
class LogoutRemovals {
  LogoutRemovals({
    this.retryEvery = const Duration(minutes: 1),
    this.maxRetryEvery = const Duration(minutes: 30),
    this.maxRetryRounds = 10,
    Random? random,
  }) : _random = random ?? Random();

  final Duration retryEvery;
  final Duration maxRetryEvery;
  final int maxRetryRounds;
  final Random _random;
  final Map<String, _Removal> _removals = {};
  final Set<String> _running = {};
  Timer? _timer;

  /// Set while the server's last wait has not passed.
  Timer? _rateLimit;
  bool _disposed = false;
  int _retryRounds = 0;

  /// The longest wait a server asked for since the last round; used for the
  /// next one.
  Duration _serverDelay = Duration.zero;

  /// The accounts whose removal, or what follows it, is not done yet.
  @visibleForTesting
  Set<String> get failedIds => _removals.keys.toSet();

  /// True while the account [id] is not removed yet: its removal runs, or
  /// failed and is kept for a retry. [forget] drops the kept record, but a
  /// run that has already started stays pending until it settles. What follows
  /// a removal (settling) does not count, except for that forgotten run.
  bool isPending(String id) =>
      (_running.contains(id) && !_removals.containsKey(id)) ||
      !(_removals[id]?.removed ?? true);

  /// Runs the steps for [id], or the ones that are left when [id] was started
  /// before. A second call while one runs is ignored. A removal that is new
  /// starts the count of background retries; one that is kept already does
  /// not, and waits for the server's last wait. Read [isPending] to know
  /// whether the account is removed.
  Future<void> remove(String id, RemovalSteps steps, ReportFailure report) {
    if (_removals.containsKey(id)) {
      if (_serverAskedToWait) return Future.value();
    } else {
      _retryRounds = 0;
    }
    return _remove(id, steps, report);
  }

  /// True while the last wait the server asked for has not passed. The one
  /// gate of every try that repeats a kept removal on demand.
  bool get _serverAskedToWait => _rateLimit != null;

  Future<void> _remove(
    String id,
    RemovalSteps steps,
    ReportFailure report,
  ) async {
    if (!_running.add(id)) return;
    final kept = _removals[id];
    if (kept != null && !identical(kept.steps, steps)) {
      Logs().w('The removal of $id is kept: the new steps are ignored');
    }
    final removal = _removals.putIfAbsent(id, () => _Removal(steps, report));
    try {
      await _run(id, removal);
    } finally {
      _running.remove(id);
    }
    if (!removal.done) _schedule();
  }

  Future<void> _run(String id, _Removal removal) async {
    if (!removal.removed) {
      removal.removed = await _attempt(
        removal,
        removal.steps.remove,
        'cannot remove logged-out account $id',
      );
    }
    if (!removal.removed) {
      if (!removal.held) {
        removal.held = await _attempt(
          removal,
          removal.steps.hold,
          'cannot hold account $id as unavailable',
        );
      }
      if (removal.held) await _afterChange(id, removal);
      return;
    }
    await _afterChange(id, removal);
    if (removal.done) _removals.remove(id);
    if (_removals.isEmpty) {
      _retryRounds = 0;
      _serverDelay = Duration.zero;
    }
  }

  /// The account list changed (held or removed): the effects first, because
  /// the user waits for them, then the record of a hold.
  Future<void> _afterChange(String id, _Removal removal) async {
    final settleNow = removal.removed || removal.steps.settleOnHold;
    if (settleNow && !removal.settled) {
      removal.settled = await _attempt(
        removal,
        removal.steps.settle,
        'after the change of account $id',
      );
    }
    final persist = removal.steps.persist;
    if (persist != null && !removal.removed && !removal.persisted) {
      removal.persisted = await _attempt(
        removal,
        persist,
        'cannot record the pending removal of account $id',
      );
    }
  }

  Future<bool> _attempt(
    _Removal removal,
    Future<void> Function() step,
    String what,
  ) async {
    try {
      await step();
      return true;
    } catch (error, stackTrace) {
      final asked = _delayAskedBy(error);
      _serverDelay = _longer(_serverDelay, asked);
      _holdOffFor(asked);
      if (removal.reported.add(what)) {
        removal.report(error, stackTrace, what);
      } else {
        Logs().w('Still failing: $what', error, stackTrace);
      }
      return false;
    }
  }

  /// The wait a Matrix rate limit (`M_LIMIT_EXCEEDED`) asked for: the
  /// `Retry-After` header in seconds, else the deprecated `retry_after_ms` of
  /// the body. Null for any other error, or when the server gave none.
  Duration? _delayAskedBy(Object error) {
    if (error is! MatrixException ||
        error.error != MatrixError.M_LIMIT_EXCEEDED) {
      return null;
    }
    final seconds = int.tryParse(error.response?.headers['retry-after'] ?? '');
    if (seconds != null && seconds >= 0) return Duration(seconds: seconds);
    final millis = error.retryAfterMs;
    return millis == null || millis < 0 ? null : Duration(milliseconds: millis);
  }

  /// Drops the kept removal of [id], if any, so that the next [remove] runs
  /// new steps (a new session opened for that account). A run in progress is
  /// not stopped, but it is not retried. Returns true when one was kept.
  bool forget(String id) {
    final forgotten = _removals.remove(id) != null;
    if (_removals.isEmpty) {
      _retryRounds = 0;
      _serverDelay = Duration.zero;
      _timer?.cancel();
      _timer = null;
      _rateLimit?.cancel();
      _rateLimit = null;
    }
    return forgotten;
  }

  /// Runs again every removal that is not done, once. It does not start the
  /// count of background retries again, and does nothing while the server's
  /// last wait (`Retry-After`) has not passed: it returns at once, and
  /// [isPending] still tells what is left.
  Future<void> retryAll() {
    if (_serverAskedToWait) return Future.value();
    return _retryEach();
  }

  /// The server asked for a wait: [retryAll] stays quiet until it passed. A
  /// later ask replaces an earlier one, as the server's newest word.
  void _holdOffFor(Duration? asked) {
    if (asked == null || _disposed) return;
    _rateLimit?.cancel();
    _rateLimit = Timer(asked, () => _rateLimit = null);
  }

  Future<void> _retryEach() async {
    for (final id in _removals.keys.toList()) {
      final removal = _removals[id];
      // Another call may have finished it while the ones before ran.
      if (removal == null) continue;
      await _remove(id, removal.steps, removal.report);
    }
  }

  void _schedule() {
    if (_disposed || _timer != null) return;
    if (_retryRounds >= maxRetryRounds) {
      Logs().w(
        'The removals are not retried in the background any more, '
        'after $_retryRounds rounds: ${_removals.keys.join(', ')}',
      );
      return;
    }
    _timer = Timer(_nextDelay(), () {
      _timer = null;
      _retryRounds++;
      unawaited(_retryEach());
    });
  }

  Duration _nextDelay() {
    final doubled = retryEvery * (1 << min(_retryRounds, 10));
    final ceiling = doubled > maxRetryEvery ? maxRetryEvery : doubled;
    final spread = ceiling * _random.nextDouble();
    final asked = _serverDelay;
    _serverDelay = Duration.zero;
    return _longer(spread, asked);
  }

  static Duration _longer(Duration a, Duration? b) =>
      b != null && b > a ? b : a;

  /// Stops the background retries.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _rateLimit?.cancel();
    _rateLimit = null;
  }
}

class _Removal {
  _Removal(this.steps, this.report);

  final RemovalSteps steps;
  final ReportFailure report;
  bool removed = false;
  bool held = false;
  bool persisted = false;
  bool settled = false;

  /// The steps that were reported already; their next failures are logged.
  final Set<String> reported = {};

  /// Nothing is left to run: removed and settled.
  bool get done => removed && settled;
}
