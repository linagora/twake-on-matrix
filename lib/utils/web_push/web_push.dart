// Conditional export: real Web Push impl on web, no-op stub elsewhere.
// Matches the existing pattern (e.g. send_file_web_extension.dart).
export 'web_push_stub.dart' if (dart.library.js_interop) 'web_push_web.dart';
