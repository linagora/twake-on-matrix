import 'package:fluffychat/widgets/mixins/popup_menu_widget_style.dart';
import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

mixin PopupMenuWidgetMixin {
  Widget popupItemByTwakeAppRouter(
    BuildContext context,
    String nameAction, {
    IconData? iconAction,
    String? imagePath,
    Color? colorIcon,
    double? iconSize,
    TextStyle? styleName,
    EdgeInsets? padding,
    OnTapIconButtonCallbackAction? onCallbackAction,
    bool isClearCurrentPage = true,
  }) {
    return InkWell(
      onTap: () {
        /// Pop the current page, snackbar, dialog or bottomsheet in the stack
        /// will close the currently open snackbar/dialog/bottomsheet AND the current page
        if (isClearCurrentPage) {
          TwakeApp.router.routerDelegate.pop();
        }
        onCallbackAction!.call();
      },
      child: _popupItemBuilder(
        context,
        nameAction,
        iconAction: iconAction,
        imagePath: imagePath,
        colorIcon: colorIcon,
        iconSize: iconSize,
        styleName: styleName,
        padding: padding,
      ),
    );
  }

  Widget popupItemByNavigator(
    BuildContext context,
    String nameAction, {
    IconData? iconAction,
    String? imagePath,
    Color? colorIcon,
    double? iconSize,
    TextStyle? styleName,
    EdgeInsets? padding,
    OnTapIconButtonCallbackAction? onCallbackAction,
    bool isClearCurrentPage = true,
  }) {
    return InkWell(
      onTap: () {
        if (isClearCurrentPage) {
          Navigator.pop(context);
        }
        onCallbackAction!.call();
      },
      child: _popupItemBuilder(
        context,
        nameAction,
        iconAction: iconAction,
        imagePath: imagePath,
        colorIcon: colorIcon,
        iconSize: iconSize,
        styleName: styleName,
        padding: padding,
      ),
    );
  }

  Widget _popupItemBuilder(
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
          width: iconSize ?? PopupMenuWidgetStyle.defaultItemIconSize,
          height: iconSize ?? PopupMenuWidgetStyle.defaultItemIconSize,
          fit: BoxFit.fill,
          colorFilter: ColorFilter.mode(
            colorIcon ?? PopupMenuWidgetStyle.defaultItemColorIcon(context)!,
            BlendMode.srcIn,
          ),
        );
      }

      if (iconAction != null) {
        return Icon(
          iconAction,
          size: iconSize ?? PopupMenuWidgetStyle.defaultItemIconSize,
          color:
              colorIcon ?? PopupMenuWidgetStyle.defaultItemColorIcon(context),
        );
      }

      return const SizedBox.shrink();
    }

    return Padding(
      padding: padding ?? PopupMenuWidgetStyle.defaultItemPadding,
      child: SizedBox(
        child: Row(
          children: [
            buildIcon(),
            const SizedBox(width: PopupMenuWidgetStyle.defaultItemElementsGap),
            Expanded(
              child: Text(
                nameAction,
                style: styleName ??
                    PopupMenuWidgetStyle.defaultItemTextStyle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
