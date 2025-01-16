import 'package:fluffychat/pages/chat/chat_input_row_send_btn.dart';
import 'package:fluffychat/pages/chat/chat_view.dart';
import 'package:fluffychat/pages/chat/input_bar/input_bar.dart';
import 'package:fluffychat/pages/chat_list/chat_list_item.dart';
import 'package:flutter_test/flutter_test.dart';
import '../base/base_scenario.dart';
import 'login_scenario.dart';

class SendTextMessageScenario extends BaseScenario {
  LoginScenario loginScenario;
  SendTextMessageScenario(
    super.$, {
    required this.loginScenario,
  });

  @override
  Future<void> execute() async {
    await loginScenario.execute();
    await $.tap($(ChatListItem));
    await $.waitUntilVisible($(ChatView));
    await $.enterText($(InputBar), "test message");
    await $.tap($(ChatInputRowSendBtn));
  }
}
