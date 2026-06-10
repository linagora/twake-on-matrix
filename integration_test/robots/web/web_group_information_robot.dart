import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../group_information_robot.dart';

/// Web-specific group-information robot.
///
/// On web the group info renders in the right column of the two-pane
/// layout, so the mobile `$.scrollUntilVisible` (which drags the first
/// `Scrollable`, i.e. the chat list of the left pane) targets the wrong
/// pane. On the headless-Chrome viewport the member rows also sit below
/// the fold of the right pane, where the list viewport reports them as
/// off-stage — the default on-stage finders never match even though the
/// element is alive. Match the row with an off-stage-inclusive finder and
/// bring it into view with `ensureVisible` (which scrolls the row's own
/// viewport) before tapping.
class WebGroupInformationRobot extends GroupInformationRobot {
  WebGroupInformationRobot(super.$);

  @override
  Future<void> openMemberDetail({required String matrixID}) async {
    // Match the key by value (any `ValueKey` type argument) and include
    // off-stage elements: rows outside the viewport's visible band are
    // excluded from the default on-stage traversal.
    final member = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey && key.value == matrixID;
    }, skipOffstage: false);

    // The member list materialises only once participants and power levels
    // have been fetched, which can exceed the global 6s exists-timeout —
    // poll the tree for up to 30s instead.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (member.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await $.pump(const Duration(milliseconds: 500));
    }
    if (member.evaluate().isEmpty) {
      throw StateError('Member "$matrixID" not found in group information');
    }

    // `ensureVisible` scrolls the right pane's own viewport; tap without
    // the hit-test warning because the decorative Lottie animation of the
    // empty middle pane can overlap the hit-test position.
    await $.tester.ensureVisible(member.first);
    await $.pump(const Duration(milliseconds: 300));
    await $.tester.tap(member.first, warnIfMissed: false);
    await $.pump(const Duration(seconds: 1));
    // On web (wide layout) the member profile opens inside an `AlertDialog`
    // hosting `ProfileInfoBody` — `ProfileInfoView` is the mobile route.
    await $(ProfileInfoBody).waitUntilExists();
  }
}
