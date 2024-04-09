import 'dart:io';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/utils/exception/save_to_downloads_exception.dart';
import 'package:matrix/matrix.dart';
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';

class StorageDirectoryUtils {
  StorageDirectoryUtils._();

  static final StorageDirectoryUtils _instance = StorageDirectoryUtils._();

  static StorageDirectoryUtils get instance => _instance;

  static String? _tempDirectoryPath;

  Future<String> getFileStoreDirectory() async {
    try {
      try {
        return (await getTemporaryDirectory()).path;
      } catch (_) {
        return (await getApplicationDocumentsDirectory()).path;
      }
    } catch (_) {
      return (await getDownloadsDirectory())!.path;
    }
  }

  Future<String> getDownloadFolderInApp() async {
    _tempDirectoryPath ??= (await getTemporaryDirectory()).path;
    return '$_tempDirectoryPath/Downloads';
  }

  Future<String> getFilePathInAppDownloads({
    required String eventId,
    required String fileName,
  }) async {
    final downloadInAppFolder =
        await StorageDirectoryUtils.instance.getDownloadFolderInApp();
    return '$downloadInAppFolder/$eventId/$fileName';
  }

  Future<String?> getTwakeDownloadsFolderInDevice() async {
    try {
      final downloadPath = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOADS,
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

  Future<String> getMediaFilePath({
    required Uri mxcUrl,
  }) async {
    final temporaryDirectory = await getTemporaryDirectory();
    return '${temporaryDirectory.path}/${Uri.encodeComponent(mxcUrl.toString())}';
  }

  String getDecryptedFilePath({
    required String savePath,
  }) {
    return '${savePath}decrypted';
  }
}
