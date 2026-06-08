/// Conditional boot for integration tests.
///
/// Mobile (`dart:io`) launches the real app entry point
/// (`package:fluffychat/main.dart`). Web swaps in [web_test_main], which
/// skips native-only init (vodozemac WASM, MediaKit, Cozy) that hangs in
/// headless Chrome and pre-seeds a dead homeserver so `AutoHomeserverPicker`
/// fails fast and renders instead of redirecting to SSO (which would destroy
/// Playwright's JS context).
///
/// This is the only platform branch in the test boot path; everything
/// downstream goes through the abstract robots resolved by `RobotFactory`.
library;

export 'test_app_initializer_io.dart'
    if (dart.library.js_interop) 'test_app_initializer_web.dart';
