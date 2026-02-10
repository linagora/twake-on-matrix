import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/utils/stream_list_int_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/size_string.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:file_saver/file_saver.dart';

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
    if (PlatformInfos.isWeb) {
      return await downloadFileInWeb(context);
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
    final box = context.findRenderObject() as RenderBox?;
    await Share.shareXFiles(
      [XFile.fromData(bytes, name: name, mimeType: mimeType)],
      sharePositionOrigin: box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    );
    return;
  }

  Future<String?> downloadFileInWeb(BuildContext context) async {
    Logs().d("MatrixFileExtension()::downloadFileInWeb()::download on Web");
    try {
      final directory = await FileSaver.instance.saveFile(
        name: name,
        bytes: bytes,
      );
      return '$directory/$name';
    } catch (e) {
      Logs().e("MatrixFileExtension()::downloadFileInWeb()::Error: $e");
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

  bool isSendingImageInWeb() {
    return this is MatrixImageFile;
  }

  bool isSendingImageInMobile() {
    return this is MatrixImageFile && !PlatformInfos.isWeb;
  }
}

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
