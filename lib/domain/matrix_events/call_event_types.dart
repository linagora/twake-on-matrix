abstract final class CallEventTypes {
  static const String callMember = 'org.matrix.msc3401.call.member';
  static const String rtcNotification = 'org.matrix.msc4075.rtc.notification';
  static const String callNotify = 'org.matrix.msc4075.call.notify';

  /// Marks the message that opens the thread of a call, as Twake Space Chat
  /// sends it when a call starts.
  static const String callThreadKey = 'app.twake.chat.call_thread';
}
