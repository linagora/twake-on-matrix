import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat/events/message/message.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../robots/send_text_message_robot.dart';
import 'login_scenario.dart';

class SendTextMessageScenario extends BaseScenario {
  LoginScenario loginScenario;
  SendTextMessageScenario(
    super.$, {
    required this.loginScenario,
  });

  @override
  Future<void> execute() async {
    final SendTextMessageRobot sendTextMessageRobot = SendTextMessageRobot($);
    await loginScenario.execute();
    await $.pumpAndSettle();
    await $.tap($(ChatListItem));
    await $.waitUntilVisible($(ChatView));
    final messagesCount = $(ListView).$(Message).evaluate().length;
    await sendTextMessageRobot.enterTextMessage('Hello World');
    await sendTextMessageRobot.tapOnSendButton();
    await $.pumpAndSettle();
    await Future.delayed(const Duration(seconds: 5));
    final messagesCountAfterSending = $(ListView).$(Message).evaluate().length;
    expect(messagesCountAfterSending, messagesCount + 1);
  }
}
