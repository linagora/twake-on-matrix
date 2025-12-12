import 'package:fluffychat/domain/model/user_info/user_info_visibility.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension VisibleEnumExtension on VisibleEnum {
  String title(BuildContext context) {
    switch (this) {
      case VisibleEnum.phone:
        return L10n.of(context)!.phone;
      case VisibleEnum.email:
        return L10n.of(context)!.email;
    }
  }

  String subtitle(BuildContext context) {
    switch (this) {
      case VisibleEnum.phone:
        return L10n.of(context)!.youNumberIsVisibleAccordingToTheSettingAbove;
      case VisibleEnum.email:
        return L10n.of(context)!.youEmailIsVisibleAccordingToTheSettingAbove;
    }
  }

  bool enableDivider() {
    return this == VisibleEnum.phone;
  }
}
