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
  Future<PatrolFinder> getNameLabel() async {
    return root.$(Text).at(0);
  }
  Future<PatrolFinder> getOwnerLabel() async {
    return root.$(Text).containing('Owner');
  }
  Future<PatrolFinder> getEmailLabel() async {
    return root.$(Text).at(2);
  }
  Future<PatrolFinder> getContactLabel() async {
    return root.$(Text).at(3);
  }
}
