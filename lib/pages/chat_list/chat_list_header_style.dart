import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class ChatListHeaderStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static double searchRadiusBorder = 24.0.r;
  static double searchBarContainerHeight = 64.0.h;
  static double searchIconSize = 24.0.r;

  static EdgeInsetsDirectional searchInputPadding = EdgeInsetsDirectional.only(
    start: 16.w,
    end: 16.w,
  );

  static const EdgeInsetsDirectional paddingZero = EdgeInsetsDirectional.zero;

  static InputDecoration searchInputDecoration(BuildContext context) {
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
      hintText: L10n.of(context)!.search,
      hintStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: LinagoraRefColors.material().neutral[60],
          ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      prefixIcon: Icon(
        Icons.search_outlined,
        size: ChatListHeaderStyle.searchIconSize,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      suffixIcon: const SizedBox.shrink(),
    );
  }
}
