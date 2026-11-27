import 'package:matrix/matrix.dart';

abstract final class CallEventTypes {
  static const String callMember = 'org.matrix.msc3401.call.member';
  static const String callNotify = 'org.matrix.msc4075.call.notify';
  static const String callDecline = 'org.matrix.msc4310.rtc.decline';
  static const String callDeclineStable = 'm.rtc.decline';

  /// Marks the message that opens the thread of a call, as Twake Space Chat
  /// sends it when a call starts.
  static const String callThreadKey = 'app.twake.chat.call_thread';

  /// The line a caller writes when leaving a call it rang (DECISION.md D31).
  static const String callLine = 'app.twake.chat.call';

  static const _prefixes = ['m.call.', 'org.matrix.call.', 'com.famedly.call.'];

  /// Call signalling and MatrixRTC events, legacy ones included.
  static bool isCallEvent(String type) =>
      type == callMember ||
      type == RtcNotificationContent.eventType ||
      type == callNotify ||
      type == callDecline ||
      type == callDeclineStable ||
      _prefixes.any(type.startsWith);
}
