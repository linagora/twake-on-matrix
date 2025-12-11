import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class SearchRobot extends CoreRobot {
  SearchRobot(super.$);

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton).$(Icon);
  }

  Future<void> backToPreviousScreen() async {
    await getBackIcon().tap();
    await $.waitUntilVisible($(BottomNavigationBar));
  }

  PatrolFinder getSearchTextField() {
    // return $(TextField).containing(find.text('Search'));// problem when change language
    return $(TextField).hitTestable();
  }

  PatrolFinder getNoResultIcon() {
    return $('No Results');
  }

  PatrolFinder getSearchingIcon() {
    return (getSearchTextField()).$(Icon).at(0);
  }

  PatrolFinder getDeleteSearchingIcon() {
    return (getSearchTextField()).$(TwakeIconButton).$(Icon);
  }

  Future<void> enterSearchText(String searchText) async {
    await getSearchTextField().tap();
    await cancelSynchronizeContact();
    await typeSlowlyWithPatrol($, getSearchTextField(), searchText);
  }

  Future<void> deleteSearchPhrase() async {
    await getDeleteSearchingIcon().tap();
  }
}
