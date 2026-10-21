import 'dart:async';

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
      if (isOpen(name)) unawaited(action());
    }).cancel,
  );

  /// Runs [setUp] when [name] is open and, when [name] was closed while it
  /// ran, [undo] right after: a set-up that outlives its client is torn down.
  Future<void> runGuarded(
    String name, {
    required Future<void> Function() setUp,
    required Future<void> Function() undo,
  }) async {
    if (!isOpen(name)) return;
    await setUp();
    if (!isOpen(name)) await undo();
  }

  /// Stops accepting subscriptions for [name] and cancels what it has. A
  /// cancel that fails stops the run and is thrown; the subscriptions not yet
  /// cancelled stay, so calling it again finishes the job.
  Future<void> cancel(String name) async {
    _open.remove(name);
    final kept = _byClient[name];
    if (kept == null) return;
    for (final entry in kept.entries.toList()) {
      await entry.value();
      kept.remove(entry.key);
    }
    _byClient.remove(name);
  }

  /// Cancels everything, for every client.
  Future<void> cancelAll() async {
    final names = {..._open, ..._byClient.keys};
    await Future.wait([for (final name in names) cancel(name)]);
  }
}
