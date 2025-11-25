import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../base/test_base.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'login successfully with correct user/pass',
    user: 'thhoang2',
    pass: '!Twake123',
    test: ($) async {
      expect($(ChatList).exists, isTrue);
    },
  );
}