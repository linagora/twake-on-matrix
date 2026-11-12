import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/presentation/mixins/chat_list_item_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../domain/usecase/room/send_text_message_interactor_test.mocks.dart'
    show MockClient;
import 'chat_list_item_mixin_test.mocks.dart';

class ChatListItemMixinTest with ChatListItemMixin {}

@GenerateNiceMocks([MockSpec<BuildContext>(), MockSpec<Room>()])
void main() {
  // This level is gated by the flag (off by default until #3609).
  late bool threadsFlagBefore;
  setUp(() {
    threadsFlagBefore = AppConfig.threadsEnabled;
    AppConfig.threadsEnabled = true;
  });
  tearDown(() => AppConfig.threadsEnabled = threadsFlagBefore);

  group('notificationColor Test', () {
    late Room room;
    late BuildContext context;
    late ChatListItemMixinTest chatListItemMixinTest;

    setUp(() {
      room = MockRoom();
      context = MockBuildContext();
      chatListItemMixinTest = ChatListItemMixinTest();
    });

    DateTime at(int minute) => DateTime.utc(2026, 11, 6, 10, minute);

    /// Bob's last message at 10:05; the user read the main timeline at
    /// [readAtMinute] (a threaded `main` receipt, as the app sends them).
    void lastMessageFromBob({required int readAtMinute}) {
      final client = MockClient();
      when(client.userID).thenReturn('@me:example.com');
      when(
        client.roomPreviewLastEvents,
      ).thenReturn({EventTypes.Message, EventTypes.Encrypted});
      when(room.client).thenReturn(client);
      when(room.lastEvent).thenReturn(
        Event(
          type: EventTypes.Message,
          content: {'msgtype': 'm.text', 'body': 'hello'},
          eventId: r'$last',
          senderId: '@bob:example.com',
          originServerTs: at(5),
          room: room,
        ),
      );
      final read = LatestReceiptStateData(
        r'$read',
        at(readAtMinute).millisecondsSinceEpoch,
      );
      when(room.receiptState).thenReturn(
        LatestReceiptState(
          global: LatestReceiptStateForTimeline.empty(),
          mainThread: LatestReceiptStateForTimeline(
            ownPrivate: null,
            ownPublic: read,
            latestOwnReceipt: read,
            otherUsers: {},
          ),
        ),
      );
    }

    group('Test highlight message and invitation', () {
      testWidgets('WHEN group is invite\n'
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

      testWidgets('WHEN has new message with mention\n'
          'AND highlight count is greater than zero\n'
          'AND pushRuleState is notify\n'
          'THEN color should be primary\n', (WidgetTester tester) async {
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
      testWidgets('WHEN notification count is zero\n'
          'AND pushRuleState is notify\n'
          'THEN color should have transparent\n', (WidgetTester tester) async {
        when(room.notificationCount).thenReturn(0);
        when(room.pushRuleState).thenReturn(PushRuleState.notify);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Colors.transparent);
      });

      testWidgets('WHEN notification count is greater than zero\n'
          'AND pushRuleState is notify\n'
          'THEN color should be primary\n', (WidgetTester tester) async {
        when(room.notificationCount).thenReturn(5);
        when(room.pushRuleState).thenReturn(PushRuleState.notify);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Theme.of(context).colorScheme.primary);
      });

      testWidgets('WHEN notification count is greater than zero\n'
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be tertiary[30]\n', (WidgetTester tester) async {
        when(room.notificationCount).thenReturn(5);
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, LinagoraRefColors.material().tertiary[30]);
      });

      testWidgets('WHEN has new message \n'
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be tertiary[30]\n', (WidgetTester tester) async {
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
        lastMessageFromBob(readAtMinute: 1);
        when(room.notificationCount).thenReturn(0);
        when(room.highlightCount).thenReturn(0);
        when(room.markedUnread).thenReturn(false);
        when(room.membership).thenReturn(Membership.join);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, LinagoraRefColors.material().tertiary[30]);
      });

      testWidgets('WHEN the last message is already read\n'
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be transparent\n', (WidgetTester tester) async {
        when(room.pushRuleState).thenReturn(PushRuleState.mentionsOnly);
        lastMessageFromBob(readAtMinute: 6);
        when(room.notificationCount).thenReturn(0);
        when(room.highlightCount).thenReturn(0);
        when(room.markedUnread).thenReturn(false);
        when(room.membership).thenReturn(Membership.join);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Colors.transparent);
      });

      testWidgets('WHEN has new message but no notification count\n'
          'AND pushRuleState is notify\n'
          'THEN color should be transparent (race condition)\n', (
        WidgetTester tester,
      ) async {
        when(room.pushRuleState).thenReturn(PushRuleState.notify);
        lastMessageFromBob(readAtMinute: 1);
        when(room.notificationCount).thenReturn(0);
        when(room.highlightCount).thenReturn(0);
        when(room.markedUnread).thenReturn(false);
        when(room.membership).thenReturn(Membership.join);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Colors.transparent);
      });
    });

    group('Test room is mark as unread', () {
      testWidgets('WHEN marked unread for room\n'
          'AND pushRuleState is notify\n'
          'THEN color should be primary]\n', (WidgetTester tester) async {
        when(room.markedUnread).thenReturn(true);

        final color = chatListItemMixinTest.notificationColor(
          context: context,
          room: room,
        );

        expect(color, Theme.of(context).colorScheme.primary);
      });

      testWidgets('WHEN marked unread for room\n'
          'AND pushRuleState is mentionsOnly\n'
          'THEN color should be primary]\n', (WidgetTester tester) async {
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
