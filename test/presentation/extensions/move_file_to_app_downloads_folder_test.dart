import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';
import 'package:path/path.dart' as p;
import 'package:twake_chat/presentation/extensions/send_file_extension.dart';

class _UnencryptedRoom extends Fake implements Room {
  @override
  bool get encrypted => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('move_file_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => tempDir.path,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    tempDir.deleteSync(recursive: true);
  });

  test('a sent file counts as cached when it is kept, not when it was last '
      'edited, so the 7-day cleanup does not take it at once', () async {
    final picked = File(p.join(tempDir.path, 'picked', 'old.pdf'))
      ..createSync(recursive: true)
      ..setLastModifiedSync(DateTime(2020));
    final before = DateTime.now().subtract(const Duration(seconds: 2));

    await _UnencryptedRoom().moveFileToAppDownloadsFolder(
      eventId: r'$sent',
      fileName: 'old.pdf',
      sourcePath: picked.path,
    );

    final kept = File(p.join(tempDir.path, r'$sent', 'old.pdf'));
    expect(kept.existsSync(), isTrue);
    expect(kept.lastModifiedSync().isAfter(before), isTrue);
  });
}
