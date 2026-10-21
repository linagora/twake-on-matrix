import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/chat/events/message_content.dart';

/// The newest message bubble containing [child], i.e. the lowest one on
/// screen. Returns an empty finder when no bubble matches yet.
PatrolFinder lastMessageContaining(PatrolIntegrationTester $, Finder child) {
  final bubbles = $(MessageContent).containing(child);
  final count = bubbles.evaluate().length;
  var lastIndex = 0;
  var lastBottom = double.negativeInfinity;
  for (var index = 0; index < count; index++) {
    final bottom = $.tester.getRect(bubbles.at(index)).bottom;
    if (bottom > lastBottom) {
      lastBottom = bottom;
      lastIndex = index;
    }
  }
  return count == 0 ? bubbles : bubbles.at(lastIndex);
}
