import 'package:fluffychat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chat_list_item_mixin_test.mocks.dart';

class ChatListItemMixinTest with ChatListItemMixin {}

@GenerateNiceMocks([
  MockSpec<BuildContext>(),
  MockSpec<Room>(),
])
void main() {
  group('notificationColor Test', () {
    late Room room;
    late BuildContext context;
    late ChatListItemMixinTest chatListItemMixinTest;

    setUp(() {
      room = MockRoom();
      context = MockBuildContext();
      chatListItemMixinTest = ChatListItemMixinTest();
    });

    testWidgets(
        'WHEN notification count is zero\n'
        'AND room is unmuted\n'
        'THEN color should have transparent\n', (
      WidgetTester tester,
    ) async {
      when(room.notificationCount).thenReturn(0);
      when(room.pushRuleState).thenReturn(PushRuleState.notify);

      final color = chatListItemMixinTest.notificationColor(
        context: context,
        room: room,
      );

      expect(color, Colors.transparent);
    });

    testWidgets(
        'WHEN group is invite\n'
        'THEN color should have color primary\n', (
      WidgetTester tester,
    ) async {
      when(room.membership).thenReturn(Membership.invite);

      final color = chatListItemMixinTest.notificationColor(
        context: context,
        room: room,
      );

      expect(color, Theme.of(context).colorScheme.primary);
    });

    testWidgets(
        'WHEN notification count is greater than zero\n'
        'AND room is unmuted\n'
        'THEN color should be primary\n', (
      WidgetTester tester,
    ) async {
      when(room.notificationCount).thenReturn(5);
      when(room.pushRuleState).thenReturn(PushRuleState.notify);

      final color = chatListItemMixinTest.notificationColor(
        context: context,
        room: room,
      );

      expect(color, Theme.of(context).colorScheme.primary);
    });

    testWidgets(
        'WHEN notification count is greater than zero\n'
        'AND room is muted\n'
        'THEN color should be tertiary[30]\n', (
      WidgetTester tester,
    ) async {
      when(room.notificationCount).thenReturn(5);
      when(room.pushRuleState).thenReturn(PushRuleState.dontNotify);

      final color = chatListItemMixinTest.notificationColor(
        context: context,
        room: room,
      );

      expect(color, LinagoraRefColors.material().tertiary[30]);
    });

    testWidgets(
        'WHEN marked unread for room\n'
        'THEN color should be tertiary[30]\n', (
      WidgetTester tester,
    ) async {
      when(room.markedUnread).thenReturn(true);

      final color = chatListItemMixinTest.notificationColor(
        context: context,
        room: room,
      );

      expect(color, LinagoraRefColors.material().tertiary[30]);
    });
  });
}
