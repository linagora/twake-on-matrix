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
import '../robots/login_robot.dart';
import '../robots/search_robot.dart';
import '../robots/setting/app_language_setting_robot.dart';
import '../robots/setting/setting_robot.dart';
import 'robot_factory.dart';

/// Mobile implementation of [RobotFactory].
///
/// Delegates to the concrete robot classes that existed before the
/// cross-platform refactor.
class MobileRobotFactory implements RobotFactory {
  const MobileRobotFactory(this.$);

  @override
  final PatrolIntegrationTester $;

  @override
  AbstractLoginRobot loginRobot() => LoginRobot($);

  @override
  AbstractHomeRobot homeRobot() => HomeRobot($);

  @override
  AbstractChatListRobot chatListRobot() => ChatListRobot($);

  @override
  AbstractChatGroupDetailRobot chatGroupDetailRobot() =>
      ChatGroupDetailRobot($);

  @override
  AbstractSearchRobot searchRobot() => SearchRobot($);

  @override
  AbstractContactListRobot contactListRobot() => ContactListRobot($);

  @override
  AbstractSettingRobot settingRobot() => SettingRobot($);

  @override
  AbstractLanguageSettingRobot languageSettingRobot() =>
      LanguageSettingRobot($);
}
