import 'package:fluffychat/pages/chat_list/chat_list_item_subtitle.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item_title.dart';
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

  Future<PatrolFinder> getCheckBox() async {
    return root.$(Checkbox).at(0);
  }
  
  PatrolFinder getTitle() {
    return root.$(ChatListItemTitle).$(Text).at(0);
  }

  Future<PatrolFinder> getOwnerLabel() async {
    return root.$(Text).containing('Owner');
  }

  Future<PatrolFinder> getEmailLabel() async {
    return root.$(ChatListItemSubtitle).$(Text).at(0);
  }

  Future<PatrolFinder> getContactLabel() async {
    return root.$(ChatListItemSubtitle).$(Text).at(1);
  }
}
