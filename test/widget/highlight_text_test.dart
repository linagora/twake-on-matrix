import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

void main() {
  setUp(() {
    getIt.registerSingleton(const SearchEngine());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets(
    'HighlightText highlights a diacritic-insensitive match with the default options',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightText(
              text: 'Élie Dupont',
              searchWord: 'elie',
              style: TextStyle(color: Colors.black),
              highlightStyle: TextStyle(color: Colors.amber),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final wrapperSpan = richText.text as TextSpan;
      final rootSpan = wrapperSpan.children!.single as TextSpan;
      final spans = rootSpan.children!.cast<TextSpan>();

      expect(spans.map((s) => s.text).toList(), ['Élie', ' Dupont']);
      expect(spans[0].style?.color, Colors.amber);
      expect(spans[1].style?.color, Colors.black);
    },
  );

  testWidgets(
    'HighlightText renders plain text with no highlight when searchWord is empty',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HighlightText(
              text: 'Élie Dupont',
              searchWord: '',
              style: TextStyle(color: Colors.black),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final wrapperSpan = richText.text as TextSpan;
      final rootSpan = wrapperSpan.children!.single as TextSpan;
      final spans = rootSpan.children!.cast<TextSpan>();

      expect(spans.map((s) => s.text).toList(), ['Élie Dupont']);
    },
  );
}
