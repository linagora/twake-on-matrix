// Use SoftAssertHelper when you have multiple verifications in a test
// and you don’t want the script to stop at the first failure.
// Instead, all verification failures will be collected and reported
// after all steps of the script have been executed.

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
