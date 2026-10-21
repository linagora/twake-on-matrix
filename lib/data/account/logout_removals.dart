import 'dart:async';

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
/// kept, and runs again with [retryAll] and in the background every
/// [retryEvery], until it works; until then the account stays listed.
class LogoutRemovals {
  LogoutRemovals({this.retryEvery = const Duration(minutes: 1)});

  final Duration retryEvery;
  final Map<String, _Removal> _removals = {};
  final Set<String> _running = {};
  Timer? _timer;
  bool _disposed = false;

  /// The accounts whose removal, or what follows it, is not done yet.
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
      removal.report(error, stackTrace, what);
      return false;
    }
  }

  /// Runs again every removal that is not done.
  Future<void> retryAll() async {
    for (final entry in _removals.entries.toList()) {
      await remove(entry.key, entry.value.steps, entry.value.report);
    }
  }

  void _schedule() {
    if (_disposed || _timer != null) return;
    _timer = Timer(retryEvery, () {
      _timer = null;
      unawaited(retryAll());
    });
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

  /// Nothing is left to run: removed and settled.
  bool get done => removed && settled;
}
