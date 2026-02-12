import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'common_settings_information.g.dart';

@JsonSerializable()
class CommonSettingsInformation with EquatableMixin {
  bool? enabled;

  @JsonKey(name: "application_url")
  String? applicationUrl;

  CommonSettingsInformation({this.enabled, this.applicationUrl});

  factory CommonSettingsInformation.fromJson(Map<String, dynamic> json) =>
      _$CommonSettingsInformationFromJson(json);

  Map<String, dynamic> toJson() => _$CommonSettingsInformationToJson(this);

  @override
  List<Object?> get props => [enabled, applicationUrl];
}
