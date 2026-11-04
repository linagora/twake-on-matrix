import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:matrix/matrix.dart';
import 'package:twake_chat/data/network/extensions/file_info_extension.dart';
import 'package:twake_chat/domain/model/file_info/image_file_info.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('file_info_extension_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  Future<String> writePng(int width, int height) async {
    final bytes = Uint8List.fromList(
      img.encodePng(img.Image(width: width, height: height)),
    );
    final file = File('${tempDir.path}/image_${width}x$height.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  group('FileInfoExtension.toMatrixFile', () {
    testWidgets(
      'reads the dimensions of an image picked without width and height',
      (tester) async {
        final file = await tester.runAsync(() async {
          final path = await writePng(40, 80);
          return ImageFileInfo('portrait.png', filePath: path).toMatrixFile();
        });

        expect(file, isA<MatrixImageFile>());
        expect((file as MatrixImageFile).width, 40);
        expect(file.height, 80);
      },
    );

    testWidgets('keeps the dimensions already known by the file info', (
      tester,
    ) async {
      final file = await tester.runAsync(() async {
        final path = await writePng(40, 80);
        return ImageFileInfo(
          'portrait.png',
          filePath: path,
          width: 400,
          height: 800,
        ).toMatrixFile();
      });

      expect((file as MatrixImageFile).width, 400);
      expect(file.height, 800);
    });
  });
}
