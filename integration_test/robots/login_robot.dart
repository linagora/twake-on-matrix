import 'dart:io';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/pages/login/login_view.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class LoginRobot extends CoreRobot {
  LoginRobot(super.$);

  Selector getLoginTxt() {
    if (Platform.isAndroid) {
      return Selector(resourceId: 'email_username');
    } else {
      return Selector(className: 'textField', textContains: 'Email / Username');
    }
  }

  Selector getPassTxt() {
    if (Platform.isAndroid) {
      return Selector(resourceId: 'password');
    } else {
      return Selector(className: 'secureTextField', textContains: 'Password');
    }
  }

  Selector getSignInBtn() {
    const label = 'Sign in';
    if (Platform.isIOS) {
      return Selector(text: label);
    } else {
      return Selector(className: 'android.widget.Button', textContains: label);
    }
  }

  Selector getOKBtnInVerifyCaptchaDialog() {
    if (Platform.isIOS) {
      return Selector(text: 'Close', className: 'button');
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
    final context = $.tester.element(find.byType(Scaffold).first);
    final l10n = L10n.of(context)!;
    await $(l10n.useYourCompanyServer).tap();
  }

  Future<void> enterServerUrl(String serverUrl) async {
    await $.enterText($(HomeserverTextField), serverUrl);
  }

  Future<void> clickOnContinueBtn() async {
    final context = $.tester.element(find.byType(Scaffold).first);
    final label = L10n.of(context)!.continueProcess;
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
        try {
          await $.native.tap(Selector(textContains: label), appId: appId);
        } catch (_) {
          // Dialog may have been dismissed by iOS before the tap completed.
        }
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
      return Selector(className: 'android.widget.Button', textContains: label);
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
        await $.native.tap(getSignInTab(), appId: getBrowserAppId());
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
    await $.native.tap(getPassTxt(), appId: getBrowserAppId());
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

    // tap on Sign in – the browser modal may close immediately after a
    // successful login, causing Patrol to report an error even though the
    // tap succeeded. We catch that error and let the flow continue.
    try {
      await $.native.tap(getSignInBtn(), appId: getBrowserAppId());
    } catch (_) {
      // Browser closed after successful SSO login – expected.
      return;
    }

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
      try {
        await $.native.tap(getSignInBtn(), appId: getBrowserAppId());
      } catch (_) {
        // Browser closed after successful SSO login – expected.
      }
    }
  }

  // Password Login Methods (in-app)
  Future<void> waitForLoginView() async {
    await $(LoginView).waitUntilVisible(timeout: const Duration(seconds: 30));
  }

  Future<void> enterUsername(String username) async {
    final usernameField = $(TextField).at(0);
    await $.enterText(usernameField, username);
  }

  Future<void> enterPassword(String password) async {
    final passwordField = $(TextField).at(1);
    await $.enterText(passwordField, password);
  }

  Future<void> tapSignInButton() async {
    final signInButton = $(ElevatedButton).first;
    await signInButton.tap();
  }

  Future<void> loginWithPassword({
    required String username,
    required String password,
  }) async {
    await waitForLoginView();
    await enterUsername(username);
    await enterPassword(password);
    await tapSignInButton();
  }

  /// Logs in by running the OIDC flow via HTTP (no browser UI interaction).
  /// Obtains a one-time [loginToken] from the SSO server and feeds it directly
  /// to the app via the /onAuthRedirect deep link, bypassing any SSO browser
  /// modal entirely.
  Future<void> loginViaApi({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    // Wait for either TwakeWelcome (not logged in) or ChatList (already logged
    // in from a previous test run whose tokens persisted in the iOS keychain).
    await waitForEitherVisible(
      $: $,
      first: $(TwakeWelcome),
      second: $(ChatList),
      timeout: const Duration(seconds: 60),
    );

    if (await isChatListVisible()) return;

    final httpClient = await initialRedirectRequest();
    final oidcResult = await getLoginTokenViaOIDC(
      httpClient,
      username,
      password,
    );
    await closeHTTPClient(httpClient);

    final encodedServer = Uri.encodeComponent(serverUrl);
    // Use router.go() directly — bypasses app_links which only listens when
    // ChatList is active (post-login). go_router navigates synchronously.
    TwakeApp.router.go(
      '/onAuthRedirect?loginToken=${oidcResult.loginToken}&homeserver=$encodedServer',
    );
    await $.pump();

    await waitForChatList();
  }

  Future<void> waitForChatList() async {
    await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));
  }

  Future<bool> isLoginViewVisible() async {
    return $(LoginView).exists;
  }

  Future<bool> isChatListVisible() async {
    return $(ChatList).exists;
  }
}
