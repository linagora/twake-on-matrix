import 'package:twake_chat/di/global/get_it_initializer.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ProfileInfoBodyViewStyle {
  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static const double presenceLetterSpacingMobile = 0.5;

  static const double presenceLetterSpacing = 0.15;

  static TextStyle? presenceTextStyle(
    BuildContext context, {
    required bool isOnline,
  }) {
    final isMobile = responsive.isMobile(context);
    final colors = LinagoraRefColors.material();
    return Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: isOnline
          ? colors.secondary
          : isMobile
          ? colors.tertiary[30]
          : colors.neutral[50],
      letterSpacing: isMobile
          ? presenceLetterSpacingMobile
          : presenceLetterSpacing,
    );
  }

  static const EdgeInsetsGeometry profileInformationsTopPadding =
      EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0);

  static const double bigDividerThickness = 1;

  static const EdgeInsetsGeometry actionItemPadding = EdgeInsets.only(
    left: 16.0,
    right: 16.0,
  );

  static const EdgeInsetsGeometry actionsPadding = EdgeInsets.only(
    bottom: 16.0,
  );

  static const EdgeInsetsGeometry copiableRowPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 8,
  );

  static const EdgeInsetsGeometry avatarPadding = EdgeInsets.symmetric(
    vertical: 16.0,
  );

  static const double actionHeight = 40.0;

  static const double avatarSize = 96;

  static const double nonMobileAvatarSize = 160;
  static const double avatarFontSize = 36;
  static const double minAvatarBackgroundHeight = 184;
  static const double maxAvatarBackgroundHeight = 360;
}
