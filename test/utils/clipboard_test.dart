import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:twake_chat/utils/clipboard.dart';

class _FakeProgress extends Fake implements ReadProgress {}

class _FakeFile extends Fake implements DataReaderFile {
  _FakeFile(this.bytes);

  final Uint8List bytes;

  @override
  String? get fileName => 'copied.png';

  @override
  Future<Uint8List> readAll() async => bytes;
}

class _FakeItem extends Fake implements ClipboardDataReader {
  _FakeItem({this.bytes});

  final Uint8List? bytes;

  @override
  List<DataFormat> getFormats(List<DataFormat> allFormats) =>
      bytes != null && allFormats.contains(Formats.png)
      ? [Formats.png]
      : const [];

  @override
  ReadProgress? getFile(
    FileFormat? format,
    AsyncValueChanged<DataReaderFile> onFile, {
    ValueChanged<Object>? onError,
    bool allowVirtualFiles = true,
    bool synthesizeFilesFromURIs = true,
  }) {
    onFile(_FakeFile(bytes!));
    return _FakeProgress();
  }
}

void main() {
  testWidgets('skips a pasted item that is not an image', (tester) async {
    final images = await tester.runAsync(
      () async => TwakeClipboard.instance.pasteImagesUsingBytes(
        reader: ClipboardReader([
          _FakeItem(),
          _FakeItem(bytes: Uint8List.fromList([1, 2, 3])),
        ]),
      ),
    );

    expect(images, hasLength(1));
    expect(images!.single!.bytes, [1, 2, 3]);
  });
}
