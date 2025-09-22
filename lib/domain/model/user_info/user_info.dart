import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_info.g.dart';

@JsonSerializable(includeIfNull: false)
class UserInfo extends Equatable {
  final String? uid;
  final String? displayName;
  final String? avatarUrl;
  final List<String>? phones;
  final List<String>? mail;
  final String? sn;
  final String? givenName;
  final String? language;
  final String? timezone;

  const UserInfo({
    this.uid,
    this.displayName,
    this.avatarUrl,
    this.phones,
    this.mail,
    this.sn,
    this.givenName,
    this.language,
    this.timezone,
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
        mail,
        sn,
        givenName,
        language,
        timezone,
      ];
}
