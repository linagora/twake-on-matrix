import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/contact.dart';
import 'package:json_annotation/json_annotation.dart';

part 'third_party_contact_hive_obj.g.dart';

abstract class ThirdPartyContactHiveObj with EquatableMixin {
  const ThirdPartyContactHiveObj({
    required this.matrixId,
    required this.thirdPartyId,
    required this.thirdPartyIdType,
  });

  final String matrixId;

  final String thirdPartyId;

  final ThirdPartyIdType thirdPartyIdType;

  @override
  List<Object?> get props => [matrixId, thirdPartyId, thirdPartyIdType];
}

@JsonSerializable(explicitToJson: true)
class PhoneNumberHiveObject extends ThirdPartyContactHiveObj {
  final String number;

  PhoneNumberHiveObject({required this.number, required super.matrixId})
    : super(thirdPartyId: number, thirdPartyIdType: ThirdPartyIdType.msisdn);

  factory PhoneNumberHiveObject.fromJson(Map<String, dynamic> json) =>
      _$PhoneNumberHiveObjectFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneNumberHiveObjectToJson(this);

  @override
  List<Object?> get props => [number, matrixId, thirdPartyId, thirdPartyIdType];
}

@JsonSerializable(explicitToJson: true)
class EmailHiveObject extends ThirdPartyContactHiveObj {
  final String email;

  EmailHiveObject({required this.email, required super.matrixId})
    : super(thirdPartyId: email, thirdPartyIdType: ThirdPartyIdType.email);

  factory EmailHiveObject.fromJson(Map<String, dynamic> json) =>
      _$EmailHiveObjectFromJson(json);

  Map<String, dynamic> toJson() => _$EmailHiveObjectToJson(this);

  @override
  List<Object?> get props => [email, matrixId, thirdPartyId, thirdPartyIdType];
}
