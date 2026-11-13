import 'package:freezed_annotation/freezed_annotation.dart';

part 'rtc_focus.freezed.dart';
part 'rtc_focus.g.dart';

@freezed
abstract class RtcFocus with _$RtcFocus {
  static const String rtcFociKey = 'org.matrix.msc4143.rtc_foci';
  static const String liveKitType = 'livekit';

  const RtcFocus._();

  const factory RtcFocus({
    String? type,
    @JsonKey(name: 'livekit_base_url') Uri? livekitBaseUrl,

    /// The MatrixRTC token service (MSC4195); older well-knowns only give the
    /// base url.
    @JsonKey(name: 'livekit_service_url') Uri? livekitServiceUrl,
  }) = _RtcFocus;

  bool get isLiveKit => type == liveKitType;

  factory RtcFocus.fromJson(Map<String, dynamic> json) =>
      _$RtcFocusFromJson(json);
}
