/// Shared by successive sessions because they write to the same local store.
class ContactMutationQueue {
  Future<void> _pending = Future<void>.value();

  Future<void> run(Future<void> Function() mutation) {
    final result = _pending.then((_) => mutation());
    // A failed write must reach its caller without blocking later clears.
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

/// Cancels further work without waiting for an already dispatched HTTP call.
class ContactSyncSession {
  ContactSyncSession(this._mutations);

  final ContactMutationQueue _mutations;
  bool _active = true;

  bool get isActive => _active;

  void invalidate() => _active = false;

  Future<void> mutate(Future<void> Function() mutation) =>
      _mutations.run(() async {
        if (isActive) await mutation();
      });
}
