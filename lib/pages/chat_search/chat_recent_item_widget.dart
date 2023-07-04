import 'dart:convert';
import 'dart:developer';

import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/forward/forward_item_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class ChatRecentItemWidget extends StatelessWidget {
  final Room room;
  final void Function()? onTap;

  const ChatRecentItemWidget(
    this.room,
    {
      this.onTap,
      Key? key,
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    log(jsonEncode(room));
    final displayName = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    return Material(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                SizedBox(
                  width: ForwardItemStyle.avatarSize,
                  child: Avatar(
                    mxContent: room.avatar,
                    name: displayName,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        softWrap: false,
                        style: Theme.of(context).textTheme.titleMedium?.merge(
                          TextStyle(
                            overflow: TextOverflow.ellipsis,
                            letterSpacing: 0.15,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      _buildInformationWidget(context)
                    ],
                  ),
                ),
              ],
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }

  Widget _buildInformationWidget(BuildContext context) {
    final directChatMatrixID = room.directChatMatrixID;
    if (directChatMatrixID == null) {
      return _groupChatInformation(context);
    } else {
      return _directChatInformation(context);
    }
  }

  Widget _groupChatInformation(BuildContext context) {
    final actualMembersCount = (room.summary.mInvitedMemberCount ?? 0) +
      (room.summary.mJoinedMemberCount ?? 0);
    return Text(
      L10n.of(context)!.membersCount(actualMembersCount),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      softWrap: false,
      style: Theme.of(context).textTheme.bodyMedium?.merge(
        TextStyle(
          overflow: TextOverflow.ellipsis,
          letterSpacing: 0.15,
          color: LinagoraRefColors.material().tertiary[30],
        ),
      ),
    );
  }

  Widget _directChatInformation(BuildContext context) {
    final client = room.client;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client.userID ?? "",
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyMedium?.merge(
            TextStyle(
              overflow: TextOverflow.ellipsis,
              letterSpacing: 0.15,
              color: LinagoraRefColors.material().tertiary[30],
            ),
          ),
        ),
        Text(
          (client.userID ?? "").replaceAll('@', '').replaceAll(':', '@'),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          softWrap: false,
          style: Theme.of(context).textTheme.bodyMedium?.merge(
            TextStyle(
              overflow: TextOverflow.ellipsis,
              letterSpacing: 0.15,
              color: LinagoraRefColors.material().tertiary[30],
            ),
          ),
        )
      ],
    );
  }
}
