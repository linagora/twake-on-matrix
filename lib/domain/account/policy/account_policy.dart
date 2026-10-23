/// Account selection rules. They see ids only, never a `Client`.
class AccountPolicy {
  const AccountPolicy();

  /// The account that follows [removedId] in store order, else the one before
  /// it; null when no other account remains or [removedId] is unknown.
  String? nextActiveAfterRemoving({
    required List<String> ids,
    required String removedId,
  }) {
    final index = ids.indexOf(removedId);
    if (index == -1) return null;
    final remaining = [...ids]..removeAt(index);
    if (remaining.isEmpty) return null;
    return index < remaining.length ? remaining[index] : remaining.last;
  }

  /// The persisted account when it is logged in, else the first logged-in
  /// one by store order; null when nobody is logged in.
  String? selectInitialActive({
    required List<String> loggedInIds,
    required String? persistedId,
  }) {
    if (loggedInIds.isEmpty) return null;
    if (persistedId != null && loggedInIds.contains(persistedId)) {
      return persistedId;
    }
    return loggedInIds.first;
  }
}
