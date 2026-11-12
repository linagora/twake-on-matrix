import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/domain/model/file_info/video_file_info.dart';
import 'package:twake_chat/presentation/extensions/send_file_extension.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('video_compress');
  late Directory tempDir;
  late File original;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('compress_video_test');
    original = File('${tempDir.path}/screen.mp4')
      ..writeAsBytesSync(List.filled(100, 1));
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await tempDir.delete(recursive: true);
  });

  void mockCompression({required int compressedSize}) {
    final compressed = File('${tempDir.path}/compressed.mp4')
      ..writeAsBytesSync(List.filled(compressedSize, 2));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method != 'compressVideo') return null;
          // What the Android plugin returns for a 640x1422 portrait output.
          return jsonEncode({
            'path': compressed.path,
            'width': 1422,
            'height': 640,
            'orientation': 0,
            'filesize': compressedSize,
            'duration': 4000,
            'isCancel': false,
          });
        });
  }

  test('a compressed video does not take the width and height reported by '
      'the compressor, so the thumbnail gives its real orientation', () async {
    mockCompression(compressedSize: 10);

    final result = await compressVideoForUpload(
      VideoFileInfo(
        'screen.mp4',
        filePath: original.path,
        duration: const Duration(seconds: 4),
      ),
    );

    expect(result.filePath, '${tempDir.path}/compressed.mp4');
    expect(result.width, isNull);
    expect(result.height, isNull);
    expect(result.duration, const Duration(seconds: 4));
  });

  test('a compressed file that is not smaller is dropped and the original '
      'is sent as it is', () async {
    mockCompression(compressedSize: 200);
    final input = VideoFileInfo(
      'screen.mp4',
      filePath: original.path,
      width: 1080,
      height: 2400,
    );

    final result = await compressVideoForUpload(input);

    expect(result, same(input));
    expect(File('${tempDir.path}/compressed.mp4').existsSync(), isFalse);
  });
}
