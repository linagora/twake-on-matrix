import 'package:twake_chat/pages/chat/chat_view_body_style.dart';
import 'package:twake_chat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class BlockedUserBanner extends StatelessWidget {
  const BlockedUserBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ChatViewBodyStyle.blockedUserBannerHeight,
      decoration: BoxDecoration(
        color: LinagoraSysColors.material().secondaryContainer,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            ImagePaths.icFrontHand,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              LinagoraSysColors.material().primary,
              BlendMode.srcIn,
            ),
          ),
          Text(
            L10n.of(context)!.unblockUser,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: LinagoraSysColors.material().primary,
            ),
          ),
        ],
      ),
    );
  }
}
