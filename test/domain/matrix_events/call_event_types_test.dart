import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/domain/matrix_events/call_event_types.dart';

void main() {
  test('call signalling and MatrixRTC events are call events', () {
    for (final type in [
      CallEventTypes.callMember,
      CallEventTypes.rtcNotification,
      CallEventTypes.callNotify,
      EventTypes.CallInvite,
      EventTypes.CallAnswer,
      EventTypes.CallHangup,
      EventTypes.CallCandidates,
      EventTypes.CallReject,
      EventTypes.CallSelectAnswer,
      EventTypes.CallNegotiate,
      EventTypes.GroupCallMember,
      'org.matrix.call.sdp_stream_metadata_changed',
    ]) {
      expect(CallEventTypes.isCallEvent(type), isTrue, reason: type);
    }
  });

  test('messages and room state are not call events', () {
    for (final type in [
      EventTypes.Message,
      EventTypes.Encrypted,
      EventTypes.RoomMember,
      'm.callback',
    ]) {
      expect(CallEventTypes.isCallEvent(type), isFalse, reason: type);
    }
  });
}
