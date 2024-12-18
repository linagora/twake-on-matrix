import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/homeserver_picker/homeserver_picker_view.dart';
import 'package:fluffychat/pages/twake_welcome/twake_welcome.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import '../base/base_scenario.dart';

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
  @override
  Future<void> execute() async {
    await $.waitUntilVisible($(TwakeWelcome));
    await expectViewVisible($(TwakeWelcome));
    await $('Use your company server').tap();
    await $.waitUntilVisible($(HomeserverPickerView));
    await $.enterText($(HomeserverTextField), serverUrl);
    await $.tap($('Continue'));

    await $.native.enterTextByIndex(
      username,
      index: 0,
    );
    await $.native.enterTextByIndex(
      password,
      index: 1,
    );
    await $.native.tap(
      Selector(
        text: 'Sign in',
        instance: 1,
      ),
    );
    await expectViewVisible($(ChatList));
  }
}
