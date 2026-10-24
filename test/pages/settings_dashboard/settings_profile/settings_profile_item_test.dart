import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/settings_dashboard/settings_profile/settings_profile_item.dart';
import 'package:twake_chat/presentation/enum/settings/settings_profile_enum.dart';
import 'package:twake_chat/presentation/model/settings/settings_profile_presentation.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController(text: 'Alice');
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Widget item(
    SettingsProfileEnum settingsProfileEnum, {
    required bool canEditDisplayName,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onCopyAction,
  }) {
    return SettingsProfileItemBuilder(
      settingsProfileEnum: settingsProfileEnum,
      title: settingsProfileEnum.name,
      settingsProfilePresentation: SettingsProfilePresentation(
        settingsProfileType: settingsProfileEnum.getSettingsProfileType(),
      ),
      suffixIcon: settingsProfileEnum.getTrailingIcon(),
      textEditingController: controller,
      canEditDisplayName: canEditDisplayName,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onCopyAction: onCopyAction,
    );
  }

  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Column(children: [child])),
      ),
    );
  }

  group('SettingsProfileItemBuilder', () {
    testWidgets('pencil focuses the editable display name', (tester) async {
      await pump(
        tester,
        item(SettingsProfileEnum.displayName, canEditDisplayName: true),
      );

      expect(focusNode.hasFocus, isFalse);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pump();

      expect(focusNode.hasFocus, isTrue);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).focusNode,
        focusNode,
      );
    });

    testWidgets('typing and submitting reach the callbacks', (tester) async {
      final changes = <String>[];
      final submissions = <String>[];
      await pump(
        tester,
        item(
          SettingsProfileEnum.displayName,
          canEditDisplayName: true,
          onChanged: changes.add,
          onSubmitted: submissions.add,
        ),
      );

      await tester.enterText(find.byType(TextField), 'Bob');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(controller.text, 'Bob');
      expect(changes, ['Bob']);
      expect(submissions, ['Bob']);
    });

    testWidgets('display name is read only when the server forbids edits', (
      tester,
    ) async {
      await pump(
        tester,
        item(SettingsProfileEnum.displayName, canEditDisplayName: false),
      );

      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('another edit row does not get the display name field', (
      tester,
    ) async {
      await pump(
        tester,
        item(SettingsProfileEnum.bio, canEditDisplayName: true),
      );

      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('matrix id row copies and is not editable', (tester) async {
      var copied = 0;
      await pump(
        tester,
        item(
          SettingsProfileEnum.matrixId,
          canEditDisplayName: true,
          onCopyAction: () => copied++,
        ),
      );

      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.byIcon(Icons.content_copy));

      expect(copied, 1);
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('editable field looks like the read only text at rest', (
      tester,
    ) async {
      await pump(
        tester,
        item(SettingsProfileEnum.displayName, canEditDisplayName: false),
      );
      final readOnlyText = tester.widget<Text>(find.text('Alice'));
      final readOnlyHeight = tester.getSize(find.text('Alice')).height;

      await pump(
        tester,
        item(SettingsProfileEnum.displayName, canEditDisplayName: true),
      );
      final textField = tester.widget<TextField>(find.byType(TextField));
      final editable = tester.widget<EditableText>(find.byType(EditableText));

      expect(textField.style, readOnlyText.style);
      expect(editable.style.color, readOnlyText.style?.color);
      expect(editable.style.fontSize, readOnlyText.style?.fontSize);
      expect(editable.style.fontWeight, readOnlyText.style?.fontWeight);
      expect(textField.decoration?.border, InputBorder.none);
      expect(textField.decoration?.isCollapsed, isTrue);
      expect(tester.getSize(find.byType(TextField)).height, readOnlyHeight);
    });
  });
}
