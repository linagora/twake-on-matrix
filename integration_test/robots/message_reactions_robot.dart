import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/chat/events/message/message.dart';

import '../base/core_robot.dart';

/// Reactions shown under a message, matched by emoji text only so the checks
/// do not depend on the widget that renders the pill.
class MessageReactionsRobot extends CoreRobot {
  MessageReactionsRobot(super.$);

  PatrolFinder _message(String message) =>
      $(Message).containing(find.textContaining(message, findRichText: true));

  PatrolFinder _reaction(String message, String emoji) =>
      _message(message).$(find.text(emoji));

  Future<void> expectReactionUnder(String message, String emoji) async {
    await $.waitUntilVisible(
      _reaction(message, emoji),
      timeout: const Duration(seconds: 30),
    );
  }

  Future<void> expectNoReactionUnder(String message, String emoji) async {
    final bubble = _message(message);
    await $.waitUntilVisible(bubble, timeout: const Duration(seconds: 15));
    await waitUntilAbsent(
      $,
      _reaction(message, emoji),
      timeout: const Duration(seconds: 30),
    );
    expect(
      bubble.visible,
      isTrue,
      reason: '"$message" must be on screen to check its reactions',
    );
  }
}
