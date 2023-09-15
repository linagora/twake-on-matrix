import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/data/model/media/upload_file_json.dart';
import 'package:fluffychat/data/model/media/url_preview_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/data/network/extensions/file_info_extension.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:matrix/matrix.dart';

class MediaAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.homeDioClientName);

  MediaAPI();

  Future<UploadFileResponse> uploadFile({required FileInfo fileInfo}) async {
    final dioHeaders = _client.getHeaders();
    dioHeaders[HttpHeaders.contentLengthHeader] =
        await File(fileInfo.filePath).length();
    dioHeaders[HttpHeaders.contentTypeHeader] = fileInfo.mimeType;
    final response = await _client
        .post(
          HomeserverEndpoint.uploadMediaServicePath
              .generateHomeserverIdentityEndpoint(),
          data: fileInfo.readStream ?? File(fileInfo.filePath).openRead(),
          queryParameters: {
            'fileName': fileInfo.fileName,
          },
          options: Options(headers: dioHeaders),
        )
        .onError((error, stackTrace) => throw Exception(error));

    return UploadFileResponse.fromJson(response);
  }

  Future<UrlPreviewResponse> getUrlPreview({
    required Uri uri,
    int? ts,
  }) async {
    final response = await _client.get(
      HomeserverEndpoint.getPreviewUrlServicePath
          .generateHomeserverIdentityEndpoint(),
      queryParameters: {
        'url': uri.toString(),
        if (ts != null) 'ts': ts,
      },
    ).onError((error, stackTrace) => throw Exception(error));

    return UrlPreviewResponse.fromJson(response);
  }
}
