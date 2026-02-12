import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invitation_status_hive_obj.g.dart';

@JsonSerializable(explicitToJson: true)
class InvitationStatusHiveObj with EquatableMixin {
  final String invitationId;

  final String contactId;

  InvitationStatusHiveObj({
    required this.invitationId,
    required this.contactId,
  });

  factory InvitationStatusHiveObj.fromJson(Map<String, dynamic> json) =>
      _$InvitationStatusHiveObjFromJson(json);

  Map<String, dynamic> toJson() => _$InvitationStatusHiveObjToJson(this);

  @override
  List<Object?> get props => [invitationId, contactId];
}
