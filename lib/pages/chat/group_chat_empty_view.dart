import 'package:fluffychat/pages/chat/others_group_chat_empty_view.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:matrix/matrix.dart';

class GroupChatEmptyView extends StatelessWidget {
  final Event firstEvent;
  const GroupChatEmptyView({super.key, required this.firstEvent});

  @override
  Widget build(BuildContext context) {
    final hasCreatedRoom = firstEvent.type == EventTypes.RoomCreate &&
        firstEvent.senderId == Matrix.of(context).client.userID;

    return hasCreatedRoom
        ? _buildOwnGroupChatEmptyView(context)
        : OthersGroupChatEmptyView(firstEvent: firstEvent);
  }

  Container _buildOwnGroupChatEmptyView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 18, right: 16, left: 16, bottom: 26),
      constraints: const BoxConstraints(
        maxWidth: 256,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(ImagePaths.icEmptyGroupChat),
          const SizedBox(
            height: 26.0,
          ),
          Text(
            L10n.of(context)!.youCreatedGroupChat,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                L10n.of(context)!.chatCanHave,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: LinagoraRefColors.material().neutral[40],
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          _ruleChannel(L10n.of(context)!.upTo100000Members),
          const SizedBox(height: 8),
          _ruleChannel(L10n.of(context)!.persistentChatHistory),
        ],
      ),
    );
  }

  Widget _ruleChannel(String rule) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          ImagePaths.icDone,
          width: 20,
          height: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            rule,
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 15,
              color: LinagoraRefColors.material().neutral[40],
            ),
          ),
        ),
      ],
    );
  }
}
