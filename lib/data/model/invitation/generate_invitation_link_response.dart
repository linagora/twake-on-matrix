import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generate_invitation_link_response.g.dart';

@JsonSerializable()
class GenerateInvitationLinkResponse with EquatableMixin {
  @JsonKey(name: "link")
  final String link;
  @JsonKey(name: "id")
  final String id;

  GenerateInvitationLinkResponse({required this.link, required this.id});

  factory GenerateInvitationLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateInvitationLinkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateInvitationLinkResponseToJson(this);

  @override
  List<Object?> get props => [link, id];
}
