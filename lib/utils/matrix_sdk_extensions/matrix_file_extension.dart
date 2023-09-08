import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/size_string.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:file_saver/file_saver.dart';

extension MatrixFileExtension on MatrixFile {
  void downloadFile(BuildContext context) async {
    if (PlatformInfos.isWeb) {
      return downloadImageInWeb(context);
    }

    if (PlatformInfos.isMobile) {
      return downloadImageInMobile(context);
    }
  }

  void share(BuildContext context) async {
    // Workaround for iPad from
    // https://github.com/fluttercommunity/plus_plugins/tree/main/packages/share_plus/share_plus#ipad
    final box = context.findRenderObject() as RenderBox?;
    if (bytes == null) {
      return;
    }
    await Share.shareXFiles(
      [XFile.fromData(bytes!, name: name, mimeType: mimeType)],
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
    return;
  }

  void downloadImageInWeb(BuildContext context) async {
    Logs().d("MatrixFileExtension()::downloadImageInWeb()::download on Web");

    final directory = await FileSaver.instance.saveFile(
      name,
      bytes!,
      extensionFromMime(mimeType),
      mimeType: mimeType.toMimeTypeEnum(),
    );

    Fluttertoast.showToast(
      msg: L10n.of(context)!.downloadFileInWeb(directory),
    );
  }

  void downloadImageInMobile(BuildContext context) async {
    Logs().d(
      "MatrixFileExtension()::downloadImageInMobile()::download on Mobile",
    );

    final result = await ImageGallerySaver.saveImage(
      bytes ?? Uint8List(0),
      name: name,
    );

    Fluttertoast.showToast(
      msg: result?['isSuccess']
          ? L10n.of(context)!.downloadImageSuccess
          : L10n.of(context)!.downloadImageError,
    );
  }

  FileType get filePickerFileType {
    if (this is MatrixImageFile) return FileType.image;
    if (this is MatrixAudioFile) return FileType.audio;
    if (this is MatrixVideoFile) return FileType.video;
    return FileType.any;
  }

  MatrixFile get detectFileType {
    if (bytes == null) {
      return this;
    }
    if (msgType == MessageTypes.Image) {
      return MatrixImageFile(bytes: bytes!, name: name, filePath: filePath);
    }
    if (msgType == MessageTypes.Video) {
      return MatrixVideoFile(bytes: bytes!, name: name, filePath: filePath);
    }
    if (msgType == MessageTypes.Audio) {
      return MatrixAudioFile(bytes: bytes!, name: name, filePath: filePath);
    }
    return this;
  }

  String get sizeString => size.sizeString;
}
