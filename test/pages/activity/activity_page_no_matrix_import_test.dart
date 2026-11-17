import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Review of #3606 (activity_page.dart:52, nqhhdev): the CI check "Legacy
/// code does not grow" refuses a new import of package:matrix in a page. The
/// failures are logged below the page (use case), the page only catches.
void main() {
  test('the Activity page does not import package:matrix', () {
    final source = File(
      'lib/pages/activity/activity_page.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("package:matrix/")));
  });
}
