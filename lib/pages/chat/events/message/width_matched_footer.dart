import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [body] above [footer]: the footer is as wide as the body, unless its own
/// minimum is wider. A Column shrinks to its widest child, so a footer that
/// fills the width it is given would widen the bubble of a short message; an
/// IntrinsicWidth cannot be used, the text of a message is a LayoutBuilder.
class WidthMatchedFooter extends MultiChildRenderObjectWidget {
  WidthMatchedFooter({super.key, required Widget body, required Widget footer})
    : super(children: [body, footer]);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWidthMatchedFooter();
}

class _RenderWidthMatchedFooter extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
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
    math.max(bodyWidth, _footer.getMinIntrinsicWidth(double.infinity)),
  );

  @override
  void performLayout() {
    _body.layout(constraints.loosen(), parentUsesSize: true);
    final width = _width(_body.size.width, constraints);
    _footer.layout(_footerConstraints(width), parentUsesSize: true);
    (_footer.parentData! as MultiChildLayoutParentData).offset = Offset(
      0,
      _body.size.height,
    );
    size = constraints.constrain(
      Size(width, _body.size.height + _footer.size.height),
    );
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _body.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _body.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      _body.getMinIntrinsicHeight(width) + _footer.getMinIntrinsicHeight(width);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _body.getMaxIntrinsicHeight(width) + _footer.getMaxIntrinsicHeight(width);

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
