import 'dart:js_interop';

import 'package:web/web.dart' show console;

void log(String message) {
  console.log(message.toJS);
}
