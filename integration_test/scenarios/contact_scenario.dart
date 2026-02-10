import 'package:fluffychat/pages/contacts_tab/contacts_tab_body_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../base/core_robot.dart';
import '../help/soft_assertion_helper.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/contact_list_robot.dart';
import '../robots/search_robot.dart';

class ContactScenario extends BaseScenario {
  ContactScenario(super.$);

  Future<void> enterSearchText(String searchText) async {
    await SearchRobot($).enterSearchText(searchText);
    await $.pump();
  }

  Future<ChatGroupDetailRobot> openChatWithContact(String contactName) async {
    await enterSearchText(contactName);
    await (await ContactListRobot($).getListOfContact())[0].root.tap();
    final chatGroupDetailRobot = ChatGroupDetailRobot($);
    await chatGroupDetailRobot.confirmAccessMedia();
    await $.pumpAndSettle();
    return chatGroupDetailRobot;
  }

  Future<void> backToContactLisFromChatGroupScreen() async {
    await ChatGroupDetailRobot($).clickOnBackIcon();
  }

  Future<void> verifyDisplayOfContactListScreen(SoftAssertHelper s) async {
    s.softAssertEquals(
      (SearchRobot($).getSearchTextField()).exists,
      true,
      'Search Text Field is not visible',
    );

    // // title (avoid hard-coded text if localized)
    // final appBarCtx = $.tester.element(find.byType(TwakeAppBar));
    // final title = L10n.of(appBarCtx)!.contacts; // or 'Contacts' if not localized
    // s.softAssertEquals($(TwakeAppBar).containing($(Text(title))).exists,true,'Contact title is wrong',);

    s.softAssertEquals(
      $(ContactsTabBodyView).visible,
      true,
      'Contacts tab is not visible',
    );
    s.softAssertEquals(
      $(BottomNavigationBar).visible,
      true,
      'Bottom navigator bar is not visible',
    );
  }

  Future<void> verifyContactListCanBeScrollable(SoftAssertHelper s) async {
    s.softAssertEquals(
      await CoreRobot($).isActuallyScrollable($, root: $(CustomScrollView)),
      true,
      'Contact list is not scrollable',
    );
  }
}
