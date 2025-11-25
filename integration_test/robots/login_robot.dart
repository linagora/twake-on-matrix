import 'dart:io';

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
    await $.waitUntilVisible($('Continue'));
    await $.tap($('Continue'));
  }

  Future<void> confirmShareInformation() async {
    try {
      await $.native.waitUntilVisible(
        Selector(textContains: 'Continue'),
        appId: 'com.apple.springboard',
      );
      await $.native.tap(
        Selector(textContains: 'Continue'),
        appId: 'com.apple.springboard',
      );
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> enterWebCredentialsWhenVisible({
    required String username,
    required String password,
  }) async {
    await enterUsernameSsoLogin(username);
    await enterPasswordSsoLogin(password);
    await pressSignInSsoLogin();
  }

  Selector getLoginTxt() {
    if (Platform.isAndroid) {
      return Selector(resourceId: 'login');
    } else {
      return Selector(textContains: 'login');
    }
  }

  Selector getPassTxt() {
    if (Platform.isAndroid) {
      return Selector(resourceId: 'password');
    } else {
      return Selector(text: 'Password');
    }
  }

  Selector getSignIn() {
    if (Platform.isIOS) {
      return Selector(text: 'Sign in');
    } else {
      return Selector(
        className: 'android.widget.Button',
        instance: 3,
      );
    }
  }

  Selector getErrorMgs() {
    return Selector(text: 'Invalid credentials');
  }

  String? getBrowserAppId() {
    if (Platform.isAndroid) {
      return 'com.android.chrome';
    }
    return null;
  }

  Future<bool> isLoginBtnVisible() async {
    if (Platform.isAndroid) {
      return true;
    }

    if (await CoreRobot($).existsOptionalNativeItems(
      $,
      getSignIn(),
      timeout: const Duration(milliseconds: 10000),
    )) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> enterUsernameSsoLogin(String username) async {
    try {
      await $.native.enterText(
        getLoginTxt(),
        text: username,
        appId: getBrowserAppId(),
      );
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> enterPasswordSsoLogin(String password) async {
    try {
      await $.native.enterText(
        getPassTxt(),
        text: password,
        appId: getBrowserAppId(),
      );
    } catch (e) {
      ignoreException();
    }
  }

  Future<void> pressSignInSsoLogin() async {
    try {
      await $.native.waitUntilVisible(
        getSignIn(),
        appId: getBrowserAppId(),
        timeout: const Duration(seconds: 10),
      );
      await Future.delayed(const Duration(seconds: 10));
      await $.native.tap(
        getSignIn(),
        appId: getBrowserAppId(),
      );
    } catch (e) {
      ignoreException();
    }
  }
}
