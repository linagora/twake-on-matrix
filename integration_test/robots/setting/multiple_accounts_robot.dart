import 'package:twake_chat/providers/login_sessions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
import 'package:flutter_test/flutter_test.dart';
import 'package:linagora_design_flutter/dialog/confirmation_dialog_builder.dart';
import 'package:linagora_design_flutter/multiple_account/multiple_account_view.dart';
import 'package:matrix/matrix.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/pages/chat_list/chat_list.dart';
import 'package:twake_chat/pages/twake_welcome/twake_welcome.dart';
import 'package:twake_chat/providers/active_matrix_client_provider.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/widgets/matrix.dart';
import 'package:twake_chat/widgets/twake_app.dart';

import '../../base/api_login_helper.dart';
import '../../base/matrix_login_retry.dart';
import '../home_robot.dart';
import 'settings_profile_robot.dart';

/// Drives the legacy multiple-account flow: Settings > Profile > account
/// picker ("Add another account" / switch), and Settings > Logout.
class MultipleAccountsRobot extends HomeRobot {
  MultipleAccountsRobot(super.$);

  static const _timeout = Duration(seconds: 60);

  L10n get _l10n => L10n.of($.tester.element(find.byType(Scaffold).first))!;

  BuildContext get _context => $.tester.element(find.byType(Scaffold).first);

  MatrixState get _matrix => Matrix.of(_context);

  /// Matrix ID of the account the Riverpod consumers see as active. It is read
  /// from `activeMatrixClientProvider`, not from `MatrixState.client`: the
  /// state stays right when the provider is stale, which is the failure this
  /// scenario has to see.
  String? activeUserId() => ProviderScope.containerOf(
    _context,
    listen: false,
  ).read(activeMatrixClientProvider)?.userID;

  /// Matrix IDs of every logged-in account known to the app.
  List<String> loggedInUserIds() => _matrix.currentClients
      .whereType<Client>()
      .where((client) => client.isLogged())
      .map((client) => client.userID!)
      .toList();

  PatrolFinder picker() => $(MultipleAccountView);

  PatrolFinder pickerAccount(String userId) => picker().$(userId);

  PatrolFinder addAnotherAccountButton() => $(_l10n.addAnotherAccount);

  Future<SettingsProfileRobot> openProfile() async {
    await gotoSettingScreen();
    final profileRobot = SettingsProfileRobot($);
    await profileRobot.openProfile();
    return profileRobot;
  }

  Future<void> openPicker() async {
    final profileRobot = await openProfile();
    await profileRobot.openMultipleAccountsPicker();
    await picker().waitUntilVisible();
  }

  /// Opens the picker from Settings > Profile and returns the Matrix IDs it
  /// lists.
  Future<List<String>> listedAccounts() async {
    await openPicker();
    final ids = picker()
        .$(Text)
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .whereType<String>()
        .where((text) => text.startsWith('@') && text.contains(':'))
        .toList();
    await closePicker();
    await SettingsProfileRobot($).backToSettings();
    return ids;
  }

  Future<void> closePicker() async {
    if (!picker().exists) return;
    await $.native.pressBack().catchError((_) {});
    if (picker().exists) {
      await $.tester.tapAt(const Offset(10, 10));
      await $.pumpAndSettle();
    }
    await waitUntilAbsent($, picker());
  }

  /// Adds [username] through "Add another account" and waits until it is the
  /// active account. Uses the same login path as the initial test login
  /// (SSO bypass when `SSO_URL` is set, `m.login.password` otherwise), so no
  /// credentials are typed in a browser.
  Future<String> addAccount({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final before = activeUserId();
    await openPicker();
    await addAnotherAccountButton().tap();
    await $(TwakeWelcome).waitUntilVisible(timeout: _timeout);

    const ssoURL = String.fromEnvironment('SSO_URL');
    if (ssoURL.isNotEmpty) {
      final loginToken = await fetchAuthToken(
        username: username,
        password: password,
      );
      TwakeApp.router.go(
        '/onAuthRedirect?loginToken=${Uri.encodeQueryComponent(loginToken)}'
        '&homeserver=${Uri.encodeComponent(serverUrl)}',
      );
      await $.pump();
    } else {
      final context = $.tester.element($(TwakeWelcome).finder.first);
      final client = await Matrix.of(context).getLoginClient();
      await ProviderScope.containerOf(context, listen: false)
          .read(loginSessionsProvider)
          .checkHomeserver(client, Uri.parse(serverUrl));
      await loginWithRateLimitRetry(
        () => client.login(
          LoginType.mLoginPassword,
          identifier: AuthenticationUserIdentifier(user: username),
          password: password,
          initialDeviceDisplayName: PlatformInfos.clientName,
        ),
        log: debugPrint,
      );
    }

    await _waitUntil(
      () => activeUserId() != null && activeUserId() != before,
      'added account did not become active',
    );
    // The scaffold is still on the Settings tab: the real flow does not jump
    // to the rooms either, so the test goes to the chat list tab itself.
    TwakeApp.router.go('/rooms');
    await waitForMainNavigation();
    await gotoChatListScreen();
    await _ensureChatList();
    return activeUserId()!;
  }

  /// Switches to [userId] from the account picker.
  Future<void> switchTo(String userId) async {
    await openPicker();
    await pickerAccount(userId).tap();
    await _waitUntil(
      () => activeUserId() == userId,
      'did not switch to $userId',
    );
    await _ensureChatList();
  }

  /// Logs the active account out from Settings > Logout.
  Future<void> logoutActiveAccount() async {
    final settingRobot = await gotoSettingScreen();
    await settingRobot.logoutOfApp();
    await $(ConfirmationDialogBuilder).$(_l10n.logout).tap();
  }

  /// The welcome screen is shown once the last account logged out.
  Future<void> waitForWelcome() async {
    await $(TwakeWelcome).waitUntilVisible(timeout: _timeout);
  }

  Future<void> waitForActiveAccount(String userId) async {
    await _waitUntil(
      () => activeUserId() == userId,
      '$userId is not the active account',
    );
    await _ensureChatList();
  }

  Future<void> _ensureChatList() async {
    await $(ChatList).waitUntilVisible(timeout: _timeout);
  }

  Future<void> _waitUntil(bool Function() condition, String reason) async {
    final deadline = DateTime.now().add(_timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) throw TestFailure(reason);
      await $.pump(const Duration(milliseconds: 200));
    }
  }
}
