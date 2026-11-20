import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/di/global/network_di.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';

class _DrainingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    return ResponseBody.fromString(
      jsonEncode({'content_uri': 'mxc://example.com/media'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() {
    final dio = Dio()..httpClientAdapter = _DrainingAdapter();
    getIt.registerSingleton<DioClient>(
      DioClient(dio),
      instanceName: NetworkDI.homeDioClientName,
    );
  });

  tearDown(() {
    getIt.unregister<DioClient>(instanceName: NetworkDI.homeDioClientName);
  });

  test(
    'uploadFileMobile reports progress while in-memory bytes are sent',
    () async {
      const size = 1024 * 1024;
      final progress = <int>[];

      final response = await MediaAPI().uploadFileMobile(
        fileInfo: FileInfo('video.mp4', bytes: Uint8List(size)),
        onSendProgress: (sent, total) => progress.add(sent),
      );

      expect(response.contentUri, 'mxc://example.com/media');
      expect(progress.length, greaterThan(1));
      expect(progress.first, lessThan(size));
      expect(progress.last, size);
    },
  );
}
