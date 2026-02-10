import 'package:fluffychat/domain/exception/room/invite_user_exception.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

extension InviteUserPartialFailureExceptionExtension
    on InviteUserPartialFailureException {
  /// Builds a localized error message based on the types of failures
  String getLocalizedErrorMessage(BuildContext context) {
    final bannedCount = bannedUsers.length;
    final otherFailedCount = otherFailedUsers.length;
    final totalFailed = failedUsers.length;

    assert(
      totalFailed > 0,
      'InviteUserPartialFailureException should not exist with empty failedUsers',
    );

    if (bannedCount > 0 && otherFailedCount > 0) {
      return L10n.of(
        context,
      )!.failedToAddMembersMixed(totalFailed, bannedCount, otherFailedCount);
    } else if (bannedCount > 0) {
      return L10n.of(context)!.failedToAddBannedUsers(bannedCount);
    } else if (otherFailedCount > 0) {
      return L10n.of(context)!.failedToAddMembers(otherFailedCount);
    } else {
      return L10n.of(context)!.errorDialogTitle;
    }
  }
}
