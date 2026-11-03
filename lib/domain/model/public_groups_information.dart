// ignore_for_file: invalid_annotation_target

import 'package:freezed_annotation/freezed_annotation.dart';

part 'public_groups_information.freezed.dart';
part 'public_groups_information.g.dart';

@freezed
abstract class PublicGroupsInformation with _$PublicGroupsInformation {
  const factory PublicGroupsInformation({
    @JsonKey(name: 'enabled') bool? isEnabled,
  }) = _PublicGroupsInformation;

  factory PublicGroupsInformation.fromJson(Map<String, dynamic> json) =>
      _$PublicGroupsInformationFromJson(json);
}
