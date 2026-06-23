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
      expect($(MaterialApp), findsOneWidget);
    },
  );
}
