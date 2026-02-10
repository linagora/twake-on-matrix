import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const double searchRadiusBorder = 24.0;
  static const double searchBarContainerHeight = 57.0;
  static const double searchIconSize = 24.0;

  static const EdgeInsetsDirectional searchInputPadding =
      EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 8);

  static const EdgeInsetsDirectional paddingZero = EdgeInsetsDirectional.zero;

  static InputDecoration searchInputDecoration(
    BuildContext context, {
    String? hintText,
    Color? prefixIconColor,
  }) {
    return InputDecoration(
      filled: true,
      contentPadding: ChatListHeaderStyle.paddingZero,
      fillColor: Theme.of(context).colorScheme.surface,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(
          ChatListHeaderStyle.searchRadiusBorder,
        ),
      ),
      hintText: hintText ?? L10n.of(context)!.search,
      hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: LinagoraRefColors.material().neutral[60],
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: Icon(
        Icons.search,
        size: ChatListHeaderStyle.searchIconSize,
        color: prefixIconColor ?? LinagoraRefColors.material().neutral[60],
      ),
      suffixIcon: const SizedBox.shrink(),
    );
  }

  static const dividerHeight = 1.0;
  static const dividerThickness = 1.0;
}
