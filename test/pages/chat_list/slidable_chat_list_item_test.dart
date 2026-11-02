import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/chat_list/slidable_chat_list_item.dart';

import 'slidable_chat_list_item_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ChatListController>()])
void main() {
  Future<void> pump(WidgetTester tester, List<Widget> slidables) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlidableChatListItem(
              controller: MockChatListController(),
              slidables: slidables,
              chatListItem: const Text('row'),
            ),
          ),
        ),
      );

  group('SlidableChatListItem', () {
    testWidgets('withoutAction_showsTheRowAlone', (tester) async {
      await pump(tester, const []);

      expect(tester.takeException(), isNull);
      expect(find.text('row'), findsOneWidget);
      expect(find.byType(Slidable), findsNothing);
    });

    testWidgets('withActions_staysSlidable', (tester) async {
      await pump(tester, const [SizedBox()]);

      expect(find.text('row'), findsOneWidget);
      expect(find.byType(Slidable), findsOneWidget);
    });
  });
}
