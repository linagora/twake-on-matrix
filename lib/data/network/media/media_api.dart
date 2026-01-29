import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fluffychat/data/model/media/download_file_response.dart';
import 'package:fluffychat/data/model/media/upload_file_json.dart';
import 'package:fluffychat/data/model/media/url_preview_response.dart';
import 'package:fluffychat/data/network/dio_client.dart';
import 'package:fluffychat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:fluffychat/data/network/homeserver_endpoint.dart';
import 'package:fluffychat/data/network/media/cancel_exception.dart';
import 'package:fluffychat/data/network/media/file_not_exist_exception.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/di/global/network_di.dart';
import 'package:fluffychat/domain/model/file_info/file_info.dart';
import 'package:matrix/matrix.dart';

class MediaAPI {
  final DioClient _client =
      getIt.get<DioClient>(instanceName: NetworkDI.homeDioClientName);

  MediaAPI();

  Future<UploadFileResponse> uploadFileMobile({
    required FileInfo fileInfo,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final dioHeaders = _client.getHeaders();
    dioHeaders[HttpHeaders.contentLengthHeader] = fileInfo.fileSize;
    dioHeaders[HttpHeaders.contentTypeHeader] = fileInfo.mimeType;
    Stream<List<int>>? readStream;
    if (fileInfo.bytes != null) {
      readStream = Stream.value(fileInfo.bytes!);
    } else if (fileInfo.filePath != null) {
      final file = File(fileInfo.filePath!);
      final exist = await file.exists();
      if (!exist) {
        throw FileNotExistException(path: fileInfo.filePath!);
      }
      try {
        readStream = file.openRead();
      } on FileSystemException catch (e) {
        // Map "file missing" to the same exception for consistent UX.
        if (e.osError?.errorCode == 2) {
          throw FileNotExistException(path: fileInfo.filePath!);
        }
        rethrow;
      }
    } else {
      throw ArgumentError('FileInfo must have either bytes or filePath');
    }
    final response = await _client
        .postToGetBody(
      HomeserverEndpoint.uploadMediaServicePath
          .generateHomeserverMediaEndpoint(),
      data: readStream,
      queryParameters: {
        'fileName': fileInfo.fileName,
      },
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      options: Options(headers: dioHeaders),
    )
        .onError((error, stackTrace) {
      if (error is DioException && error.type == DioExceptionType.cancel) {
        throw CancelRequestException();
      } else {
        throw Exception(error);
      }
    });

    return UploadFileResponse.fromJson(response);
  }

  Future<UploadFileResponse> uploadFileWeb({
    required MatrixFile file,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final dioHeaders = _client.getHeaders();
    dioHeaders[HttpHeaders.contentLengthHeader] = file.bytes.length;
    dioHeaders[HttpHeaders.contentTypeHeader] = file.mimeType;
    final response = await _client
        .postToGetBody(
      HomeserverEndpoint.uploadMediaServicePath
          .generateHomeserverMediaEndpoint(),
      data: Stream.value(file.bytes),
      queryParameters: {
        'fileName': file.name,
      },
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      options: Options(headers: dioHeaders),
    )
        .onError((error, stackTrace) {
      if (error is DioException && error.type == DioExceptionType.cancel) {
        throw CancelRequestException();
      } else {
        throw Exception(error);
      }
    });

    return UploadFileResponse.fromJson(response);
  }

  Future<DownloadFileResponse> downloadFileInfo({
    required Uri uriPath,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _client.download(
      uriPath,
      savePath: savePath,
      options: Options(
        headers: {HttpHeaders.acceptEncodingHeader: '*'}, // Disable gzip
      ),
      onReceiveProgress: (receive, total) {
        if (onReceiveProgress != null) {
          onReceiveProgress(receive, total);
        }
      },
      cancelToken: cancelToken,
    ).onError((error, stackTrace) {
      if (error is DioException && error.type == DioExceptionType.cancel) {
        throw CancelRequestException();
      } else if (error is DioDuplicateDownloadException) {
        Logs().i('downloadFileInfo error: $error');
        throw DioDuplicateDownloadException(
          requestOptions: error.requestOptions,
        );
      } else {
        Logs().i('downloadFileInfo error: $error');
        throw Exception(error);
      }
    });

    return DownloadFileResponse(
      savePath: savePath,
      onReceiveProgress: onReceiveProgress,
      requestOptions: response.requestOptions,
      statusCode: response.statusCode,
      statusMessage: response.statusMessage,
      data: response.data,
      extra: response.extra,
      headers: response.headers,
      isRedirect: response.isRedirect,
      redirects: response.redirects,
    );
  }

  Future<Stream<List<int>>> downloadFileWeb({
    required Uri uri,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _client
        .get(
      uri.path,
      onReceiveProgress: onReceiveProgress,
      cancelToken: cancelToken,
      options: Options(
        responseType: ResponseType.stream,
      ),
    )
        .onError((error, stackTrace) {
      if (error is DioException && error.type == DioExceptionType.cancel) {
        throw CancelRequestException();
      } else {
        throw Exception(error);
      }
    });

    return response.stream;
  }

  Future<UrlPreviewResponse> getUrlPreview({
    required Uri uri,
    int? preferredPreviewTime,
  }) async {
    final response = await _client.get(
      HomeserverEndpoint.getPreviewUrlServicePath
          .generateHomeserverMediaEndpoint(),
      queryParameters: {
        'url': uri.toString(),
        if (preferredPreviewTime != null) 'ts': preferredPreviewTime,
      },
    ).onError((error, stackTrace) => throw Exception(error));

    return UrlPreviewResponse.fromJson(response);
  }
}
