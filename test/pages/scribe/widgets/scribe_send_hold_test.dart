import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:twake_chat/pages/chat/chat_input_row_style.dart';
import 'package:twake_chat/pages/scribe/scribe_controller.dart';
import 'package:twake_chat/pages/scribe/widgets/scribe_send_hold.dart';

const _roomId = '!room:example.com';

class _Rewriting extends ScribeController {
  @override
  bool build(String roomId) => true;
}

void main() {
  late int sends;

  setUp(() => sends = 0);

  Future<void> pumpHold(WidgetTester tester, {required bool rewriting}) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            if (rewriting)
              scribeControllerProvider(_roomId).overrideWith(_Rewriting.new),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ScribeSendHold(
                roomId: _roomId,
                child: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () => sends++,
                ),
              ),
            ),
          ),
        ),
      );

  double opacity(WidgetTester tester) => tester
      .widget<Opacity>(
        find.ancestor(
          of: find.byIcon(Icons.send),
          matching: find.byType(Opacity),
        ),
      )
      .opacity;

  testWidgets('the send works while the Scribe is idle', (tester) async {
    await pumpHold(tester, rewriting: false);

    await tester.tap(find.byIcon(Icons.send));

    expect(sends, 1);
    expect(opacity(tester), 1);
  });

  testWidgets('the send waits, dimmed, while the Scribe rewrites', (
    tester,
  ) async {
    await pumpHold(tester, rewriting: true);

    await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);

    expect(sends, 0);
    expect(opacity(tester), ChatInputRowStyle.inputComposerOpacity);
  });
}
