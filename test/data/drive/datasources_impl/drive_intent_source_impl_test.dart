import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_intent_source_impl.dart';
import 'package:twake_chat/domain/drive/entities/drive_id_token.dart';
import 'package:twake_chat/domain/drive/entities/drive_picker_options.dart';
import 'package:twake_chat/domain/drive/entities/drive_session.dart';
import 'package:twake_chat/domain/drive/exceptions/drive_exception.dart';

import '../support/fake_http_adapter.dart';

final _stack = Uri.parse('https://alice.twake.example');

DriveSession _session(String token) => DriveSession(
  idToken: DriveIdToken(value: token, expiresAt: DateTime.utc(2030)),
  platformUrl: _stack,
);

const _options = DrivePickerOptions(linkLabel: 'Add as link', darkTheme: false);

Map<String, Object?> _intentAnswer({
  String href = 'https://drive.example/#/intents/1',
}) => {
  'data': {
    'id': 'intent-1',
    'type': 'io.cozy.intents',
    'attributes': {
      'action': 'PICK',
      'type': 'io.cozy.files',
      'permissions': ['GET'],
      'services': [
        {'href': href},
      ],
      'client': 'https://chat.example',
    },
  },
};

void main() {
  late FakeHttpAdapter adapter;
  late ResponseBody Function(RequestOptions) onExchange;
  late ResponseBody Function(RequestOptions) onIntents;
  late int renewals;
  late Future<DriveSession> Function() renew;

  DriveIntentSourceImpl source({
    bool requireHttps = true,
    DioExceptionType? rejectWith,
  }) {
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
    return DriveIntentSourceImpl(dio: dio, requireHttps: requireHttps);
  }

  Future<dynamic> create({
    bool requireHttps = true,
    DioExceptionType? rejectWith,
  }) => source(requireHttps: requireHttps, rejectWith: rejectWith).createIntent(
    session: _session('first'),
    renewSession: renew,
    options: _options,
  );

  setUp(() {
    renewals = 0;
    renew = () async {
      renewals++;
      return _session('second');
    };
    onExchange = (options) => jsonResponse({'access_token': 'drive-token'});
    onIntents = (options) => jsonResponse(_intentAnswer());
    adapter = FakeHttpAdapter((options) {
      if (options.path.endsWith('/auth/token_exchange')) {
        return onExchange(options);
      }
      return onIntents(options);
    });
  });

  group('DriveIntentSourceImpl.createIntent', () {
    test(
      'trades the id token, then creates the intent with the Drive token',
      () async {
        final intent = await create();

        expect(intent.intentId, 'intent-1');
        expect(
          intent.intentUrl,
          Uri.parse('https://drive.example/#/intents/1'),
        );
        expect(intent.client, 'https://chat.example');
        final exchange = adapter.requests.first;
        expect(
          exchange.path,
          'https://alice.twake.example/auth/token_exchange',
        );
        expect(exchange.data, {'id_token': 'first', 'exchange_type': 'app'});
        final intents = adapter.requests.last;
        expect(intents.uri.origin, 'https://alice.twake.example');
        expect(intents.uri.path, '/intents');
        expect(intents.headers['Authorization'], 'Bearer drive-token');
        expect(renewals, 0);
      },
    );

    test('asks Drive for the link button only, in the app theme', () async {
      await create();

      final data = (adapter.requests.last.data as Map)['data'] as Map;
      final picker = (data['attributes'] as Map)['data'] as Map;
      expect((picker['sharingLink'] as Map)['label'], 'Add as link');
      expect(picker['downloadLink'], isNull);
      expect((picker['theme'] as Map)['type'], 'light');
    });

    test(
      'asks Drive for the attach button with its limit and no folders',
      () async {
        await source().createIntent(
          session: _session('first'),
          renewSession: renew,
          options: const DrivePickerOptions(
            linkLabel: 'Add as link',
            attachLabel: 'Add as attachment',
            maxAttachmentBytes: 5000,
            darkTheme: true,
          ),
        );

        final data = (adapter.requests.last.data as Map)['data'] as Map;
        final picker = (data['attributes'] as Map)['data'] as Map;
        final attach = picker['downloadLink'] as Map;
        expect(attach['label'], 'Add as attachment');
        expect(attach['maxFileSize'], 5000);
        expect(attach['allowFolder'], isFalse);
        expect((picker['sharingLink'] as Map)['label'], 'Add as link');
        expect((picker['theme'] as Map)['type'], 'dark');
      },
    );

    test('renews a stale token once and retries with the new one', () async {
      var attempts = 0;
      onExchange = (options) {
        attempts++;
        return attempts == 1
            ? jsonResponse({'error': 'stale'}, 401)
            : jsonResponse({'access_token': 'drive-token'});
      };

      final intent = await create();

      expect(intent.intentId, 'intent-1');
      expect(renewals, 1);
      final exchanges = adapter.requests.where(
        (r) => r.path.endsWith('/auth/token_exchange'),
      );
      expect(exchanges.map((r) => (r.data as Map)['id_token']), [
        'first',
        'second',
      ]);
    });

    test('a renewal on another workplace is refused, not followed', () async {
      onExchange = (options) => jsonResponse({'error': 'stale'}, 401);
      renew = () async => DriveSession(
        idToken: DriveIdToken(value: 'second', expiresAt: DateTime.utc(2030)),
        platformUrl: Uri.parse('https://other.twake.example'),
      );

      await expectLater(create(), throwsA(isA<DriveWorkplaceUnknown>()));
      final exchanges = adapter.requests.where(
        (r) => r.path.endsWith('/auth/token_exchange'),
      );
      expect(exchanges, hasLength(1));
    });

    test(
      'a token refused again after a renewal is rejected for good',
      () async {
        onExchange = (options) => jsonResponse({'error': 'stale'}, 401);

        await expectLater(create(), throwsA(isA<DriveExchangeRejected>()));

        expect(renewals, 1);
        expect(
          adapter.requests.where(
            (r) => r.path.endsWith('/auth/token_exchange'),
          ),
          hasLength(2),
        );
      },
    );

    test('a 400 from the exchange is treated as a stale token too', () async {
      onExchange = (options) => jsonResponse({'error': 'invalid_grant'}, 400);

      await expectLater(create(), throwsA(isA<DriveExchangeRejected>()));

      expect(renewals, 1);
    });

    test('a Drive without the Chat app says so', () async {
      onExchange = (options) =>
          jsonResponse({'error': 'chat is not installed'}, 400);

      await expectLater(create(), throwsA(isA<DriveChatAppMissing>()));
    });

    test('a server error on the exchange fails without a renewal', () async {
      onExchange = (options) => jsonResponse({}, 500);

      await expectLater(create(), throwsA(isA<DriveIntentFailed>()));

      expect(renewals, 0);
    });

    test('a 429 on the exchange reports rate limiting', () async {
      onExchange = (options) => jsonResponse({}, 429);

      await expectLater(create(), throwsA(isA<DriveRateLimited>()));
      expect(renewals, 0);
    });

    test('an exchange timeout reports a timeout', () async {
      await expectLater(
        create(rejectWith: DioExceptionType.connectionTimeout),
        throwsA(isA<DriveTimedOut>()),
      );
    });

    test('an offline exchange reports no connection', () async {
      await expectLater(
        create(rejectWith: DioExceptionType.connectionError),
        throwsA(isA<DriveOffline>()),
      );
    });

    test('a failed renewal reaches the caller as it is', () async {
      onExchange = (options) => jsonResponse({}, 401);
      renew = () async => throw const DriveSignInCancelled();

      await expectLater(create(), throwsA(isA<DriveSignInCancelled>()));
    });

    test('a programmer error in renewal is not hidden', () async {
      onExchange = (options) => jsonResponse({}, 401);
      renew = () async => throw StateError('bad renewal state');

      await expectLater(create(), throwsStateError);
    });

    test('a server error on /intents fails the intent', () async {
      onIntents = (options) => jsonResponse({}, 500);

      await expectLater(create(), throwsA(isA<DriveIntentFailed>()));
    });

    test('an exchange answer with no access token fails the intent', () async {
      onExchange = (options) => jsonResponse({'client_id': 'x'});

      await expectLater(create(), throwsA(isA<DriveIntentFailed>()));
    });

    test('an intent with no service fails the intent', () async {
      onIntents = (options) => jsonResponse({
        'data': {
          'id': 'intent-1',
          'attributes': {
            'action': 'PICK',
            'type': 'io.cozy.files',
            'permissions': ['GET'],
            'services': <Object>[],
          },
        },
      });

      await expectLater(create(), throwsA(isA<DriveIntentFailed>()));
    });

    test('a mistyped service href fails as an invalid Drive answer', () async {
      final answer = _intentAnswer();
      final data = answer['data']! as Map<String, Object?>;
      final attributes = data['attributes']! as Map<String, Object?>;
      attributes['services'] = [
        {'href': 123},
      ];
      onIntents = (options) => jsonResponse(answer);

      await expectLater(create(), throwsA(isA<DriveIntentFailed>()));
    });

    test('an http intent URL is refused when https is required', () async {
      onIntents = (options) =>
          jsonResponse(_intentAnswer(href: 'http://drive.example/#/intents/1'));

      await expectLater(create(), throwsA(isA<DriveIntentFailed>()));
    });

    test('an http intent URL is accepted when https is not required', () async {
      onIntents = (options) =>
          jsonResponse(_intentAnswer(href: 'http://drive.example/#/intents/1'));

      final intent = await create(requireHttps: false);

      expect(intent.intentUrl.scheme, 'http');
    });
  });
}
