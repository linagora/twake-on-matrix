import 'package:fluffychat/pages/auto_homeserver_picker/auto_homeserver_picker.dart';
import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matrix/matrix.dart';

import '../../base/core_robot.dart';
import '../abstract/abstract_login_robot.dart';

/// Web-specific login robot.
///
/// On web the home route renders [AutoHomeserverPicker] (not `TwakeWelcome`)
/// and the SSO OIDC bypass is not available (cross-origin XHR blocked).
/// Authentication always goes through `m.login.password` against the
/// Matrix SDK directly.
class WebLoginRobot extends CoreRobot implements AbstractLoginRobot {
  WebLoginRobot(super.$);

  @override
  Future<void> loginViaApi({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    await waitForEitherVisible(
      $: $,
      first: $(AutoHomeserverPicker),
      second: $(ChatList),
      timeout: const Duration(seconds: 60),
    );

    if ($(ChatList).exists) return;

    // On web, always authenticate via m.login.password — SSO bypass
    // is not reachable (cross-origin XHR blocked).
    final context = $.tester.element(find.byType(AutoHomeserverPicker).first);
    final matrix = Matrix.of(context);
    Logs().i('WebLoginRobot: getLoginClient()');
    final client = await matrix.getLoginClient();
    Logs().i('WebLoginRobot: checkHomeserver($serverUrl)');
    matrix.loginHomeserverSummary = await client
        .checkHomeserver(Uri.parse(serverUrl))
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
            'WebLoginRobot: checkHomeserver($serverUrl) timed out after 30s',
          ),
        )
        .toHomeserverSummary();

    Logs().i('WebLoginRobot: client.login($username)');
    await client
        .login(
          LoginType.mLoginPassword,
          identifier: AuthenticationUserIdentifier(user: username),
          password: password,
          initialDeviceDisplayName: PlatformInfos.clientName,
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => throw Exception(
            'WebLoginRobot: client.login($username) timed out after 30s',
          ),
        );
    Logs().i('WebLoginRobot: login complete');

    // Force the router to re-evaluate redirects → lands on ChatList.
    TwakeApp.router.go('/');
    await $.pump();
    await $(ChatList).waitUntilVisible(timeout: const Duration(seconds: 60));
  }
}
