import 'dart:convert';
import 'dart:developer';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/message_robot.dart';

class MessageScenario extends BaseScenario {
  MessageScenario(super.$);

  Future<void> openAGroupChatByAPI(String groupID) async {
    final client = await MessageRobot($).initialRedirectRequest();
    await MessageRobot($).loginByAPI(client);
    await MessageRobot($).openGroupChatByAPI(client, groupID);
    await MessageRobot($).closeClient(client);
  }

  Future<void> sendAMessageByAPI(String groupID, String message) async {
    final client = await MessageRobot($).initialRedirectRequest();
    final list = await MessageRobot($).loginByAPI(client);
    await MessageRobot($).sendMessageByAPI(list[0], list[1], list[2], groupID, message);
    await MessageRobot($).closeClient(client);
  }

  Future<void> verifyMessageIsSentByAPI(String message) async {
    //get all message
    final client = await MessageRobot($).initialRedirectRequest();
    final list = await MessageRobot($).loginByAPI(client);
    final responseBody = await MessageRobot($).getAllSentMessage(client, list[1]);
    await MessageRobot($).closeClient(client);
    //verify response of that message contains expected message
    final jsonData = json.decode(responseBody);

    final events = jsonData['rooms']?['join']?.values
        .expand((room) => room['timeline']?['events'] ?? [])
        .toList();

    final containsHayNhi = events.any((event) =>
        event['type'] == 'm.room.message' &&
        event['content']?['body']?.toString().toLowerCase() == 'hay nhi',);

    if (containsHayNhi) {
      log('✅ Message "Hay nhi" is found!');
    } else {
      log('❌ Message "Hay nhi" not found.');
    }
  }

  Future<void> verifyMessageIsReadByAPI(String message) async {
    
  }

  Future<void> verifyMessageIsShown(String message) async {
    final text = await ChatGroupDetailRobot($).getText(message);
    expect(text, findsOneWidget);
  }

  Future<void> sendAMesage(String message) async {
    // Find the TextField using its type or placeholder text
    final messageField = $(TextField); // Or use $(#input_message_id) if it has a key

    // Tap to focus the field
    await messageField.tap();

    // Enter the message
    await messageField.enterText(message);

    // tab on send button
    final sendBtn = $(ChatInputRowSendBtn);
    await sendBtn.tap();

    //xem co loaij text nao co  gia tri la kia dc hien len ko
    await Future.delayed(const Duration(seconds: 2)); 
  }
  @override
  Future<void> execute() {
    // TODO: implement execute
    throw UnimplementedError();
  }
  
}
