import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/list_item/twake_list_item.dart';

import '../../base/core_robot.dart';
import '../abstract/abstract_search_view_robot.dart';
import '../search_robot.dart';
import '../twake_list_item_robot.dart';

class SearchViewRobot extends SearchRobot implements AbstractSearchViewRobot {
  SearchViewRobot(super.$);

  @override
  Future<bool> searchAndOpenRoom(String roomName) async {
    final room = await searchRoom(roomName);
    if (room == null) {
      return false;
    }
    await openRoom(room);
    return true;
  }

  Future<List<TwakeListItemRobot>> getRoomsInSearch() async {
    final List<TwakeListItemRobot> rooms = [];

    // Evaluate once to find how many TwakeListItem widgets exist
    final matches = $(TwakeListItem).evaluate();
    for (final element in matches) {
      final finder = $(element.widget.runtimeType);
      rooms.add(TwakeListItemRobot($, finder));
    }
    return rooms;
  }

  Future<TwakeListItemRobot?> searchRoom(String roomName) async {
    if ($(CircularProgressIndicator).exists) {
      await $.waitUntilVisible($(CircularProgressIndicator));
      await CoreRobot($).waitUntilAbsent($, $(CircularProgressIndicator));
    }
    await $.pump(const Duration(seconds: 2));

    await enterSearchText(roomName);

    // Check if any chat rooms were found
    final rooms = await SearchViewRobot($).getRoomsInSearch();
    if (rooms.isEmpty) {
      // Room not found, end test gracefully
      return null;
    }

    return rooms.firstOrNull;
  }

  Future<void> openRoom(TwakeListItemRobot room) async {
    await room.root.tap();
    await $.pumpAndSettle();
  }
}
