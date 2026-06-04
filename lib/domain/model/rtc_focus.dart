import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'rtc_focus.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class RtcFocus with EquatableMixin {
  static const String rtcFociKey = 'org.matrix.msc4143.rtc_foci';
  static const String liveKitType = 'livekit';

  final String? type;

  final Uri? livekitBaseUrl;

  RtcFocus({this.type, this.livekitBaseUrl});

  bool get isLiveKit => type == liveKitType;

  factory RtcFocus.fromJson(Map<String, dynamic> json) =>
      _$RtcFocusFromJson(json);

  Map<String, dynamic> toJson() => _$RtcFocusToJson(this);

  @override
  List<Object?> get props => [type, livekitBaseUrl];
}
