import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/model/media/download_file_response.dart';
import 'package:twake_chat/data/network/exception/dio_duplicate_download_exception.dart';
import 'package:twake_chat/data/network/media/cancel_exception.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/app_state/download/download_file_state.dart';
import 'package:twake_chat/domain/usecase/room/download_media_file_interactor.dart';
import 'package:twake_chat/presentation/mixins/handle_video_download_mixin.dart';

import '../../../fake_client.dart';

class _FailingMediaAPI implements MediaAPI {
  _FailingMediaAPI(this.error);

  final Object error;

  @override
  Future<DownloadFileResponse> downloadFileInfo({
    required Uri uriPath,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) => Future.error(error);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VideoDownloader with HandleVideoDownloadMixin {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Room room;
  late Directory tempDir;

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
  });

  tearDown(() {
    if (getIt.isRegistered<MediaAPI>()) getIt.unregister<MediaAPI>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  Event mediaEvent(String msgtype, String body) => Event(
    type: EventTypes.Message,
    content: {
      'msgtype': msgtype,
      'body': body,
      'url': 'mxc://example.com/gone',
    },
    eventId: '\$media',
    senderId: '@alice:example.com',
    originServerTs: DateTime(2026, 11, 12),
    room: room,
  );

  void downloadFailsWith(Object error) =>
      getIt.registerSingleton<MediaAPI>(_FailingMediaAPI(error));

  final duplicate = DioDuplicateDownloadException(
    requestOptions: RequestOptions(),
  );

  group('DownloadMediaFileInteractor', () {
    Future<List<Either>> run() => DownloadMediaFileInteractor()
        .execute(event: mediaEvent(MessageTypes.Image, 'photo.png'))
        .toList();

    test('reports a real download error with its exception', () async {
      final error = Exception('404');
      downloadFailsWith(error);

      expect(await run(), [Left(DownloadMediaFileFailure(exception: error))]);
    });

    test('reports nothing for a duplicate request', () async {
      downloadFailsWith(duplicate);

      expect(await run(), isEmpty);
    });

    test('reports nothing for a cancelled request', () async {
      downloadFailsWith(CancelRequestException());

      expect(await run(), isEmpty);
    });
  });

  group('HandleVideoDownloadMixin', () {
    Future<void> run() => _VideoDownloader().handleDownloadVideoEvent(
      event: mediaEvent(MessageTypes.Video, 'clip.mp4'),
    );

    test('throws on a real download error', () async {
      downloadFailsWith(Exception('404'));

      await expectLater(run(), throwsException);
    });

    test('returns quietly for a duplicate request', () async {
      downloadFailsWith(duplicate);

      await expectLater(run(), completes);
    });
  });
}
