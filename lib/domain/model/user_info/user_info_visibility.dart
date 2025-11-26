import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';

part 'user_info_visibility.g.dart';

enum VisibleEnum {
  email,
  phone;

  String title(BuildContext context) {
    switch (this) {
      case VisibleEnum.phone:
        return L10n.of(context)!.phone;
      case VisibleEnum.email:
        return L10n.of(context)!.email;
    }
  }

  String subtitle(BuildContext context) {
    switch (this) {
      case VisibleEnum.phone:
        return L10n.of(context)!.youNumberIsVisibleAccordingToTheSettingAbove;
      case VisibleEnum.email:
        return L10n.of(context)!.youEmailIsVisibleAccordingToTheSettingAbove;
    }
  }

  bool enableDivider() {
    switch (this) {
      case VisibleEnum.phone:
        return true;
      case VisibleEnum.email:
        return false;
    }
  }
}

@JsonSerializable()
class UserInfoVisibility with EquatableMixin {
  @JsonKey(name: "matrix_id")
  final String? matrixId;
  @JsonKey(name: "visibility")
  final String? visibility;
  @JsonKey(name: "visible_fields")
  final List<VisibleEnum>? visibleFields;

  UserInfoVisibility({
    this.matrixId,
    this.visibility,
    this.visibleFields,
  });

  factory UserInfoVisibility.fromJson(Map<String, dynamic> json) =>
      _$UserInfoVisibilityFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoVisibilityToJson(this);

  @override
  List<Object?> get props => [
        matrixId,
        visibility,
        visibleFields,
      ];
}
