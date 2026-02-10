import 'package:equatable/equatable.dart';
import 'package:fluffychat/data/hive/dto/contact/third_party_contact_hive_obj.dart';
import 'package:json_annotation/json_annotation.dart';

part 'contact_hive_obj.g.dart';

@JsonSerializable(explicitToJson: true)
class ContactHiveObj with EquatableMixin {
  final String id;

  final String? displayName;

  final Set<EmailHiveObject>? emails;

  final Set<PhoneNumberHiveObject>? phoneNumbers;

  ContactHiveObj({
    required this.id,
    this.displayName,
    required this.emails,
    required this.phoneNumbers,
  });

  factory ContactHiveObj.fromJson(Map<String, dynamic> json) =>
      _$ContactHiveObjFromJson(json);

  Map<String, dynamic> toJson() => _$ContactHiveObjToJson(this);

  @override
  List<Object?> get props => [id, displayName, emails, phoneNumbers];
}
