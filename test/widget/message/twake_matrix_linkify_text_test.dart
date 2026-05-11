import 'package:fluffychat/widgets/twake_components/twake_matrix_linkify_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkfy_text/linkfy_text.dart';

void main() {
  group('[WIDGET TEST] - TwakeMatrixLinkifyText', () {
    testWidgets(
      'GIVEN a URL text WHEN tapping with primary button THEN calls onTapDownLink',
      (tester) async {
        Link? tappedLink;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwakeMatrixLinkifyText(
                text: 'https://example.com',
                onTapDownLink: (_, link) => tappedLink = link,
              ),
            ),
          ),
        );

        await tester.tap(find.text('https://example.com'));
        await tester.pump();

        expect(tappedLink?.value, 'https://example.com');
      },
    );

    testWidgets(
      'GIVEN a URL text WHEN right-clicking THEN calls onSecondaryTapDownLink',
      (tester) async {
        Link? tappedLink;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TwakeMatrixLinkifyText(
                text: 'https://example.com',
                onSecondaryTapDownLink: (_, link) => tappedLink = link,
              ),
            ),
          ),
        );

        await tester.tapAt(
          tester.getCenter(find.text('https://example.com')),
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await tester.pump();

        expect(tappedLink?.value, 'https://example.com');
      },
    );
  });
}
