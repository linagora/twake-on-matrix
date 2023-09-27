@JS()
library window;

import 'package:fluffychat/utils/js_window/universal_image_bitmap.dart';
import 'package:universal_html/html.dart';
import 'dart:typed_data';

import 'package:js/js.dart';
import 'package:js/js_util.dart';

@JS()
@staticInterop
class JSWindow {}

extension JSWindowExtension on JSWindow {
  external Function get createImageBitmap;
}

JSWindow get jsWindow => window as JSWindow;

Future<UniversalImageBitmap?> convertUint8ListToBitmap(Uint8List buffer) async {
  final blob = Blob([buffer]);

  final result = await jsWindow.createImageBitmap(blob);
  final ImageBitmap bitmap = await promiseToFuture(result);

  return UniversalImageBitmap(width: bitmap.width, height: bitmap.height);
}
