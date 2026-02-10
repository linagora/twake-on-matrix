import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class EditContentStyle {
  static final responsive = getIt.get<ResponsiveUtils>();

  static const double replyContentSize = 40;

  static EdgeInsets editParentContainerPadding(BuildContext context) =>
      EdgeInsets.only(
        left: 4,
        right: responsive.isMobile(context) ? 8.0 : 16.0,
        top: 8.0,
        bottom: !responsive.isMobile(context) ? 8.0 : 0.0,
      );

  static EdgeInsets prefixBarVerticalPadding(BuildContext context) =>
      EdgeInsets.only(
        right: 4,
        left: responsive.isMobile(context) ? 4.0 : 16.0,
      );

  static BoxDecoration editParentContainerDecoration(BuildContext context) {
    if (responsive.isMobile(context)) {
      return const BoxDecoration(color: Colors.transparent);
    }
    return BoxDecoration(
      color: LinagoraSysColors.material().primaryContainer,
      borderRadius: BorderRadius.circular(16.0),
    );
  }

  static const double prefixBarWidth = 3.0;

  static BoxDecoration prefixBarDecoration(BuildContext context) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(2),
      color: Theme.of(context).colorScheme.primary,
    );
  }

  static const double contentSpacing = 6.0;

  static TextStyle? editTitleDefaultStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelMedium?.copyWith(
      color: LinagoraSysColors.material().secondary,
    );
  }
}
