import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/search/recent_item_widget_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class RecentItemWidget extends StatelessWidget {
  final Room room;
  final void Function()? onTap;

  const RecentItemWidget(
    this.room,
    {
      this.onTap,
      Key? key,
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayName = room.getLocalizedDisplayname(
      MatrixLocals(L10n.of(context)!),
    );
    final directChatMatrixID = room.directChatMatrixID;
    return Material(
      borderRadius: BorderRadius.circular(AppConfig.borderRadius),
      clipBehavior: Clip.hardEdge,
      color: Colors.transparent,
      child: Padding(
        padding: RecentItemStyle.paddingRecentItem,
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title:  Row(
              crossAxisAlignment: directChatMatrixID != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: RecentItemStyle.avatarSize,
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
                      _buildInformationWidget(context, directChatMatrixID: directChatMatrixID)
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

  Widget _buildInformationWidget(
    BuildContext context,
    {
      String? directChatMatrixID,
    }
  ) {
    if (directChatMatrixID == null) {
      return _GroupChatInformation(room: room);
    } else {
      return _DirectChatInformation(room: room);
    }
  }
}

class _GroupChatInformation extends StatelessWidget {
  final Room room;
  const _GroupChatInformation({required this.room});

  @override
  Widget build(BuildContext context) {
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
}


class _DirectChatInformation extends StatelessWidget {
  final Room room;
  const _DirectChatInformation({required this.room});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          room.summary.mHeroes?.first ?? "",
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
          room.name,
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
