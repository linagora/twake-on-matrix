import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:twake_chat/utils/stream_list_int_extension.dart';
import 'package:twake_chat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';
import 'package:twake_chat/utils/extension/share_position_origin_extension.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/size_string.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:twake_chat/domain/model/extensions/string_extension.dart';
import 'package:twake_chat/utils/manager/storage_directory_manager.dart';

extension MatrixFileExtension on MatrixFile {
  bool isImage() {
    // List of common image MIME types
    const imageMimeTypes = [
      'image/jpeg',
      'image/png',
      'image/gif',
      'image/bmp',
      'image/webp',
      'image/tiff',
    ];

    // List of common image file extensions
    const imageExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.bmp',
      '.webp',
      '.tiff',
    ];

    // Check if the MIME type is in the list, considering null
    if (imageMimeTypes.contains(mimeType)) {
      return true;
    }

    // Check if the file name ends with an image extension
    for (final ext in imageExtensions) {
      if (name.toLowerCase().endsWith(ext)) {
        return true;
      }
    }

    return false;
  }

  Future<String?> downloadFile(BuildContext context) async {
    if (PlatformInfos.isDesktop) {
      return await downloadFileOnDesktop(context);
    }

    if (PlatformInfos.isMobile) {
      return await downloadImageInMobile(context);
    }

    throw UnsupportedError(
      'Download feature is not supported on this platform',
    );
  }

  void share(BuildContext context) async {
    // Workaround for iPad from
    // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus/share_plus#ipad
    await Share.shareXFiles([
      XFile.fromData(bytes, name: name, mimeType: mimeType),
    ], sharePositionOrigin: context.sharePositionOrigin);
    return;
  }

  /// Writes the file into Downloads under the next free name, never over an
  /// existing file, and says so. Returns the full path, or null on failure.
  Future<String?> downloadFileOnDesktop(BuildContext context) async {
    try {
      final downloads = await getDownloadsDirectory();
      if (downloads == null) return null;
      final fileExt = extensionFromMime(mimeType);
      final hasExt =
          fileExt.isEmpty || name.toLowerCase().endsWith('.$fileExt');
      final fileName = hasExt ? name : '$name.$fileExt';
      final path = await StorageDirectoryManager.instance.getAvailableFilePath(
        '${downloads.path}/${fileName.safeFileName}',
      );
      await File(path).writeAsBytes(bytes);
      if (context.mounted) {
        TwakeSnackBar.show(context, L10n.of(context)!.fileSavedToDownloads);
      }
      return path;
    } catch (e) {
      Logs().e("MatrixFileExtension()::downloadFileOnDesktop()::Error: $e");
    }
    return null;
  }

  Future<String> downloadImageInMobile(BuildContext context) async {
    Logs().d(
      "MatrixFileExtension()::downloadImageInMobile()::download on Mobile",
    );

    final result = await ImageGallerySaver.saveImage(bytes, name: name);

    TwakeSnackBar.show(
      context,
      result?['isSuccess'] == true
          ? L10n.of(context)!.downloadImageSuccess
          : L10n.of(context)!.downloadImageError,
    );

    return result?['filePath'] ?? '';
  }

  FileType get filePickerFileType {
    if (this is MatrixImageFile) return FileType.image;
    if (this is MatrixAudioFile) return FileType.audio;
    if (this is MatrixVideoFile) return FileType.video;
    return FileType.any;
  }

  MatrixFile get detectFileType {
    if (msgType == MessageTypes.Image) {
      return MatrixImageFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    if (msgType == MessageTypes.Video) {
      return MatrixVideoFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    if (msgType == MessageTypes.Audio) {
      return MatrixAudioFile(bytes: bytes, name: name, mimeType: mimeType);
    }
    return this;
  }

  String get sizeString => size.sizeString;

  String? get fileExtension =>
      name.contains('.') ? name.split('.').last.toUpperCase() : null;

  Future<Uint8List> streamToUint8List(Stream<List<int>> stream) async {
    return await stream.toBytes();
  }

  bool get isFileHaveThumbnail =>
      this is MatrixImageFile || this is MatrixVideoFile;

  bool isFileHaveError(double maxSize) => size > maxSize;

  bool isSendingImage() {
    return this is MatrixImageFile;
  }
}

@immutable
class TwakeAudioFile extends MatrixFile {
  final int? duration;

  TwakeAudioFile({
    required super.name,
    super.mimeType,
    required super.bytes,
    this.duration,
  });

  @override
  String get msgType => 'm.audio';

  @override
  Map<String, dynamic> get info =>
      ({...super.info, if (duration != null) 'duration': duration});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TwakeAudioFile &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          mimeType == other.mimeType &&
          bytes == other.bytes &&
          duration == other.duration;

  @override
  int get hashCode =>
      name.hashCode ^ mimeType.hashCode ^ bytes.hashCode ^ duration.hashCode;
}
