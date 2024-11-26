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

    group('Test highlight message and invitation', () {
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
          'WHEN has new message with mention\n'
          'AND highlight count is greater than zero\n'
          'AND pushRuleState is notify\n'
          'THEN color should be primary\n', (
        WidgetTester tester,
      ) async {
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
        when(room.highlightCount).thenReturn(1);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Theme.of(context).colorScheme.primary);
      });
    });

    group('Test room has new message', () {
      testWidgets(
          'WHEN notification count is zero\n'
          'AND pushRuleState is notify\n'
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
          'WHEN notification count is greater than zero\n'
          'AND pushRuleState is notify\n'
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
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be tertiary[30]\n', (
        WidgetTester tester,
      ) async {
        when(room.notificationCount).thenReturn(5);
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, LinagoraRefColors.material().tertiary[30]);
      });

      testWidgets(
          'WHEN has new message \n'
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be tertiary[30]\n', (
        WidgetTester tester,
      ) async {
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
        when(room.hasNewMessages).thenReturn(true);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, LinagoraRefColors.material().tertiary[30]);
      });
    });

    group('Test room is mark as unread', () {
      testWidgets(
          'WHEN marked unread for room\n'
          'AND pushRuleState is notify\n'
          'THEN color should be primary]\n', (
        WidgetTester tester,
      ) async {
        when(room.markedUnread).thenReturn(true);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Theme.of(context).colorScheme.primary);
      });

      testWidgets(
          'WHEN marked unread for room\n'
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be primary]\n', (
        WidgetTester tester,
      ) async {
        when(room.markedUnread).thenReturn(true);
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, LinagoraRefColors.material().tertiary[30]);
      });
    });
  });
}
