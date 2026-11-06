import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/model/thread/thread_relation_extension.dart';

abstract final class ThreadRules {
  static bool canStartThread(
    Event event, {
    required bool hasThread,
    bool inThreadScreen = false,
  }) =>
      !hasThread &&
      !inThreadScreen &&
      event.room.canSendDefaultMessages &&
      event.type != EventTypes.Encrypted &&
      event.threadRootId == null;

  static bool shouldScrollToBottomOnNewReply({
    required bool isOwnReply,
    required bool isAtBottom,
  }) => isOwnReply || isAtBottom;
}
