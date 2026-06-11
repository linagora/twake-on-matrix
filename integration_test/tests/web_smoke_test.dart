import 'package:fluffychat/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest(
    'Web smoke — app boots and MaterialApp is rendered',
    config: const PatrolTesterConfig(
      printLogs: true,
      visibleTimeout: Duration(minutes: 1),
    ),
    framePolicy: LiveTestWidgetsFlutterBindingFramePolicy.fullyLive,
    ($) async {
      app.main();

      await $(MaterialApp).waitUntilVisible();
      expect($(MaterialApp), findsOneWidget);
    },
  );
}
