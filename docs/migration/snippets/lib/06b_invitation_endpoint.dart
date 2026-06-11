// data/network/invitation/invitation_endpoint.dart

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:retrofit/retrofit.dart';

part '06b_invitation_endpoint.g.dart';

// --- Request models ---

@JsonSerializable()
class GenerateInvitationLinkRequest {
  @JsonKey(name: 'room_id')
  final String roomId;

  const GenerateInvitationLinkRequest({required this.roomId});

  factory GenerateInvitationLinkRequest.fromJson(Map<String, dynamic> json) =>
      _$GenerateInvitationLinkRequestFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GenerateInvitationLinkRequestToJson(this);
}

@JsonSerializable()
class SendInvitationRequest {
  @JsonKey(name: 'room_id')
  final String roomId;
  @JsonKey(name: 'target_user_id')
  final String targetUserId;

  const SendInvitationRequest({
    required this.roomId,
    required this.targetUserId,
  });

  factory SendInvitationRequest.fromJson(Map<String, dynamic> json) =>
      _$SendInvitationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendInvitationRequestToJson(this);
}

// --- Response models ---

@JsonSerializable()
class GenerateInvitationLinkResponse {
  @JsonKey(name: 'invitation_link')
  final String invitationLink;

  const GenerateInvitationLinkResponse({required this.invitationLink});

  factory GenerateInvitationLinkResponse.fromJson(Map<String, dynamic> json) =>
      _$GenerateInvitationLinkResponseFromJson(json);

  Map<String, dynamic> toJson() =>
      _$GenerateInvitationLinkResponseToJson(this);
}

// --- Endpoint ---

@RestApi()
abstract class InvitationEndpoint {
  factory InvitationEndpoint(Dio dio, {String baseUrl}) = _InvitationEndpoint;

  @POST('/_twake/v1/invite/generate')
  Future<GenerateInvitationLinkResponse> generateInvitationLink(
    @Body() GenerateInvitationLinkRequest request,
  );

  @POST('/_twake/v1/invite')
  Future<void> sendInvitation(
    @Body() SendInvitationRequest request,
  );
}
