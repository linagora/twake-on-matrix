import 'package:fluffychat/pages/search/public_room/search_public_room_view_style.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/twake_components/twake_text_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class EmptySearchPublicRoomWidget extends StatelessWidget {
  final String genericSearchTerm;
  final VoidCallback? onTapJoin;

  const EmptySearchPublicRoomWidget({
    super.key,
    required this.genericSearchTerm,
    this.onTapJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: SearchPublicRoomViewStyle.paddingListItem,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: SearchPublicRoomViewStyle.paddingAvatar,
            child: Avatar(
              name: genericSearchTerm,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genericSearchTerm,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  style: SearchPublicRoomViewStyle.roomNameTextStyle,
                ),
                const SizedBox(
                  height: SearchPublicRoomViewStyle.nameToButtonSpace,
                ),
                TwakeTextButton(
                  message: L10n.of(context)!.joinRoom,
                  styleMessage:
                      SearchPublicRoomViewStyle.joinButtonLabelStyle(context),
                  paddingAll: SearchPublicRoomViewStyle.paddingButton,
                  onTap: onTapJoin,
                  buttonDecoration:
                      SearchPublicRoomViewStyle.actionButtonDecoration(
                    context,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
