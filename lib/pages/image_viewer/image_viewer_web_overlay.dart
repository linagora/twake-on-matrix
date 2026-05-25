import 'dart:typed_data';

import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:universal_html/html.dart' as html;

/// Injects a transparent `<img>` element into the DOM so the browser's
/// native "Save Image As" context menu targets the actual image bytes
/// rather than the canvas-rendered Flutter surface.
class ImageViewerWebOverlay {
  html.ImageElement? _imgElement;
  String? _objectUrl;

  html.DivElement? _containerElement;

  /// Attaches a full-viewport `<img>` overlay with [bytes] as its source.
  ///
  /// A wrapper `<div>` with `pointer-events: none` passes left-clicks through
  /// to Flutter's canvas while the `<img>` inside uses `pointer-events: all`
  /// so the browser's native right-click context menu detects it as a real
  /// image (enabling "Save Image As").
  void attach({
    required Uint8List bytes,
    required String mimeType,
    double appBarHeight = 56,
  }) {
    dispose();

    _objectUrl = bytes.toWebUrl(mimeType: mimeType);

    _imgElement = html.ImageElement()
      ..src = _objectUrl!
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.pointerEvents = 'all'
      ..style.opacity = '0';

    _containerElement = html.DivElement()
      ..style.position = 'fixed'
      ..style.top = '${appBarHeight}px'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = 'calc(100% - ${appBarHeight}px)'
      ..style.zIndex = '-1'
      ..style.pointerEvents = 'none'
      ..append(_imgElement!);

    html.document.body?.append(_containerElement!);
  }

  /// Removes the overlay element and releases the object URL.
  void dispose() {
    _containerElement?.remove();
    _containerElement = null;
    _imgElement?.remove();
    _imgElement = null;
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
      _objectUrl = null;
    }
  }
}
