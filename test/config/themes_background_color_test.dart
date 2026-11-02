import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:twake_chat/config/themes.dart';

void main() {
  Future<Color> pumpAndGetColor(
    WidgetTester tester,
    Brightness brightness,
  ) async {
    late Color color;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: brightness),
        home: Builder(
          builder: (context) {
            color = TwakeThemes.backgroundColor(context);
            return const SizedBox();
          },
        ),
      ),
    );
    return color;
  }

  group('TwakeThemes.backgroundColor', () {
    testWidgets('returns the light background token in light mode', (
      tester,
    ) async {
      expect(
        await pumpAndGetColor(tester, Brightness.light),
        LinagoraSysColors.material().background,
      );
    });

    testWidgets('returns the dark background token in dark mode', (
      tester,
    ) async {
      expect(
        await pumpAndGetColor(tester, Brightness.dark),
        LinagoraSysColors.material().backgroundDark,
      );
    });
  });
}
