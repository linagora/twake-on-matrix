import 'package:flutter/widgets.dart';

extension SharePositionOriginExtension on BuildContext {
  /// The rect the share sheet is anchored to. iPad and recent iOS refuse to
  /// open the sheet without it. Read it before any `await`.
  Rect? get sharePositionOrigin => shareOriginOf(findRenderObject());

  @visibleForTesting
  static Rect? shareOriginOf(RenderObject? box) =>
      box is RenderBox && box.hasSize
      ? box.localToGlobal(Offset.zero) & box.size
      : null;
}
