import '../base/test_base.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Should see chat list after successful login',
    test: ($) async {
      await TestBase().loginAndRun($, (_) async {
      });
    },
  );
}
