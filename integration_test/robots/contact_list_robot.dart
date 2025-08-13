import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'home_robot.dart';

import 'twake_list_item_robot.dart';

class ContactListRobot extends HomeRobot {
  ContactListRobot(super.$);
  
  Future<List<TwakeListItemRobot>> getListOfContact() async {
    final List<TwakeListItemRobot> contactList = [];

    // Evaluate once to find how many TwakeInkWell widgets exist
    final matches = $(TwakeListItem).evaluate();

    for (int i = 0; i < matches.length; i++) {
      final item = $(TwakeListItem).at(i);
      contactList.add(TwakeListItemRobot($,item));
    }
    return contactList;
  }
}
