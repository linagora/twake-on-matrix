import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

enum SettingsProfileEnum {
  displayName,
  bio,
  matrixId,
  email,
  company;

  String getTitle(BuildContext context) {
    switch (this) {
      case SettingsProfileEnum.displayName:
        return L10n.of(context)!.displayName;
      case SettingsProfileEnum.bio:
        return L10n.of(context)!.bio;
      case SettingsProfileEnum.matrixId:
        return L10n.of(context)!.matrixId;
      case SettingsProfileEnum.email:
        return L10n.of(context)!.email;
      case SettingsProfileEnum.company:
        return L10n.of(context)!.company;
    }
  }

  IconData getLeadingIcon() {
    switch (this) {
      case SettingsProfileEnum.displayName:
      case SettingsProfileEnum.bio:
        return Icons.person_outline;
      case SettingsProfileEnum.matrixId:
        return Icons.language_outlined;
      case SettingsProfileEnum.email:
        return Icons.email_outlined;
      case SettingsProfileEnum.company:
        return Icons.apartment_outlined;
    }
  }

  IconData getTrailingIcon() {
    switch (this) {
      case SettingsProfileEnum.displayName:
      case SettingsProfileEnum.bio:
      case SettingsProfileEnum.company:
        return Icons.edit_outlined;
      case SettingsProfileEnum.matrixId:
      case SettingsProfileEnum.email:
        return Icons.content_copy;
    }
  }

  SettingsProfileType getSettingsProfileType() {
    switch (this) {
      case SettingsProfileEnum.displayName:
      case SettingsProfileEnum.bio:
      case SettingsProfileEnum.company:
        return SettingsProfileType.edit;
      case SettingsProfileEnum.matrixId:
      case SettingsProfileEnum.email:
        return SettingsProfileType.copy;
    }
  }
}

enum SettingsProfileType {
  edit,
  copy,
}

enum AvatarAction {
  camera,
  file,
  remove,
}
