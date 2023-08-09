import 'package:flutter/foundation.dart';
import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

extension FileInfoExtension on FileInfo {
  String get fileExtension => fileName.split('.').last;

  String get mimeType =>
      lookupMimeType(kIsWeb ? fileName : filePath) ??
      'application/octet-stream';

  Map<String, dynamic> get metadata => ({
        'mimetype': mimeType,
        'size': fileSize,
      });
}
