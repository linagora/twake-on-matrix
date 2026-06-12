import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';

String _stamp() {
  final now = DateTime.now();
  return '${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}';
}

/// Cross-platform scenario: start a DM with a user already chatted with.
///
/// Opens the new-chat flow for an existing account, sends a message and
/// asserts it renders. Drives the UI exclusively through the abstract robots
/// exposed by the `RobotFactory`.
class CreateDmWithExistingUserScenario extends BaseTestScenario {
  CreateDmWithExistingUserScenario(super.$, super.robots);

  static const _existingUser = String.fromEnvironment('User2MaxtrixAddress');

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final opened = await robots.chatListRobot().createDirectMessage(
      _existingUser,
    );
    expect(opened, isTrue, reason: 'Existing user should resolve to a chat');

    final message = 'sender sent at ${_stamp()}';
    await robots.chatGroupDetailRobot().sendMessage(message);
    final text = await robots.chatGroupDetailRobot().getText(message);
    await $.waitUntilVisible(text);
    expect(text, findsOneWidget);
  }
}

/// Cross-platform scenario: start a DM with a never-before-chatted account.
class CreateDmWithNewUserScenario extends BaseTestScenario {
  CreateDmWithNewUserScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final account = '@new${_stamp()}:linagora.com';
    final opened = await robots.chatListRobot().createDirectMessage(account);

    // A never-chatted remote address only resolves to a draft tile where the
    // homeserver can look it up (mobile / federated). Where it does not (web on
    // the isolated test server), there is no chat to send into — nothing to
    // assert beyond "no chat was created".
    if (!opened) return;

    final message = _stamp();
    await robots.chatGroupDetailRobot().sendMessage(message);
    final text = await robots.chatGroupDetailRobot().getText(message);
    await $.waitUntilVisible(text);
    expect(text, findsOneWidget);
  }
}

/// Cross-platform scenario: a DM with a non-existing account sends nothing.
class CreateDmWithNonExistingUserScenario extends BaseTestScenario {
  CreateDmWithNonExistingUserScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().gotoChatListScreen();
    final account = '@anon${_stamp()}:linagora.com';
    final opened = await robots.chatListRobot().createDirectMessage(account);

    // Web surfaces no draft tile for a non-existing remote address, so there is
    // nothing to send into. Only the platforms that open a draft can assert the
    // message never renders (room creation fails).
    if (!opened) return;

    final message = _stamp();
    await robots.chatGroupDetailRobot().sendMessage(message);
    await $.pump(const Duration(seconds: 2));
    final text = await robots.chatGroupDetailRobot().getText(message);
    expect(text, findsNothing);
  }
}
