import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Enables the browser's native "Save Image As" context menu for the image
/// viewer on web.
///
/// Strategy:
/// - `<img>` sits over the image area with `pointer-events: none` by default
///   → Flutter receives all interactions normally.
/// - On `mousedown` with right-button (button=2), we flip the img to
///   `pointer-events: auto` BEFORE the browser fires `contextmenu`.
///   The browser's next event (`contextmenu`) then hits the `<img>` directly
///   → browser shows "Save Image As" natively (no synthetic re-dispatch needed).
/// - After `contextmenu` fires, we restore `pointer-events: none`.
class ImageViewerWebOverlay {
  web.HTMLImageElement? _imgElement;
  web.HTMLDivElement? _container;
  String? _blobUrl;

  web.EventListener? _mousedownListener;
  web.EventListener? _contextMenuDoneListener;

  /// Injects the overlay. Call [dispose] when the viewer closes.
  void attach({
    required Uint8List bytes,
    required String mimeType,
    double appBarHeight = 56,
  }) {
    dispose();

    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    _blobUrl = web.URL.createObjectURL(blob);

    _imgElement = web.document.createElement('img') as web.HTMLImageElement
      ..src = _blobUrl!
      ..style.position = 'absolute'
      ..style.top = '0'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = 'contain'
      ..style.opacity = '0'
      ..style.pointerEvents = 'none';

    _container = web.document.createElement('div') as web.HTMLDivElement
      ..style.position = 'fixed'
      ..style.top = '${appBarHeight}px'
      ..style.left = '0'
      ..style.width = '100%'
      ..style.height = 'calc(100% - ${appBarHeight}px)'
      ..style.zIndex = '9999'
      ..style.pointerEvents = 'none';

    _container!.appendChild(_imgElement!);
    web.document.body?.appendChild(_container!);

    // Capture mousedown to detect right-click before contextmenu fires.
    _mousedownListener = _onMouseDown.toJS;
    web.document.addEventListener('mousedown', _mousedownListener, true.toJS);
  }

  /// Removes the overlay and cleans up listeners.
  void dispose() {
    if (_mousedownListener != null) {
      web.document.removeEventListener(
        'mousedown',
        _mousedownListener,
        true.toJS,
      );
      _mousedownListener = null;
    }
    _removeContextMenuDoneListener();

    _container?.remove();
    _container = null;
    _imgElement = null;
    if (_blobUrl != null) {
      web.URL.revokeObjectURL(_blobUrl!);
      _blobUrl = null;
    }
  }

  void _onMouseDown(web.Event event) {
    final mouseEvent = event as web.MouseEvent;
    // button=2 is right mouse button.
    if (mouseEvent.button != 2) return;

    final img = _imgElement;
    final container = _container;
    if (img == null || container == null) return;

    // Check the right-click is inside the image area.
    final cx = mouseEvent.clientX.toDouble();
    final cy = mouseEvent.clientY.toDouble();
    final rect = container.getBoundingClientRect();
    if (cx < rect.left || cx > rect.right || cy < rect.top || cy > rect.bottom) {
      return;
    }

    // Enable pointer-events so the upcoming contextmenu event hits the <img>.
    img.style.pointerEvents = 'auto';

    // Restore after contextmenu fires (one-shot listener).
    _removeContextMenuDoneListener();
    _contextMenuDoneListener = _onContextMenuDone.toJS;
    web.document.addEventListener(
      'contextmenu',
      _contextMenuDoneListener,
      true.toJS,
    );
  }

  void _onContextMenuDone(web.Event _) {
    _removeContextMenuDoneListener();
    // Small delay so the browser has time to read the img src for the menu.
    Future<void>.delayed(const Duration(milliseconds: 300), _restorePointerEvents);
  }

  void _removeContextMenuDoneListener() {
    if (_contextMenuDoneListener != null) {
      web.document.removeEventListener(
        'contextmenu',
        _contextMenuDoneListener,
        true.toJS,
      );
      _contextMenuDoneListener = null;
    }
  }

  void _restorePointerEvents() {
    _imgElement?.style.pointerEvents = 'none';
  }
}
