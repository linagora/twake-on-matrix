import 'dart:convert';
import 'dart:developer';
import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../base/core_robot.dart';
import '../robots/chat_group_detail_robot.dart';

class MessageScenario extends BaseScenario {
  MessageScenario(super.$);

  // Future<void> openAGroupChatByAPI(String groupID) async {
  //   final client = await CoreRobot($).initialRedirectRequest();
  //   await CoreRobot($).loginByAPI(client);
  //   await CoreRobot($).openGroupChatByAPI(client, groupID);
  //   await CoreRobot($).closeClient(client);
  // }

  // Future<void> sendAMessageByAPI(String groupID, String message) async {
  //   final client = await CoreRobot($).initialRedirectRequest();
  //   final list = await CoreRobot($).loginByAPI(client);
  //   await CoreRobot($).sendMessageByAPI(list[0], list[1], list[2], groupID, message);
  //   await CoreRobot($).closeClient(client);
  // }

  // Future<void> verifyMessageIsSentByAPI(String message) async {
  //   //get all message
  //   final client = await CoreRobot($).initialRedirectRequest();
  //   final list = await CoreRobot($).loginByAPI(client);
  //   final responseBody = await CoreRobot($).getAllSentMessage(client, list[1]);
  //   await CoreRobot($).closeClient(client);
  //   //verify response of that message contains expected message
  //   final jsonData = json.decode(responseBody);

  //   final events = jsonData['rooms']?['join']?.values
  //       .expand((room) => room['timeline']?['events'] ?? [])
  //       .toList();

  //   final containsMessage = events.any((event) =>
  //       event['type'] == 'm.room.message' &&
  //       event['content']?['body']?.toString().toLowerCase() == message,);

  //   if (containsMessage) {
  //     log('✅ Message $message is found!');
  //   } else {
  //     log('❌ Message $message not found.');
  //   }
  // }

  // Future<void> verifyMessageIsReadByAPI(String message) async {
    
  // }

  // Future<void> verifyMessageIsShown(String message) async {
  //   final text = await ChatGroupDetailRobot($).getText(message);
  //   expect(text, findsOneWidget);
  // }

  // Future<void> sendAMesage(String message) async {
  //   // Find the TextField using its type or placeholder text
  //   final messageField = $(TextField); // Or use $(#input_message_id) if it has a key

  //   // Tap to focus the field
  //   await messageField.tap();

  //   // Enter the message
  //   await messageField.enterText(message);

  //   // tab on send button
  //   final sendBtn = $(ChatInputRowSendBtn);
  //   await sendBtn.tap();

  //   //xem co loaij text nao co  gia tri la kia dc hien len ko
  //   await Future.delayed(const Duration(seconds: 2)); 
  // }
  @override
  Future<void> execute() {
    // TODO: implement execute
    throw UnimplementedError();
  }
  
}
