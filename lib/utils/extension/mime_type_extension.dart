import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

typedef TwakeMimeType = String?;

extension TwakeMimeTypeExtension on TwakeMimeType {
  static const String defaultUnsupportedImageMimeType = 'file/image';

  static const String defaultUnsupportedVideoMimeType = 'file/video';

  bool isAndroidSupportedPreview() =>
      SupportedPreviewFileTypes.androidSupportedTypes.contains(this);

  bool isIOSSupportedPreview() =>
      SupportedPreviewFileTypes.iOSSupportedTypes.containsKey(this);

  bool isImageFile() =>
      SupportedPreviewFileTypes.imageMimeTypes.contains(this) ||
      defaultUnsupportedImageMimeType == this;

  bool isDocFile({String? fileType}) =>
      SupportedPreviewFileTypes.docMimeTypes.contains(this) ||
      fileType != null &&
          SupportedPreviewFileTypes.docFileTypes
              .contains(fileType.toLowerCase());

  bool isPowerPointFile({String? fileType}) =>
      SupportedPreviewFileTypes.pptMimeTypes.contains(this) ||
      fileType != null &&
          SupportedPreviewFileTypes.pptFileTypes
              .contains(fileType.toLowerCase());

  bool isExcelFile({String? fileType}) =>
      SupportedPreviewFileTypes.xlsMimeTypes.contains(this) ||
      fileType != null &&
          SupportedPreviewFileTypes.xlsFileTypes
              .contains(fileType.toLowerCase());

  bool isZipFile({String? fileType}) =>
      SupportedPreviewFileTypes.zipMimeTypes.contains(this) ||
      fileType != null &&
          SupportedPreviewFileTypes.zipFileTypes
              .contains(fileType.toLowerCase());

  bool isVideoFile() {
    return SupportedPreviewFileTypes.videoMimeTypes.contains(this) ||
        defaultUnsupportedVideoMimeType == this;
  }

  bool isPdfFile({String? fileType}) =>
      SupportedPreviewFileTypes.pdfMimeTypes.contains(this) ||
      fileType != null &&
          SupportedPreviewFileTypes.pdfFileTypes
              .contains(fileType.toLowerCase());

  bool isAudioFile() => SupportedPreviewFileTypes.audioMimeTypes.contains(this);

  bool isSupportedPreviewAnotherFile() =>
      SupportedPreviewFileTypes.supportAnotherTypes.contains(this);

  SupportedIconFileTypesEnum getPreviewIconFileType() {
    if (isImageFile()) {
      return SupportedIconFileTypesEnum.image;
    } else if (isDocFile()) {
      return SupportedIconFileTypesEnum.doc;
    } else if (isExcelFile()) {
      return SupportedIconFileTypesEnum.excel;
    } else if (isPowerPointFile()) {
      return SupportedIconFileTypesEnum.powerPoint;
    } else if (isPdfFile()) {
      return SupportedIconFileTypesEnum.pdf;
    } else if (isZipFile()) {
      return SupportedIconFileTypesEnum.zip;
    } else if (isVideoFile()) {
      return SupportedIconFileTypesEnum.video;
    } else if (isAudioFile()) {
      return SupportedIconFileTypesEnum.audio;
    } else {
      return SupportedIconFileTypesEnum.unknown;
    }
  }

  String getIcon({String? fileType}) {
    Logs().d(
      'AttachmentExtension::getIcon(): mediaType: $this || fileType: $fileType',
    );
    if (this?.isEmpty == true || fileType == null) {
      return ImagePaths.icFileUnknown;
    }

    return getPreviewIconFileType().imagePath;
  }

  String getFileType(BuildContext context, {String? fileType}) {
    if (fileType != null) {
      if (isSupportedPreviewAnotherFile()) {
        return L10n.of(context)!.file.toUpperCase();
      } else {
        return fileType;
      }
    } else {
      return L10n.of(context)!.file.toUpperCase();
    }
  }

  static const String avifMimeType = 'image/avif';

  static const List<String> heicMimeTypes = [
    'image/heic',
    'image/heif',
  ];
}
