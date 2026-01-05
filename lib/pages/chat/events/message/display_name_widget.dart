import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/domain/model/user_info/user_info.dart';
import 'package:fluffychat/pages/chat/events/message/message_style.dart';
import 'package:fluffychat/utils/manager/twake_user_info_manager/twake_user_info_manager.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:matrix/matrix.dart';

class DisplayNameWidget extends StatelessWidget {
  const DisplayNameWidget({
    super.key,
    required this.event,
  });

  final Event event;

  static const int maxCharactersDisplayNameBubble = 68;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserInfo>(
      future: getIt.get<TwakeUserInfoManager>().getTwakeProfileFromUserId(
            client: Matrix.of(context).client,
            userId: event.senderId,
            getFromRooms: false,
          ),
      builder: (context, snapshot) {
        final twakeDisplayName = snapshot.data?.displayName;
        final displayName =
            (twakeDisplayName != null && twakeDisplayName.isNotEmpty)
                ? twakeDisplayName
                : event.senderFromMemoryOrFallback.calcDisplayname();
        return Padding(
          padding: MessageStyle.paddingDisplayName(event),
          child: Text(
            displayName.shortenDisplayName(
              maxCharacters: maxCharactersDisplayNameBubble,
            ),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontFamily: 'Inter',
                  color: LinagoraSysColors.material().secondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.clip,
          ),
        );
      },
    );
  }
}
