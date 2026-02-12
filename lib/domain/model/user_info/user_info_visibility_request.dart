import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_info_visibility_request.g.dart';

@JsonSerializable()
class UserInfoVisibilityRequest with EquatableMixin {
  @JsonKey(name: "visibility")
  final String? visibility;
  @JsonKey(name: "visible_fields")
  final List<VisibleEnum>? visibleFields;

  UserInfoVisibilityRequest({this.visibility, this.visibleFields});

  factory UserInfoVisibilityRequest.fromJson(Map<String, dynamic> json) =>
      _$UserInfoVisibilityRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoVisibilityRequestToJson(this);

  @override
  List<Object?> get props => [visibility, visibleFields];
}
