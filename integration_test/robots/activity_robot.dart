import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/pages/activity/activity_page.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';

import '../base/core_robot.dart';

/// The Activity tab of the bottom bar (THR-M-12).
class ActivityRobot extends CoreRobot {
  ActivityRobot(super.$);

  static const _timeout = Duration(seconds: 30);

  PatrolFinder get page => $(ActivityPage);

  /// Opens the Activity tab from the bottom bar.
  Future<void> open() async {
    await $(find.byKey(NavigationKeys.activityDestination.key)).first.tap();
    await $.pumpAndTrySettle();
    await page.waitUntilVisible(timeout: _timeout);
  }

  Future<void> selectFilter(String label) async {
    await page.$(find.text(label)).first.tap();
    await $.pumpAndTrySettle();
  }

  /// The chip named [label] is the one selected, as accessibility reads it.
  bool isFilterSelected(String label) {
    final semantics = $.tester.ensureSemantics();
    try {
      final data = $.tester
          .getSemantics(page.$(find.text(label)).first)
          .getSemanticsData();
      return data.flagsCollection.isSelected == Tristate.isTrue;
    } finally {
      semantics.dispose();
    }
  }

  /// Waits for a row quoting [text], then touches it.
  Future<void> openItem(String text) async {
    final row = page.$(find.textContaining(text, findRichText: true));
    await row.waitUntilVisible(timeout: _timeout);
    await row.first.tap();
    await $.pumpAndTrySettle();
  }

  Future<void> expectItem(String text) async {
    await page
        .$(find.textContaining(text, findRichText: true))
        .waitUntilVisible(timeout: _timeout);
  }

  Future<void> expectNoItem(String text) async {
    await waitUntilAbsent(
      $,
      page.$(find.textContaining(text, findRichText: true)),
      timeout: _timeout,
    );
  }

  /// Back on the Activity tab: its page shows and the bottom bar has
  /// Activity selected.
  Future<void> expectOnActivityTab() async {
    await page.waitUntilVisible(timeout: _timeout);
    final bar = $.tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar).last,
    );
    expect(
      bar.items[bar.currentIndex].label,
      'Activity',
      reason: 'the Activity tab is the one selected',
    );
  }
}
