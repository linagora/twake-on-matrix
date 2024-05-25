import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/style/linagora_text_style.dart';

class SearchPublicRoomViewStyle {
  static const double nameToButtonSpace = 8.0;

  static const double paddingButton = 12.0;

  static const EdgeInsetsGeometry paddingListItem = EdgeInsets.all(16.0);

  static const EdgeInsetsGeometry paddingAvatar = EdgeInsets.only(right: 12.0);

  static TextStyle roomNameTextStyle =
      LinagoraTextStyle.material().bodyMedium2.copyWith(
            color: LinagoraSysColors.material().onSurface,
            fontFamily: GoogleFonts.inter().fontFamily,
          );

  static TextStyle roomAliasTextStyle =
      LinagoraTextStyle.material().bodyMedium3.copyWith(
            color: LinagoraSysColors.material().onSurface,
            fontFamily: GoogleFonts.inter().fontFamily,
          );

  static TextStyle? joinButtonLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          color: LinagoraSysColors.material().primary,
        );
  }

  static TextStyle? viewButtonLabelStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelLarge?.copyWith(
          color: LinagoraSysColors.material().onSurface,
        );
  }

  static BoxDecoration actionButtonDecoration(BuildContext context) {
    return BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: const BorderRadius.all(
        Radius.circular(28.0),
      ),
    );
  }
}
