import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
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

  Future<void> login() async {
    final loginRobot = LoginRobot($);
    if(await loginRobot.isWelComePageVisible()){
      await loginRobot.tapOnUseYourCompanyServer();
      await _handleWaitUntilVisibleHomeServerPickerView(loginRobot);
      await loginRobot.enterServerUrl(serverUrl);
      await loginRobot.confirmServerUrl();
      await loginRobot.confirmShareInformation();
    }
    if (await loginRobot.isLoginBtnVisible()) {
      await loginRobot.enterWebCredentialsWhenVisible(username: username, password: password,);
    }
    await loginRobot.grantNotificationPermission();
    await expectViewVisible($(ChatList));
  }

  // Future<void> _handleFirebaseTestLab(LoginRobot loginRobot) async {
  //   try {
  //     await $.native.tap(Selector(text: "Use without an account"));
  //     await $.native.waitUntilVisible(Selector(resourceId: 'login'));
  //   } catch (e) {
  //     loginRobot.ignoreException();
  //   }
  // }

  Future<void> _handleWaitUntilVisibleHomeServerPickerView(
    LoginRobot loginRobot,
  ) async {
    try {
      await $.waitUntilVisible(
        $(HomeserverPickerView),
      );
    } catch (e) {
      loginRobot.ignoreException();
    }
  }
}
