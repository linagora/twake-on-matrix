import '../base/test_base.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Checking sending message between members',
    test: ($) async {

      await TestBase().loginAndRun($, (_) async {
        
      });
    },
  );
}