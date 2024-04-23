// reference to: https://pub.dev/packages/contextmenu
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_position.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_style.dart';
import 'package:flutter/material.dart';
import 'package:after_layout/after_layout.dart';
import 'twake_context_menu_area.dart';

const double _kMinTileHeight = 24;

/// The actual [TwakeContextMenu] to be displayed
///
/// You will most likely use [showTwakeContextMenu] to manually display a [TwakeContextMenu].
///
/// If you just want to use a normal [TwakeContextMenu], please use [TwakeContextMenuArea].

class TwakeContextMenu extends StatefulWidget {
  /// The [Offset] from coordinate origin the [TwakeContextMenu] will be displayed at.
  final Offset position;

  /// The builder for the items to be displayed. [ListTile] is very useful in most cases.
  final ContextMenuBuilder builder;

  /// The padding value at the top an bottom between the edge of the [TwakeContextMenu] and the first / last item
  final double? verticalPadding;

  const TwakeContextMenu({
    Key? key,
    required this.position,
    required this.builder,
    this.verticalPadding,
  }) : super(key: key);

  @override
  TwakeContextMenuState createState() => TwakeContextMenuState();
}

class TwakeContextMenuState extends State<TwakeContextMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _animationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  final Map<ValueKey, double> _heights = {};

  @override
  Widget build(BuildContext context) {
    final children = widget.builder(context);
    final contextMenuPosition = _calculatePosition(children);

    return GestureDetector(
      onTap: () => closeContextMenu(),
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          height: double.infinity,
          width: double.infinity,
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: contextMenuPosition.left,
                top: contextMenuPosition.top,
                bottom: contextMenuPosition.bottom,
                right: contextMenuPosition.right,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      alignment: contextMenuPosition.alignment,
                      child: Opacity(
                        opacity: _animation.value,
                        child: child,
                      ),
                    );
                  },
                  child: Card(
                    elevation: TwakeContextMenuStyle.menuElevation,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        TwakeContextMenuStyle.menuBorderRadius,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        TwakeContextMenuStyle.menuBorderRadius,
                      ),
                      child: Material(
                        color: TwakeContextMenuStyle.defaultMenuColor(context),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: TwakeContextMenuStyle.menuMinWidth,
                            maxWidth: TwakeContextMenuStyle.menuMaxWidth,
                          ),
                          child: IntrinsicWidth(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: widget.verticalPadding ??
                                    TwakeContextMenuStyle
                                        .defaultVerticalPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: children
                                    .map(
                                      (e) => Listener(
                                        onPointerDown: (_) =>
                                            PlatformInfos.isMobile
                                                ? closeContextMenu()
                                                : null,
                                        child: _GrowingWidget(
                                          child: e,
                                          onHeightChange: (height) {
                                            setState(() {
                                              _heights[ValueKey(e)] = height;
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void closeContextMenu() {
    _animationController
        .reverse()
        .whenComplete(() => Navigator.of(context).pop());
  }

  ContextMenuPosition _calculatePosition(List<Widget> children) {
    double height = 2 *
        (widget.verticalPadding ??
            TwakeContextMenuStyle.defaultVerticalPadding);
    for (final element in _heights.values) {
      height += element;
    }

    final heightsNotAvailable = children.length - _heights.length;
    height += heightsNotAvailable * _kMinTileHeight;

    if (height > MediaQuery.sizeOf(context).height) {
      height = MediaQuery.sizeOf(context).height;
    }

    double positionTop = widget.position.dy -
        MediaQueryData.fromView(View.of(context)).viewPadding.top;
    double positionBottom =
        MediaQuery.sizeOf(context).height - widget.position.dy - height;

    if (positionBottom < 0) {
      positionTop += positionBottom;
      positionBottom = 0;
    }

    final double positionLeftTap = widget.position.dx;
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final double availableRightSpace = screenWidth - positionLeftTap;
    double? positionLeft;
    double? positionRight;
    Alignment alignment = Alignment.topLeft;

    if (availableRightSpace < TwakeContextMenuStyle.menuMaxWidth) {
      positionRight = screenWidth - positionLeftTap;
      alignment = Alignment.topRight;
    } else {
      positionLeft = positionLeftTap;
    }

    return ContextMenuPosition(
      alignment: alignment,
      left: positionLeft,
      top: positionTop,
      right: positionRight,
      bottom: positionBottom,
    );
  }
}

class _GrowingWidget extends StatefulWidget {
  final Widget child;
  final ValueChanged<double> onHeightChange;

  const _GrowingWidget({
    Key? key,
    required this.child,
    required this.onHeightChange,
  }) : super(key: key);

  @override
  __GrowingWidgetState createState() => __GrowingWidgetState();
}

class __GrowingWidgetState extends State<_GrowingWidget> with AfterLayoutMixin {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: widget.child,
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final newHeight = _key.currentContext!.size!.height;
    widget.onHeightChange.call(newHeight);
  }
}
