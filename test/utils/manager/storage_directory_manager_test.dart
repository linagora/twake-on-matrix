import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
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

  group('writeDecryptedFile', () {
    test(
      'writeDecryptedFile_always_writesTheBytesInTheDecryptedFolderOfTheEvent',
      () async {
        // Arrange
        final matrixFile = MatrixFile(
          bytes: Uint8List.fromList([1, 2, 3]),
          name: 'voice.ogg',
        );

        // Act
        final file = await StorageDirectoryManager.instance.writeDecryptedFile(
          eventId: eventId,
          file: matrixFile,
        );

        // Assert
        expect(
          file.path,
          p.join(tempDir.path, 'decrypted', eventId, 'voice.ogg'),
        );
        expect(file.readAsBytesSync(), [1, 2, 3]);
        expect(tempDir.listSync().whereType<File>(), isEmpty);
      },
    );

    test(
      'writeDecryptedFile_whenOnlyDownloadsIsAvailable_throwsAndWritesNothing',
      () async {
        // Arrange
        final downloads = Directory(p.join(tempDir.path, 'Downloads'))
          ..createSync();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, (call) async {
              if (call.method == 'getDownloadsDirectory') return downloads.path;
              throw PlatformException(code: 'unavailable');
            });
        final matrixFile = MatrixFile(
          bytes: Uint8List.fromList([1, 2, 3]),
          name: 'voice.ogg',
        );

        // Act
        final writing = StorageDirectoryManager.instance.writeDecryptedFile(
          eventId: eventId,
          file: matrixFile,
        );

        // Assert
        await expectLater(writing, throwsStateError);
        expect(downloads.listSync(), isEmpty);
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

    test('deleteDownloadedFiles_whenAFileIsNamedLikeAnEvent_keepsIt', () async {
      // Arrange
      final userFile = File(p.join(tempDir.path, r'$budget.pdf'))..createSync();

      // Act
      await StorageDirectoryManager.instance.deleteDownloadedFiles();

      // Assert
      expect(userFile.existsSync(), isTrue);
    });

    test(
      'deleteDownloadedFiles_whenOnlyDownloadsIsAvailable_deletesNothing',
      () async {
        // Arrange
        final downloads = Directory(p.join(tempDir.path, 'Downloads'));
        final userFolder = Directory(p.join(downloads.path, r'$photos'))
          ..createSync(recursive: true);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, (call) async {
              if (call.method == 'getDownloadsDirectory') return downloads.path;
              throw PlatformException(code: 'unavailable');
            });

        // Act
        await StorageDirectoryManager.instance.deleteDownloadedFiles();

        // Assert
        expect(userFolder.existsSync(), isTrue);
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

  group('deleteFilesCachedBefore', () {
    final now = DateTime(2026, 11, 27, 12);
    final cutoff = now.subtract(const Duration(days: 7));
    final old = now.subtract(const Duration(days: 8));

    File place(String path, DateTime modified) =>
        File(p.join(tempDir.path, path))
          ..createSync(recursive: true)
          ..setLastModifiedSync(modified);

    test(
      'deleteFilesCachedBefore_always_deletesOnlyTheCachedFilesOlderThanTheCutoff',
      () async {
        // Arrange
        final oldDecrypted = place('decrypted/\$old/a.pdf', old);
        final oldDownloaded = place('\$old/a.pdf', old);
        final newDecrypted = place('decrypted/\$new/b.pdf', now);
        final newDownloaded = place('\$new/b.pdf', now);

        // Act
        await StorageDirectoryManager.instance.deleteFilesCachedBefore(cutoff);

        // Assert
        expect(oldDecrypted.existsSync(), isFalse);
        expect(oldDownloaded.existsSync(), isFalse);
        expect(newDecrypted.existsSync(), isTrue);
        expect(newDownloaded.existsSync(), isTrue);
        expect(oldDecrypted.parent.existsSync(), isFalse);
        expect(oldDownloaded.parent.existsSync(), isFalse);
        expect(
          Directory(p.join(tempDir.path, 'decrypted')).existsSync(),
          isTrue,
        );
      },
    );

    test(
      'deleteFilesCachedBefore_always_keepsSavedFilesAndOtherLibraries',
      () async {
        // Arrange
        final twakeFolder = await StorageDirectoryManager.instance
            .getTwakeDownloadsFolderInDevice();
        final saved = File(p.join(twakeFolder!, 'saved.pdf'))
          ..createSync(recursive: true)
          ..setLastModifiedSync(old);
        final other = place('image_picker/photo.jpg', old);
        final topLevel = place('\$budget.pdf', old);

        // Act
        await StorageDirectoryManager.instance.deleteFilesCachedBefore(cutoff);

        // Assert
        expect(saved.existsSync(), isTrue);
        expect(other.existsSync(), isTrue);
        expect(topLevel.existsSync(), isTrue);
      },
    );

    test(
      'deleteFilesCachedBefore_whenOnlyDownloadsIsAvailable_deletesNothing',
      () async {
        // Arrange
        final downloads = Directory(p.join(tempDir.path, 'Downloads'));
        final userFile = File(p.join(downloads.path, r'$photos', 'a.jpg'))
          ..createSync(recursive: true)
          ..setLastModifiedSync(old);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(pathProviderChannel, (call) async {
              if (call.method == 'getDownloadsDirectory') return downloads.path;
              throw PlatformException(code: 'unavailable');
            });

        // Act
        await StorageDirectoryManager.instance.deleteFilesCachedBefore(cutoff);

        // Assert
        expect(userFile.existsSync(), isTrue);
      },
    );

    test(
      'deleteFilesCachedBefore_whenAFileCannotBeDeleted_deletesTheOthersAndLogs',
      () async {
        // Arrange
        final locked = place('\$locked/a.pdf', old);
        final deletable = place('\$other/b.pdf', old);
        Process.runSync('chmod', ['555', locked.parent.path]);
        addTearDown(
          () => Process.runSync('chmod', ['755', locked.parent.path]),
        );
        Logs().outputEvents.clear();

        // Act
        await StorageDirectoryManager.instance.deleteFilesCachedBefore(cutoff);

        // Assert
        expect(locked.existsSync(), isTrue);
        expect(deletable.existsSync(), isFalse);
        expect(
          Logs().outputEvents.map((e) => e.level),
          contains(Level.warning),
        );
      },
    );

    test(
      'getFilePathInAppDownloads_duringTheSweep_resolvesOnceItIsDone',
      () async {
        // Arrange
        final cached = place('\$old/a.pdf', old);

        // Act
        final sweep = StorageDirectoryManager.instance.deleteFilesCachedBefore(
          cutoff,
        );
        await StorageDirectoryManager.instance.getFilePathInAppDownloads(
          eventId: r'$old',
          fileName: 'a.pdf',
        );

        // Assert
        expect(cached.existsSync(), isFalse);
        await sweep;
      },
    );
  });
}
