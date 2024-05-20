import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsMembersPage extends StatelessWidget {
  static const int addMemberItemCount = 1;

  final ValueNotifier<List<User>?> membersNotifier;
  final int actualMembersCount;
  final VoidCallback openDialogInvite;
  final VoidCallback requestMoreMembersAction;
  final VoidCallback? onUpdatedMembers;
  final bool canRequestMoreMembers;
  final bool isMobileAndTablet;

  const ChatDetailsMembersPage({
    super.key,
    required this.membersNotifier,
    required this.actualMembersCount,
    required this.openDialogInvite,
    required this.requestMoreMembersAction,
    required this.canRequestMoreMembers,
    required this.isMobileAndTablet,
    this.onUpdatedMembers,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: membersNotifier,
      builder: (context, members, child) {
        members ??= [];
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length +
                    (canRequestMoreMembers ? 1 : 0) +
                    addMemberItemCount,
                itemBuilder: (BuildContext context, int index) {
                  if (index == 0) {
                    return _listMemberInfoMobileAndTablet(context);
                  }
                  if (index - addMemberItemCount < members!.length) {
                    return ParticipantListItem(
                      members[index - addMemberItemCount],
                      onUpdatedMembers: onUpdatedMembers,
                    );
                  }
                  final haveMoreMembers = actualMembersCount > members.length;
                  if (!haveMoreMembers) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    title: Text(
                      L10n.of(context)!.loadCountMoreParticipants(
                        (actualMembersCount - members.length).toString(),
                      ),
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).scaffoldBackgroundColor,
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.grey,
                      ),
                    ),
                    onTap: requestMoreMembersAction,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _listMemberInfoMobileAndTablet(BuildContext context) {
    if (!isMobileAndTablet) return const SizedBox.shrink();
    return Column(
      children: [
        Container(
          padding: const EdgeInsetsDirectional.all(16),
          color: LinagoraSysColors.material().surface,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              L10n.of(context)!.membersInfo(
                actualMembersCount.toString(),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: LinagoraRefColors.material().neutral[40],
                  ),
            ),
          ),
        ),
        InkWell(
          onTap: openDialogInvite,
          child: Container(
            padding: const EdgeInsetsDirectional.only(
              start: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            margin: const EdgeInsetsDirectional.symmetric(
              horizontal: 16.0,
              vertical: 10.0,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_add,
                  size: 18,
                  color: LinagoraSysColors.material().primary,
                ),
                const SizedBox(width: 8),
                Text(
                  L10n.of(context)!.addMembers,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: LinagoraSysColors.material().primary,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
