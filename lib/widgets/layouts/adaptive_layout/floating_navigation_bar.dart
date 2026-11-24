import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/style/linagora_text_style.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:twake_chat/widgets/twake_components/floating_capsule.dart';

/// The phone tab bar: a capsule that hugs equal-width tabs and ignores the
/// system text size, its labels shrinking instead of being cut.
class FloatingNavigationBar extends StatelessWidget {
  const FloatingNavigationBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestinationEnum> destinations;
  final AdaptiveDestinationEnum selected;
  final ValueChanged<int> onDestinationSelected;

  static const double height = 56;
  static const double _innerPadding = 4;
  static const double _minItemWidth = 82;
  static const double _labelSpacing = 16;
  static const double _sideMargin = 16;
  static const double _topMargin = 8;
  static const double _bottomGap = 12;

  static TextStyle get _labelStyle => LinagoraTextStyle.material().labelMedium;

  double _bottomMargin(BuildContext context) {
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    if (inset == 0) return _bottomGap;
    // On iOS the capsule may overlap the home indicator's inset, not the line.
    return Theme.of(context).platform == TargetPlatform.iOS
        ? math.max(_bottomGap, inset - 13)
        : inset + 8;
  }

  double _itemWidth(BuildContext context, Iterable<String> labels) {
    final style = DefaultTextStyle.of(context).style.merge(_labelStyle);
    return labels.fold(_minItemWidth, (widest, label) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      final width = painter.width + _labelSpacing;
      painter.dispose();
      return math.max(widest, width);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final labels = [
      for (final destination in destinations) destination.label(l10n),
    ];
    return MediaQuery.withNoTextScaling(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _sideMargin,
          _topMargin,
          _sideMargin,
          _bottomMargin(context),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            heightFactor: 1,
            child: FloatingCapsule(
              padding: const EdgeInsets.all(_innerPadding),
              child: _Items(
                destinations: destinations,
                labels: labels,
                selectedIndex: destinations.indexOf(selected),
                itemWidth: math.min(
                  _itemWidth(context, labels),
                  (constraints.maxWidth - 2 * _innerPadding) /
                      destinations.length,
                ),
                onDestinationSelected: onDestinationSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Items extends StatelessWidget {
  const _Items({
    required this.destinations,
    required this.labels,
    required this.selectedIndex,
    required this.itemWidth,
    required this.onDestinationSelected,
  });

  final List<AdaptiveDestinationEnum> destinations;
  final List<String> labels;
  final int selectedIndex;
  final double itemWidth;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          FloatingNavigationBar.height -
          2 * FloatingNavigationBar._innerPadding,
      width: itemWidth * destinations.length,
      child: Stack(
        children: [
          if (selectedIndex >= 0)
            PositionedDirectional(
              start: selectedIndex * itemWidth,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: LinagoraSysColors.material().surface,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          Row(
            children: [
              for (final (index, destination) in destinations.indexed)
                SizedBox(
                  width: itemWidth,
                  child: _Item(
                    destination: destination,
                    label: labels[index],
                    isSelected: index == selectedIndex,
                    onTap: () {
                      unawaited(HapticFeedback.selectionClick());
                      onDestinationSelected(index);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.destination,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final AdaptiveDestinationEnum destination;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = LinagoraSysColors.material();
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: isSelected,
        // An InkWell, not a GestureDetector: a hardware keyboard can focus it.
        child: InkWell(
          key: destination.navigationKey,
          onTap: onTap,
          customBorder: const StadiumBorder(),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              destination.floatingBarIcon(
                isSelected: isSelected,
                color: colors.onSurface,
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: FloatingNavigationBar._labelStyle.copyWith(
                    color: isSelected ? colors.primary : colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
