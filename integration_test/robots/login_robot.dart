import 'dart:io';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class LoginRobot extends CoreRobot {
  LoginRobot(super.$);

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

  Selector getOKBtnInVerifyCaptchaDialog() {
    if (Platform.isIOS) {
      return Selector(
        text: 'Close',
        className: 'button',
      );
    } else {
      return Selector(resourceId: 'com.android.chrome:id/positive_button');
    }
  }

  Future<bool> isWelcomePageVisible() async {
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
    await waitUntilAbsent(
      $,
      $(TwakeWelcome),
      timeout: const Duration(seconds: 60),
    );
  }

  Future<void> confirmShareInformation() async {
    if (PlatformInfos.isIOS) {
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

  Future<bool> isSignInPageVisible() async {
    //login on Chrome browser without an account
    if (Platform.isAndroid) {
      final loginBrowserWithoutAccountOpt = Selector(
        resourceId: 'com.android.chrome:id/signin_fre_dismiss_button',
      );
      if (await CoreRobot($).existsOptionalNativeItems(
        $,
        loginBrowserWithoutAccountOpt,
        appId: getBrowserAppId(),
      )) {
        await $.native.tap(
          loginBrowserWithoutAccountOpt,
          appId: getBrowserAppId(),
        );
        await waitNativeGone(loginBrowserWithoutAccountOpt);
      }
    }

    for (int i = 0; i < 12; i++) {
      // check if login page is skipt to show the Chat list
      if ($(ChatList).exists) {
        break;
      }
      //login in Twake Chat
      if (await CoreRobot($).existsOptionalNativeItems(
        $,
        getSignInTab(),
        appId: getBrowserAppId(),
      )) {
        await $.native.tap(
          getSignInTab(),
          appId: getBrowserAppId(),
        );
        return true;
      }
    }
    return false;
  }

  Future<void> enterUsernameSsoLogin(String username) async {
    await $.native.waitUntilVisible(
      getLoginTxt(),
      appId: getBrowserAppId(),
      timeout: const Duration(seconds: 10),
    );
    await $.native.enterText(
      getLoginTxt(),
      text: username,
      appId: getBrowserAppId(),
    );
  }

  Future<void> enterPasswordSsoLogin(String password) async {
    await $.native.waitUntilVisible(
      getPassTxt(),
      appId: getBrowserAppId(),
      timeout: const Duration(seconds: 10),
    );
    // Tap the field and wait for 1 second to avoid
    // a flaky issue where the screen sometimes navigates
    // back to the previous page right after entering the password
    await $.native.tap(
      getPassTxt(),
      appId: getBrowserAppId(),
    );
    await Future.delayed(const Duration(seconds: 1));

    await $.native.enterText(
      getPassTxt(),
      text: password,
      appId: getBrowserAppId(),
    );
  }

  Future<void> pressSignInSsoLogin() async {
    await $.native.waitUntilVisible(
      getSignInBtn(),
      appId: getBrowserAppId(),
      timeout: const Duration(seconds: 20),
    );

    // set a delay for verifying Captcha
    await Future.delayed(const Duration(seconds: 2));

    // tap on Sign in
    await $.native.tap(
      getSignInBtn(),
      appId: getBrowserAppId(),
    );

    // if "verify ...please wait for Captcha" dialog is shown, click OK to continue waiting
    // and click Sign in again
    if (await CoreRobot($).existsOptionalNativeItems(
      $,
      getOKBtnInVerifyCaptchaDialog(),
      appId: getBrowserAppId(),
      timeout: const Duration(seconds: 2),
    )) {
      await $.native.tap(
        getOKBtnInVerifyCaptchaDialog(),
        appId: getBrowserAppId(),
      );
      await $.native.tap(
        getSignInBtn(),
        appId: getBrowserAppId(),
      );
    }
  }
}
