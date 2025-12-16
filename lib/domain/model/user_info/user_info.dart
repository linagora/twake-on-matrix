import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_info.g.dart';

@JsonSerializable(includeIfNull: false)
class UserInfo extends Equatable {
  final String? uid;
  @JsonKey(name: 'display_name')
  final String? displayName;
  @JsonKey(name: 'avatar')
  final String? avatarUrl;
  final List<String>? phones;
  final List<String>? emails;
  final String? sn;
  final String? givenName;
  final String? language;
  final String? timezone;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? workplaceFqdn;

  const UserInfo({
    this.uid,
    this.displayName,
    this.avatarUrl,
    this.phones,
    this.emails,
    this.sn,
    this.givenName,
    this.language,
    this.timezone,
    this.firstName,
    this.lastName,
    this.workplaceFqdn,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) =>
      _$UserInfoFromJson(json);

  Map<String, dynamic> toJson() => _$UserInfoToJson(this);

  @override
  List<Object?> get props => [
    uid,
    displayName,
    avatarUrl,
    phones,
    emails,
    sn,
    givenName,
    language,
    timezone,
    firstName,
    lastName,
    workplaceFqdn,
  ];
}
