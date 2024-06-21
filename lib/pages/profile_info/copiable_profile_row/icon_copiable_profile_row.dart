import 'package:fluffychat/pages/profile_info/copiable_profile_row/copiable_profile_row.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:flutter/material.dart';

import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class IconCopiableProfileRow extends CopiableProfileRow {
  IconCopiableProfileRow({
    required IconData icon,
    required super.caption,
    required super.copiableText,
    super.key,
  }) : super(
          leadingIcon: Icon(
            icon,
            size: ChatProfileInfoStyle.iconSize,
            color: LinagoraSysColors.material().onSurface,
          ),
        );
}
