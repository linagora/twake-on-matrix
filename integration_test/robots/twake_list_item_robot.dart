import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
import 'package:fluffychat/widgets/highlight_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class TwakeListItemRobot extends CoreRobot {
  final PatrolFinder root;
  TwakeListItemRobot(super.$, this.root);

  Future<PatrolFinder> getRadiobtn() async {
    return root.$(Radio).at(0);
  }

  PatrolFinder getCheckBox() {
    return root.$(Checkbox);
  }
  
  PatrolFinder getTitle() {
    return root.$(ChatListItemTitle).$(Text).at(0);
  }

  Future<PatrolFinder> getOwnerLabel() async {
    return root.$(Text).containing('Owner');
  }

  PatrolFinder getNumberUnReadIcon() {
    return root.$(ChatListItemSubtitle).$(AnimatedContainer).containing($(Text));
  }

  Future<PatrolFinder> getEmailLabelIncaseSearching() async {
    return root.$(HighlightText).$(Text).at(0);
  }

  Future<PatrolFinder> getEmailLabel() async {
    return root.$(ChatListItemSubtitle).$(Text).at(0);
  }

  Future<PatrolFinder> getContactLabel() async {
    return root.$(ChatListItemSubtitle).$(Text).at(1);
  }

  PatrolFinder getPinIcon(){
    final title = root.$(ChatListItemTitle);
    const pinData = IconData(0xF2D7, fontFamily: 'MaterialIcons');
    final pinFinder = find.descendant(of: title, matching: find.byIcon(pinData));
    return $(pinFinder);
  }

  PatrolFinder getUnReadStatus() {
    const target = Color(0xFF0A84FF);

    return root.$(ChatListItemSubtitle).$(
      find.byWidgetPredicate(
        (w) {
          if (w is AnimatedContainer) {
            final d = w.decoration;
            if (d is BoxDecoration && d.color?.value == target.value) return true;
          }

          return false;
        },
        description: 'Any box with background #0A48FF',
      ),
    );
  }

  int getUnreadMessage(){
    final animated = find.descendant(
      of: root,
      matching: find.byType(AnimatedContainer),
    );
    if(animated.evaluate().isNotEmpty) 
      { 
        final raw = root.$(ChatListItemSubtitle).$(Text).last.text; // String?
        final s = (raw ?? '').trim();
        final n = int.tryParse(s);
        return n ?? 0;
      }
    else {return 0;}
  }
}
