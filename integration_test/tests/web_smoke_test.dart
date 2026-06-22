import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../base/web_test_main.dart' as app;
import '../base/web_benign_error_filter.dart';

void main() {
  patrolTest(
    'Web smoke — app boots and MaterialApp is rendered',
    config: const PatrolTesterConfig(
      printLogs: true,
      visibleTimeout: Duration(minutes: 1),
    ),
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      // Same benign web-only rendering-assertion filter the real test harness
      // (TestBase) installs. Without it, a benign RenderFlex overflow on the
      // boot/home screen propagates into the test zone and fails this
      // login-less smoke test (the 14 real tests survive because they install
      // the filter via TestBase.runPatrolTest).
      installWebBenignErrorFilter();

      await app.main();

      await $(MaterialApp).waitUntilVisible();
      // The web boot passes through a splash/redirect chain ('/' → '/home');
      // GoRouter rebuilds the MaterialApp.router subtree during that
      // transition, so the count is not stably exactly one on the frame after
      // waitUntilVisible returns. The smoke test only asserts the app booted
      // and rendered a MaterialApp, so "at least one" is the correct matcher.
      expect($(MaterialApp), findsWidgets);
    },
  );
}
