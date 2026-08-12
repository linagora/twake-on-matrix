import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_controller.dart';
import 'package:twake_chat/resource/image_paths.dart';
import 'package:twake_chat/utils/platform_infos.dart';
import 'package:twake_chat/utils/responsive/responsive_utils.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar_style.dart';
import 'package:twake_chat/widgets/layouts/adaptive_layout/adaptive_scaffold_view_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AdaptiveScaffoldAppBar extends StatefulWidget {
  const AdaptiveScaffoldAppBar({super.key});

  @override
  State<AdaptiveScaffoldAppBar> createState() => _AdaptiveScaffoldAppBarState();
}

class _AdaptiveScaffoldAppBarState extends State<AdaptiveScaffoldAppBar> {
  @override
  Widget build(BuildContext context) {
    final child = SlotLayout(
      config: <Breakpoint, SlotLayoutConfig>{
        const WidthPlatformBreakpoint(
          begin: ResponsiveUtils.minDesktopWidth,
        ): SlotLayout.from(
          key: AdaptiveScaffoldAppBarStyle.adaptiveAppBarKey,
          builder: (_) {
            return Container(
              height: AppScaffoldViewStyle.appBarSize,
              decoration: BoxDecoration(
                color: LinagoraSysColors.material().onPrimary,
              ),
              child: Padding(
                padding: AdaptiveScaffoldAppBarStyle.appBarPadding,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _LeadingAppBarWidget(),
                    if (AppConfig.appGridDashboardAvailable &&
                        PlatformInfos.isWeb)
                      const Expanded(child: AppGridDashboard()),
                  ],
                ),
              ),
            );
          },
        ),
      },
    );

    return FutureBuilder(
      future: CozyConfigManager().isInsideCozy,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) return child;

        return const SizedBox();
      },
    );
  }
}

class _LeadingAppBarWidget extends StatelessWidget {
  const _LeadingAppBarWidget();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      ImagePaths.icTwakeImageLogoBeta,
      width: AdaptiveScaffoldAppBarStyle.sizeWidthIcTwakeImageLogo,
      height: AdaptiveScaffoldAppBarStyle.sizeHeightIcTwakeImageLogo,
    );
  }
}
