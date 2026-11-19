import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/widgets/blur_hash_background.dart';

const _hash = 'L5H2EC=PM+yV0g-mq.wG9c010J}I';

Widget _app({required bool tickersEnabled}) => MaterialApp(
  home: TickerMode(
    enabled: tickersEnabled,
    child: const SizedBox(
      width: 100,
      height: 100,
      child: BlurHashBackground(hash: _hash),
    ),
  ),
);

Future<void> _decode(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();
  }
}

void main() {
  testWidgets('shows the decoded hash', (tester) async {
    await tester.pumpWidget(_app(tickersEnabled: true));
    await _decode(tester);

    expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
  });

  testWidgets(
    'keeps a usable image after memory pressure while covered by another route',
    (tester) async {
      await tester.pumpWidget(_app(tickersEnabled: true));
      await _decode(tester);

      await tester.pumpWidget(_app(tickersEnabled: false));
      tester.binding.handleMemoryPressure();
      await tester.pumpWidget(_app(tickersEnabled: true));
      await _decode(tester);

      expect(tester.takeException(), isNull);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    },
  );

  testWidgets('falls back to a plain background on an invalid hash', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BlurHashBackground(hash: 'invalid')),
    );
    await _decode(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(RawImage), findsNothing);
  });
}
