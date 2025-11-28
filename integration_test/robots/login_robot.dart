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
      await welcomePage.waitUntilVisible();
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

  Future<void> clickOnContinueBtn() async {
    const label = 'Continue';
    await $.waitUntilVisible($(label));
    await $.tap($(label));
    await Future.delayed(const Duration(seconds: 3));
  }

  Future<void> confirmShareInformation() async {
    if (Platform.isIOS) {
      const appId = 'com.apple.springboard';
      const label = 'Continue';
      if (await CoreRobot($).existsOptionalNativeItems(
        $,
        Selector(textContains: label),
        appId: appId,
      )) {
        await $.native.tap(
          Selector(textContains: label),
          appId: appId,
        );
      }
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

  Selector getSignInTab() {
    const label = 'Email / Username';
    if (Platform.isAndroid) {
      return Selector(
        className: 'android.widget.Button',
        textContains: label,
      );
    } else {
      return Selector(text: label);
    }
  }

  Selector getLoginTxt() {
    if (Platform.isAndroid) {
      return Selector(resourceId: 'email_username');
    } else {
      return Selector(
        className: 'textField',
        textContains: 'Email / Username',
      );
    }
  }

  Selector getPassTxt() {
    if (Platform.isAndroid) {
      return Selector(resourceId: 'password');
    } else {
      return Selector(
        className: 'secureTextField',
        textContains: 'Password',
      );
    }
  }

  Selector getSignInBtn() {
    const label = 'Sign in';
    if (Platform.isIOS) {
      return Selector(text: label);
    } else {
      return Selector(
        className: 'android.widget.Button',
        textContains: label,
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
    if (await CoreRobot($).existsOptionalNativeItems(
      $,
      getSignInTab(),
      appId: getBrowserAppId(),
      timeout: const Duration(seconds: 60),
    )) {
      await $.native.tap(
        getSignInTab(),
        appId: getBrowserAppId(),
      );
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
        getSignInBtn(),
        appId: getBrowserAppId(),
        timeout: const Duration(seconds: 10),
      );
      await Future.delayed(const Duration(seconds: 10));
      await $.native.tap(
        getSignInBtn(),
        appId: getBrowserAppId(),
      );
    } catch (e) {
      ignoreException();
    }
  }
}
