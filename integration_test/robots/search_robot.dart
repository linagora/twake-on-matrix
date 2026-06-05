import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'abstract/abstract_search_robot.dart';

class SearchRobot extends CoreRobot implements AbstractSearchRobot {
  SearchRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  PatrolFinder getBackIcon() {
    return $(AppBar).$(TwakeIconButton).$(Icon);
  }

  /// Mobile implementation — waits for `BottomNavigationBar` after going back.
  /// Web uses [WebSearchRobot] which skips that wait.
  @override
  Future<void> backToPreviousScreen() async {
    await goBack();
    await $.waitUntilVisible($(BottomNavigationBar));
  }

  PatrolFinder getSearchTextField() {
    // return $(TextField).containing(find.text('Search'));// problem when change language
    return $(TextField).hitTestable();
  }

  PatrolFinder getNoResultIcon() {
    return $(_l10n.noResults);
  }

  @override
  bool isNoResultVisible() => getNoResultIcon().visible;

  @override
  bool isSearchFieldVisible() => getSearchTextField().exists;

  PatrolFinder getSearchingIcon() {
    return (getSearchTextField()).$(Icon).at(0);
  }

  PatrolFinder getDeleteSearchingIcon() {
    return (getSearchTextField()).$(TwakeIconButton).$(Icon);
  }

  @override
  Future<void> enterSearchText(String searchText) async {
    final field = getSearchTextField();
    await field.tap();
    await cancelSynchronizeContact();
    await typeSlowlyWithPatrol($, field, searchText);
  }

  @override
  Future<void> deleteSearchPhrase() async {
    await getDeleteSearchingIcon().tap();
  }
}
