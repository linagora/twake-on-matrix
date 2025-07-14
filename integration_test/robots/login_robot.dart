
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:patrol/patrol.dart';

import '../base/core_robot.dart';

class LoginRobot extends CoreRobot {
  LoginRobot(super.$);

  Future<void> tapOnUseYourCompanyServer() async {
    await $('Use your company server').tap();
  }

  Future<void> enterServerUrl(String serverUrl) async {
    await $.enterText($(HomeserverTextField), serverUrl);
  }

  Future<void> confirmServerUrl() async {
    await $.tap($('Continue'));
  }

  Future<void> confirmShareInformation() async {
    try {
      await $.native.waitUntilVisible(Selector(textContains: 'Continue'), appId:'com.apple.springboard',);
      await $.native.tap(Selector(textContains: 'Continue'), appId:'com.apple.springboard',);
    } catch (e) {
      ignoreException();
    }
  }
  Future<void> enterWebCredentialsWhenVisible({required String username,required String password,}) async {
    await enterPasswordSsoLogin(password);
    // await enterUsernameSsoLogin(username);
    await pressSignInSsoLogin();
  }

  Future<void> enterUsernameSsoLogin(String username) async {
    try {
      // final usernameSelector = Selector(text: 'Phone number / Username / Email');
      // await $.native.waitUntilVisible(usernameSelector,timeout: const Duration(seconds: 3));
      // await $.native.enterText(usernameSelector, text: username);

      await $.native.enterTextByIndex(
        username,
        index: 0,
      );
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> enterPasswordSsoLogin(String password) async {
    try {
      await $.native.waitUntilVisible(Selector(text: 'Password'),timeout: const Duration(seconds: 3));
      await $.native.enterText(
        Selector(text: 'Password'),
        text: password,
      );
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> pressSignInSsoLogin() async {
    try {
      await $.native.tap(
        Selector(
          text: 'Sign in',
          instance: 1,
        ),
      );
    } catch (e) {
      ignoreException();
    }
  }
}
