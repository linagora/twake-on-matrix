import 'dart:async';
import 'dart:io';

import 'package:twake_chat/data/drive/datasources_impl/drive_upload_limit_source.provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/drive/datasources_impl/drive_upload_limit_source_impl.dart';

class _FakeClient extends Fake implements Client {
  _FakeClient(this.loadConfig);

  final Future<MediaConfig> Function() loadConfig;
  int calls = 0;

  @override
  Future<MediaConfig> getConfig({
    Duration cacheLifetime = const Duration(days: 3),
    bool throwOnUpdateFailure = false,
  }) {
    calls++;
    return loadConfig();
  }
}

void main() {
  test('returns the server upload size', () async {
    final client = _FakeClient(() async => MediaConfig(mUploadSize: 1024));

    expect(await DriveUploadLimitSourceImpl(client).read(), 1024);
    expect(client.calls, 1);
  });

  test('returns null when m.upload.size is absent', () async {
    final client = _FakeClient(() async => MediaConfig());

    expect(await DriveUploadLimitSourceImpl(client).read(), isNull);
  });

  final failures = <String, Exception>{
    '401': MatrixException(http.Response('{"errcode":"M_UNKNOWN"}', 401)),
    '429': MatrixException(
      http.Response('{"errcode":"M_LIMIT_EXCEEDED"}', 429),
    ),
    'timeout': TimeoutException('config timed out'),
    'offline': const SocketException('network unavailable'),
  };
  for (final failure in failures.entries) {
    test('returns null on ${failure.key}', () async {
      final client = _FakeClient(() async => throw failure.value);

      expect(await DriveUploadLimitSourceImpl(client).read(), isNull);
      expect(client.calls, 1);
    });
  }

  test('does not hide programmer errors', () async {
    final client = _FakeClient(() async => throw StateError('bad setup'));

    await expectLater(
      DriveUploadLimitSourceImpl(client).read(),
      throwsStateError,
    );
  });

  test('provider reads each captured room client independently', () async {
    final alice = _FakeClient(() async => MediaConfig(mUploadSize: 1024));
    final bob = _FakeClient(() async => MediaConfig(mUploadSize: 2048));
    final container = ProviderContainer.test(retry: (_, _) => null);

    final aliceLimit = container.read(driveUploadLimitSourceProvider(alice));
    final bobLimit = container.read(driveUploadLimitSourceProvider(bob));

    expect(await aliceLimit.read(), 1024);
    expect(await bobLimit.read(), 2048);
    expect(alice.calls, 1);
    expect(bob.calls, 1);
  });
}
