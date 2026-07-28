import 'package:fluffychat/config/default_power_level_member.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/utils/search/search_engine.dart';
import 'package:fluffychat/utils/search/search_options.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

extension UserExtension on User {
  static const double fixedDialogWidth = 448;

  static const EdgeInsets closeButtonPadding = EdgeInsets.all(16);

  DefaultPowerLevelMember get getDefaultPowerLevelMember {
    return DefaultPowerLevelMember.getDefaultPowerLevelByUsersDefault(
      usersDefault: powerLevel.level,
    );
  }

  bool get isOwnerRole {
    return getDefaultPowerLevelMember == DefaultPowerLevelMember.owner;
  }

  bool get isBanned {
    return membership == Membership.ban;
  }

  Future openProfileView({
    required BuildContext context,
    VoidCallback? onUpdatedMembers,
    VoidCallback? onTransferOwnershipSuccess,
  }) {
    final responsive = getIt.get<ResponsiveUtils>();

    if (responsive.isMobile(context)) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (ctx) => ProfileInfoPage(
            roomId: room.id,
            userId: id,
            onUpdatedMembers: onUpdatedMembers,
            onTransferOwnershipSuccess: () {
              Navigator.of(ctx).pop();
              onTransferOwnershipSuccess?.call();
            },
          ),
        ),
      );
      return Future.value();
    }
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        contentPadding: const EdgeInsets.all(0),
        backgroundColor: LinagoraRefColors.material().primary[100],
        surfaceTintColor: Colors.transparent,
        content: SizedBox(
          width: fixedDialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: closeButtonPadding,
                      child: IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ),
                  ),
                  ProfileInfoBody(
                    user: this,
                    onNewChatOpen: () {
                      Navigator.of(dialogContext).pop();
                    },
                    onTransferOwnershipSuccess: () {
                      Navigator.of(dialogContext).pop();
                      onTransferOwnershipSuccess?.call();
                    },
                    onUpdatedMembers: onUpdatedMembers,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension IterableUsersExtension on Iterable<User> {
  List<User> searchUsers(String keyword) {
    if (keyword.isEmpty) return toList();
    return getIt.get<SearchEngine>().matchAnyField<User>(
      keyword,
      toList(),
      fieldExtractors: [
        (user) => [user.displayName ?? ''],
        (user) => [user.id],
      ],
      options: const SearchOptions(diacriticSensitive: false),
    );
  }
}
