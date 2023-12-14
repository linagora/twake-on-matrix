import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:matrix/matrix.dart';

mixin SearchDebouncerMixin {
  static const _debouncerIntervalInMilliseconds = 300;

  Debouncer<String>? _debouncer;

  void initializeDebouncer(void Function(String)? onDebouncerChanged) {
    _debouncer = Debouncer(
      const Duration(milliseconds: _debouncerIntervalInMilliseconds),
      initialValue: '',
    );

    _debouncer?.values.listen((keyword) async {
      Logs().d(
        "SearchDebouncerMixin::initializeDebouncer: $keyword",
      );
      onDebouncerChanged?.call(keyword);
    });
  }

  String get debouncerValue => _debouncer?.value ?? '';

  void setDebouncerValue(String keyword) {
    _debouncer?.value = keyword;
  }

  void disposeDebouncer() {
    _debouncer?.cancel();
  }
}
