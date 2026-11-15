import 'package:json_annotation/json_annotation.dart';
import 'package:twake_chat/domain/model/call/call_models.dart';

part 'call_member_content.g.dart';

/// How many times the membership lasts its [CallMemberContent.lifetime], from
/// when it was sent.
typedef MembershipExpiry = ({int count, int? createdTs});

/// The content of an `org.matrix.msc3401.call.member` state event, as Twake
/// Space Chat writes it (DECISION.md D14). Only the device is read back.
@JsonSerializable(includeIfNull: false)
class CallMemberContent {
  const CallMemberContent({
    this.deviceId,
    this.membershipId,
    this.expires,
    this.intent,
    this.fociPreferred,
    this.createdTs,
    this.application = 'm.call',
    this.callId = '',
    this.scope = 'm.room',
    this.focusActive = const {
      'type': 'livekit',
      'focus_selection': 'oldest_membership',
    },
  });

  factory CallMemberContent.forJoin(
    CallDevice device,
    CallJoin join, [
    MembershipExpiry expiry = firstExpiry,
  ]) => CallMemberContent(
    deviceId: device.deviceId,
    membershipId: '${device.userId}:${device.deviceId}',
    expires: lifetime.inMilliseconds * expiry.count,
    intent: join.isVideo ? 'video' : 'audio',
    fociPreferred: [
      {'type': 'livekit', 'livekit_service_url': join.serviceUrl},
    ],
    createdTs: expiry.createdTs,
  );

  factory CallMemberContent.fromJson(Map<String, dynamic> json) =>
      _$CallMemberContentFromJson(json);

  static const MembershipExpiry firstExpiry = (count: 1, createdTs: null);
  static const lifetime = Duration(hours: 4);

  @JsonKey(includeFromJson: false, includeToJson: true)
  final String application;

  @JsonKey(name: 'call_id', includeFromJson: false, includeToJson: true)
  final String callId;

  @JsonKey(includeFromJson: false, includeToJson: true)
  final String scope;

  @JsonKey(name: 'device_id', fromJson: _stringOrNull)
  final String? deviceId;

  @JsonKey(name: 'membershipID', includeFromJson: false, includeToJson: true)
  final String? membershipId;

  @JsonKey(includeFromJson: false, includeToJson: true)
  final int? expires;

  @JsonKey(name: 'm.call.intent', includeFromJson: false, includeToJson: true)
  final String? intent;

  @JsonKey(name: 'focus_active', includeFromJson: false, includeToJson: true)
  final Map<String, Object?> focusActive;

  @JsonKey(name: 'foci_preferred', includeFromJson: false, includeToJson: true)
  final List<Map<String, Object?>>? fociPreferred;

  @JsonKey(name: 'created_ts', includeFromJson: false, includeToJson: true)
  final int? createdTs;

  Map<String, dynamic> toJson() => _$CallMemberContentToJson(this);

  static String? _stringOrNull(Object? value) => value is String ? value : null;
}
