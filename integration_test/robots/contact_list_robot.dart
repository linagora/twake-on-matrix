import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';
import 'home_robot.dart';

import 'twake_list_item_robot.dart';

class ContactListRobot extends HomeRobot {
  ContactListRobot(super.$);

  Future<List<TwakeListItemRobot>> getListOfContact() async {
    final List<TwakeListItemRobot> contactList = [];

    // Evaluate once to find how many TwakeListItem widgets exist
    final matches = $(TwakeListItem).evaluate();

    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      contactList.add(TwakeListItemRobot($, finder));
    }

    return contactList;
  }
}
