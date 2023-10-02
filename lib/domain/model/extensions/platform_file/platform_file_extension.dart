import 'package:file_picker/file_picker.dart';
import 'package:matrix/matrix.dart';

extension PlatformFileListExtension on PlatformFile {
  MatrixFile toMatrixFile() {
    return MatrixFile.fromMimeType(
      bytes: bytes,
      name: name,
      filePath: '',
    );
  }
}
