import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/widgets/file_widget/base_file_tile_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

void main() {
  setUp(() {
    getIt.registerSingleton(const SearchEngine());
  });

  tearDown(() {
    GetIt.instance.reset();
  });

  testWidgets(
    'FileNameText highlights a diacritic-insensitive match in the filename',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [LinagoraTextThemeExtension.material()]),
          home: const Scaffold(
            body: FileNameText(
              filename: 'Élie-report.pdf',
              highlightText: 'elie',
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final wrapperSpan = richText.text as TextSpan;
      final rootSpan = wrapperSpan.children!.single as TextSpan;
      final spans = rootSpan.children!.cast<TextSpan>();

      expect(spans.map((s) => s.text).toList(), ['Élie', '-report.pdf']);
    },
  );
}
