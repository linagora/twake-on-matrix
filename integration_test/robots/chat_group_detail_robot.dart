import 'package:linkfy_text/linkfy_text.dart';
import 'package:patrol/patrol.dart';
import '../base/core_robot.dart';

class ChatGroupDetailRobot extends CoreRobot {
  ChatGroupDetailRobot(super.$);

  Future<PatrolFinder> getText(String text) async {
    return $(MatrixLinkifyText).containing(text);
  }
}
