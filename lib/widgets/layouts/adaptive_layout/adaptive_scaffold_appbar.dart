import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';

class AdaptiveScaffoldAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveScaffoldAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(AdaptiveScaffoldAppBarStyle.toolbarHeight);

  @override
  Widget build(BuildContext context) {
    return SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(begin: ResponsiveUtils.minDesktopWidth): SlotLayout.from(
          key: AdaptiveScaffoldAppBarStyle.adaptiveAppBarKey,
          builder: (_) {
            return AppBar(
              toolbarHeight: AdaptiveScaffoldAppBarStyle.toolbarHeight,
              title: const Padding(
                padding: AdaptiveScaffoldAppBarStyle.appBarPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _LeadingAppBarWidget(),
                  ],
                ),
              ),
            );
          },
        )
      },
    );
  }
}

class _LeadingAppBarWidget extends StatelessWidget {
  const _LeadingAppBarWidget();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(ImagePaths.icTwakeImageLogo,
          width: AdaptiveScaffoldAppBarStyle.sizeIcTwakeImageLogo,
          height: AdaptiveScaffoldAppBarStyle.sizeIcTwakeImageLogo,
        ),
        const SizedBox(width: 10),
        Text(
          L10n.of(context)!.twake,
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w600,
            color: LinagoraRefColors.material().primary[0],
          ),
        ),
      ],
    );
  }
}

