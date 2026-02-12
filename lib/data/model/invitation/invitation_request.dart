import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invitation_request.g.dart';

@JsonSerializable()
class InvitationRequest with EquatableMixin {
  @JsonKey(name: "contact")
  final String? contact;
  @JsonKey(name: "medium")
  final String? medium;

  InvitationRequest({this.contact, this.medium});

  factory InvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$InvitationRequestFromJson(json);

  Map<String, dynamic> toJson() => (contact == null && medium == null)
      ? {}
      : _$InvitationRequestToJson(this);

  @override
  List<Object?> get props => [contact, medium];
}
