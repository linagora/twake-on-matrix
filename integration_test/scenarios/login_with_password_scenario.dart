import 'package:fluffychat/pages/chat_list/chat_list.dart';
import 'package:fluffychat/pages/login/login_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../base/base_test_scenario.dart';
import '../help/soft_assertion_helper.dart';

/// Verifies that the auto-login performed by [TestBase] succeeded.
///
/// By the time [runTestLogic] is called the session is already authenticated,
/// so this scenario only asserts the post-login state: [ChatList] visible and
/// [LoginView] gone.
class LoginWithPasswordScenario extends BaseTestScenario {
  LoginWithPasswordScenario(super.$, super.robots);

  @override
  Future<void> runTestLogic() async {
    final s = SoftAssertHelper();

    s.softAssertEquals($(ChatList).exists, true, 'Navigated to ChatList');

    s.softAssertEquals(
      $(LoginView).exists,
      false,
      'LoginView is no longer visible',
    );

    s.verifyAll();
  }
}
