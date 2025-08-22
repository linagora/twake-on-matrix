// soft_assert_helper.dart
class SoftAssertHelper {
  final List<String> _errors = [];

  void softAssertEquals(dynamic actual, dynamic expected, String message) {
    if (actual != expected) {
      _errors.add('$message — Expected: $expected, Actual: $actual');
    }
  }

  void verifyAll() {
  if (_errors.isNotEmpty) {
    final buffer = StringBuffer('❌ Soft assertions failed:\n');
    for (var i = 0; i < _errors.length; i++) {
      // Ensure each error is trimmed and placed on its own line
      buffer.writeln('${i + 1}. ${_errors[i].trim()}');
      }
    // Remove trailing newline and throw
    throw AssertionError(buffer.toString().trimRight());
    }
  }
}
