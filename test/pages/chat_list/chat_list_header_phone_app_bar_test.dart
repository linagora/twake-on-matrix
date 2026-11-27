import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/avatar/avatar.dart';

import 'chat_list_header_test_harness.dart';

void main() {
  setUpHeaderTests();

  group('[ChatList] phone header without a search field', () {
    testWidgets('GIVEN a phone\n'
        'THEN the header has no search field', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.phone());

      expect(
        find.descendant(of: headerFinder, matching: find.byType(TextField)),
        findsNothing,
      );
    });

    testWidgets('GIVEN a wide screen\n'
        'THEN the header keeps its search field', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.wide());

      expect(
        find.descendant(of: headerFinder, matching: find.byType(TextField)),
        findsOneWidget,
      );
    });
  });

  // Settings stays a tab of the bottom bar; the avatar is another PR (#3829).
  group('[ChatList] phone app bar', () {
    testWidgets('GIVEN a phone\n'
        'THEN the app bar has no avatar', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.phone(roomCount: 0));

      expect(
        find.descendant(of: headerFinder, matching: find.byType(Avatar)),
        findsNothing,
      );
    });
  });
}
