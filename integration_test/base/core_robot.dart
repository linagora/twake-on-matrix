import 'dart:async';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/permission_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

class CoreRobot {
  final PatrolIntegrationTester $;

  CoreRobot(this.$);

  dynamic ignoreException() => $.tester.takeException();

  String? getBrowserAppId() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'com.android.chrome';
    }
    return null;
  }

  Future<bool> tapNextOnPermissionDialog() async {
    final dialog = $(PermissionDialog);
    if (!dialog.exists) {
      return false;
    }

    final ctx = $.tester.element(dialog); // BuildContext inside dialog
    final nextLabel = L10n.of(ctx)!.next; // localized label for "Next"

    await $.tester.tap(
      find.descendant(of: dialog, matching: find.text(nextLabel)),
    );
    await $.tester.pumpAndSettle();
    return true;
  }

  Future<void> confirmShareContactInformation() async {
    await tapNextOnPermissionDialog();
  }

  Future<void> confirmAccessContact() async {
    // OS permission dialogs only exist on mobile — on web the browser
    // handles its own prompts and nothing surfaces through Patrol's
    // native automator, which itself is unavailable on the web target.
    if (kIsWeb) return;
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> cancelSynchronizeContact() async {
    final tapped = await tapNextOnPermissionDialog();
    if (!tapped) {
      return;
    }
    if (kIsWeb) return;
    if (await $.native.isPermissionDialogVisible(
      timeout: const Duration(seconds: 5),
    )) {
      await $.native.denyPermission();
    }
  }

  Future<void> grantNotificationPermission() async {
    if (kIsWeb) return;
    if (await $.native.isPermissionDialogVisible(
      timeout: const Duration(seconds: 15),
    )) {
      await $.native.grantPermissionWhenInUse();
    }
  }

  Future<void> waitForEitherVisible({
    required PatrolIntegrationTester $,
    required PatrolFinder first,
    required PatrolFinder second,
    required Duration timeout,
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      if (first.exists || second.exists) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }
    throw Exception(
      'Neither widget became visible within ${timeout.inSeconds} seconds',
    );
  }

  Future<void> waitUntilAbsent(
    PatrolIntegrationTester $,
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.exists) {
      if (DateTime.now().isAfter(end)) {
        throw TimeoutException('Widget $finder still exists after $timeout');
      }
      await $.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> waitNativeGone(
    Selector selector, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 200),
  }) async {
    final appId = getBrowserAppId();
    final end = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(end)) {
      final views = await $.native.getNativeViews(selector, appId: appId);
      if (views.isEmpty) return;

      await Future.delayed(interval);
    }

    throw TimeoutException('Native element still visible: $selector');
  }

  Future<void> waitSnackGone(
    PatrolIntegrationTester $, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    final end = DateTime.now().add(timeout);
    while ($(SnackBar).exists || $(CupertinoPopupSurface).exists) {
      if (DateTime.now().isAfter(end)) break;
      await $.pump(const Duration(milliseconds: 150));
    }
  }

  Future<bool> existsOptionalFlutterItems(
    PatrolIntegrationTester $,
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await $.pumpAndTrySettle(duration: timeout);
    return finder.exists;
  }

  Future<bool> existsOptionalNativeItems(
    PatrolIntegrationTester $,
    Selector selector, {
    String? appId,
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 500),
  }) async {
    try {
      await $.native.waitUntilVisible(selector, appId: appId, timeout: timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> typeSlowlyWithPatrol(
    PatrolIntegrationTester $,
    Finder field,
    String text, {
    Duration perChar = const Duration(milliseconds: 500),
  }) async {
    await $.tap(field);

    final buffer = StringBuffer();
    buffer.write(text.characters.characterAt(0));
    await $.enterText(field, buffer.toString());
    await $.pump();
    await Future.delayed(perChar);
    buffer.write(text.characters.getRange(1, text.characters.length));
    await $.enterText(field, buffer.toString());
    await $.pump();
    await Future.delayed(perChar);
  }

  Future<String?> captureAsyncError(Future<void> Function() body) async {
    Object? err;
    final done = Completer<void>();

    runZonedGuarded(
      () async {
        try {
          await body();
        } finally {
          done.complete();
        }
      },
      (e, _) {
        err ??= e; // store the first error
      },
    );

    await done.future;
    return err?.toString();
  }

  Future<void> scrollToBottom(
    PatrolIntegrationTester $, {
    PatrolFinder? root,
    int maxDrags = 30,
  }) async {
    // Find the Scrollable to act on
    final PatrolFinder scrollable = root == null
        ? $(Scrollable).first
        : $(
            find.descendant(of: root.finder, matching: find.byType(Scrollable)),
          ).first;

    var lastPixels = -1.0;
    for (var i = 0; i < maxDrags; i++) {
      // drag up a bit
      await $.tester.drag(scrollable, const Offset(0, -400));
      await $.tester.pump(const Duration(milliseconds: 120));

      final s = $.tester.state<ScrollableState>(scrollable);
      final p = s.position.pixels;

      if (p == lastPixels) break; // no more movement → bottom reached
      lastPixels = p;
    }
  }

  Future<void> scrollToTop(
    PatrolIntegrationTester $, {
    PatrolFinder? root,
    int maxDrags = 30,
  }) async {
    // Find the Scrollable to act on
    final PatrolFinder scrollable = root == null
        ? $(Scrollable).first
        : $(
            find.descendant(of: root.finder, matching: find.byType(Scrollable)),
          ).first;

    for (var i = 0; i < maxDrags; i++) {
      // drag down a bit
      await $.tester.drag(scrollable, const Offset(0, 400));
      await $.tester.pump(const Duration(milliseconds: 120));

      final s = $.tester.state<ScrollableState>(scrollable);
      final p = s.position.pixels;

      if (p <= 0.0) break; // reached top
    }
  }

  Future<void> scrollUntilVisible(
    PatrolIntegrationTester $,
    Finder target, {
    Finder? scrollable,
    int maxSwipes = 10,
  }) async {
    final container = scrollable ?? find.byType(Scrollable).first;

    for (int i = 0; i < maxSwipes; i++) {
      if ($.tester.any(target)) return;
      await $.tester.drag(container, const Offset(0, -300)); // swipper up
      await $.tester.pumpAndSettle();
    }

    for (int i = 0; i < maxSwipes; i++) {
      if ($.tester.any(target)) return;
      await $.tester.drag(container, const Offset(0, 300)); // swipper down
      await $.tester.pumpAndSettle();
    }

    if (!$.tester.any(target)) {
      throw Exception('can not found widget after scrolling');
    }
  }

  Future<bool> isActuallyScrollable(
    PatrolIntegrationTester $, {
    PatrolFinder? root,
  }) async {
    final scrollableFinder = root == null
        ? $(Scrollable)
        : $(
            find.descendant(of: root.finder, matching: find.byType(Scrollable)),
          );

    return scrollableFinder.exists;
  }
}
