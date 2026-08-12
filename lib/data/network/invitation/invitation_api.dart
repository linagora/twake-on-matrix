import 'package:dio/dio.dart';
import 'package:twake_chat/data/model/invitation/generate_invitation_link_response.dart';
import 'package:twake_chat/data/model/invitation/invitation_request.dart';
import 'package:twake_chat/data/model/invitation/invitation_status_response.dart';
import 'package:twake_chat/data/model/invitation/send_invitation_response.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:twake_chat/data/network/tom_endpoint.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';

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
        .onError((error, stackTrace) {
          if (error is DioException) {
            throw DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: error.error,
              stackTrace: error.stackTrace,
            );
          } else {
            throw Exception(error);
          }
        });

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
        .onError((error, stackTrace) {
          if (error is DioException) {
            throw DioException(
              requestOptions: error.requestOptions,
              response: error.response,
              type: error.type,
              error: error.error,
              stackTrace: error.stackTrace,
            );
          } else {
            throw Exception(error);
          }
        });

    return GenerateInvitationLinkResponse.fromJson(response);
  }

  Future<InvitationStatusResponse> getInvitationStatus({
    required String invitationId,
  }) async {
    final uri =
        "${TomEndpoint.invitationServicePath.generateTomEndpoint()}/$invitationId/status";
    final dioCacheCustomInterceptor = getIt.get<MatrixDioCacheInterceptor>(
      instanceName: NetworkDI.memCacheDioInterceptorName,
    );

    dioCacheCustomInterceptor.addUriSupportsCache([uri]);

    final response = await _client.get(uri).onError((error, stackTrace) {
      if (error is DioException) {
        throw DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: error.error,
          stackTrace: error.stackTrace,
        );
      } else {
        throw Exception(error);
      }
    });

    return InvitationStatusResponse.fromJson(response);
  }
}
