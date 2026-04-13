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
    await loginRobot.loginViaApi(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );
    await loginRobot.grantNotificationPermission();
  }
}
