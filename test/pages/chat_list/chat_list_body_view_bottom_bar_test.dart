import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat_list/slidable_chat_list_item.dart';

import 'chat_list_header_test_harness.dart';

void main() {
  setUpHeaderTests();

  testWidgets('GIVEN a bottom bar floating over the list\n'
      'WHEN the list is scrolled to its end\n'
      'THEN the last room ends above the bar', (tester) async {
    final h = await HeaderHarness.pump(
      tester,
      const HeaderView(bottomBarHeight: 80),
    );

    h.scroll.jumpTo(h.scroll.position.maxScrollExtent);
    await tester.pumpAndSettle();

    final lastRow = tester.getRect(find.byType(SlidableChatListItem).last);
    final bar = tester.getRect(find.byKey(bottomBarKey));
    expect(lastRow.bottom, lessThanOrEqualTo(bar.top));
  });
}
