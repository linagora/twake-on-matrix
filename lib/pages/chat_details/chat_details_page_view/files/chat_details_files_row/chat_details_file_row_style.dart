import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class ChatDetailsFileRowStyle {
  static TextStyle textInformationStyle(BuildContext context) {
    return Theme.of(context).textTheme.bodySmall!.copyWith(
          color: LinagoraSysColors.material().tertiary,
        );
  }

  static const double textTopMargin = 4.0;
}
