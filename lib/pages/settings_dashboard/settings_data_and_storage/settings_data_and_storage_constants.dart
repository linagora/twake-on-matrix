import 'package:fluffychat/domain/model/preview_file/supported_preview_file_types.dart';

enum StorageCategory {
  stickers(extensions: {'tgs', 'lottie'}),
  medias(
    extensions: {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'heic',
      'heif',
      'tiff',
      'ico',
      'avif',
    },
  ),
  files(
    extensions: {
      ...SupportedPreviewFileTypes.pdfFileTypes,
      'rtf',
      ...SupportedPreviewFileTypes.docFileTypes,
      'odt',
      'txt',
      ...SupportedPreviewFileTypes.xlsFileTypes,
      'csv',
      ...SupportedPreviewFileTypes.pptFileTypes,
      ...SupportedPreviewFileTypes.zipFileTypes,
      'tar',
      'gz',
      'json',
      'xml',
      'html',
      'epub',
    },
  ),
  videos(
    extensions: {
      'mp4',
      'mov',
      'avi',
      'mkv',
      'm4v',
      '3gp',
      'flv',
      'wmv',
      'ts',
      'webm',
      'mpeg',
      'mpg',
      'asf',
    },
  ),
  other(extensions: {});

  const StorageCategory({required this.extensions});

  final Set<String> extensions;

  static StorageCategory fromFile(String filePath) => values.firstWhere(
    (category) => category._matches(filePath),
    orElse: () => other,
  );

  bool _matches(String filePath) {
    final String ext = filePath.contains('.')
        ? filePath.split('.').last.toLowerCase()
        : '';
    return switch (this) {
      StorageCategory.stickers =>
        extensions.contains(ext) || filePath.toLowerCase().contains('sticker'),
      StorageCategory.other => false,
      _ => extensions.contains(ext),
    };
  }
}
