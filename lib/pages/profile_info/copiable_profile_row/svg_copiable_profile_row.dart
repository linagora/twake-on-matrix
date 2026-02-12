import 'package:fluffychat/pages/profile_info/copiable_profile_row/copiable_profile_row.dart';
import 'package:fluffychat/pages/chat_profile_info/chat_profile_info_style.dart';
import 'package:flutter/material.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class SvgCopiableProfileRow extends CopiableProfileRow {
  SvgCopiableProfileRow({
    required String leadingIconPath,
    required super.caption,
    required super.copiableText,
    super.enableDividerTop,
    super.key,
  }) : super(
         leadingIcon: SvgPicture.asset(
           leadingIconPath,
           width: ChatProfileInfoStyle.iconSize,
           height: ChatProfileInfoStyle.iconSize,
           colorFilter: ColorFilter.mode(
             LinagoraSysColors.material().tertiary,
             BlendMode.srcIn,
           ),
         ),
       );
}
