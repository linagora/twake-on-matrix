import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:twake_chat/data/model/media/download_file_response.dart';
import 'package:twake_chat/data/network/media/cancel_exception.dart';
import 'package:twake_chat/data/network/media/media_api.dart';
import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/domain/model/file_info/file_info.dart';
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';
import 'package:twake_chat/utils/matrix_sdk_extensions/download_file_extension.dart';

import '../../fake_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const eventId = r'$encrypted:example.org';
  const fileName = 'Secret Plan.pdf';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;
  late Room room;

  setUpAll(() async {
    final client = await getClient();
    room = Room(id: '!room:example.org', client: client);
  });

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('download_file_ext_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => tempDir.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  Future<FileInfo?> downloadAndDecrypt(
    Uint8List plain,
    String fileName, {
    Room? inRoom,
  }) async {
    final encrypted = await MatrixFile(bytes: plain, name: fileName).encrypt();
    final encryptedPath = await StorageDirectoryManager.instance
        .getFilePathInAppDownloads(eventId: eventId, fileName: fileName);
    await File(encryptedPath).create(recursive: true);
    await File(encryptedPath).writeAsBytes(encrypted.data);
    final event = Event(
      content: {
        'msgtype': MessageTypes.File,
        'body': fileName,
        'info': {'size': plain.length},
        'file': {
          'url': 'mxc://example.org/encrypted',
          'v': 'v2',
          'iv': encrypted.iv,
          'hashes': {'sha256': encrypted.sha256},
          'key': {
            'kty': 'oct',
            'alg': 'A256CTR',
            'ext': true,
            'key_ops': ['encrypt', 'decrypt'],
            'k': encrypted.k,
          },
        },
      },
      type: EventTypes.Message,
      eventId: eventId,
      senderId: '@bob:example.org',
      originServerTs: DateTime.now(),
      room: inRoom ?? room,
    );
    final decryptedPath = await StorageDirectoryManager.instance
        .getDecryptedFilePath(eventId: eventId, fileName: fileName);
    return event.decryptFile(
      FileInfo(fileName, filePath: encryptedPath),
      decryptedPath,
      filename: fileName,
    );
  }

  group('decryptFile', () {
    test(
      'decryptFile_whenFileIsNamedDecrypted_writesPlainFileUnderOriginalName',
      () async {
        // Arrange
        final plain = Uint8List.fromList(utf8.encode('plain bytes'));

        // Act
        final result = await downloadAndDecrypt(plain, 'decrypted');

        // Assert
        expect(result?.filePath?.split('/').last, 'decrypted');
        expect(await File(result!.filePath!).readAsBytes(), plain);
      },
    );

    test(
      'decryptFile_whenAttachmentIsEncrypted_writesPlainFileUnderOriginalName',
      () async {
        // Arrange
        final plain = Uint8List.fromList(utf8.encode('%PDF-1.4 secret plan'));

        // Act
        final result = await downloadAndDecrypt(plain, fileName);

        // Assert
        expect(result?.filePath?.split('/').last, fileName);
        expect(await File(result!.filePath!).readAsBytes(), plain);
      },
    );

    test('decryptFile_whenTheClientIsLoggedOut_writesNoPlainFile', () async {
      // Arrange
      final loggedOutRoom = Room(
        id: '!room:example.org',
        client: Client('logged out', database: MockDatabase()),
      );
      final plain = Uint8List.fromList(utf8.encode('%PDF-1.4 secret plan'));
      final decryptedPath = await StorageDirectoryManager.instance
          .getDecryptedFilePath(eventId: eventId, fileName: fileName);

      // Act
      final decrypting = downloadAndDecrypt(
        plain,
        fileName,
        inRoom: loggedOutRoom,
      );

      // Assert
      await expectLater(decrypting, throwsStateError);
      expect(File(decryptedPath).existsSync(), isFalse);
    });
  });

  group('cancelDownloadsInFlight', () {
    tearDown(() {
      if (getIt.isRegistered<MediaAPI>()) getIt.unregister<MediaAPI>();
    });

    test(
      'cancelDownloadsInFlight_beforeTheLogoutSweep_leavesNoDownloadedFile',
      () async {
        // Arrange
        final mediaAPI = _HangingMediaAPI();
        getIt.registerSingleton<MediaAPI>(mediaAPI);
        final event = Event(
          type: EventTypes.Message,
          content: {
            'msgtype': MessageTypes.File,
            'body': fileName,
            'url': 'mxc://example.org/plain',
          },
          eventId: eventId,
          senderId: '@bob:example.org',
          originServerTs: DateTime.now(),
          room: room,
        );
        final downloading = event.getFileInfo();
        await mediaAPI.started.future;

        // Act
        await DownloadFileExtension.cancelDownloadsInFlight();
        await StorageDirectoryManager.instance.deleteDownloadedFiles();
        mediaAPI.finish.complete();

        // Assert
        expect(await downloading, isNull);
        expect(Directory(p.join(tempDir.path, eventId)).existsSync(), isFalse);
      },
    );
  });
}

class _HangingMediaAPI implements MediaAPI {
  final started = Completer<void>();
  final finish = Completer<void>();

  @override
  Future<DownloadFileResponse> downloadFileInfo({
    required Uri uriPath,
    required String savePath,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    final file = File(savePath);
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    started.complete();
    await Future.any([finish.future, ?cancelToken?.whenCancel]);
    if (cancelToken?.isCancelled == true) {
      if (await file.exists()) await file.delete();
      throw CancelRequestException();
    }
    await file.create(recursive: true);
    await file.writeAsBytes([4, 5, 6], mode: FileMode.append);
    return DownloadFileResponse(
      statusCode: 200,
      requestOptions: RequestOptions(),
      savePath: savePath,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
