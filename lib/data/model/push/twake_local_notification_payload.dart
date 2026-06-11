import 'package:json_annotation/json_annotation.dart';

part 'twake_local_notification_payload.g.dart';

/// Payload attached to local notifications for routing on tap.
@JsonSerializable()
class TwakeLocalNotificationPayload {
  @JsonKey(name: 'room_id')
  final String? roomId;

  @JsonKey(name: 'receiver_id')
  final String? receiverId;

  @JsonKey(name: 'event_id')
  final String? eventId;

  const TwakeLocalNotificationPayload({
    this.roomId,
    this.receiverId,
    this.eventId,
  });

  factory TwakeLocalNotificationPayload.fromJson(Map<String, dynamic> json) =>
      _$TwakeLocalNotificationPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$TwakeLocalNotificationPayloadToJson(this);

  /// Returns an empty payload used as a safe fallback.
  factory TwakeLocalNotificationPayload.empty() =>
      const TwakeLocalNotificationPayload();
}
