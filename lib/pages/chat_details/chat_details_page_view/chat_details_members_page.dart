import 'package:fluffychat/pages/chat_details/participant_list_item/participant_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:matrix/matrix.dart';

class ChatDetailsMembersPage extends StatelessWidget {
  final ValueNotifier<List<User>?> displayMembersNotifier;
  final int actualMembersCount;
  final VoidCallback openDialogInvite;
  final VoidCallback requestMoreMembersAction;
  final VoidCallback? onUpdatedMembers;
  final bool isMobileAndTablet;

  const ChatDetailsMembersPage({
    super.key,
    required this.displayMembersNotifier,
    required this.actualMembersCount,
    required this.openDialogInvite,
    required this.requestMoreMembersAction,
    required this.isMobileAndTablet,
    this.onUpdatedMembers,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: displayMembersNotifier,
      builder: (context, members, child) {
        members ??= [];
        final canRequestMoreMembers = members.length < actualMembersCount;
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length + (canRequestMoreMembers ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (index < members!.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: ParticipantListItem(
                        members[index],
                        onUpdatedMembers: onUpdatedMembers,
                      ),
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
}
