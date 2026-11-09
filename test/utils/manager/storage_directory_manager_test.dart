import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const eventId = r'$encrypted:example.org';
  const fileName = 'Secret Plan.pdf';
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('storage_directory_test');
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

  group('getDecryptedFilePath', () {
    test('getDecryptedFilePath_always_keepsTheOriginalFileName', () async {
      // Act
      final decryptedPath = await StorageDirectoryManager.instance
          .getDecryptedFilePath(eventId: eventId, fileName: fileName);

      // Assert
      expect(decryptedPath.split('/').last, fileName);
    });

    test(
      'getDecryptedFilePath_always_isOutsideTheEncryptedDownloadFolder',
      () async {
        // Act
        final decryptedPath = await StorageDirectoryManager.instance
            .getDecryptedFilePath(eventId: eventId, fileName: fileName);
        final encryptedPath = await StorageDirectoryManager.instance
            .getFilePathInAppDownloads(eventId: eventId, fileName: fileName);

        // Assert
        expect(p.isWithin(p.dirname(encryptedPath), decryptedPath), isFalse);
      },
    );

    test(
      'getDecryptedFilePath_whenNameHasPathSeparators_staysInTheEventFolder',
      () async {
        // Act
        final decryptedPath = await StorageDirectoryManager.instance
            .getDecryptedFilePath(eventId: eventId, fileName: r'../..\../x');

        // Assert
        expect(
          p.isWithin(
            p.join(tempDir.path, 'decrypted', eventId),
            p.normalize(decryptedPath),
          ),
          isTrue,
        );
      },
    );
  });

  group('getFilePathInAppDownloads', () {
    test(
      'getFilePathInAppDownloads_whenNameHasPathSeparators_staysInTheEventFolder',
      () async {
        // Act
        final downloadPath = await StorageDirectoryManager.instance
            .getFilePathInAppDownloads(eventId: eventId, fileName: '../../x');

        // Assert
        expect(
          p.isWithin(p.join(tempDir.path, eventId), p.normalize(downloadPath)),
          isTrue,
        );
      },
    );
  });
}
