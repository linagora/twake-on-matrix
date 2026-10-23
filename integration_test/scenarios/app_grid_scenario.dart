import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';

// Apps bundled in configurations/app_dashboard.json.
const _configuredAppNames = 'Mail|Drive';
const _configuredAppLinks =
    'http://tmail.linagora.com/|https://tdrive.linagora.com/';

class AppGridOpenAndCloseScenario extends BaseTestScenario {
  AppGridOpenAndCloseScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();
    final appGrid = robots.appGridRobot();

    await appGrid.openAppGrid();
    s
      ..softAssertEquals(
        appGrid.isHelpButtonVisible(),
        true,
        'help button is not shown next to the app grid',
      )
      ..softAssertEquals(
        appGrid.getVisibleAppNames().join('|'),
        _configuredAppNames,
        'app grid does not list the configured apps',
      )
      ..softAssertEquals(
        appGrid.getVisibleAppLinks().join('|'),
        _configuredAppLinks,
        'app grid apps do not link to the configured URLs',
      );

    await appGrid.closeAppGridByTappingButton();
    s.softAssertEquals(appGrid.isAppGridOpen(), false, 'app grid still open');

    s.verifyAll();
  }
}

class AppGridCloseOnTapOutsideScenario extends BaseTestScenario {
  AppGridCloseOnTapOutsideScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final appGrid = robots.appGridRobot();

    await appGrid.openAppGrid();
    await appGrid.closeAppGridByTappingOutside();

    final s = SoftAssertHelper()
      ..softAssertEquals(appGrid.isAppGridOpen(), false, 'app grid still open');
    s.verifyAll();
  }
}

class AppGridHiddenScenario extends BaseTestScenario {
  AppGridHiddenScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    await robots.homeRobot().waitForMainNavigation();

    final s = SoftAssertHelper()
      ..softAssertEquals(
        robots.appGridRobot().isAppGridButtonVisible(),
        false,
        'app grid button is shown on mobile',
      );
    s.verifyAll();
  }
}
