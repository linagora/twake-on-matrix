import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

/// A near-white, fully rounded surface floating over the page: the bottom bar
/// and the new chat button of the chat list.
class FloatingCapsule extends StatelessWidget {
  const FloatingCapsule({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  static const _shadow = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 20,
    offset: Offset(0, 4),
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        shape: StadiumBorder(),
        shadows: [_shadow],
      ),
      child: Material(
        color: LinagoraSysColors.material().onPrimary,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}
