import '../../base/test_base.dart';
import '../../scenarios/login_scenario.dart';
import '../../scenarios/send_image_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Should see Message image after sending image in chat',
    test: ($) async {
      final loginScenario = LoginScenario(
        $,
        username: const String.fromEnvironment('USERNAME'),
        serverUrl: const String.fromEnvironment('SERVER_URL'),
        password: const String.fromEnvironment('PASSWORD'),
      );
      final sendImageScenario = SendImageScenario(
        $,
        loginScenario: loginScenario,
      );
      await sendImageScenario.execute();
    },
  );
}
