import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/widgets/twake_components/filter_pills_style.dart';

/// One row of [FilterPill]s that scrolls under an end fade.
class FilterPills extends StatelessWidget {
  const FilterPills({
    super.key,
    required this.semanticsLabel,
    required this.pills,
  });

  final String semanticsLabel;
  final List<Widget> pills;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: FilterPillsStyle.maxTextScale,
      child: SizedBox(
        height: FilterPillsStyle.height,
        child: Semantics(
          label: semanticsLabel,
          child: _EndFade(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: FilterPillsStyle.padding,
              itemCount: pills.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: FilterPillsStyle.spacing),
              itemBuilder: (_, index) => pills[index],
            ),
          ),
        ),
      ),
    );
  }
}

class _EndFade extends StatelessWidget {
  const _EndFade({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        begin: AlignmentDirectional.centerStart,
        end: AlignmentDirectional.centerEnd,
        stops: [0, 1 - FilterPillsStyle.fadeWidth / rect.width, 1],
        colors: const [Colors.black, Colors.black, Colors.transparent],
      ).createShader(rect, textDirection: textDirection),
      child: child,
    );
  }
}

/// Selected: filled in primary. Otherwise light grey. A long press or a right
/// click calls [onMenu].
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.dotColor,
    this.onMenu,
  });

  final String label;
  final bool isSelected;

  /// Null disables the pill.
  final VoidCallback? onTap;
  final Color? dotColor;
  final void Function(BuildContext context, Offset position)? onMenu;

  Offset _center(BuildContext context) {
    final box = context.findRenderObject()! as RenderBox;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    final onMenu = this.onMenu;
    final VoidCallback? onLongPress = onMenu == null
        ? null
        : () => onMenu(context, _center(context));
    final GestureTapUpCallback? onSecondaryTapUp = onMenu == null
        ? null
        : (details) => onMenu(context, details.globalPosition);
    // The margin above and below the 32 dp pill still answers the finger.
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        onLongPress: onLongPress,
        onSecondaryTapUp: onSecondaryTapUp,
        child: SizedBox(
          height: FilterPillsStyle.touchTargetHeight,
          child: Center(
            widthFactor: 1,
            child: Material(
              color: isSelected ? colors.primary : colors.surface,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                onSecondaryTapUp: onSecondaryTapUp,
                child: _content(colors),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(LinagoraSysColors colors) {
    final dotColor = this.dotColor;
    return Container(
      height: FilterPillsStyle.pillHeight,
      constraints: const BoxConstraints(
        maxWidth: FilterPillsStyle.pillMaxWidth,
      ),
      padding: FilterPillsStyle.pillContentPadding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            CircleAvatar(
              radius: FilterPillsStyle.dotRadius,
              backgroundColor: dotColor,
            ),
            const SizedBox(width: FilterPillsStyle.dotGap),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LinagoraTextStyle.material().labelLarge.copyWith(
                color: isSelected ? colors.onPrimary : colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
