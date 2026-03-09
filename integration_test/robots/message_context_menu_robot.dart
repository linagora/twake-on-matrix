import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';

/// Robot for interacting with message context menu dialog
class MessageContextMenuRobot extends CoreRobot {
  MessageContextMenuRobot(super.$);

  /// Find SafeArea widget in the dialog
  PatrolFinder getSafeArea() {
    return $(SafeArea);
  }

  /// Find SingleChildScrollView in the dialog
  PatrolFinder getScrollView() {
    return $(SingleChildScrollView);
  }

  /// Find the backdrop filter (background)
  PatrolFinder getBackdrop() {
    return $(BackdropFilter);
  }

  /// Find the PullDownMenu (context menu items)
  PatrolFinder getContextMenu() {
    return $(PullDownMenu);
  }

  /// Find a specific menu item by text
  PatrolFinder getMenuItem(String text) {
    return $(find.text(text));
  }

  /// Get Reply menu item
  PatrolFinder getReplyItem() {
    return getMenuItem('Reply');
  }

  /// Get Forward menu item
  PatrolFinder getForwardItem() {
    return getMenuItem('Forward');
  }

  /// Get Copy menu item
  PatrolFinder getCopyItem() {
    return getMenuItem('Copy');
  }

  /// Get Delete menu item
  PatrolFinder getDeleteItem() {
    return getMenuItem('Delete');
  }

  /// Get Pin menu item
  PatrolFinder getPinItem() {
    return getMenuItem('Pin');
  }

  /// Get Select menu item
  PatrolFinder getSelectItem() {
    return getMenuItem('Select');
  }

  /// Verify SafeArea wraps SingleChildScrollView
  Future<void> verifySafeAreaHierarchy() async {
    // Find SafeArea
    expect(getSafeArea().exists, isTrue, reason: 'SafeArea not found');

    // Find SingleChildScrollView inside SafeArea
    final scrollViewInSafeArea = find.descendant(
      of: getSafeArea().finder,
      matching: getScrollView().finder,
    );

    expect(
      scrollViewInSafeArea,
      findsAtLeastNWidgets(1),
      reason: 'SingleChildScrollView not inside SafeArea',
    );
  }

  /// Verify ClampingScrollPhysics is used
  Future<void> verifyClampingScrollPhysics() async {
    // Find SingleChildScrollView inside SafeArea (to get the specific one in dialog)
    final scrollViewInSafeArea = find.descendant(
      of: getSafeArea().finder,
      matching: getScrollView().finder,
    );

    final scrollViews = $.tester.widgetList<SingleChildScrollView>(
      scrollViewInSafeArea,
    );

    // Find the first one (should be our dialog's scroll view)
    final dialogScrollView = scrollViews.first;

    expect(
      dialogScrollView.physics,
      isA<ClampingScrollPhysics>(),
      reason: 'Should use ClampingScrollPhysics',
    );
  }

  /// Scroll to the top of the context menu dialog
  Future<void> scrollDialogToTop() async {
    // Find SingleChildScrollView inside SafeArea (the dialog's scroll view)
    final scrollViewInSafeArea = find.descendant(
      of: getSafeArea().finder,
      matching: getScrollView().finder,
    );

    // Scroll all the way to the top
    await $.tester.drag(scrollViewInSafeArea.first, const Offset(0, 5000));
    await $.pumpAndSettle();
  }

  /// Scroll to the bottom of the context menu dialog
  Future<void> scrollDialogToBottom() async {
    // Find SingleChildScrollView inside SafeArea (the dialog's scroll view)
    final scrollViewInSafeArea = find.descendant(
      of: getSafeArea().finder,
      matching: getScrollView().finder,
    );

    // Scroll all the way to the bottom
    await $.tester.drag(scrollViewInSafeArea.first, const Offset(0, -5000));
    await $.pumpAndSettle();
  }

  /// Close the dialog by tapping backdrop
  Future<void> closeByTappingBackdrop() async {
    // Tap at top-left corner of screen (outside the dialog)
    // This is more reliable than trying to find the GestureDetector
    await $.tester.tapAt(const Offset(10, 10));
    await $.pumpAndSettle();
  }

  /// Verify SafeArea respects insets
  Future<void> verifySafeAreaInsets() async {
    final safeAreas = $.tester.widgetList<SafeArea>(getSafeArea().finder);

    // Find the SafeArea that wraps our content
    final dialogSafeArea = safeAreas.firstWhere(
      (sa) => sa.child is SingleChildScrollView,
      orElse: () => safeAreas.first,
    );

    expect(dialogSafeArea.top, isTrue, reason: 'Top inset not respected');
    expect(dialogSafeArea.bottom, isTrue, reason: 'Bottom inset not respected');
  }

  /// Wait for dialog to appear
  Future<void> waitForDialogToAppear() async {
    await $.waitUntilVisible(
      getSafeArea(),
      timeout: const Duration(seconds: 5),
    );
  }

  /// Verify menu item is visible after scrolling
  Future<void> verifyMenuItemVisible(String itemText) async {
    final item = getMenuItem(itemText);
    expect(item.exists, isTrue, reason: 'Menu item "$itemText" not visible');
  }

  /// Scroll incrementally by a specific distance
  Future<void> _scrollByDistance(double distance) async {
    final scrollViewInSafeArea = find.descendant(
      of: getSafeArea().finder,
      matching: getScrollView().finder,
    );
    await $.tester.drag(scrollViewInSafeArea.first, Offset(0, distance));
    await $.pumpAndSettle();
  }

  /// Scroll until menu item is visible
  Future<void> scrollUntilMenuItemVisible(String itemText) async {
    final item = getMenuItem(itemText);

    int attempts = 0;
    const maxAttempts = 5;

    while (!item.exists && attempts < maxAttempts) {
      await _scrollByDistance(-100);
      attempts++;
    }

    expect(
      item.exists,
      isTrue,
      reason: 'Could not find menu item "$itemText" after scrolling',
    );
  }
}
