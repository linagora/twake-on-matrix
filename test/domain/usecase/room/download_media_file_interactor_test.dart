import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/media/download_file_response.dart';
import 'package:twake_chat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:twake_chat/data/network/interceptor/download_file_interceptor.dart';
import 'package:twake_chat/data/network/media/cancel_exception.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/download/download_file_state.dart';
import 'package:twake_chat/domain/usecase/room/download_media_file_interactor.dart';
import 'package:twake_chat/presentation/mixins/handle_video_download_mixin.dart';

import '../../../fake_client.dart';

const _inFlightPath = '_matrix/media/v3/download/example.com/gone';

class _FakeMediaAPI implements MediaAPI {
  _FakeMediaAPI(this.outcomes);

  final List<Object?> outcomes;
  int calls = 0;

  @override
  Future<DownloadFileResponse> downloadFileInfo({
    required Uri uriPath,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final outcome = outcomes[calls++];
    if (outcome != null) throw outcome;
    await File(savePath).create(recursive: true);
    await File(savePath).writeAsBytes([1, 2, 3]);
    return DownloadFileResponse(
      statusCode: 200,
      requestOptions: RequestOptions(),
      savePath: savePath,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VideoDownloader with HandleVideoDownloadMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Room room;
  late Directory tempDir;
  late DownloadFileInterceptor interceptor;
  late _FakeMediaAPI mediaAPI;

  setUpAll(() async {
    final client = await getClient();
    room = Room(client: client, id: '!files:example.com');
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('download_media_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => tempDir.path,
        );
    interceptor = DownloadFileInterceptor();
    getIt.registerSingleton<DownloadFileInterceptor>(interceptor);
  });

  tearDown(() {
    getIt.unregister<DownloadFileInterceptor>();
    if (getIt.isRegistered<MediaAPI>()) getIt.unregister<MediaAPI>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  Event mediaEvent(String msgtype, String body, {bool encrypted = false}) =>
      Event(
        type: EventTypes.Message,
        content: {
          'msgtype': msgtype,
          'body': body,
          if (encrypted)
            'file': {
              'url': 'mxc://example.com/gone',
              'key': {
                'alg': 'A256CTR',
                'ext': true,
                'k': 'not-a-key',
                'key_ops': ['encrypt', 'decrypt'],
                'kty': 'oct',
              },
              'iv': 'not-an-iv',
              'hashes': {'sha256': 'not-a-hash'},
              'v': 'v2',
            }
          else
            'url': 'mxc://example.com/gone',
        },
        eventId: '\$media',
        senderId: '@alice:example.com',
        originServerTs: DateTime(2026, 11, 12),
        room: room,
      );

  void downloads(List<Object?> outcomes) {
    mediaAPI = _FakeMediaAPI(outcomes);
    getIt.registerSingleton<MediaAPI>(mediaAPI);
  }

  final duplicate = DioDuplicateDownloadException(
    requestOptions: RequestOptions(path: _inFlightPath),
  );

  void startInFlightDownload() => interceptor.onRequest(
    RequestOptions(path: _inFlightPath),
    RequestInterceptorHandler(),
  );

  void finishInFlightDownload() => interceptor.onResponse(
    Response(requestOptions: RequestOptions(path: _inFlightPath)),
    ResponseInterceptorHandler(),
  );

  group('DownloadMediaFileInteractor', () {
    Future<List<Either>> run({bool encrypted = false}) =>
        DownloadMediaFileInteractor()
            .execute(
              event: mediaEvent(
                MessageTypes.Image,
                'photo.png',
                encrypted: encrypted,
              ),
            )
            .toList();

    test('reports a real download error with its exception', () async {
      final error = Exception('404');
      downloads([error]);

      expect(await run(), [Left(DownloadMediaFileFailure(exception: error))]);
    });

    test('waits for the in-flight download, then returns the file', () async {
      downloads([duplicate, null]);
      startInFlightDownload();

      final result = run();
      await pumpEventQueue();
      expect(mediaAPI.calls, 1);

      finishInFlightDownload();
      final states = await result;

      expect(mediaAPI.calls, 2);
      expect(states.single.isRight(), isTrue);
    });

    test('reports nothing for a cancelled request', () async {
      downloads([CancelRequestException()]);

      expect(await run(), isEmpty);
    });

    test('reports a failed decryption instead of the encrypted file', () async {
      downloads([null]);

      final states = await run(encrypted: true);

      expect(states.single.isLeft(), isTrue);
    });
  });

  group('HandleVideoDownloadMixin', () {
    Future<String?> run() async {
      String? url;
      await _VideoDownloader().handleDownloadVideoEvent(
        event: mediaEvent(MessageTypes.Video, 'clip.mp4'),
        playVideoActionByUrl: (value) => url = value,
      );
      return url;
    }

    test('throws on a real download error', () async {
      downloads([Exception('404')]);

      await expectLater(run(), throwsException);
    });

    test('plays the file once the in-flight download ends', () async {
      downloads([duplicate, null]);

      expect(await run(), endsWith('clip.mp4'));
    });
  });
}
