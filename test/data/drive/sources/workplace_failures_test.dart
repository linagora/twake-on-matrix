import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/sources/workplace_failures.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';

const _failures = WorkplaceFailures();

DioException _failure({
  String path = 'https://alice.twake.example/auth/token_exchange',
  int? status,
  Object? body,
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  group('WorkplaceFailures.isExchangeFailure', () {
    test('is true for the token exchange', () {
      expect(_failures.isExchangeFailure(_failure()), isTrue);
    });

    test('is false for another workplace call', () {
      expect(
        _failures.isExchangeFailure(
          _failure(path: 'https://alice.twake.example/intents'),
        ),
        isFalse,
      );
    });
  });

  group('WorkplaceFailures.isChatAppMissing', () {
    test('is true for a 400 exchange saying the app is not installed', () {
      expect(
        _failures.isChatAppMissing(
          _failure(status: 400, body: {'error': 'Chat is Not Installed'}),
        ),
        isTrue,
      );
    });

    for (final (name, failure) in [
      ('another status', _failure(status: 401, body: 'not installed')),
      ('another reason', _failure(status: 400, body: 'invalid_grant')),
      (
        'another call',
        _failure(
          path: 'https://alice.twake.example/intents',
          status: 400,
          body: 'not installed',
        ),
      ),
      ('no answer', _failure()),
    ]) {
      test('is false for $name', () {
        expect(_failures.isChatAppMissing(failure), isFalse);
      });
    }
  });

  group('WorkplaceFailures.connectionFailureOf', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      test('${type.name} is a timeout', () {
        expect(_failures.connectionFailureOf(type), isA<DriveTimedOut>());
      });
    }

    test('connectionError is offline', () {
      expect(
        _failures.connectionFailureOf(DioExceptionType.connectionError),
        isA<DriveOffline>(),
      );
    });

    for (final type in [
      DioExceptionType.badCertificate,
      DioExceptionType.badResponse,
      DioExceptionType.cancel,
      DioExceptionType.unknown,
    ]) {
      test('${type.name} is not a connection failure', () {
        expect(_failures.connectionFailureOf(type), isNull);
      });
    }
  });
}
