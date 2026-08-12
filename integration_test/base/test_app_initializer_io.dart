import 'package:twake_chat/main.dart' as app;

/// Mobile/desktop boot — the real application entry point, unchanged from
/// the pre-migration behaviour.
Future<void> initTestApp() async {
  app.main();
}
