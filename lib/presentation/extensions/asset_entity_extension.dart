import 'dart:convert';
import 'dart:typed_data';

import 'package:fluffychat/data/network/upload_file/file_info.dart';
import 'package:fluffychat/presentation/model/image_type.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_file_extension.dart';
import 'package:matrix/matrix.dart';
import 'package:photo_manager/photo_manager.dart';

extension AssetEntityExtension on AssetEntity {

  Future<MatrixFile?> toMatrixFile() async {
    final file = await loadFile();
    if (file != null) {
      return MatrixImageFile(
        bytes: Uint8List.fromList(utf8.encode(file.path)), 
        name: title ?? await titleAsync,
        mimeType: await mimeTypeAsync,
      );
    }
    return null;
  }

  Future<FileInfo?> toFileInfo() async {
    final file = await loadFile();
    if (file == null) {
      return null;
    }
    return FileInfo(
      fileName,
      file.path,
      file.lengthSync()
    );
  }
}