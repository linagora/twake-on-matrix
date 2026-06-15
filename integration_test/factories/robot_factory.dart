import 'package:patrol/patrol.dart';

import '../robots/abstract/abstract_chat_group_detail_robot.dart';
import '../robots/abstract/abstract_chat_list_robot.dart';
import '../robots/abstract/abstract_chat_profile_info_robot.dart';
import '../robots/abstract/abstract_contact_list_robot.dart';
import '../robots/abstract/abstract_forward_robot.dart';
import '../robots/abstract/abstract_group_information_robot.dart';
import '../robots/abstract/abstract_home_robot.dart';
import '../robots/abstract/abstract_language_setting_robot.dart';
import '../robots/abstract/abstract_login_robot.dart';
import '../robots/abstract/abstract_message_menu_robot.dart';
import '../robots/abstract/abstract_search_robot.dart';
import '../robots/abstract/abstract_search_view_robot.dart';
import '../robots/abstract/abstract_setting_robot.dart';

/// Contract for producing platform-appropriate robot implementations.
///
/// A conditional-export `robot_factory_provider.dart` picks the right
/// concrete factory at compile time: `MobileRobotFactory` on platforms
/// that expose `dart:io`, `WebRobotFactory` on the web target. Scenarios
/// and tests receive an instance of this factory and never reference a
/// concrete robot class or a platform branch.
abstract class RobotFactory {
  const RobotFactory();

  PatrolIntegrationTester get $;

  AbstractLoginRobot loginRobot();
  AbstractHomeRobot homeRobot();
  AbstractChatListRobot chatListRobot();
  AbstractChatGroupDetailRobot chatGroupDetailRobot();
  AbstractMessageMenuRobot messageMenuRobot();
  AbstractForwardRobot forwardRobot();
  AbstractSearchRobot searchRobot();
  AbstractSearchViewRobot searchViewRobot();
  AbstractGroupInformationRobot groupInformationRobot();
  AbstractChatProfileInfoRobot chatProfileInfoRobot();
  AbstractContactListRobot contactListRobot();
  AbstractSettingRobot settingRobot();
  AbstractLanguageSettingRobot languageSettingRobot();
}
