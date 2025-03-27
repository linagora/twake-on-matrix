import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'generate_invitation_link_response.g.dart';

@JsonSerializable()
class GenerateInvitationLinkResponse with EquatableMixin {
  @JsonKey(name: "link")
  final String? link;

  GenerateInvitationLinkResponse({
    this.link,
  });

  factory GenerateInvitationLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateInvitationLinkResponseFromJson(json);

  Map<String, dynamic> toJson() => _$GenerateInvitationLinkResponseToJson(this);

  @override
  List<Object?> get props => [
        link,
      ];
}
