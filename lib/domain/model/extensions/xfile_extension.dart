import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:matrix/matrix.dart';

extension XFileExtension on XFile {
  Future<MatrixFile> toMatrixFile() async {
    return MatrixFile.fromMimeType(
      bytes: await readAsBytes(),
      mimeType: mimeType,
      name: name,
      filePath: path,
      sizeInBytes: await length(),
      readStream: readAsBytes().asStream(),
    );
  }

  Future<PlatformFile> toPlatformFile() async {
    return PlatformFile.fromMap({
      'name': name,
      'path': path,
      'bytes': await readAsBytes(),
      'size': await length(),
      'readStream': readAsBytes().asStream(),
    });
  }
}
