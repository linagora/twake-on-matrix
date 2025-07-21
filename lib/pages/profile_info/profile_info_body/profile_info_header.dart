import 'package:fluffychat/pages/profile_info/profile_info_body/profile_info_body_view_style.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/presence_extension.dart';
import 'package:fluffychat/widgets/avatar/avatar.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

import 'package:matrix/matrix.dart';

class ProfileInfoHeader extends StatelessWidget {
  const ProfileInfoHeader(this.user, {super.key});

  final User user;

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    final presence = client.presences[user.id];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: ProfileInfoBodyViewStyle.avatarPadding,
          child: Avatar(
            mxContent: user.avatarUrl,
            name: user.calcDisplayname(),
            size: 160,
          ),
        ),
        Text(
          user.calcDisplayname(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: LinagoraTextStyle.material().bodyMedium2.copyWith(
                color: LinagoraSysColors.material().onSurface,
              ),
        ),
        if (presence != null) ...[
          const SizedBox(height: 8),
          Text(
            presence.getLocalizedStatusMessage(context),
            style: presence.getPresenceTextStyle(context),
          ),
        ],
      ],
    );
  }
}
