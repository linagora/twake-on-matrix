import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/scribe/datasources_impl/scribe_source_impl.dart';
import 'package:twake_chat/data/scribe/scribe_prompts.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';
import 'package:twake_chat/domain/scribe/entities/scribe_prompt.dart';
import 'package:twake_chat/domain/scribe/exceptions/scribe_exception.dart';

import '../../drive/support/fake_http_adapter.dart';

final _stack = Uri.parse('https://alice.twake.example');

DriveSession _session(String token, {Uri? platformUrl}) => DriveSession(
  idToken: DriveIdToken(value: token, expiresAt: DateTime.utc(2030)),
  platformUrl: platformUrl ?? _stack,
);

Map<String, Object?> _answer(Object? content) => {
  'choices': [
    {
      'message': {'role': 'assistant', 'content': content},
    },
  ],
};

void main() {
  late FakeHttpAdapter adapter;
  late ResponseBody Function(RequestOptions) onExchange;
  late ResponseBody Function(RequestOptions) onCompletion;
  late int renewals;
  late Future<DriveSession> Function() renew;

  Future<String> rewrite({DioExceptionType? rejectWith}) {
    final dio = Dio()..httpClientAdapter = adapter;
    if (rejectWith != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) => handler.reject(
            DioException(requestOptions: options, type: rejectWith),
          ),
        ),
      );
    }
    return ScribeSourceImpl(dio: dio, requireHttps: true).rewrite(
      session: _session('first'),
      renewSession: renew,
      prompt: ScribePrompt.translateEnglish,
      draft: 'Bonjour',
    );
  }

  RequestOptions completionRequest() => adapter.requests.lastWhere(
    (request) => request.uri.path == '/ai/v1/chat/completions',
  );

  setUp(() {
    renewals = 0;
    renew = () async {
      renewals++;
      return _session('second');
    };
    onExchange = (options) => jsonResponse({'access_token': 'stack-token'});
    onCompletion = (options) => jsonResponse(_answer('  Hello  \n'));
    adapter = FakeHttpAdapter(
      (options) => options.uri.path == '/auth/token_exchange'
          ? onExchange(options)
          : onCompletion(options),
    );
  });

  group('ScribeSourceImpl.rewrite', () {
    test(
      'trades the id token, then posts the prompt with the stack token',
      () async {
        final text = await rewrite();

        expect(text, 'Hello');
        final exchange = adapter.requests.first;
        expect(exchange.uri.path, '/auth/token_exchange');
        expect(exchange.data, {'id_token': 'first', 'exchange_type': 'app'});
        final completion = completionRequest();
        expect(completion.method, 'POST');
        expect(completion.uri.origin, 'https://alice.twake.example');
        expect(completion.headers['Authorization'], 'Bearer stack-token');
        expect(completion.contentType, startsWith(Headers.jsonContentType));
        expect(completion.data, {
          'messages': const ScribePrompts().messagesFor(
            ScribePrompt.translateEnglish,
            'Bonjour',
          ),
        });
        expect((completion.data as Map).containsKey('model'), isFalse);
        expect(renewals, 0);
      },
    );

    test('renews a stale id token once and trades it again', () async {
      var exchanges = 0;
      onExchange = (options) => exchanges++ == 0
          ? jsonResponse({'error': 'invalid_grant'}, 400)
          : jsonResponse({'access_token': 'stack-token'});

      expect(await rewrite(), 'Hello');
      expect(renewals, 1);
      expect(adapter.requests[1].data, {
        'id_token': 'second',
        'exchange_type': 'app',
      });
    });

    test('a renewal for another workplace sends no draft there', () async {
      onExchange = (options) => jsonResponse({'error': 'invalid_grant'}, 400);
      renew = () async => _session(
        'second',
        platformUrl: Uri.parse('https://bob.twake.example'),
      );

      await expectLater(rewrite(), throwsA(isA<DriveWorkplaceUnknown>()));
      expect(
        adapter.requests.where(
          (request) => request.uri.path == '/ai/v1/chat/completions',
        ),
        isEmpty,
      );
    });

    test('a token refused again after renewal is rejected', () async {
      onExchange = (options) => jsonResponse({'error': 'invalid_grant'}, 400);

      await expectLater(rewrite(), throwsA(isA<DriveExchangeRejected>()));
      expect(renewals, 1);
    });

    for (final token in ['', '  ']) {
      test(
        'a blank exchanged token "$token" is rejected, no draft sent',
        () async {
          onExchange = (options) => jsonResponse({'access_token': token});

          await expectLater(rewrite(), throwsA(isA<DriveExchangeRejected>()));
          expect(
            adapter.requests.where(
              (request) => request.uri.path == '/ai/v1/chat/completions',
            ),
            isEmpty,
          );
        },
      );
    }

    test('a workplace without the Chat app says so', () async {
      onExchange = (options) =>
          jsonResponse({'error': 'chat is not installed'}, 400);

      await expectLater(rewrite(), throwsA(isA<DriveChatAppMissing>()));
    });

    for (final (name, body) in [
      ('an empty answer', _answer('  \n ')),
      ('an answer without text', _answer(null)),
      ('an answer without choices', {'choices': <Object>[]}),
      ('an answer that is not JSON', 'oops'),
    ]) {
      test('$name fails the rewrite', () async {
        onCompletion = (options) => jsonResponse(body);

        await expectLater(rewrite(), throwsA(isA<ScribeRewriteFailed>()));
      });
    }

    test('a refused completion fails the rewrite', () async {
      onCompletion = (options) => jsonResponse({'error': 'boom'}, 500);

      await expectLater(rewrite(), throwsA(isA<ScribeRewriteFailed>()));
    });

    test('a rate-limited completion says so', () async {
      onCompletion = (options) => jsonResponse({'error': 'slow down'}, 429);

      await expectLater(rewrite(), throwsA(isA<DriveRateLimited>()));
    });

    test('no connection says the user is offline', () async {
      await expectLater(
        rewrite(rejectWith: DioExceptionType.connectionError),
        throwsA(isA<DriveOffline>()),
      );
    });

    test('a timeout says the request timed out', () async {
      await expectLater(
        rewrite(rejectWith: DioExceptionType.receiveTimeout),
        throwsA(isA<DriveTimedOut>()),
      );
    });
  });
}
