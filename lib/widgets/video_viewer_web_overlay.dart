import 'dart:typed_data';

import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:universal_html/html.dart' as html;

/// Injects a transparent `<video>` element into the DOM so the browser's
/// native "Save Video As" context menu targets the actual video bytes
/// rather than the canvas-rendered Flutter surface.
class VideoViewerWebOverlay {
  html.VideoElement? _videoElement;
  html.DivElement? _containerElement;
  String? _objectUrl;

  /// Attaches a full-viewport `<video>` overlay with [bytes] as its source.
  ///
  /// A wrapper `<div>` with `pointer-events: none` passes left-clicks through
  /// to Flutter's canvas while the `<video>` inside uses `pointer-events: all`
  /// so the browser's native right-click context menu detects it as a real
  /// video (enabling "Save Video As").
  void attach({
    required Uint8List bytes,
    required String mimeType,
    double appBarHeight = 56,
  }) {
    dispose();

    _objectUrl = bytes.toWebUrl(mimeType: mimeType);

    _videoElement = html.VideoElement()
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
      ..append(_videoElement!);

    html.document.body?.append(_containerElement!);
  }

  /// Removes the overlay element and releases the object URL.
  void dispose() {
    _containerElement?.remove();
    _containerElement = null;
    _videoElement?.remove();
    _videoElement = null;
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
      _objectUrl = null;
    }
  }
}
