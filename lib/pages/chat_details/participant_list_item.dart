import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';

class ParticipantListItem extends StatelessWidget {
  final User user;

  final VoidCallback? onUpdatedMembers;

  const ParticipantListItem(
    this.user, {
    Key? key,
    this.onUpdatedMembers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final membershipBatch = <Membership, String>{
      Membership.join: '',
      Membership.ban: L10n.of(context)!.banned,
      Membership.invite: L10n.of(context)!.invited,
      Membership.leave: L10n.of(context)!.leftTheChat,
    };
    final permissionBatch = user.powerLevel == 100
        ? L10n.of(context)!.admin
        : user.powerLevel >= 50
            ? L10n.of(context)!.moderator
            : '';

    return Opacity(
      opacity: user.membership == Membership.join ? 1 : 0.5,
      child: ListTile(
        onTap: () async {
          if (PlatformInfos.isMobile) {
            await showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              builder: (c) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
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
                            height: 4,
                            width: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(100),
                              color: LinagoraSysColors.material().outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                context.go(
                                  '/rooms/profileinfo/${user.room.id}/${user.id}',
                                );
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
                      // TODO: share button
                      /*TextButton.icon(
                        onPressed: () {
                          // Action pour le premier bouton
                        },
                        icon: Icon(Icons.share),
                        label: Text('Partager'),
                      ),*/
                    ],
                  ),
                );
              },
            );
          } else {
            await showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                contentPadding: const EdgeInsets.all(0),
                backgroundColor: LinagoraRefColors.material().primary[100],
                surfaceTintColor: Colors.transparent,
                content: SizedBox(
                  width: 448,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: IconButton(
                                onPressed: () => dialogContext.pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ),
                          ProfileInfoBody(
                            user: user,
                            parentContext: context,
                            onNewChatOpen: () {
                              dialogContext.pop();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
        title: Row(
          children: <Widget>[
            Flexible(
              child: Text(
                user.calcDisplayname(),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            if (permissionBatch.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                child: Text(
                  permissionBatch,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            membershipBatch[user.membership]!.isEmpty
                ? Container()
                : Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).secondaryHeaderColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Center(child: Text(membershipBatch[user.membership]!)),
                  ),
          ],
        ),
        subtitle: Text(user.id),
        leading:
            Avatar(mxContent: user.avatarUrl, name: user.calcDisplayname()),
      ),
    );
  }
}
