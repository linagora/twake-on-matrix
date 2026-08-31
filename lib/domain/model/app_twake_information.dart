import 'package:equatable/equatable.dart';
import 'package:twake_chat/domain/model/common_settings_information.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_twake_information.g.dart';

@JsonSerializable()
class AppTwakeInformation with EquatableMixin {
  static const String appTwakeInformationKey = 'app.twake.chat';

  static const String supportContactKey = 'support_contact';

  @JsonKey(name: 'common_settings')
  CommonSettingsInformation? commonSettingsInformation;

  @JsonKey(name: 'enable_invitations')
  final bool? isInvitationEnabled;

  AppTwakeInformation({
    this.commonSettingsInformation,
    this.isInvitationEnabled,
  });

  factory AppTwakeInformation.fromJson(Map<String, dynamic> json) =>
      _$AppTwakeInformationFromJson(json);

  Map<String, dynamic> toJson() => _$AppTwakeInformationToJson(this);

  @override
  List<Object?> get props => [commonSettingsInformation, isInvitationEnabled];
}
