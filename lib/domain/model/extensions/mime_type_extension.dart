import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/event_extension.dart';
import 'package:matrix/matrix.dart';

extension MediaTypeExtension on Event {
  bool isAndroidSupportedPreview() => SupportedPreviewFileTypes.androidSupportedTypes.contains(mimeType);

  bool isIOSSupportedPreview() => SupportedPreviewFileTypes.iOSSupportedTypes.containsKey(mimeType);

  bool isImageFile() => SupportedPreviewFileTypes.imageMimeTypes.contains(mimeType);

  bool isDocFile() => SupportedPreviewFileTypes.docMimeTypes.contains(mimeType);

  bool isPowerPointFile() => SupportedPreviewFileTypes.pptMimeTypes.contains(mimeType);

  bool isExcelFile() => SupportedPreviewFileTypes.xlsMimeTypes.contains(mimeType);

  bool isZipFile() => SupportedPreviewFileTypes.zipMimeTypes.contains(mimeType);

  bool isPdfFile() => SupportedPreviewFileTypes.pdfMimeTypes.contains(mimeType);

  bool isSupportedPreviewAnotherFile() => SupportedPreviewFileTypes.supportAnotherTypes.contains(mimeType);

  String getIcon() {
    Logs().d('AttachmentExtension::getIcon(): mediaType: $mimeType');
    if (mimeType?.isEmpty == true) {
      return ImagePaths.icFileUnKnow;
    }
    if (isDocFile()) {
      return ImagePaths.icFileDocx;
    } else if (isExcelFile()) {
      return ImagePaths.icFileXlsx;
    } else if (isPowerPointFile()) {
      return ImagePaths.icFilePptx;
    } else if (isPdfFile()) {
      return ImagePaths.icFilePdf;
    } else if (isZipFile()) {
      return ImagePaths.icFileZip;
    }
    return ImagePaths.icFileUnKnow;
  }

  String getFileType(BuildContext context) {
    if (isSupportedPreviewAnotherFile()) {
      return L10n.of(context)!.file.toUpperCase();
    } else {
      return fileType!;
    }
  }
}
