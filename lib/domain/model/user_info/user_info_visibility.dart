import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_info_visibility.g.dart';

enum VisibleEnum { email, phone }

@JsonSerializable()
class UserInfoVisibility with EquatableMixin {
  @JsonKey(name: "matrix_id")
  final String? matrixId;
  @JsonKey(name: "visibility")
  final String? visibility;
  @JsonKey(name: "visible_fields")
  final List<VisibleEnum>? visibleFields;

  UserInfoVisibility({this.matrixId, this.visibility, this.visibleFields});

  factory UserInfoVisibility.fromJson(Map<String, dynamic> json) =>
      _$UserInfoVisibilityFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoVisibilityToJson(this);

  @override
  List<Object?> get props => [matrixId, visibility, visibleFields];
}
