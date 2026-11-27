import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/call/call_ring.dart';

part 'incoming_call_state.freezed.dart';

@freezed
sealed class IncomingCallState with _$IncomingCallState {
  const factory IncomingCallState.quiet() = IncomingCallQuiet;

  /// During another call the ring shows without its sound.
  const factory IncomingCallState.ringing({
    required CallRing ring,
    required bool isInCall,
  }) = IncomingCallRinging;
}
