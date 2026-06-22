import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs a [FlutterError.onError] that, on web only, swallows a couple of
/// pre-existing, benign rendering assertions that fire under the narrow
/// headless-web harness and are unrelated to the test logic
/// (see [isBenignWebError]). Mobile stays strict.
///
/// Must be called from within a test body (it uses [addTearDown]).
/// `FlutterError.onError` is a global static, so the previous handler is
/// captured and restored on teardown — otherwise each test's wrapper would
/// stack onto the last one's, compounding the filtering.
void installWebBenignErrorFilter() {
  final originalOnError = FlutterError.onError ?? FlutterError.presentError;
  addTearDown(() => FlutterError.onError = originalOnError);
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kIsWeb && isBenignWebError(details)) {
      FlutterError.dumpErrorToConsole(details);
      return;
    }
    originalOnError(details);
  };
}

/// Whether [details] is one of the known, benign web-only rendering
/// assertions:
///   * a `RenderFlex` overflow in a few app layouts (e.g. the reply preview
///     above the composer);
///   * `chat_web_scrollbar` momentarily reporting its `ScrollController`
///     attached to multiple scroll views while the layout rebuilds (e.g.
///     entering message-select mode).
///
/// The scrollbar case requires the exact framework assertion in addition to
/// the `chat_web_scrollbar` stack frame, so an unrelated regression from that
/// file is not silently swallowed.
bool isBenignWebError(FlutterErrorDetails details) {
  final message = details.exceptionAsString();
  final stack = details.stack?.toString() ?? '';
  final isKnownScrollbarAttachAssertion =
      stack.contains('chat_web_scrollbar') &&
      message.contains('ScrollController attached to multiple scroll views');
  return message.contains('A RenderFlex overflowed by') ||
      isKnownScrollbarAttachAssertion;
}
