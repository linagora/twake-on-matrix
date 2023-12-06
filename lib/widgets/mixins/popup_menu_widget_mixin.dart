import 'package:fluffychat/widgets/twake_app.dart';
import 'package:fluffychat/widgets/twake_components/twake_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

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
    return Padding(
      padding: padding ?? const EdgeInsetsDirectional.all(12),
      child: SizedBox(
        child: Row(
          children: [
            if (iconAction != null)
              Icon(
                iconAction,
                size: iconSize ?? 20,
                color: colorIcon ?? Colors.black,
              ),
            if (imagePath != null)
              SvgPicture.asset(
                imagePath,
                width: iconSize ?? 20,
                height: iconSize ?? 20,
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                  colorIcon ?? Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                nameAction,
                style: styleName ??
                    Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: LinagoraSysColors.material().onSurface,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
