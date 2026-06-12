import 'package:fluffychat/pages/chat/events/message_content.dart';
import 'package:fluffychat/pages/forward/forward_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pull_down_button/pull_down_button.dart';

import '../base/core_robot.dart';
import 'abstract/abstract_message_menu_robot.dart';
import 'menu_robot.dart';

/// Mobile message action menu.
///
/// Long-pressing a message bubble opens a `PullDownMenu` overlay whose items
/// are `PullDownMenuItem`s, located via [PullDownMenuRobot].
class MessageMenuRobot extends CoreRobot implements AbstractMessageMenuRobot {
  MessageMenuRobot(super.$);

  @override
  Future<void> openForward(String message) async {
    await $(MessageContent).containing(find.text(message)).longPress();
    await $.waitUntilVisible($(PullDownMenu));
    await $.pump();

    await PullDownMenuRobot($).getForwardItem().tap();
    await $.pump(const Duration(milliseconds: 300));
    await $.pumpAndTrySettle();

    await $.waitUntilExists(
      $(ForwardView),
      timeout: const Duration(seconds: 15),
    );
  }
}
