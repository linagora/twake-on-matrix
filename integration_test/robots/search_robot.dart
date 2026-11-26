import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';
import 'abstract/abstract_search_robot.dart';

class SearchRobot extends CoreRobot implements AbstractSearchRobot {
  SearchRobot(super.$);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  /// The close button of the search of the bottom bar.
  PatrolFinder getBackIcon() {
    return $(NavigationKeys.searchCloseButton.key);
  }

  /// Mobile implementation — closes the search of the bottom bar, then waits
  /// for the tabs of `FloatingNavigationBar`.
  @override
  Future<void> backToPreviousScreen() async {
    await getBackIcon().tap();
    await $.waitUntilVisible($(NavigationKeys.searchButton.key));
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
