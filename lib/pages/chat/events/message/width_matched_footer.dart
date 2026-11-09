import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [body] above [footer], fit-content like the web bubble: the width is the
/// widest of the body and the natural (max intrinsic) width of the footer,
/// within the constraints, and the footer gets that whole width. A Column
/// shrinks to its widest child, so a footer that fills the width it is given
/// would widen the bubble of a short message; an IntrinsicWidth cannot be
/// used, the text of a message is a LayoutBuilder. Both start on the reading
/// side when they are narrower than the box.
class WidthMatchedFooter extends MultiChildRenderObjectWidget {
  WidthMatchedFooter({super.key, required Widget body, required Widget footer})
    : super(children: [body, footer]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWidthMatchedFooter(Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWidthMatchedFooter renderObject,
  ) => renderObject.textDirection = Directionality.of(context);
}

class _RenderWidthMatchedFooter extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderWidthMatchedFooter(this._textDirection);

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _body => firstChild!;
  RenderBox get _footer => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  BoxConstraints _footerConstraints(double width) =>
      BoxConstraints.tightFor(width: width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final body = _body.getDryLayout(constraints.loosen());
    final width = _width(body.width, constraints);
    final footer = _footer.getDryLayout(_footerConstraints(width));
    return constraints.constrain(Size(width, body.height + footer.height));
  }

  double _width(double bodyWidth, BoxConstraints constraints) => math.min(
    constraints.maxWidth,
    math.max(bodyWidth, _footer.getMaxIntrinsicWidth(double.infinity)),
  );

  @override
  void performLayout() {
    _body.layout(constraints.loosen(), parentUsesSize: true);
    final width = _width(_body.size.width, constraints);
    _footer.layout(_footerConstraints(width), parentUsesSize: true);
    size = constraints.constrain(
      Size(width, _body.size.height + _footer.size.height),
    );
    // Narrower than the box (tight constraints): start on the reading side.
    double dx(RenderBox child) => _textDirection == TextDirection.rtl
        ? size.width - child.size.width
        : 0;
    (_body.parentData! as MultiChildLayoutParentData).offset = Offset(
      dx(_body),
      0,
    );
    (_footer.parentData! as MultiChildLayoutParentData).offset = Offset(
      dx(_footer),
      _body.size.height,
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    _body.getMinIntrinsicWidth(height),
    _footer.getMinIntrinsicWidth(height),
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    _body.getMaxIntrinsicWidth(height),
    _footer.getMaxIntrinsicWidth(height),
  );

  /// The width the footer is laid out at when the box is [width] wide.
  double _footerWidthAt(double width) => math.min(
    width,
    math.max(
      _body.getMaxIntrinsicWidth(double.infinity),
      _footer.getMaxIntrinsicWidth(double.infinity),
    ),
  );

  @override
  double computeMinIntrinsicHeight(double width) =>
      _body.getMinIntrinsicHeight(width) +
      _footer.getMinIntrinsicHeight(_footerWidthAt(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _body.getMaxIntrinsicHeight(width) +
      _footer.getMaxIntrinsicHeight(_footerWidthAt(width));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
