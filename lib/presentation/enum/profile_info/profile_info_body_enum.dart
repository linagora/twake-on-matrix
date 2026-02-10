import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

enum ProfileInfoActions {
  sendMessage,
  downgradeToReadOnly,
  removeFromGroup,
  transferOwnership;

  String label(BuildContext context) {
    switch (this) {
      case ProfileInfoActions.sendMessage:
        return L10n.of(context)!.sendMessage;
      case ProfileInfoActions.removeFromGroup:
        return L10n.of(context)!.removeFromGroup;
      case ProfileInfoActions.downgradeToReadOnly:
        return L10n.of(context)!.downgradeToReadOnly;
      case ProfileInfoActions.transferOwnership:
        return L10n.of(context)!.transferOwnership;
    }
  }

  TextStyle textStyle(BuildContext context) {
    switch (this) {
      case ProfileInfoActions.sendMessage:
        return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: LinagoraSysColors.material().onPrimary,
        );
      case ProfileInfoActions.removeFromGroup:
        return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: LinagoraSysColors.material().error,
        );
      case ProfileInfoActions.downgradeToReadOnly:
        return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: LinagoraSysColors.material().primary,
        );
      case ProfileInfoActions.transferOwnership:
        return Theme.of(context).textTheme.labelLarge!.copyWith(
          color: LinagoraSysColors.material().primary,
        );
    }
  }

  Decoration? decoration(BuildContext context) {
    switch (this) {
      case ProfileInfoActions.sendMessage:
        return BoxDecoration(
          color: LinagoraSysColors.material().primary,
          borderRadius: BorderRadius.circular(100),
        );
      case ProfileInfoActions.removeFromGroup:
      case ProfileInfoActions.downgradeToReadOnly:
      case ProfileInfoActions.transferOwnership:
        return null;
    }
  }

  EdgeInsetsGeometry padding(BuildContext context) {
    switch (this) {
      case ProfileInfoActions.sendMessage:
        return const EdgeInsets.only(top: 16, bottom: 8);
      case ProfileInfoActions.removeFromGroup:
        return const EdgeInsets.only(top: 8, bottom: 8);
      case ProfileInfoActions.downgradeToReadOnly:
      case ProfileInfoActions.transferOwnership:
        return const EdgeInsets.only(bottom: 8);
    }
  }

  Divider? divider(BuildContext context) {
    switch (this) {
      case ProfileInfoActions.removeFromGroup:
      case ProfileInfoActions.transferOwnership:
        return Divider(
          thickness: ProfileInfoBodyViewStyle.bigDividerThickness,
          color: LinagoraStateLayer(
            LinagoraSysColors.material().surfaceTint,
          ).opacityLayer3,
        );
      case ProfileInfoActions.sendMessage:
      case ProfileInfoActions.downgradeToReadOnly:
        return null;
    }
  }

  Icon? icon() {
    switch (this) {
      case ProfileInfoActions.sendMessage:
        return Icon(
          Icons.chat_bubble,
          size: 15,
          color: LinagoraSysColors.material().onPrimary,
        );
      case ProfileInfoActions.removeFromGroup:
        return Icon(
          Icons.delete_outline_outlined,
          color: LinagoraSysColors.material().error,
        );
      case ProfileInfoActions.downgradeToReadOnly:
      case ProfileInfoActions.transferOwnership:
        return null;
    }
  }
}
