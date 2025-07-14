import 'package:patrol/patrol.dart';

abstract class CoreRobot {
  final PatrolIntegrationTester $;

  CoreRobot(this.$);

  dynamic ignoreException() => $.tester.takeException();
  
  Future<void> grantNotificationPermission() async {
    if (await $.native.isPermissionDialogVisible(
      timeout: const Duration(seconds: 15),
    )) {
      await $.native.grantPermissionWhenInUse();
    }
  }
}
