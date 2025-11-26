import 'package:fluffychat/widgets/twake_components/twake_navigation_icon/twake_navigation_icon.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../base/test_base.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'login successfully with correct credential',
    user: 'thhoang2',
    pass: '!Twake123',
    test: ($) async {
      expect($(TwakeNavigationIcon).exists, isTrue);
    },
  );
}