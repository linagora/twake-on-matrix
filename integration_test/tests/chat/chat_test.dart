import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat_draft/draft_chat_empty_widget.dart';
import '../../base/test_base.dart';
import '../../help/soft_assertion_helper.dart';
import '../../robots/chat_group_detail_robot.dart';
import '../../scenarios/chat_scenario.dart';
import '../../robots/home_robot.dart';

// --- Common config ---
const defaultTime = Duration(seconds: 60);
const searchPhrase = String.fromEnvironment(
  'SearchByTitle',
  defaultValue: 'My Default Group',
);
const forwardReceiver = String.fromEnvironment(
  'Receiver',
  defaultValue: 'Receiver Group',
);

int uniqueId() => DateTime.now().microsecondsSinceEpoch;

void main() {
  TestBase().runPatrolTest(
    description:
        'create a new message with a user who has been chatted with before',
    test: ($) async {
      final s = SoftAssertHelper();
      const user = String.fromEnvironment('User2MaxtrixAddress');
      final now = DateTime.now();
      final message =
          "sender sent at ${now.year}${now.month}${now.day}${now.hour}${now.minute}";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewDirectMessage(user);

      // Get localization context
      await $.pumpAndSettle();
      final draftFinder = $(DraftChatEmpty);
      if (!draftFinder.exists) {
        throw StateError('DraftChatEmpty not visible');
      }
      final context = draftFinder.evaluate().first;
      final l10n = L10n.of(context)!;

      // verify chat screen is shown
      s.softAssertEquals($(ChatView).exists, true, l10n.chat);
      s.softAssertEquals(
        ChatGroupDetailRobot($).getBackIcon().exists,
        true,
        l10n.back,
      );
      s.softAssertEquals(
        ChatGroupDetailRobot($).getSearchIcon().exists,
        true,
        l10n.search,
      );
      s.softAssertEquals(
        ChatGroupDetailRobot($).getMoreIconInAppBar().exists,
        false,
        l10n.more,
      );
      s.softAssertEquals($(DraftChatEmpty).exists, false, "DraftChatEmpty");

      // try to send message
      await ChatScenario($).sendAMesage(message);
      // see that message is send correctly
      await ChatScenario($).verifyMessageIsShown(message, true);
      await ChatScenario($).verifyMessageIsSent(message, true);
      s.verifyAll();
    },
  );

  TestBase().runPatrolTest(
    description:
        "Create a new message with a user who hasn't been chatted with before",
    test: ($) async {
      final s = SoftAssertHelper();
      final now = DateTime.now();
      final message = "${now.month}${now.day}${now.hour}${now.minute}";
      final account = "@$message:linagora.com";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewDirectMessage(account);

      // Get localization context
      await $.pumpAndSettle();
      final draftFinder = $(DraftChatEmpty);
      if (!draftFinder.exists) {
        throw StateError('DraftChatEmpty not visible');
      }
      final context = draftFinder.evaluate().first;
      final l10n = L10n.of(context)!;

      // verify draft chat empty widget is shown
      s.softAssertEquals(
        $(DraftChatEmpty).exists,
        true,
        "DraftChatEmpty widget",
      );
      s.softAssertEquals(
        $(DraftChatEmpty).$(l10n.noMessageHereYet).exists,
        true,
        l10n.noMessageHereYet,
      );
      s.softAssertEquals(
        $(DraftChatEmpty).$(l10n.sendMessageGuide).exists,
        true,
        l10n.sendMessageGuide,
      );
      //try to send a message
      await ChatScenario($).sendAMesage(message);
      // verify the message is sent
      await ChatScenario($).verifyMessageIsShown(message, true);
      await ChatScenario($).verifyMessageIsSent(message, true);
      s.verifyAll();
    },
  );

  TestBase().runPatrolTest(
    description: 'create a new message with the non-existing account',
    test: ($) async {
      final s = SoftAssertHelper();
      final now = DateTime.now();
      final message =
          "${now.year}${now.month}${now.day}${now.hour}${now.minute}";
      final nonExisingAccount = "@a$message:linagora.com";

      // goto chat screen
      await HomeRobot($).gotoChatListScreen();
      // click on Pen icon
      await ChatScenario($).createANewDirectMessage(nonExisingAccount);

      // Get localization context
      await $.pumpAndSettle();
      final draftFinder = $(DraftChatEmpty);
      if (!draftFinder.exists) {
        throw StateError('DraftChatEmpty not visible');
      }
      final context = draftFinder.evaluate().first;
      final l10n = L10n.of(context)!;

      // verify draft chat empty widget is shown
      s.softAssertEquals(
        $(DraftChatEmpty).exists,
        true,
        "DraftChatEmpty widget",
      );
      s.softAssertEquals(
        $(DraftChatEmpty).$(l10n.noMessageHereYet).exists,
        true,
        l10n.noMessageHereYet,
      );
      s.softAssertEquals(
        $(DraftChatEmpty).$(l10n.sendMessageGuide).exists,
        true,
        l10n.sendMessageGuide,
      );

      //try to send a message
      await ChatScenario($).sendAMesage(message);

      // todo: handle showing "Room creation failed" message
      // verify the message is not sent
      await ChatScenario($).verifyMessageIsShown(message, false);
      s.verifyAll();
    },
  );
}
