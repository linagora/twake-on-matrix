import 'package:file_picker/file_picker.dart';
import 'package:fluffychat/utils/mime_type_uitls.dart';
import 'package:matrix/matrix.dart';

extension PlatformFileListExtension on PlatformFile {
  MatrixFile toMatrixFileOnMobile({
    required String temporaryDirectoryPath,
  }) {
    return MatrixFile.fromMimeType(
      bytes: bytes,
      name: name,
      filePath: path ?? '$temporaryDirectoryPath/$name',
      mimeType: MimeTypeUitls.instance.getTwakeMimeType(name),
      readStream: readStream,
      sizeInBytes: size,
    );
  }

  MatrixFile toMatrixFileOnWeb() {
    return MatrixFile.fromMimeType(
      bytes: bytes,
      name: name,
      filePath: '',
      readStream: readStream,
      sizeInBytes: size,
      mimeType: MimeTypeUitls.instance.getTwakeMimeType(name),
    );
  }

  FileInfo toFileInfo({
    required String temporaryDirectoryPath,
  }) {
    return FileInfo(
      name,
      path ?? '$temporaryDirectoryPath/$name',
      size,
      readStream: readStream,
    );
  }
}
