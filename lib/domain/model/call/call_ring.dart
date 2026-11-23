import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

part 'call_ring.freezed.dart';

/// A call that rings for the account (MSC4075), until [expiresAt] or until it
/// is answered or declined.
@freezed
abstract class CallRing with _$CallRing {
  const factory CallRing({
    required String eventId,
    required CallRoom room,
    required String senderId,
    required bool isVideo,
    required DateTime expiresAt,
  }) = _CallRing;
}

/// A ring that lapsed without the account answering or declining it.
@freezed
abstract class MissedCall with _$MissedCall {
  const factory MissedCall({
    required String ringEventId,
    required CallRoom room,
    required String callerId,
    required DateTime sentAt,
    required bool isVideo,
  }) = _MissedCall;
}
