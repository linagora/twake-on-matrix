import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../base/web_test_main.dart' as app;

void main() {
  patrolTest(
    'Web smoke — app boots and MaterialApp is rendered',
    config: const PatrolTesterConfig(
      printLogs: true,
      visibleTimeout: Duration(minutes: 1),
    ),
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
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
