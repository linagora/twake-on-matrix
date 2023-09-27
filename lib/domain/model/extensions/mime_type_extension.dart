import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';

extension MediaTypeExtension on Event {
  bool isAndroidSupportedPreview() =>
      SupportedPreviewFileTypes.androidSupportedTypes.contains(mimeType);

  bool isIOSSupportedPreview() =>
      SupportedPreviewFileTypes.iOSSupportedTypes.containsKey(mimeType);

  bool isImageFile() =>
      SupportedPreviewFileTypes.imageMimeTypes.contains(mimeType);

  bool isDocFile() =>
      SupportedPreviewFileTypes.docMimeTypes.contains(mimeType) ||
      SupportedPreviewFileTypes.docFileTypes.contains(fileType!.toLowerCase());

  bool isPowerPointFile() =>
      SupportedPreviewFileTypes.pptMimeTypes.contains(mimeType) ||
      SupportedPreviewFileTypes.pptFileTypes.contains(fileType!.toLowerCase());

  bool isExcelFile() =>
      SupportedPreviewFileTypes.xlsMimeTypes.contains(mimeType) ||
      SupportedPreviewFileTypes.xlsFileTypes.contains(fileType!.toLowerCase());

  bool isZipFile() =>
      SupportedPreviewFileTypes.zipMimeTypes.contains(mimeType) ||
      SupportedPreviewFileTypes.zipFileTypes.contains(fileType!.toLowerCase());

  bool isPdfFile() =>
      SupportedPreviewFileTypes.pdfMimeTypes.contains(mimeType) ||
      SupportedPreviewFileTypes.pdfFileTypes.contains(fileType!.toLowerCase());

  bool isSupportedPreviewAnotherFile() =>
      SupportedPreviewFileTypes.supportAnotherTypes.contains(mimeType);

  String getIcon() {
    Logs().d(
      'AttachmentExtension::getIcon(): mediaType: $mimeType || fileType: $fileType',
    );
    if (mimeType?.isEmpty == true || fileType == null) {
      return ImagePaths.icFileUnknown;
    }

    switch (getPreviewIconFileType()) {
      case SupportedIconFileTypesEnum.image:
        return ImagePaths.icFileUnknown;
      case SupportedIconFileTypesEnum.doc:
        return ImagePaths.icFileDocx;
      case SupportedIconFileTypesEnum.excel:
        return ImagePaths.icFileXlsx;
      case SupportedIconFileTypesEnum.powerPoint:
        return ImagePaths.icFilePptx;
      case SupportedIconFileTypesEnum.pdf:
        return ImagePaths.icFilePdf;
      case SupportedIconFileTypesEnum.zip:
        return ImagePaths.icFileZip;
      case SupportedIconFileTypesEnum.unknown:
      default:
        return ImagePaths.icFileUnknown;
    }
  }

  String getFileType(BuildContext context) {
    if (fileType != null) {
      if (isSupportedPreviewAnotherFile()) {
        return L10n.of(context)!.file.toUpperCase();
      } else {
        return fileType!;
      }
    } else {
      return L10n.of(context)!.file.toUpperCase();
    }
  }

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
    } else {
      return SupportedIconFileTypesEnum.unknown;
    }
  }
}
