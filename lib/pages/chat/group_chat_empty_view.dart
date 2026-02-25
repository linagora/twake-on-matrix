import 'package:fluffychat/pages/chat/group_chat_empty_view_style.dart';
import 'package:fluffychat/pages/chat/others_group_chat_empty_view.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class GroupChatEmptyView extends StatelessWidget {
  final Event firstEvent;

  const GroupChatEmptyView({super.key, required this.firstEvent});

  @override
  Widget build(BuildContext context) {
    final hasCreatedRoom =
        firstEvent.type == EventTypes.RoomCreate &&
        firstEvent.senderId == Matrix.of(context).client.userID;

    return hasCreatedRoom
        ? _buildOwnGroupChatEmptyView(context)
        : OthersGroupChatEmptyView(firstEvent: firstEvent);
  }

  Container _buildOwnGroupChatEmptyView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, right: 24, left: 24, bottom: 24),
      constraints: BoxConstraints(
        maxWidth: GroupChatEmptyViewStyle.maxWidth(context),
        minWidth: GroupChatEmptyViewStyle.minWidth,
      ),
      decoration: BoxDecoration(
        color: LinagoraSysColors.material().onPrimary.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            ImagePaths.mascotEmptyGroup,
            width: GroupChatEmptyViewStyle.iconSize(context),
            height: GroupChatEmptyViewStyle.iconSize(context),
          ),
          const SizedBox(height: 26.0),
          Text(
            L10n.of(context)!.youCreatedGroupChat,
            style: GroupChatEmptyViewStyle.titleStyle(context),
            textAlign: TextAlign.center,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _ruleChannel(context, L10n.of(context)!.upTo100000Members),
              const SizedBox(height: 8),
              _ruleChannel(context, L10n.of(context)!.persistentChatHistory),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ruleChannel(BuildContext context, String rule) {
    return Padding(
      padding: GroupChatEmptyViewStyle.rulePadding(context),
      child: Text(
        rule,
        style: GroupChatEmptyViewStyle.ruleStyle(context),
        textAlign: TextAlign.start,
      ),
    );
  }
}
