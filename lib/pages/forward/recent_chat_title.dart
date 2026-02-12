import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class RecentChatsTitle extends StatelessWidget {
  const RecentChatsTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          L10n.of(context)!.recentChat,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: LinagoraRefColors.material().neutral,
          ),
        ),
      ],
    );
  }
}
