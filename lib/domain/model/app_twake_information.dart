import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/common_settings_information.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_twake_information.g.dart';

@JsonSerializable()
class AppTwakeInformation with EquatableMixin {
  static const String appTwakeInformationKey = 'app.twake.chat';

  @JsonKey(name: 'common_settings')
  CommonSettingsInformation? commonSettingsInformation;

  AppTwakeInformation({this.commonSettingsInformation});

  factory AppTwakeInformation.fromJson(Map<String, dynamic> json) =>
      _$AppTwakeInformationFromJson(json);

  Map<String, dynamic> toJson() => _$AppTwakeInformationToJson(this);

  @override
  List<Object?> get props => [commonSettingsInformation];
}
