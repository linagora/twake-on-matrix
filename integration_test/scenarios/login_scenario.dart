import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
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
    await loginRobot.tapOnUseYourCompanyServer();
    await _handleWaitUntilVisibleHomeServerPickerView(loginRobot);
    await loginRobot.enterServerUrl(serverUrl);
    await loginRobot.confirmServerUrl();
    await _handleFirebaseTestLab(loginRobot);
    await loginRobot.enterUsernameSsoLogin(username);
    await loginRobot.enterPasswordSsoLogin(password);
    await loginRobot.pressSignInSsoLogin();
    await _handleWaitUntilVisibleHomeServerPickerView(loginRobot);
    await loginRobot.grantNotificationPermission($.nativeAutomator);
    try{
      await $.tap(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
    );
    }catch(e){
      loginRobot.ignoreException();
    }
    await expectViewVisible($(ChatList));
  }

  Future<void> _handleFirebaseTestLab(LoginRobot loginRobot) async {
    try {
      await $.native.tap(Selector(text: "Use without an account"));
      await $.native.waitUntilVisible(Selector(resourceId: 'login'));
    } catch (e) {
      loginRobot.ignoreException();
    }
  }

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
