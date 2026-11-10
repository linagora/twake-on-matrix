import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:twake_chat/widgets/context_menu_builder_ios_paste_without_permission.dart';

class _DoneProgress implements ReadProgress {
  @override
  ValueListenable<double?> get fraction => ValueNotifier(1.0);

  @override
  ValueListenable<bool> get cancellable => ValueNotifier(false);

  @override
  void cancel() {}
}

class _TextClipboardReader extends ClipboardReader {
  _TextClipboardReader(this.text) : super([]);

  final String text;

  @override
  List<DataFormat> getFormats(List<DataFormat> allFormats) => [
    Formats.plainText,
  ];

  @override
  ReadProgress? getValue<T extends Object>(
    ValueFormat<T> format,
    AsyncValueChanged<T?> onValue, {
    ValueChanged<Object>? onError,
  }) {
    if (!identical(format, Formats.plainText)) return null;
    onValue(text as T);
    return _DoneProgress();
  }
}

void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.hasStrings') {
            return {'value': false};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<void> tapPaste(
    WidgetTester tester, {
    required TextEditingController controller,
    required ClipboardReader reader,
    required Future<bool> Function(ClipboardReader reader) onPasteImage,
    required VoidCallback onRead,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            contextMenuBuilder: (context, editableTextState) =>
                mobileTwakeContextMenuBuilder(
                  context,
                  editableTextState,
                  onPasteImage: onPasteImage,
                  readClipboard: () async {
                    onRead();
                    return reader;
                  },
                ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();
    tester.state<EditableTextState>(find.byType(EditableText)).showToolbar();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paste'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Paste hands a clipboard image to onPasteImage instead of pasting text',
    (tester) async {
      final controller = TextEditingController();
      final reader = _TextClipboardReader('ignored');
      ClipboardReader? received;

      await tapPaste(
        tester,
        controller: controller,
        reader: reader,
        onPasteImage: (reader) async {
          received = reader;
          return true;
        },
        onRead: () {},
      );

      expect(received, same(reader));
      expect(controller.text, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );

  testWidgets('Paste falls back to the text of the same clipboard read', (
    tester,
  ) async {
    final controller = TextEditingController();
    var reads = 0;

    await tapPaste(
      tester,
      controller: controller,
      reader: _TextClipboardReader('https://example.org'),
      onPasteImage: (_) async => false,
      onRead: () => reads++,
    );

    expect(controller.text, 'https://example.org');
    expect(reads, 1);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
}
