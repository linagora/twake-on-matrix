import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/reaction/reaction_dialog_widget.dart';
import 'package:patrol/patrol.dart';
import 'package:pull_down_button/pull_down_button.dart';
import '../base/core_robot.dart';

class PullDownMenuRobot extends CoreRobot {
  PullDownMenuRobot(super.$);

  Future<PatrolFinder> getHeartIcon() async {
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(find.text('💜'));
  }
  Future<PatrolFinder> getLikeIcon() async {
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(find.text('👍'));

  //     // 2) Wait for the overlay bar
  // final bar = $(Overlay).$(ReactionsDialogWidget);   // note the plural: ReactionsDialogWidget
  // await bar.waitUntilVisible();

  // // 3a) Tap by emoji text (if the emoji is a Text child)
  // await bar.$(InkWell).containing(find.text('👍')).tap();

  // // 3b) Or tap by index (left → right)
  // await bar.$(InkWell).at(0).tap();   // 0 = first reaction, adjust as needed

  // // 3c) Or tap by icon if your reaction uses Icons/CustomIcons
  // // await bar.$(InkWell).containing(find.byIcon(TwakeIcons.thumbsUp)).tap();
  }
  Future<PatrolFinder> getDisLikeIcon() async {
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(find.text('👎'));
  }
  Future<PatrolFinder> getCryIcon() async {
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(find.text('😂'));
  }
  Future<PatrolFinder> getSadIcon() async {
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(find.text('🥲'));
  }
  Future<PatrolFinder> getSuppriseIcon() async {
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(find.text('😮'));
  }
  Future<PatrolFinder> getExpandIcon() async {
    // return find.descendant(of: $(Overlay).$(ReactionsDialogWidget).finder, matching: find.byType(InkWell)).last;
    return $(Overlay).$(ReactionsDialogWidget).$(InkWell).containing(
      find.byWidgetPredicate((w) => w is Icon && w.icon != null && w.icon!.codePoint == 0xF04FC,),);  
  }

  Future<PatrolFinder> getReplyItem() async {
    return $(PullDownMenuItem).containing(find.text("Reply"));
  }

  PatrolFinder getForwardItem() {
    return $(PullDownMenuItem).containing(find.text("Forward"));
  }

  Future<PatrolFinder> getCopyItem() async {
    return $(PullDownMenuItem).containing(find.text("Copy"));
  }

  Future<PatrolFinder> getEditItem() async {
    return $(PullDownMenuItem).containing(find.text("Edit"));
  }

  Future<PatrolFinder> getSelectItem() async {
    return $(PullDownMenuItem).containing(find.text("Select"));
  }

  Future<PatrolFinder> getPinItem() async {
    return $(PullDownMenuItem).containing(find.text("Pin"));
  }

  Future<PatrolFinder> getDeleteItem() async {
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
  

  Future<void> close() async{
    final view = $.tester.binding.platformDispatcher.implicitView!;
    final size = view.physicalSize / view.devicePixelRatio; // logical pixels
    await $.tester.tapAt(Offset(size.width - 8, size.height - 8));
    await $.pumpAndSettle();
  }
}
