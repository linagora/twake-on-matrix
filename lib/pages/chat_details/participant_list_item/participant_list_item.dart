import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item_style.dart';
import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/pages/profile_info/profile_info_page.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ParticipantListItem extends StatelessWidget {
  final User member;

  final VoidCallback? onUpdatedMembers;

  const ParticipantListItem(
    this.member, {
    super.key,
    this.onUpdatedMembers,
  });

  @override
  Widget build(BuildContext context) {
    final membershipBatch = <Membership, String>{
      Membership.join: '',
      Membership.ban: L10n.of(context)!.banned,
      Membership.invite: L10n.of(context)!.invited,
      Membership.leave: L10n.of(context)!.leftTheChat,
    };
    final permissionBatch = member.powerLevel == 100
        ? L10n.of(context)!.admin
        : member.powerLevel >= 50
            ? L10n.of(context)!.moderator
            : '';

    return Opacity(
      opacity: member.membership == Membership.join ? 1 : 0.5,
      child: ListTile(
        onTap: () async => await _onItemTap(context),
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                member.calcDisplayname(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (permissionBatch.isNotEmpty)
              Container(
                padding: ParticipantListItemStyle.permissionBatchTextPadding,
                margin: ParticipantListItemStyle.permissionBatchMargin,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: ParticipantListItemStyle.permissionBatchRadius,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  permissionBatch,
                  style: TextStyle(
                    fontSize:
                        ParticipantListItemStyle.permissionBatchTextFontSize,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            membershipBatch[member.membership]!.isEmpty
                ? Container()
                : Container(
                    padding: ParticipantListItemStyle.membershipBatchPadding,
                    margin: ParticipantListItemStyle.membershipBatchMargin,
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      borderRadius:
                          ParticipantListItemStyle.membershipBatchRadius,
                    ),
                    child: Center(
                      child: Text(membershipBatch[member.membership]!),
                    ),
                  ),
          ],
        ),
        subtitle: Text(member.id),
        leading:
            Avatar(mxContent: member.avatarUrl, name: member.calcDisplayname()),
      ),
    );
  }

  Future _onItemTap(BuildContext context) async {
    final responsive = getIt.get<ResponsiveUtils>();

    if (responsive.isMobile(context)) {
      await _openProfileMenu(context);
    } else {
      await _openProfileDialog(context);
    }
  }

  Future _openDialogInvite(BuildContext context) async {
    if (PlatformInfos.isMobile) {
      Navigator.of(context).push(
        CupertinoPageRoute(
          builder: (ctx) => ProfileInfoPage(
            roomId: member.room.id,
            userId: member.id,
            onUpdatedMembers: onUpdatedMembers,
          ),
        ),
      );
      return;
    }
    await showDialog(
      context: context,
      barrierDismissible: false,
      useSafeArea: false,
      useRootNavigator: !PlatformInfos.isMobile,
      builder: (dialogContext) {
        return ProfileInfoPage(
          roomId: member.room.id,
          userId: member.id,
          onUpdatedMembers: onUpdatedMembers,
          onNewChatOpen: () {
            Navigator.of(dialogContext).pop();
          },
        );
      },
    );
  }

  Future _openProfileMenu(BuildContext context) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: ParticipantListItemStyle.bottomSheetTopRadius,
            topRight: ParticipantListItemStyle.bottomSheetTopRadius,
          ),
        ),
        builder: (bottomSheetContext) {
          return Container(
            padding: ParticipantListItemStyle.bottomSheetContentPadding,
            decoration: BoxDecoration(
              color: LinagoraRefColors.material().primary[100],
              borderRadius: const BorderRadius.only(
                topLeft: ParticipantListItemStyle.bottomSheetTopRadius,
                topRight: ParticipantListItemStyle.bottomSheetTopRadius,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: ParticipantListItemStyle.dragHandleHeight,
                      width: ParticipantListItemStyle.dragHandleWidth,
                      decoration: BoxDecoration(
                        borderRadius:
                            ParticipantListItemStyle.dragHandleBorderRadius,
                        color: LinagoraSysColors.material().outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: ParticipantListItemStyle.spacerHeight,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          Navigator.of(bottomSheetContext).pop();
                          await _openDialogInvite(context);
                        },
                        icon: Icon(
                          Icons.person_search,
                          color: LinagoraSysColors.material().onSurface,
                        ),
                        label: L10n.of(context)?.viewProfile != null
                            ? Row(
                                children: [
                                  Text(
                                    L10n.of(context)!.viewProfile,
                                    style: TextStyle(
                                      color: LinagoraSysColors.material()
                                          .onSurface,
                                    ),
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );

  Future _openProfileDialog(BuildContext context) => showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          contentPadding: const EdgeInsets.all(0),
          backgroundColor: LinagoraRefColors.material().primary[100],
          surfaceTintColor: Colors.transparent,
          content: SizedBox(
            width: ParticipantListItemStyle.fixedDialogWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: ParticipantListItemStyle.closeButtonPadding,
                        child: IconButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          icon: const Icon(Icons.close),
                        ),
                      ),
                    ),
                    ProfileInfoBody(
                      user: member,
                      onNewChatOpen: () {
                        Navigator.of(dialogContext).pop();
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
