import 'package:flutter/material.dart';

class SettingsViewStyle {
  static const double iconSize = 24.0;

  static const double fontSizeAvatar = 9 * 2.5;

  static const AlignmentGeometry alignment = AlignmentDirectional.centerStart;

  static const EdgeInsetsDirectional titlePadding =
      EdgeInsetsDirectional.only(start: 16);

  static EdgeInsetsDirectional itemBuilderPadding =
      const EdgeInsetsDirectional.all(16.0);

  static EdgeInsetsDirectional leadingItemBuilderPadding =
      const EdgeInsetsDirectional.only(end: 8);

  static EdgeInsetsDirectional subtitleItemBuilderPadding =
      const EdgeInsetsDirectional.only(top: 4);

  static EdgeInsetsDirectional bodySettingsScreenPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 8,
  );

  static EdgeInsetsDirectional backupSwitchPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 24,
  );

  static EdgeInsetsDirectional avatarPadding =
      const EdgeInsetsDirectional.only(end: 8);
}
