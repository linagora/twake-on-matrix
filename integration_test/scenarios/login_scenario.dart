import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import '../robots/login_robot.dart';

class LoginScenario extends BaseScenario {
  final String username;

  final String serverUrl;

  final String password;

  LoginScenario(
    super.$, {
    required this.username,
    required this.serverUrl,
    required this.password,
  });
  @override
  Future<void> execute() async {
    final loginRobot = LoginRobot($);
    await $.waitUntilVisible($(TwakeWelcome));
    await expectViewVisible($(TwakeWelcome));
    await loginRobot.tapOnUseYourCompanyServer();
    await $.waitUntilVisible(
      $(HomeserverPickerView),
    );
    await loginRobot.enterServerUrl(serverUrl);
    await loginRobot.confirmServerUrl();

    await loginRobot.enterUsernameSsoLogin(username);
    await loginRobot.enterPasswordSsoLogin(password);
    await loginRobot.pressSignInSsoLogin();
    await $.waitUntilVisible(
      $(HomeserverPickerView),
    );
    await loginRobot.grantNotificationPermission($.nativeAutomator);
    await expectViewVisible($(ChatList));
  }
}
