import 'package:equatable/equatable.dart';
import 'package:fluffychat/domain/model/contact/tom_contact.dart';
import 'package:json_annotation/json_annotation.dart';

part 'lookup_mxid_response.g.dart';

@JsonSerializable()
class LookupMxidResponse with EquatableMixin {
  @JsonKey(name: "matches")
  final Set<TomContact> contacts;

  @JsonKey(name: "inactive_matches")
  final Set<TomContact> inactiveContacts;

  LookupMxidResponse({
    required this.contacts,
    required this.inactiveContacts,
  });

  @override
  List<Object?> get props => [contacts, inactiveContacts];

  factory LookupMxidResponse.fromJson(Map<String, dynamic> json) =>
      _$LookupMxidResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LookupMxidResponseToJson(this);
}
