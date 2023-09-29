import 'package:flutter/material.dart';

class SettingsViewStyle {
  static const double iconSize = 24.0;

  static EdgeInsetsDirectional itemBuilderPadding =
      const EdgeInsetsDirectional.all(16.0);

  static EdgeInsetsDirectional leadingItemBuilderPadding =
      const EdgeInsetsDirectional.only(end: 8);

  static EdgeInsetsDirectional subtitleItemBuilderPadding =
      const EdgeInsetsDirectional.only(top: 4);

  static EdgeInsetsDirectional bodySettingsScreenPadding =
      const EdgeInsetsDirectional.symmetric(
    horizontal: 16,
  );

  static EdgeInsetsDirectional avatarPadding =
      const EdgeInsetsDirectional.only(end: 8);
}
