import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/reaction/reaction_dialog_widget.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';

class PullDownMenuRobot extends CoreRobot {
  PullDownMenuRobot(super.$);

  PatrolFinder getHeartIcon() {
    return $(
      Overlay,
    ).$(ReactionsDialogWidget).$(InkWell).containing(find.text('💜'));
  }

  PatrolFinder getLikeIcon() {
    return $(
      Overlay,
    ).$(ReactionsDialogWidget).$(InkWell).containing(find.text('👍'));
  }

  PatrolFinder getDisLikeIcon() {
    return $(
      Overlay,
    ).$(ReactionsDialogWidget).$(InkWell).containing(find.text('👎'));
  }

  PatrolFinder getCryIcon() {
    return $(
      Overlay,
    ).$(ReactionsDialogWidget).$(InkWell).containing(find.text('😂'));
  }

  PatrolFinder getSadIcon() {
    return $(
      Overlay,
    ).$(ReactionsDialogWidget).$(InkWell).containing(find.text('🥲'));
  }

  PatrolFinder getSuppriseIcon() {
    return $(
      Overlay,
    ).$(ReactionsDialogWidget).$(InkWell).containing(find.text('😮'));
  }

  PatrolFinder getExpandIcon() {
    // return find.descendant(of: $(Overlay).$(ReactionsDialogWidget).finder, matching: find.byType(InkWell)).last;
    return $(Overlay)
        .$(ReactionsDialogWidget)
        .$(InkWell)
        .containing(
          find.byWidgetPredicate(
            (w) => w is Icon && w.icon != null && w.icon!.codePoint == 0xF04FC,
          ),
        );
  }

  PatrolFinder getReplyItem() {
    return $(PullDownMenuItem).containing(find.text("Reply"));
  }

  PatrolFinder getForwardItem() {
    return $(PullDownMenuItem).containing(find.text("Forward"));
  }

  PatrolFinder getCopyItem() {
    return $(PullDownMenuItem).containing(find.text("Copy"));
  }

  PatrolFinder getEditItem() {
    return $(PullDownMenuItem).containing(find.text("Edit"));
  }

  PatrolFinder getSelectItem() {
    return $(PullDownMenuItem).containing(find.text("Select"));
  }

  PatrolFinder getPinItem() {
    return $(PullDownMenuItem).containing(find.text("Pin"));
  }

  PatrolFinder getUnpinItem() {
    return $(PullDownMenuItem).containing(find.text("Unpin"));
  }

  PatrolFinder getDeleteItem() {
    return $(PullDownMenuItem).containing(find.text("Delete"));
  }

  Future<List<PatrolFinder>> getListOfMenu() async {
    final List<PatrolFinder> items = [];

    // Evaluate once to find how many TwakeInkWell widgets exist
    final matches = $(PullDownMenuItem).evaluate();

    for (int i = 0; i < matches.length; i++) {
      final item = $(PullDownMenuItem).at(i);
      items.add(item);
    }
    return items;
  }

  Future<void> reply() async {
    await getReplyItem().tap();
  }

  Future<void> forward() async {
    await getReplyItem().tap();
  }

  Future<void> copy() async {
    await getReplyItem().tap();
  }

  Future<void> edit() async {
    await getReplyItem().tap();
  }

  Future<void> select() async {
    await getReplyItem().tap();
  }

  Future<void> pin() async {
    await getReplyItem().tap();
  }

  Future<void> delete() async {
    await getReplyItem().tap();
  }

  Future<void> close() async {
    final view = $.tester.binding.platformDispatcher.implicitView!;
    final size = view.physicalSize / view.devicePixelRatio; // logical pixels
    await $.tester.tapAt(Offset(size.width - 8, size.height - 8));
  }
}
