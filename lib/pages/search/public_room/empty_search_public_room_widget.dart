import 'package:fluffychat/pages/search/public_room/empty_search_public_room_widget_style.dart';
import 'package:fluffychat/pages/search/public_room/search_public_room_view_style.dart';
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
      child: Padding(
        padding: SearchPublicRoomViewStyle.paddingInsideListItem,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: SearchPublicRoomViewStyle.paddingAvatar,
              child: ClipRRect(
                borderRadius:
                    EmptySearchPublicRoomWidgetStyle.avatarBorderRadius,
                child: Container(
                  width: EmptySearchPublicRoomWidgetStyle.avatarSize,
                  height: EmptySearchPublicRoomWidgetStyle.avatarSize,
                  decoration: BoxDecoration(
                    borderRadius:
                        EmptySearchPublicRoomWidgetStyle.avatarBorderRadius,
                    color:
                        EmptySearchPublicRoomWidgetStyle.avatarBackgroundColor(
                      context,
                    ),
                    border:
                        EmptySearchPublicRoomWidgetStyle.avatarBorder(context),
                  ),
                  child: Center(
                    child: Text(
                      genericSearchTerm[0],
                      style: EmptySearchPublicRoomWidgetStyle
                          .avatarLetterTextStyle(
                        context,
                      ),
                    ),
                  ),
                ),
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
                    message: L10n.of(context)!.join,
                    styleMessage:
                        SearchPublicRoomViewStyle.joinButtonLabelStyle(context),
                    paddingAll: 0.0,
                    onTap: onTapJoin,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
