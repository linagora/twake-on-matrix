import 'package:fluffychat/config/app_constants.dart';
import 'package:fluffychat/generated/l10n/app_localizations.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/platform_infos.dart';
import 'package:fluffychat/utils/string_extension.dart';
import 'package:fluffychat/utils/twake_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';
import 'package:matrix/matrix.dart';
import 'package:share_plus/share_plus.dart';

class SliverInviteFriendButton extends StatelessWidget {
  const SliverInviteFriendButton({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      floating: true,
      delegate: _InviteFriendButtonDelegate(userId),
    );
  }
}

class _InviteFriendButtonDelegate extends SliverPersistentHeaderDelegate {
  const _InviteFriendButtonDelegate(this.userId);

  final String userId;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final sysColor = LinagoraSysColors.material();
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: sysColor.onPrimary,
      child: InkWell(
        onTap: () async {
          // TODO: Placeholder url
          const domain = AppConstants.appLinkUniversalLinkDomain;
          final url = 'https://$domain/chat/#/${Uri.encodeComponent(userId)}';
          try {
            if (PlatformInfos.isMobile) {
              await Share.share(url);
            } else if (PlatformInfos.isWeb) {
              await Clipboard.setData(ClipboardData(text: url));
              TwakeSnackBar.show(
                context,
                L10n.of(context)!.linkCopiedToClipboard,
              );
            }
          } catch (e) {
            Logs().e('InviteFriendButtonDelegate::onTap():', e);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(
                color: sysColor.surfaceTint.withValues(alpha: 0.16),
              ),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: SvgPicture.asset(
                  ImagePaths.icPersonCheck,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    sysColor.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  L10n.of(context)!.inviteFriend.capitalize(context),
                  style: textTheme.bodyLarge?.copyWith(
                    fontSize: 17,
                    height: 24 / 17,
                    color: sysColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 64;

  @override
  double get minExtent => 0;

  @override
  bool shouldRebuild(covariant _InviteFriendButtonDelegate oldDelegate) =>
      oldDelegate.userId != userId;
}
