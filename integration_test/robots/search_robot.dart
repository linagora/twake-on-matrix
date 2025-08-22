import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class SearchRobot extends CoreRobot {
  SearchRobot(super.$);

  Future<PatrolFinder> getBackIcon() async {
    return $(AppBar).$(TwakeIconButton).$(Icon);
  }

  Future<void> backToPreviousScreen() async {
    await getBackIcon().tap();
    await $.waitUntilVisible($(BottomNavigationBar));
  }

  Future<PatrolFinder> getSearchTextField() async {
    // return $(TextField).containing(find.text('Search'));// problem when change language
    return $(TextField).hitTestable();
  }

  Future<PatrolFinder> getNoResultIcon() async {
    return $('No Results');
  }

  Future<PatrolFinder> getSearchingIcon() async {
    return (await getSearchTextField()).$(Icon).at(0);
  }

  Future<PatrolFinder> getDeleteSearchingIcon() async {
    return (await getSearchTextField()).$(TwakeIconButton).$(Icon);
  }

  Future<void> enterSearchText(String searchText) async {
    await getSearchTextField().tap();
    await getSearchTextField().enterText(searchText);
  }

  Future<void> deleteSearchPhrase() async {
    await getDeleteSearchingIcon().tap();
  }
}
