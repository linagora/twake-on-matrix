// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:twake_chat/domain/model/common_settings_information.dart';

part 'app_twake_information.freezed.dart';
part 'app_twake_information.g.dart';

@freezed
abstract class AppTwakeInformation with _$AppTwakeInformation {
  static const String appTwakeInformationKey = 'app.twake.chat';

  static const String supportContactKey = 'support_contact';

  const factory AppTwakeInformation({
    @JsonKey(name: 'common_settings')
    CommonSettingsInformation? commonSettingsInformation,
    @JsonKey(name: 'enable_invitations') bool? isInvitationEnabled,
  }) = _AppTwakeInformation;

  factory AppTwakeInformation.fromJson(Map<String, dynamic> json) =>
      _$AppTwakeInformationFromJson(json);
}
