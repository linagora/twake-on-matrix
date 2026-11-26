import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/style/linagora_text_style.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';
import 'package:twake_chat/presentation/widget_keys/widget_keys.dart';
import 'package:twake_chat/widgets/context_menu_builder_ios_paste_without_permission.dart';
import 'package:twake_chat/widgets/layouts/enum/adaptive_destinations_enum.dart';
import 'package:twake_chat/widgets/twake_components/floating_capsule.dart';
import 'package:twake_chat/widgets/twake_components/twake_icon_button.dart';

/// The phone tab bar: a capsule that hugs equal-width tabs and ignores the
/// system text size, its labels shrinking instead of being cut.
///
/// Settings is never a tab, even when [destinations] holds it: it opens from
/// the avatar of the app bar. With [searchOpen] (the Chats tab) a round search
/// button sits at the end; opened, it grows into a field writing into
/// [searchQuery], the tabs fold away and a close button comes at the end.
class FloatingNavigationBar extends StatelessWidget {
  const FloatingNavigationBar({
    super.key,
    required this.destinations,
    required this.selected,
    required this.onDestinationSelected,
    this.searchOpen,
    this.searchQuery,
    this.searchSuffix,
  }) : assert(searchOpen == null || searchQuery != null);

  final List<AdaptiveDestinationEnum> destinations;
  final AdaptiveDestinationEnum selected;
  final ValueChanged<int> onDestinationSelected;
  final ValueNotifier<bool>? searchOpen;
  final TextEditingController? searchQuery;

  /// At the end of the search field while it is empty.
  final Widget? searchSuffix;

  static const double height = 56;
  static const double _innerPadding = 4;
  static const double _minItemWidth = 82;
  static const double _labelSpacing = 16;
  static const double _sideMargin = 16;
  static const double _topMargin = 8;
  static const double _bottomGap = 12;
  static const double _homeIndicatorOverlap = 13;
  static const double _gestureBarGap = 8;
  static const double _searchGap = 8;
  static const Duration _searchDuration = Duration(milliseconds: 400);

  static TextStyle get _labelStyle => LinagoraTextStyle.material().labelMedium;

  double _bottomMargin(BuildContext context, {required bool searching}) {
    // The open search field stays above the keyboard.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (searching && keyboard > 0) return keyboard + _gestureBarGap;
    final inset = MediaQuery.viewPaddingOf(context).bottom;
    if (inset == 0) return _bottomGap;
    // On iOS the capsule may overlap the home indicator's inset, not the line.
    return Theme.of(context).platform == TargetPlatform.iOS
        ? math.max(_bottomGap, inset - _homeIndicatorOverlap)
        : inset + _gestureBarGap;
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

  void _closeSearch() {
    FocusManager.instance.primaryFocus?.unfocus();
    searchQuery?.clear();
    searchOpen?.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final searchOpen = this.searchOpen;
    if (searchOpen == null) return _bar(context, open: false, progress: 0);
    return ValueListenableBuilder<bool>(
      valueListenable: searchOpen,
      builder: (context, open, _) => PopScope(
        // Android back closes the search before it leaves the screen.
        canPop: !open,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _closeSearch();
        },
        child: _animate(
          context,
          open,
          (progress) => _animate(
            context,
            open || FloatingSearchButtonShown.of(context),
            (buttonShown) => _bar(
              context,
              open: open,
              progress: progress,
              buttonShown: buttonShown,
            ),
          ),
        ),
      ),
    );
  }

