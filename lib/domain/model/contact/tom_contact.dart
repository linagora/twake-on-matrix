import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tom_contact.g.dart';

@JsonSerializable()
class TomContact with EquatableMixin {
  @JsonKey(name: "uid")
  final String uid;

  final String? mail;

  @JsonKey(name: "mobile")
  final String? phoneNumber;

  final String? address;

  @JsonKey(name: "cn")
  final String? cn;

  @JsonKey(name: "displayName")
  final String? rawDisplayName;

  String? get displayName => rawDisplayName ?? cn;

  const TomContact(
    this.uid, {
    this.mail,
    this.phoneNumber,
    this.address,
    this.cn,
    this.rawDisplayName,
  });

  @override
  List<Object?> get props => [uid, mail, phoneNumber, address];

  factory TomContact.fromJson(Map<String, dynamic> json) =>
      _$TomContactFromJson(json);

  Map<String, dynamic> toJson() => _$TomContactToJson(this);
}
