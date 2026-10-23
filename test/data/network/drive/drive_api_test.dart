import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/drive/drive_api.dart';
import 'package:twake_chat/data/network/drive/drive_dio.dart';

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this._body);

  final Object _body;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(_body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

final _url = Uri.parse('https://workplace.example/custom/endpoint');

DriveApi _api(_RecordingAdapter adapter) =>
    DriveApi(DioClient(createDriveDio()..httpClientAdapter = adapter));

Future<void> _postsTheBodyAndHeadersToTheUrl() async {
  final adapter = _RecordingAdapter({'ok': true});

  final json = await _api(
    adapter,
  ).post(_url, body: {'a': 1}, headers: {'X-Test': 'yes'});

  final request = adapter.requests.single;
  expect(json, {'ok': true});
  expect(request.method, 'POST');
  expect(request.uri, _url);
  expect(request.data, {'a': 1});
  expect(request.headers['X-Test'], 'yes');
}

Future<void> _failsWhenTheResponseIsNotAJsonObject() async {
  final adapter = _RecordingAdapter(['not', 'an', 'object']);

  await expectLater(_api(adapter).post(_url, body: {}), throwsFormatException);
}

void main() {
  test(
    'posts the body and headers to the url',
    _postsTheBodyAndHeadersToTheUrl,
  );
  test(
    'fails when the response is not a JSON object',
    _failsWhenTheResponseIsNotAJsonObject,
  );
}
