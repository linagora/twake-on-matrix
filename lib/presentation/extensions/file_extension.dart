import 'dart:io';

import 'package:matrix/matrix.dart';
import 'package:mime/mime.dart';

extension XFileExtension on File {
  Future<MatrixFile> toMatrixFile() async {
    return MatrixImageFile(
      bytes: await readAsBytes(),
      sizeInBytes: lengthSync(),
      name: path.split('/').last,
      filePath: path,
      mimeType: lookupMimeType(path),
    );
  }
}
