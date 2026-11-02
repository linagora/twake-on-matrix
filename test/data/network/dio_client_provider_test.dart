import 'dart:convert';
import 'dart:io';

import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/data/network/dio_client.dart';
import 'package:twake_chat/data/network/dio_client.provider.dart';
import 'package:twake_chat/data/network/identity_endpoint.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/authorization_interceptor.provider.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/dynamic_url_interceptor.provider.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.dart';
import 'package:twake_chat/data/network/interceptor/matrix_dio_cache_interceptor.provider.dart';
import 'package:twake_chat/data/network/tom_endpoint.dart';

void main() {
  late HttpServer server;
  late List<HttpRequest> requests;
  late MatrixDioCacheInterceptor cache;
  late DioClient client;

  final userInfoPath = TomEndpoint.userInfoServicePath
      .generateTomUserInfoEndpoint('@alice:example.com');
  final videoCallPath = TomEndpoint.videoCallRoomsServicePath
      .generateTomEndpoint();

  setUp(() async {
    requests = [];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      requests.add(request);
      await utf8.decoder.bind(request).join();
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'request': requests.length}));
      await request.response.close();
    });
    cache = MatrixDioCacheInterceptor(
      options: CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.forceCache,
      ),
    );
    final container = ProviderContainer.test(
      retry: (_, _) => null,
      overrides: [
        tomServerUrlInterceptorProvider.overrideWithValue(
          DynamicUrlInterceptors()
            ..changeBaseUrl('http://${server.address.host}:${server.port}'),
        ),
        authorizationInterceptorProvider.overrideWithValue(
          AuthorizationInterceptor()..accessToken = 'token',
        ),
        memCacheDioInterceptorProvider.overrideWithValue(cache),
      ],
    );
    client = container.read(tomDioClientProvider);
  });

  tearDown(() => server.close(force: true));

  test('serves a registered user info request from the cache', () async {
    cache.addUriSupportsCache([userInfoPath]);

    final first = await client.get(userInfoPath);
    final second = await client.get(userInfoPath);

    expect(requests, hasLength(1));
    expect(
      requests.single.headers.value(HttpHeaders.authorizationHeader),
      'Bearer token',
    );
    expect(second, first);
  });

  test('sends every video call room creation to the server', () async {
    cache.addUriSupportsCache([
      userInfoPath,
      '${TomEndpoint.invitationServicePath.generateTomEndpoint()}/id/status',
      IdentityEndpoint.hashDetailsServicePath.generateTwakeIdentityEndpoint(),
    ]);

    await client.postToGetBody(videoCallPath, data: const {});
    await client.postToGetBody(videoCallPath, data: const {});

    expect(requests, hasLength(2));
  });
}
