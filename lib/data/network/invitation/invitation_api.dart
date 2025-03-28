import 'package:fluffychat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:fluffychat/data/model/invitation/invitation_request.dart';
import 'package:fluffychat/data/model/invitation/send_invitation_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/tom_endpoint.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';

class InvitationAPI {
  final DioClient _client = getIt.get<DioClient>(
    instanceName: NetworkDI.tomDioClientName,
  );

  Future<SendInvitationResponse> sendInvitation({
    required InvitationRequest request,
  }) async {
    final response = await _client
        .postToGetBody(
          TomEndpoint.invitationServicePath.generateTomEndpoint(),
          data: request.toJson(),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return SendInvitationResponse.fromJson(response);
  }

  Future<GenerateInvitationLinkResponse> generateInvitationLink({
    required InvitationRequest request,
  }) async {
    final response = await _client
        .postToGetBody(
          TomEndpoint.generateInvitationServicePath.generateTomEndpoint(),
          data: request.toJson(),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return response;
  }

  Future<dynamic> getInvitationInformationById({
    required String id,
  }) async {
    final response = await _client
        .get(
          '${TomEndpoint.invitationServicePath.generateTomEndpoint()}/$id',
        )
        .onError((error, stackTrace) => throw Exception(error));

    return response;
  }
}
