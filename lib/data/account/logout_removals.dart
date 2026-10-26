import 'dart:async';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:matrix/matrix.dart' show Logs;

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
/// until then the account stays listed. The background retries wait
/// [retryEvery], then twice as long after each round, up to [maxRetryEvery].
/// A step is reported on its first failure only; the retries are logged.
class LogoutRemovals {
  LogoutRemovals({
    this.retryEvery = const Duration(minutes: 1),
    this.maxRetryEvery = const Duration(minutes: 30),
  });

  final Duration retryEvery;
  final Duration maxRetryEvery;
  final Map<String, _Removal> _removals = {};
  final Set<String> _running = {};
  Timer? _timer;
  bool _disposed = false;
  int _retryRounds = 0;

  /// The accounts whose removal, or what follows it, is not done yet.
  @visibleForTesting
  Set<String> get failedIds => _removals.keys.toSet();

  /// Runs the steps for [id], or the ones that are left when [id] was started
  /// before. Returns true when the account was removed (what follows it may
  /// still be waiting for a retry). A second call while one runs is ignored.
  Future<bool> remove(
    String id,
    RemovalSteps steps,
    ReportFailure report,
  ) async {
    if (!_running.add(id)) return false;
    final kept = _removals[id];
    if (kept == null) {
      _retryRounds = 0;
    } else if (!identical(kept.steps, steps)) {
      Logs().w('The removal of $id is kept: the new steps are ignored');
    }
    final removal = _removals.putIfAbsent(id, () => _Removal(steps, report));
    try {
      await _run(id, removal);
    } finally {
      _running.remove(id);
    }
    if (!removal.done) _schedule();
    return removal.removed;
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
    if (_removals.isEmpty) _retryRounds = 0;
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
      if (removal.reported.add(what)) {
        removal.report(error, stackTrace, what);
      } else {
        Logs().w('Still failing: $what', error, stackTrace);
      }
      return false;
    }
  }

  /// Runs again every removal that is not done.
  Future<void> retryAll() async {
    for (final id in _removals.keys.toList()) {
      final removal = _removals[id];
      // Another call may have finished it while the ones before ran.
      if (removal == null) continue;
      await remove(id, removal.steps, removal.report);
    }
  }

  void _schedule() {
    if (_disposed || _timer != null) return;
    _timer = Timer(_nextDelay(), () {
      _timer = null;
      _retryRounds++;
      unawaited(retryAll());
    });
  }

  Duration _nextDelay() {
    final doubled = retryEvery * (1 << (_retryRounds < 10 ? _retryRounds : 10));
    return doubled > maxRetryEvery ? maxRetryEvery : doubled;
  }

  /// Stops the background retries.
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
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
