import 'dart:io';

import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/extensions/string_extension.dart';
import 'package:twake_chat/utils/exception/save_to_downloads_exception.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';

class StorageDirectoryManager {
  StorageDirectoryManager._();

  static final StorageDirectoryManager _instance = StorageDirectoryManager._();

  static StorageDirectoryManager get instance => _instance;

  static const _decryptedFolder = 'decrypted';

  Future<String> getFileStoreDirectory() async =>
      await _appFileStoreDirectory() ?? (await getDownloadsDirectory())!.path;

  Future<String?> _appFileStoreDirectory() async {
    try {
      return (await getTemporaryDirectory()).path;
    } catch (_) {}
    try {
      return (await getApplicationDocumentsDirectory()).path;
    } catch (_) {}
    return null;
  }

  /// Only the manager's own folders, never the public Downloads fallback.
  Future<void> deleteDownloadedFiles() async {
    final root = await _appFileStoreDirectory();
    if (root == null) return;
    final directory = Directory(root);
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name != _decryptedFolder && !name.startsWith(r'$')) continue;
      try {
        await entity.delete(recursive: true);
      } on PathNotFoundException {
        // Two last logouts can run at once.
      }
    }
  }

  Future<String> getFilePathInAppDownloads({
    required String eventId,
    required String fileName,
  }) async {
    final fileStoreDirectory = await StorageDirectoryManager.instance
        .getFileStoreDirectory();
    return '$fileStoreDirectory/$eventId/${fileName.safeFileName}';
  }

  Future<String?> getTwakeDownloadsFolderInDevice() async {
    try {
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOAD,
      );
      if (downloadPath.isNotEmpty == true) {
        return '$downloadPath/${AppConfig.applicationName}';
      }
      throw SaveToDownloadsException(error: 'Download path is empty');
    } catch (e) {
      Logs().e('StorageDirectoryUtils:: getDownloadFolderDevice: $e');
    }
    return null;
  }

  Future<String> getFilePathInTwakeDownloads(String fileName) async {
    final twakeFolder = await getTwakeDownloadsFolderInDevice();
    if (twakeFolder?.isNotEmpty != true) {
      throw SaveToDownloadsException(error: 'Twake folder is empty');
    }
    return getAvailableFilePath('$twakeFolder/${fileName.safeFileName}');
  }

  Future<String> getAvailableFilePath(String filePath) async {
    String availableFilePath = filePath;
    final positionOfDot = filePath.lastIndexOf('.');
    String extension = '';
    String fileName = '';
    int counter = 1;
    if (positionOfDot != -1) {
      extension = filePath.substring(positionOfDot);
      fileName = filePath.substring(0, positionOfDot);
    } else {
      fileName = filePath;
    }
    while (await File(availableFilePath).exists()) {
      availableFilePath = '$fileName ($counter)$extension';
      counter++;
    }
    return availableFilePath;
  }

  Future<String> getDecryptedFilePath({
    required String eventId,
    required String fileName,
  }) async {
    final fileStoreDirectory = await StorageDirectoryManager.instance
        .getFileStoreDirectory();
    return _decryptedFilePath(fileStoreDirectory, eventId, fileName);
  }

  String _decryptedFilePath(String root, String eventId, String fileName) =>
      '$root/$_decryptedFolder/$eventId/${fileName.safeFileName}';

  Future<File> writeDecryptedFile({
    required String eventId,
    required MatrixFile file,
  }) async {
    final root = await _appFileStoreDirectory();
    if (root == null) {
      throw StateError('No app-owned directory for decrypted files');
    }
    final decryptedFile = File(_decryptedFilePath(root, eventId, file.name));
    await decryptedFile.parent.create(recursive: true);
    return decryptedFile.writeAsBytes(file.bytes);
  }

  String convertFileExtension(String filename, String newExtension) {
    final lastDotIndex = filename.lastIndexOf('.');

    if (lastDotIndex == -1) {
      return '$filename.$newExtension';
    } else {
      final nameWithoutExtension = filename.substring(0, lastDotIndex);
      return '$nameWithoutExtension.$newExtension';
    }
  }
}
