// reference to: https://pub.dev/packages/contextmenu
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/context_menu/context_menu_action_item_widget.dart';
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
  /// The [BuildContext] of the dialog/modal that will display the [TwakeContextMenu]. This is used to close the dialog/modal when the [TwakeContextMenu] is closed.
  final BuildContext dialogContext;

  /// The list of items to be displayed in the [TwakeContextMenu]. This is used to build the UI of items
  final List<ContextMenuAction> listActions;

  /// The [Offset] from coordinate origin the [TwakeContextMenu] will be displayed at.
  final Offset position;

  /// The padding value at the top an bottom between the edge of the [TwakeContextMenu] and the first / last item
  final double? verticalPadding;

  const TwakeContextMenu({
    super.key,
    required this.dialogContext,
    required this.listActions,
    required this.position,
    this.verticalPadding,
  });

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
    final contextMenuPosition = _calculatePosition(widget.listActions);

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
                bottom:
                    !PlatformInfos.isMobile ? contextMenuPosition.bottom : null,
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
                                children: widget.listActions
                                    .map(
                                      (action) => _GrowingWidget(
                                        child: action,
                                        closeMenuAction: () {
                                          closeContextMenu(
                                            popResult: widget.listActions
                                                .indexOf(action),
                                          );
                                        },
                                        onHeightChange: (height) {
                                          setState(() {
                                            _heights[ValueKey(action)] = height;
                                          });
                                        },
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

  void closeContextMenu({dynamic popResult}) {
    _animationController.reverse().whenComplete(() {
      Navigator.of(widget.dialogContext).pop<dynamic>(popResult);
    });
  }

  ContextMenuPosition _calculatePosition(List<ContextMenuAction> children) {
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
  final ContextMenuAction child;
  final ValueChanged<double> onHeightChange;
  final void Function()? closeMenuAction;

  const _GrowingWidget({
    required this.child,
    required this.onHeightChange,
    this.closeMenuAction,
  });

  @override
  __GrowingWidgetState createState() => __GrowingWidgetState();
}

class __GrowingWidgetState extends State<_GrowingWidget> with AfterLayoutMixin {
  final GlobalKey _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _key,
      child: ContextMenuActionItemWidget(
        action: widget.child,
        closeMenuAction: widget.closeMenuAction,
      ),
    );
  }

  @override
  void afterFirstLayout(BuildContext context) {
    final newHeight = _key.currentContext!.size!.height;
    widget.onHeightChange.call(newHeight);
  }
}
