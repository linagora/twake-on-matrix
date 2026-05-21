import 'dart:ui' as ui;

import 'package:flutter/material.dart';

enum BubbleTailDirection { none, left, right }

class BubbleShape extends ShapeBorder {
  final BorderRadius borderRadius;
  final BorderSide side;
  final BubbleTailDirection tailDirection;

  const BubbleShape({
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.side = BorderSide.none,
    this.tailDirection = BubbleTailDirection.none,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  ShapeBorder scale(double t) => BubbleShape(
    borderRadius: borderRadius * t,
    side: side.scale(t),
    tailDirection: tailDirection,
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _buildPath(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid && side.width > 0) {
      canvas.drawPath(
        getOuterPath(rect, textDirection: textDirection),
        side.toPaint()
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  Path _buildPath(Rect rect) {
    final hasLeft = tailDirection == BubbleTailDirection.left;
    final hasRight = tailDirection == BubbleTailDirection.right;
    final bubbleRect = Offset.zero & rect.size;
    final bubblePath = Path()..addRRect(borderRadius.toRRect(bubbleRect));

    if (tailDirection == BubbleTailDirection.none) {
      return bubblePath.shift(rect.topLeft);
    }

    final tailPath = _tailPath(
      anchorX: hasRight ? bubbleRect.right : bubbleRect.left,
      anchorY: bubbleRect.bottom,
      mirrored: hasLeft,
    );

    return Path.combine(
      PathOperation.union,
      bubblePath,
      tailPath,
    ).shift(rect.topLeft);
  }

  static Path _tailPath({
    required double anchorX,
    required double anchorY,
    required bool mirrored,
  }) {
    final s = mirrored ? -1.0 : 1.0;
    double x(double designX) => anchorX + (designX - 9) * s;
    double y(double designY) => anchorY + (designY - 19);

    final path = ui.Path()..moveTo(x(9), y(11.5166));
    path.cubicTo(
      x(9.75872),
      y(13.7447), //
      x(11.0429),
      y(15.8486), //
      x(13.1611),
      y(18.1309),
    );
    path.cubicTo(
      x(13.464),
      y(18.4574), //
      x(13.2403),
      y(18.9997), //
      x(12.7949),
      y(18.9922),
    );
    path.cubicTo(
      x(9.40352),
      y(18.9347), //
      x(3.38509),
      y(18.4463), //
      x(0.22168),
      y(14.3027),
    );
    path.cubicTo(
      x(0.153575),
      y(14.2134), //
      x(0.121483),
      y(14.1064), //
      x(0.125),
      y(14),
    );
    path.lineTo(x(0), y(14));
    path.lineTo(x(0), y(0));
    path.lineTo(x(9), y(0));
    path.close();
    return path;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is BubbleShape &&
        other.borderRadius == borderRadius &&
        other.side == side &&
        other.tailDirection == tailDirection;
  }

  @override
  int get hashCode => Object.hash(borderRadius, side, tailDirection);
}
