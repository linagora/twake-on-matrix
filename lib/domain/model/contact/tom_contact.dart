import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'tom_contact.g.dart';

@JsonSerializable()
class TomContact with EquatableMixin {

  @JsonKey(name: "uid")
  final String mxid;

  final String? mail;

  @JsonKey(name: "mobile")
  final String? phoneNumber;

  const TomContact(
    this.mxid, {
    this.mail,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [mxid, mail, phoneNumber];

  factory TomContact.fromJson(Map<String, dynamic> json) 
    => _$TomContactFromJson(json);

  Map<String, dynamic> toJson() => _$TomContactToJson(this);
}