import 'dart:async';
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
import 'package:twake_chat/utils/matrix_sdk_extensions/download_file_extension.dart';

import '../../../fake_client.dart';

const _firstHalf = [1, 2, 3];
const _secondHalf = [4, 5, 6];

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
    if (outcome is! Completer && outcome != null) throw outcome;
    final file = File(savePath);
    await file.create(recursive: true);
    await file.writeAsBytes(_firstHalf);
    if (outcome is Completer) await outcome.future;
    await file.writeAsBytes(_secondHalf, mode: FileMode.append);
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
  });

  tearDown(() {
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
    requestOptions: RequestOptions(),
  );

  Future<Completer<void>> startSlowDownload(String msgtype, String body) async {
    final secondHalf = Completer<void>();
    downloads([secondHalf]);
    unawaited(mediaEvent(msgtype, body).getFileInfo());
    await pumpEventQueue();
    return secondHalf;
  }

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

    test('reads the file only once the in-flight download is saved', () async {
      final secondHalf = await startSlowDownload(
        MessageTypes.Image,
        'photo.png',
      );

      var done = false;
      final result = run().whenComplete(() => done = true);
      await pumpEventQueue();
      expect(done, isFalse);

      secondHalf.complete();
      final states = await result;

      expect(mediaAPI.calls, 1);
      final fileInfo =
          (states.single as Right).value as DownloadMediaFileSuccess;
      expect(await File(fileInfo.fileInfo.filePath!).readAsBytes(), [
        ..._firstHalf,
        ..._secondHalf,
      ]);
    });

    test('reports nothing for a duplicate request', () async {
      downloads([duplicate]);

      expect(await run(), isEmpty);
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

    test('plays the file once the in-flight download is saved', () async {
      final secondHalf = await startSlowDownload(
        MessageTypes.Video,
        'clip.mp4',
      );

      var done = false;
      final url = run().whenComplete(() => done = true);
      await pumpEventQueue();
      expect(done, isFalse);
      secondHalf.complete();

      final path = Uri.parse((await url)!).toFilePath();
      expect(await File(path).readAsBytes(), [..._firstHalf, ..._secondHalf]);
      expect(mediaAPI.calls, 1);
    });

    test('waits for a download that starts at the same time', () async {
      final secondHalf = Completer<void>();
      downloads([secondHalf, duplicate]);

      var done = false;
      final both = Future.wait([
        mediaEvent(MessageTypes.Video, 'clip.mp4').getFileInfo(),
        run().whenComplete(() => done = true),
      ]);
      await pumpEventQueue();
      expect(done, isFalse);

      secondHalf.complete();
      final url = (await both).last as String?;

      expect(mediaAPI.calls, 1);
      final path = Uri.parse(url!).toFilePath();
      expect(await File(path).readAsBytes(), [..._firstHalf, ..._secondHalf]);
    });
  });
}
