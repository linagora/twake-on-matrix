import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'send_invitation_response.g.dart';

@JsonSerializable()
class SendInvitationResponse with EquatableMixin {
  @JsonKey(name: "message")
  final String? message;
  @JsonKey(name: "id")
  final String? id;

  SendInvitationResponse({this.message, this.id});

  factory SendInvitationResponse.fromJson(Map<String, dynamic> json) =>
      _$SendInvitationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SendInvitationResponseToJson(this);

  @override
  List<Object?> get props => [message, id];
}
