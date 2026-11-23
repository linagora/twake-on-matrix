/// The list `cacheExtent` raised while a jump or the unread opening mounts a
/// far row, and the value to restore once the last of them ends.
class JumpCacheExtent {
  static const double mountExtent = 20000;

  double? value;
  double? _baseline;
  bool _hasBaseline = false;

  void _captureBaselineIfNeeded() {
    if (_hasBaseline) return;
    _hasBaseline = true;
    _baseline = value;
  }

  bool _restore() {
    if (!_hasBaseline) return false;
    final changed = value != _baseline;
    value = _baseline;
    _baseline = null;
    _hasBaseline = false;
    return changed;
  }

  void startJump() => _captureBaselineIfNeeded();

  bool raiseForJump() {
    if (value == mountExtent) return false;
    value = mountExtent;
    return true;
  }

  bool endJump({required bool isLatest}) => isLatest && _restore();

  void startUnreadOpening() {
    _captureBaselineIfNeeded();
    value = mountExtent;
  }

  bool endUnreadOpening({required bool jumpInFlight}) =>
      !jumpInFlight && _restore();
}
