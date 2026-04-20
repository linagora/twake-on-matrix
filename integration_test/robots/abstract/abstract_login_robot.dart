/// Platform-agnostic login contract for integration tests.
///
/// Concrete implementations drive whichever login flow is appropriate for
/// the running platform: OIDC SSO bypass on mobile, direct
/// `m.login.password` via the Matrix SDK on web, etc. Scenarios should
/// depend only on this interface — never on a concrete robot class.
abstract class AbstractLoginRobot {
  Future<void> loginViaApi({
    required String serverUrl,
    required String username,
    required String password,
  });
}
