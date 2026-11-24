import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twake_chat/widgets/twake_components/floating_capsule.dart';
import 'package:twake_chat/widgets/twake_components/twake_header.dart';

import 'chat_list_header_test_harness.dart';

const _pen = Key('new_chat_pen');

void main() {
  setUpHeaderTests();

  group('[ChatList] new chat capsule', () {
    testWidgets('GIVEN a phone\n'
        'THEN the pen sits in a floating capsule, outside the app bar', (
      tester,
    ) async {
      await HeaderHarness.pump(tester, const HeaderView.phoneWithStatusBar());

      expect(
        find.ancestor(
          of: find.byKey(_pen),
          matching: find.byType(FloatingCapsule),
        ),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: find.byKey(_pen), matching: find.byType(TwakeHeader)),
        findsNothing,
      );
    });

    testWidgets('GIVEN a phone\n'
        'THEN the capsule sits on the app bar row, 16 pt from the edge', (
      tester,
    ) async {
      await HeaderHarness.pump(tester, const HeaderView.phoneWithStatusBar());

      final capsule = tester.getRect(find.byType(FloatingCapsule));
      final appBar = tester.getRect(find.byType(TwakeHeader));
      expect(capsule.right, mobileSize.width - 16);
      expect(capsule.top, greaterThanOrEqualTo(statusBar));
      expect(capsule.bottom, lessThanOrEqualTo(appBar.bottom));
    });

    testWidgets('GIVEN a phone\n'
        'WHEN the pen is tapped\n'
        'THEN a new direct chat opens', (tester) async {
      final h = await HeaderHarness.pump(tester, const HeaderView.phone());

      await tester.tap(find.byKey(_pen));

      verify(h.controller.goToNewPrivateChat()).called(1);
    });

    testWidgets('GIVEN select mode\n'
        'THEN the capsule is hidden', (tester) async {
      final h = await HeaderHarness.pump(tester, const HeaderView.phone());

      await h.startSelectMode(tester);

      expect(find.byType(FloatingCapsule), findsNothing);
    });

    testWidgets('GIVEN a wide screen\n'
        'THEN the pen stays a bare icon in the app bar', (tester) async {
      await HeaderHarness.pump(tester, const HeaderView.wide());

      expect(find.byType(FloatingCapsule), findsNothing);
      expect(
        find.ancestor(of: find.byKey(_pen), matching: find.byType(AppBar)),
        findsOneWidget,
      );
    });
  });
}
