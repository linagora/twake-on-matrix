import 'package:fluffychat/presentation/extensions/text_editting_controller_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('addNewLine function', () {
    group('when input text have no selection', () {
      test('when cursor at the beginning', () {
        final textEditingController = TextEditingController();
        textEditingController.text = 'Hello World';
        _selectText(textEditingController, start: 0, end: 0);

        textEditingController.addNewLine();

        expect(textEditingController.text, equals('\nHello World'));
      });

      test('when cursor at the middle', () {
        final textEditingController = TextEditingController();
        textEditingController.text = 'Hello World';
        _selectText(textEditingController, start: 6, end: 6);

        textEditingController.addNewLine();

        expect(textEditingController.text, equals('Hello \nWorld'));
      });

      test('when cursor at the end', () {
        final textEditingController = TextEditingController();
        textEditingController.text = 'Hello World';
        _selectText(textEditingController, start: 11, end: 11);

        textEditingController.addNewLine();

        expect(textEditingController.text, equals('Hello World\n'));
      });
    });

    group('when input text have selection', () {
      test('when selection at the beginning with 5 characters', () {
        final textEditingController = TextEditingController();
        textEditingController.text = 'Hello World';
        _selectText(textEditingController, start: 0, end: 5);

        textEditingController.addNewLine();

        expect(textEditingController.text, equals('\n World'));
      });

      test('when selection at the middle', () {
        final textEditingController = TextEditingController();
        textEditingController.text = 'HelloWorld';
        _selectText(textEditingController, start: 6, end: 9);

        textEditingController.addNewLine();

        expect(textEditingController.text, equals('HelloW\nd'));
      });

      test('when selection at the end', () {
        final textEditingController = TextEditingController();
        textEditingController.text = 'Hello World';
        _selectText(textEditingController, start: 9, end: 11);

        textEditingController.addNewLine();

        expect(textEditingController.text, equals('Hello Wor\n'));
      });
    });
  });
}

void _selectText(
  TextEditingController textEditingController, {
  required int start,
  required int end,
}) {
  textEditingController.selection =
      TextSelection(baseOffset: start, extentOffset: end);
}
