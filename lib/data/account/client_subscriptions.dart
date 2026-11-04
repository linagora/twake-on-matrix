import 'dart:async';

import 'package:matrix/matrix.dart' show Logs;

/// Cancels one subscription.
typedef CancelSubscription = Future<void> Function();

/// The subscriptions the app keeps for each client, by client name and kind.
///
/// A name accepts subscriptions between [open] and [cancel]. One that is
/// started after the cancel (a set-up that was still waiting when a login was
/// rolled back, say) is not started, so nothing outlives the client it listens
/// to.
class ClientSubscriptions {
  final Map<String, Map<String, CancelSubscription>> _byClient = {};
  final Set<String> _open = {};

  /// Cancels that failed or did not run yet, by client name.
  final Map<String, List<CancelSubscription>> _unfinished = {};

  /// Starts accepting subscriptions for [name]. Calling it again changes
  /// nothing.
  void open(String name) => _open.add(name);

  bool isOpen(String name) => _open.contains(name);

  /// Starts the subscription of kind [key] for [name] with [listen], which
  /// returns how to cancel it. Does nothing when [name] is not open or already
  /// has one of that kind.
  void keep(String name, String key, CancelSubscription Function() listen) {
    if (!_open.contains(name)) return;
    _byClient.putIfAbsent(name, () => {}).putIfAbsent(key, listen);
  }

  /// Waits for the first event of [trigger] and then runs [action], unless
  /// [name] was closed meanwhile. The wait is a subscription of kind [key]: it
  /// is cancelled with the others, so a trigger that never comes leaves nothing
  /// behind. Does nothing when [name] is not open or already has one of that
  /// kind.
  void keepOnce(
    String name,
    String key,
    Stream<Object?> trigger,
    Future<void> Function() action,
  ) => keep(
    name,
    key,
    () => trigger.take(1).listen((_) {
      if (isOpen(name)) unawaited(_runLogged(name, key, action));
    }).cancel,
  );

  /// A failing action is logged: nobody awaits it, so it would otherwise end
  /// as an uncaught error.
  Future<void> _runLogged(
    String name,
    String key,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error, stackTrace) {
      Logs().e('ClientSubscriptions: $key of $name failed', error, stackTrace);
    }
  }

  /// Runs [setUp] when [name] is open and, when [name] was closed while it
  /// ran, [undo] right after: a set-up that outlives its client is torn down.
  Future<void> runGuarded(
    String name, {
    required Future<void> Function() setUp,
    required Future<void> Function() undo,
  }) async {
    if (!isOpen(name)) return;
    try {
      await setUp();
    } catch (_) {
      // Half done: what was set up before the failure is undone too.
      if (!isOpen(name)) await _undoLogged(name, undo);
      rethrow;
    }
    if (!isOpen(name)) await undo();
  }

  Future<void> _undoLogged(String name, Future<void> Function() undo) async {
    try {
      await undo();
    } catch (error, stackTrace) {
      Logs().w('ClientSubscriptions: undo of $name failed', error, stackTrace);
    }
  }

  /// Stops accepting subscriptions for [name] and cancels what it has. The
  /// entries are taken off before the first await, so what a re-login keeps
  /// meanwhile, of any kind, is tracked on its own. A cancel that fails stops
  /// the run and is thrown; it and the ones not yet run are kept, so calling it
  /// again finishes the job.
  Future<void> cancel(String name) async {
    _open.remove(name);
    final pending = [
      ...?_unfinished.remove(name),
      ...?_byClient.remove(name)?.values,
    ];
    for (var i = 0; i < pending.length; i++) {
      try {
        await pending[i]();
      } catch (_) {
        _unfinished.putIfAbsent(name, () => []).addAll(pending.skip(i));
        rethrow;
      }
    }
  }

  /// Cancels everything, for every client.
  Future<void> cancelAll() async {
    final names = {..._open, ..._byClient.keys, ..._unfinished.keys};
    await Future.wait([for (final name in names) cancel(name)]);
  }
}
