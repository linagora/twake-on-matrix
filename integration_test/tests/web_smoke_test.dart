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
      installWebBenignErrorFilter();

      // DIAGNOSTIC: capture any error so the real failure reason surfaces in
      // the CI log (Patrol web does not serialize the Dart TestFailure).
      FlutterError.onError = (FlutterErrorDetails details) {
        debugPrint('SMOKE_FLUTTER_ERROR: ${details.exceptionAsString()}');
        debugPrint('SMOKE_FLUTTER_STACK: ${details.stack}');
      };

      try {
        await app.main();

        await $(MaterialApp).waitUntilVisible();
        expect($(MaterialApp), findsWidgets);

        // Drain async boot init before the test ends.
        await $.pump(const Duration(seconds: 3));
      } catch (e, s) {
        debugPrint('SMOKE_CAUGHT_ERROR: $e');
        debugPrint('SMOKE_CAUGHT_STACK: $s');
        rethrow;
      }
    },
  );
}
