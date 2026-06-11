import 'dart:typed_data';

import 'package:fluffychat/utils/extension/web_url_creation_extension.dart';
import 'package:universal_html/html.dart' as html;

/// Injects a transparent HTML media element into the DOM so the browser's
/// native right-click context menu targets the actual media bytes rather than
/// the canvas-rendered Flutter surface.
///
/// Use [MediaViewerWebOverlay.image] for images (enables "Save Image As") and
/// [MediaViewerWebOverlay.video] for videos (enables "Save Video As").
class MediaViewerWebOverlay {
  MediaViewerWebOverlay._({required html.HtmlElement Function() createElement})
    : _createElement = createElement;

  /// Creates an overlay backed by a transparent `<img>` element.
  factory MediaViewerWebOverlay.image() =>
      MediaViewerWebOverlay._(createElement: html.ImageElement.new);

  /// Creates an overlay backed by a transparent `<video>` element.
  factory MediaViewerWebOverlay.video() =>
      MediaViewerWebOverlay._(createElement: html.VideoElement.new);

  final html.HtmlElement Function() _createElement;

  html.HtmlElement? _mediaElement;
  html.DivElement? _containerElement;
  String? _objectUrl;

  /// Attaches a full-viewport media overlay with [bytes] as its source.
  ///
  /// A wrapper `<div>` with `pointer-events: none` passes left-clicks through
  /// to Flutter's canvas while the media element inside uses
  /// `pointer-events: all` so the browser's native right-click context menu
  /// detects it as a real media element.
  void attach({
    required Uint8List bytes,
    required String mimeType,
    double appBarHeight = 56,
  }) {
    dispose();

    _objectUrl = bytes.toWebUrl(mimeType: mimeType);

    _mediaElement = _createElement()
      ..setAttribute('src', _objectUrl!)
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
      ..append(_mediaElement!);

    html.document.body?.append(_containerElement!);
  }

  /// Removes the overlay element and releases the object URL.
  void dispose() {
    _containerElement?.remove();
    _containerElement = null;
    _mediaElement?.remove();
    _mediaElement = null;
    if (_objectUrl != null) {
      html.Url.revokeObjectUrl(_objectUrl!);
      _objectUrl = null;
    }
  }
}
