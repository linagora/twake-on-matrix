import 'web_test_main.dart' as web_test_main;

/// Web boot — uses the web-test-safe entry point (dead homeserver, no
/// native init) so `AutoHomeserverPicker` renders and the API login flow
/// can drive `m.login.password` against the real `SERVER_URL`.
Future<void> initTestApp() async {
  await web_test_main.main();
}
