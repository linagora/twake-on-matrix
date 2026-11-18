import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/pages/chat/input_bar/focus_suggestion_controller.dart';
import 'package:twake_chat/pages/chat/input_bar/input_bar.dart';

void main() {
  testWidgets('arrow up in a multi-line draft moves the cursor up a line', (
    tester,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final suggestionsController = SuggestionsController<Map<String, String?>>();
    addTearDown(() {
      controller.dispose();
      focusNode.dispose();
      suggestionsController.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: InputBar(
              minLines: 1,
              maxLines: 8,
              controller: controller,
              typeAheadFocusNode: focusNode,
              rawKeyboardFocusNode: FocusNode(),
              suggestionsController: suggestionsController,
              focusSuggestionController: FocusSuggestionController(),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump(const Duration(milliseconds: 200));

    const draft = 'one\ntwo\nthree';
    await tester.enterText(find.byType(TextField), draft);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 200));

    expect(focusNode.hasFocus, isTrue);
    expect(controller.text, draft);
    expect(controller.selection.baseOffset, 'one\ntwo'.length);
  });
}
