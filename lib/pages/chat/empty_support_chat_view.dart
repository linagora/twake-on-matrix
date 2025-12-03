import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class EmptySupportChatView extends StatelessWidget {
  const EmptySupportChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = L10n.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            ImagePaths.supportWelcomePng,
            width: 140.59,
            height: 135.67,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.supportChat,
            style: textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              height: 32 / 24,
              color: LinagoraSysColors.material().onSurface,
            ),
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: 274,
            child: Text(
              l10n.supportChatDescription,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 17,
                height: 24 / 17,
                color: LinagoraRefColors.material().tertiary[20],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
