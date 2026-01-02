import 'package:fluffychat/widgets/context_menu/context_menu_action.dart';
import 'package:fluffychat/widgets/mixins/twake_context_menu_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ContextMenuActionItemWidget extends StatelessWidget {
  final ContextMenuAction action;
  final void Function()? closeMenuAction;
  final bool leadingIcon;

  const ContextMenuActionItemWidget({
    super.key,
    required this.action,
    this.closeMenuAction,
    this.leadingIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        closeMenuAction?.call();
      },
      child: _itemBuilder(
        context,
        action.name,
        iconAction: action.icon,
        imagePath: action.imagePath,
        colorIcon: action.colorIcon,
        iconSize: action.iconSize,
        styleName: action.styleName,
        padding: action.padding,
      ),
    );
  }

  Widget _itemBuilder(
    BuildContext context,
    String nameAction, {
    IconData? iconAction,
    String? imagePath,
    Color? colorIcon,
    double? iconSize,
    TextStyle? styleName,
    EdgeInsets? padding,
  }) {
    Widget buildIcon() {
      // We try to get the SVG first and then the IconData
      if (imagePath != null) {
        return SvgPicture.asset(
          imagePath,
          width: iconSize ?? TwakeContextMenuStyle.defaultItemIconSize,
          height: iconSize ?? TwakeContextMenuStyle.defaultItemIconSize,
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            colorIcon ?? TwakeContextMenuStyle.defaultItemColorIcon(context)!,
            BlendMode.srcIn,
          ),
        );
      }

      if (iconAction != null) {
        return Icon(
          iconAction,
          size: iconSize ?? TwakeContextMenuStyle.defaultItemIconSize,
          color:
              colorIcon ?? TwakeContextMenuStyle.defaultItemColorIcon(context),
        );
      }

      return const SizedBox.shrink();
    }

    final List<Widget> children = [
      Expanded(
        child: Text(
          nameAction,
          style:
              styleName ?? TwakeContextMenuStyle.defaultItemTextStyle(context),
        ),
      ),
      const SizedBox(width: TwakeContextMenuStyle.defaultItemElementsGap),
      buildIcon(),
    ];

    return Padding(
      padding: padding ?? TwakeContextMenuStyle.defaultItemPadding,
      child: SizedBox(
        child: Row(
          children: leadingIcon ? children.reversed.toList() : children,
        ),
      ),
    );
  }
}
