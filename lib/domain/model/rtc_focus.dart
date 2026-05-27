import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rtc_focus.g.dart';

@JsonSerializable()
class RtcFocus with EquatableMixin {
  static const String rtcFociKey = 'org.matrix.msc4143.rtc_foci';
  static const String liveKitType = 'livekit';

  final String? type;

  @JsonKey(name: 'livekit_base_url')
  final String? liveKitBaseUrl;

  RtcFocus({this.type, this.liveKitBaseUrl});

  bool get isLiveKit => type == liveKitType;

  factory RtcFocus.fromJson(Map<String, dynamic> json) =>
      _$RtcFocusFromJson(json);

  Map<String, dynamic> toJson() => _$RtcFocusToJson(this);

  @override
  List<Object?> get props => [type, liveKitBaseUrl];
}
