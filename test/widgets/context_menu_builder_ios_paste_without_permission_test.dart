import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/context_menu_builder_ios_paste_without_permission.dart';

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

  testWidgets(
    'Paste hands a clipboard image to onPasteImage instead of pasting text',
    (tester) async {
      final controller = TextEditingController();
      var pasteImageCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextField(
              controller: controller,
              contextMenuBuilder: (context, editableTextState) =>
                  mobileTwakeContextMenuBuilder(
                    context,
                    editableTextState,
                    onPasteImage: () async {
                      pasteImageCalls++;
                      return true;
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

      expect(pasteImageCalls, 1);
      expect(controller.text, isEmpty);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
  );
}
