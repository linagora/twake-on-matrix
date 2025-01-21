import '../../base/test_base.dart';
import '../../scenarios/login_scenario.dart';
import '../../scenarios/send_text_message_scenario.dart';

void main() {
  TestBase().runPatrolTest(
    description: 'Should see Message bubble after sending text message',
    test: ($) async {
      final loginScenario = LoginScenario(
        $,
        username: const String.fromEnvironment('USERNAME'),
        serverUrl: const String.fromEnvironment('SERVER_URL'),
        password: const String.fromEnvironment('PASSWORD'),
      );
      final sendTextMessageScenario = SendTextMessageScenario(
        $,
        loginScenario: loginScenario,
      );
      await sendTextMessageScenario.execute();
    },
  );
}
