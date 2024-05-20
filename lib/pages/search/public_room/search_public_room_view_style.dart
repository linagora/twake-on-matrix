import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:linagora_design_flutter/style/linagora_text_style.dart';

class SearchPublicRoomViewStyle {
  static const double nameToButtonSpace = 8.0;

  static const EdgeInsetsGeometry paddingListItem = EdgeInsets.all(8.0);

  static const EdgeInsetsGeometry paddingInsideListItem = EdgeInsets.all(8.0);

  static const EdgeInsetsGeometry paddingAvatar = EdgeInsets.only(right: 12.0);

  static TextStyle roomNameTextStyle =
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
}
