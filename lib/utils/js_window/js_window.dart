@JS()
library window;

import 'dart:js_interop';

import 'package:fluffychat/utils/js_window/universal_image_bitmap.dart';
import 'package:universal_html/html.dart';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

@JS()
@staticInterop
class JSWindow {}

extension JSWindowExtension on JSWindow {
  @JS('createImageBitmap')
  external JSPromise<web.ImageBitmap> createImageBitmap(web.Blob blob);
}

JSWindow get jsWindow => window as JSWindow;

Future<UniversalImageBitmap?> convertUint8ListToBitmap(Uint8List buffer) async {
  final blob = web.Blob([buffer.toJS].toJS);

  final web.ImageBitmap bitmap = await jsWindow.createImageBitmap(blob).toDart;
  
  return UniversalImageBitmap(width: bitmap.width, height: bitmap.height);
}