  Widget _animate(
    BuildContext context,
    bool on,
    Widget Function(double value) builder,
  ) => TweenAnimationBuilder<double>(
    tween: Tween(end: on ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _searchDuration,
    curve: Curves.easeOutCubic,
    builder: (context, value, _) => builder(value),
  );

  /// [progress] goes from 0 (tabs and search button) to 1 (search field);
  /// [buttonShown] from 0 (no search button) to 1.
  Widget _bar(
    BuildContext context, {
    required bool open,
    required double progress,
    double buttonShown = 1,
  }) {
    final l10n = L10n.of(context)!;
    final tabs = [
      for (final (index, destination) in destinations.indexed)
        if (destination != AdaptiveDestinationEnum.settings)
          (index, destination),
    ];
    final labels = [
      for (final (_, destination) in tabs) destination.label(l10n),
    ];
    final hasSearch = searchOpen != null;
    return MediaQuery.withNoTextScaling(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          _sideMargin,
          _topMargin,
          _sideMargin,
          _bottomMargin(context, searching: open),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchButtonRoom = hasSearch ? height + _searchGap : 0;
            final itemWidth = math.min(
              _itemWidth(context, labels),
              (constraints.maxWidth - 2 * _innerPadding - searchButtonRoom) /
                  tabs.length,
            );
            final tabsCapsule = FloatingCapsule(
              padding: const EdgeInsets.all(_innerPadding),
              child: _Items(
                destinations: [
                  for (final (_, destination) in tabs) destination,
                ],
                labels: labels,
                selectedIndex: tabs.indexWhere((tab) => tab.$2 == selected),
                itemWidth: itemWidth,
                onDestinationSelected: (shown) =>
                    onDestinationSelected(tabs[shown].$1),
              ),
            );
            if (!hasSearch) {
              return Center(heightFactor: 1, child: tabsCapsule);
            }
            final tabsWidth = itemWidth * tabs.length + 2 * _innerPadding;
            final fieldWidth = constraints.maxWidth - _searchGap - height;
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!open || progress < 1) ...[
                  _Reveal(
                    width: tabsWidth * (1 - progress),
                    fullWidth: tabsWidth,
                    opacity: 1 - progress,
                    child: IgnorePointer(ignoring: open, child: tabsCapsule),
                  ),
                  SizedBox(width: _searchGap * (1 - progress) * buttonShown),
                ],
                Opacity(
                  opacity: open ? 1 : buttonShown.clamp(0, 1),
                  child: SizedBox(
                    width: lerpDouble(
                      height * buttonShown,
                      fieldWidth,
                      progress,
                    ),
                    height: height,
                    child: FloatingCapsule(
                      child: open
                          ? OverflowBox(
                              alignment: AlignmentDirectional.centerStart,
                              minWidth: fieldWidth,
                              maxWidth: fieldWidth,
                              child: _SearchField(
                                query: searchQuery!,
                                suffix: searchSuffix,
                              ),
                            )
                          : IgnorePointer(
                              ignoring: buttonShown < 1,
                              child: _RoundButton(
                                buttonKey: NavigationKeys.searchButton.key,
                                label: l10n.search,
                                icon: Icons.search,
                                onTap: () => searchOpen!.value = true,
                              ),
                            ),
                    ),
                  ),
                ),
                if (open) ...[
                  SizedBox(width: _searchGap * progress),
                  _Reveal(
                    width: height * progress,
                    fullWidth: height,
                    opacity: progress,
                    child: FloatingCapsule(
                      child: _RoundButton(
                        buttonKey: NavigationKeys.searchCloseButton.key,
                        label: l10n.close,
                        icon: Icons.close,
                        onTap: _closeSearch,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// While its [notifier] is false, the search button of the
/// [FloatingNavigationBar] below folds away: the chat list shows a search
/// field of its own meanwhile.
class FloatingSearchButtonShown extends InheritedNotifier<ValueNotifier<bool>> {
  const FloatingSearchButtonShown({
    super.key,
    required super.notifier,
    required super.child,
  });

  static bool of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FloatingSearchButtonShown>()
          ?.notifier
          ?.value ??
      true;
}

/// [child] laid out at [fullWidth], shown through a [width] wide window from
/// its start: folds or unfolds it without squeezing it.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.width,
    required this.fullWidth,
    required this.opacity,
    required this.child,
  });

  final double width;
  final double fullWidth;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: FloatingNavigationBar.height,
      child: ClipRect(
        // At rest nothing is cut: the shadow of the capsule shows.
        clipBehavior: width < fullWidth ? Clip.hardEdge : Clip.none,
        child: OverflowBox(
          alignment: AlignmentDirectional.centerStart,
          minWidth: fullWidth,
          maxWidth: fullWidth,
          child: Opacity(opacity: opacity.clamp(0, 1), child: child),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.buttonKey,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final Key buttonKey;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        button: true,
        label: label,
        child: InkWell(
          key: buttonKey,
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox.square(
            dimension: FloatingNavigationBar.height,
            child: Icon(icon, color: LinagoraSysColors.material().onSurface),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.query, this.suffix});

  final TextEditingController query;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context)!;
    final colors = LinagoraSysColors.material();
    return TextField(
      key: NavigationKeys.searchField.key,
      controller: query,
      autofocus: true,
      textInputAction: TextInputAction.search,
      contextMenuBuilder: mobileTwakeContextMenuBuilder,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: l10n.search,
        prefixIcon: Icon(Icons.search, color: colors.onSurface),
        suffixIcon: ValueListenableBuilder(
          valueListenable: query,
          builder: (context, value, _) => value.text.isEmpty
              ? suffix ?? const SizedBox.shrink()
              : TwakeIconButton(
                  tooltip: l10n.clear,
                  icon: Icons.close,
                  onTap: query.clear,
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
