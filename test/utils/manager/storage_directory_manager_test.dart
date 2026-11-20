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
  const externalPathChannel = MethodChannel('external_path');
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('storage_directory_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => tempDir.path,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          externalPathChannel,
          (_) async => p.join(tempDir.path, 'Download'),
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(externalPathChannel, null);
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
      'getDecryptedFilePath_whenNameHasPathSeparators_keepsOnlyTheLastNames',
      () async {
        // Act
        final decryptedPath = await StorageDirectoryManager.instance
            .getDecryptedFilePath(eventId: eventId, fileName: r'../..\../x');

        // Assert
        expect(decryptedPath, p.join(tempDir.path, 'decrypted', eventId, 'x'));
      },
    );

    test(
      'getDecryptedFilePath_whenNameHasOnlyDotSegments_fallsBackToFile',
      () async {
        // Act
        final decryptedPath = await StorageDirectoryManager.instance
            .getDecryptedFilePath(eventId: eventId, fileName: '..');

        // Assert
        expect(
          decryptedPath,
          p.join(tempDir.path, 'decrypted', eventId, 'file'),
        );
      },
    );
  });

  group('getFilePathInAppDownloads', () {
    test(
      'getFilePathInAppDownloads_whenNameHasPathSeparators_joinsTheNames',
      () async {
        // Act
        final downloadPath = await StorageDirectoryManager.instance
            .getFilePathInAppDownloads(
              eventId: eventId,
              fileName: '../a/b.txt',
            );

        // Assert
        expect(downloadPath, p.join(tempDir.path, eventId, 'a_b.txt'));
      },
    );
  });

  group('getFilePathInTwakeDownloads', () {
    test(
      'getFilePathInTwakeDownloads_whenNameHasPathSeparators_keepsOnlyTheLastName',
      () async {
        // Act
        final twakeFolder = await StorageDirectoryManager.instance
            .getTwakeDownloadsFolderInDevice();
        final filePath = await StorageDirectoryManager.instance
            .getFilePathInTwakeDownloads('../../x');

        // Assert
        expect(filePath, p.join(twakeFolder!, 'x'));
      },
    );
  });

  group('deleteDownloadedFiles', () {
    Future<List<File>> placeFiles() async {
      final files = [
        File(
          await StorageDirectoryManager.instance.getDecryptedFilePath(
            eventId: eventId,
            fileName: fileName,
          ),
        ),
        File(
          await StorageDirectoryManager.instance.getFilePathInAppDownloads(
            eventId: eventId,
            fileName: fileName,
          ),
        ),
        File(p.join(tempDir.path, 'flutter_callback_cache.json')),
      ];
      for (final file in files) {
        file.createSync(recursive: true);
      }
      return files;
    }

    test(
      'deleteDownloadedFiles_always_keepsTheFilesOfOtherLibraries',
      () async {
        // Arrange
        final [decrypted, downloaded, other] = await placeFiles();

        // Act
        await StorageDirectoryManager.instance.deleteDownloadedFiles();

        // Assert
        expect(decrypted.existsSync(), isFalse);
        expect(downloaded.existsSync(), isFalse);
        expect(other.existsSync(), isTrue);
      },
    );

    test('deleteDownloadedFiles_calledTwiceAtOnce_bothComplete', () async {
      // Arrange
      final [decrypted, downloaded, _] = await placeFiles();

      // Act
      await Future.wait([
        StorageDirectoryManager.instance.deleteDownloadedFiles(),
        StorageDirectoryManager.instance.deleteDownloadedFiles(),
      ]);

      // Assert
      expect(decrypted.existsSync(), isFalse);
      expect(downloaded.existsSync(), isFalse);
    });
  });
}
