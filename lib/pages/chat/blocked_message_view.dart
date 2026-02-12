import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

class BlockedMessageView extends StatelessWidget {
  const BlockedMessageView({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobileResponsive = getIt.get<ResponsiveUtils>().isMobile(context);
    final isTabletLargeResponsive = getIt.get<ResponsiveUtils>().isTabletLarge(
      context,
    );
    final refColor = LinagoraRefColors.material();
    final sysColor = LinagoraSysColors.material();
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobileResponsive ? 33.5 : 25,
          vertical: isTabletLargeResponsive ? 17.5 : 12,
        ),
        decoration: BoxDecoration(
          color: sysColor.surface,
          border: BoxBorder.fromLTRB(
            top: BorderSide(
              width: 1,
              color: sysColor.surfaceTint.withValues(alpha: 0.16),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.front_hand_outlined,
                size: 20,
                color: refColor.tertiary[30],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 11.5,
                vertical: 6,
              ),
              child: Text(
                L10n.of(context)!.unblockUserToSendMessages,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 17,
                  height: 24 / 17,
                  color: refColor.tertiary[30],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
