import '../chat_group_detail_robot.dart';

/// Web-specific chat-room detail robot.
///
/// On web there is no in-app media-permission dialog — the browser grants
/// media permissions (Playwright pre-grants them), so [confirmAccessMedia] is
/// a no-op. Keeping the mobile dialog flow out of the web path avoids a wasted
/// wait on a dialog that never appears (and a noisy failed step in the log).
class WebChatGroupDetailRobot extends ChatGroupDetailRobot {
  WebChatGroupDetailRobot(super.$);

  @override
  Future<void> confirmAccessMedia() async {}
}
