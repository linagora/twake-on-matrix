import 'package:patrol/patrol.dart';

import '../robots/abstract/abstract_chat_group_detail_robot.dart';
import '../robots/abstract/abstract_chat_list_robot.dart';
import '../robots/abstract/abstract_contact_list_robot.dart';
import '../robots/abstract/abstract_home_robot.dart';
import '../robots/abstract/abstract_language_setting_robot.dart';
import '../robots/abstract/abstract_login_robot.dart';
import '../robots/abstract/abstract_search_robot.dart';
import '../robots/abstract/abstract_setting_robot.dart';
import '../robots/chat_group_detail_robot.dart';
import '../robots/chat_list_robot.dart';
import '../robots/contact_list_robot.dart';
import '../robots/home_robot.dart';
import '../robots/setting/setting_robot.dart';
import '../robots/web/web_language_setting_robot.dart';
import '../robots/web/web_login_robot.dart';
import '../robots/web/web_search_robot.dart';
import 'robot_factory.dart';

/// Web implementation of [RobotFactory].
///
/// Uses dedicated `WebXRobot` classes where the UI genuinely diverges
/// between mobile and web (login flow, navigation back, language text
/// casing). Robots without platform divergence (home, chat list, chat
/// group detail, contacts, settings) are shared with mobile.
class WebRobotFactory implements RobotFactory {
  const WebRobotFactory(this.$);

  @override
  final PatrolIntegrationTester $;

  @override
  AbstractLoginRobot loginRobot() => WebLoginRobot($);

  @override
  AbstractHomeRobot homeRobot() => HomeRobot($);

  @override
  AbstractChatListRobot chatListRobot() => ChatListRobot($);

  @override
  AbstractChatGroupDetailRobot chatGroupDetailRobot() =>
      ChatGroupDetailRobot($);

  @override
  AbstractSearchRobot searchRobot() => WebSearchRobot($);

  @override
  AbstractContactListRobot contactListRobot() => ContactListRobot($);

  @override
  AbstractSettingRobot settingRobot() => SettingRobot($);

  @override
  AbstractLanguageSettingRobot languageSettingRobot() =>
      WebLanguageSettingRobot($);
}
