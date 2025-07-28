import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class LoginRobot extends CoreRobot {
  LoginRobot(super.$);

  Future<bool> isWelComePageVisible() async {
    final welcomePage = $(TwakeWelcome);
    try {
      await welcomePage.waitUntilVisible(timeout: const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

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
    await enterUsernameSsoLogin(username);
    await enterPasswordSsoLogin(password);
    await pressSignInSsoLogin();
  }

  Future<void> enterUsernameSsoLogin(String username) async {
    try {
      await $.native.enterText(Selector(text: 'login'),text: username,);
      } catch (e) {
        ignoreException();
      }
  }

  Future<void> enterPasswordSsoLogin(String password) async {
    try {
      await $.native.enterText(Selector(text: 'Password'),text: password,
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
