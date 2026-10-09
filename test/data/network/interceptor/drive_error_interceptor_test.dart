import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/network/drive/drive_dio.dart';
import 'package:twake_chat/data/network/interceptor/drive_error_interceptor.dart';
import 'package:twake_chat/domain/model/drive/drive_exceptions.dart';

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter({this.status, this.failure});

  final int? status;
  final DioExceptionType? failure;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final type = failure;
    if (type != null) {
      throw DioException(requestOptions: options, type: type);
    }
    return ResponseBody.fromString('{"error":"nope"}', status!);
  }

  @override
  void close({bool force = false}) {}
}

class _ErrorCase {
  const _ErrorCase(
    this.name,
    this.path,
    this.expected, {
    this.status,
    this.failure,
  });

  final String name;
  final String path;
  final Matcher expected;
  final int? status;
  final DioExceptionType? failure;
}

Future<Object?> _errorOf(_ErrorCase testCase) async {
  final dio = createDriveDio()
    ..httpClientAdapter = _StatusAdapter(
      status: testCase.status,
      failure: testCase.failure,
    );
  try {
    await runDriveRequest(
      () => dio.postUri<Object?>(
        Uri.parse('https://workplace.example${testCase.path}'),
      ),
    );
  } catch (e) {
    return e;
  }
  return null;
}

final _cases = [
  _ErrorCase(
    'a 400 on token_exchange is an auth error',
    '/auth/token_exchange',
    isA<DriveAuthRejectedException>(),
    status: 400,
  ),
  _ErrorCase(
    'a 403 is an auth error',
    '/intents',
    isA<DriveAuthRejectedException>(),
    status: 403,
  ),
  _ErrorCase(
    'a 401 is an auth error',
    '/intents',
    isA<DriveAuthRejectedException>(),
    status: 401,
  ),
  _ErrorCase(
    'a 400 on intents is a generic failure',
    '/intents',
    isA<DriveRequestFailedException>(),
    status: 400,
  ),
  _ErrorCase(
    'a 404 is a generic failure',
    '/intents',
    isA<DriveRequestFailedException>(),
    status: 404,
  ),
  _ErrorCase(
    'a 409 is a generic failure',
    '/auth/token_exchange',
    isA<DriveRequestFailedException>(),
    status: 409,
  ),
  _ErrorCase(
    'a 500 is a generic failure',
    '/intents',
    isA<DriveRequestFailedException>(),
    status: 500,
  ),
  _ErrorCase(
    'a timeout is a generic failure',
    '/intents',
    isA<DriveRequestFailedException>(),
    failure: DioExceptionType.receiveTimeout,
  ),
  _ErrorCase(
    'a connection error is a generic failure',
    '/intents',
    isA<DriveRequestFailedException>(),
    failure: DioExceptionType.connectionError,
  ),
  _ErrorCase(
    'a cancelled request stays a DioException',
    '/intents',
    isA<DioException>(),
    failure: DioExceptionType.cancel,
  ),
];

void main() {
  for (final testCase in _cases) {
    test(testCase.name, () async {
      expect(await _errorOf(testCase), testCase.expected);
    });
  }

  test('keeps the status code and never the response body', () async {
    final error = await _errorOf(_cases.firstWhere((c) => c.status == 500));

    expect('$error', 'DriveRequestFailedException(500)');
  });
}
