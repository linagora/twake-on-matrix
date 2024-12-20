import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_controller.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_overlay.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/utils/extension/value_notifier_extension.dart';
import 'package:fluffychat/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';

class AppGridDashboardView extends StatelessWidget {
  final AppGridDashboardController controller;

  const AppGridDashboardView({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (AppConfig.supportUrl.isNotEmpty)
            TapRegion(
              behavior: HitTestBehavior.opaque,
              onTapInside: (_) {
                UrlLauncher(
                  context,
                  url: AppConfig.supportUrl,
                ).openUrlInAppBrowser();
              },
              onTapOutside: (_) {
                controller.hoverColorAppHelp.value = Colors.transparent;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => controller.hoverColorAppHelp.value =
                    AppGridDashboardViewStyle.hoverColor,
                onExit: (_) {
                  controller.hoverColorAppHelp.value = Colors.transparent;
                },
                child: ValueListenableBuilder(
                  valueListenable: controller.hoverColorAppHelp,
                  builder: (context, color, _) {
                    return TooltipVisibility(
                      visible: true,
                      child: Tooltip(
                        message: L10n.of(context)!.help,
                        showDuration: const Duration(seconds: 1),
                        waitDuration: const Duration(seconds: 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: AppGridDashboardViewStyle
                                .appGridIconBorderRadius,
                          ),
                          padding: AppGridDashboardViewStyle.appGridIconPadding,
                          child: SvgPicture.asset(
                            ImagePaths.icTwakeSupport,
                            width:
                                AppGridDashboardViewStyle.sizeIcSupportButton,
                            height:
                                AppGridDashboardViewStyle.sizeIcSupportButton,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ValueListenableBuilder(
            valueListenable: controller.isOpenAppGridDashboardNotifier,
            builder: (context, isOpenAppGridDashboard, _) {
              return TapRegion(
                behavior: HitTestBehavior.opaque,
                onTapInside: (_) {
                  controller.isOpenAppGridDashboardNotifier.toggle();
                },
                onTapOutside: (_) {
                  controller.hideAppGridDashboard();
                  controller.hoverColorAppGrid.value = Colors.transparent;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => controller.hoverColorAppGrid.value =
                      AppGridDashboardViewStyle.hoverColor,
                  onExit: (_) {
                    if (!isOpenAppGridDashboard) {
                      controller.hoverColorAppGrid.value = Colors.transparent;
                    }
                  },
                  child: ValueListenableBuilder(
                    valueListenable: controller.hoverColorAppGrid,
                    builder: (context, color, child) {
                      return PortalTarget(
                        portalFollower: const SizedBox(
                          width: AppGridDashboardViewStyle.sizIcAppGrid,
                        ),
                        visible: isOpenAppGridDashboard,
                        child: PortalTarget(
                          anchor: const Aligned(
                            follower: Alignment.topRight,
                            target: Alignment.bottomRight,
                          ),
                          portalFollower: ValueListenableBuilder(
                            valueListenable: controller.linagoraApplications,
                            builder: (context, linagoraApplications, child) {
                              if (linagoraApplications == null) return child!;
                              return AppGridDashboardOverlay(
                                linagoraApplications,
                              );
                            },
                            child: const SizedBox.shrink(),
                          ),
                          visible: isOpenAppGridDashboard,
                          child: Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: AppGridDashboardViewStyle
                                  .appGridIconBorderRadius,
                            ),
                            padding:
                                AppGridDashboardViewStyle.appGridIconPadding,
                            child: SvgPicture.asset(
                              ImagePaths.icApplicationGrid,
                              width: AppGridDashboardViewStyle.sizIcAppGrid,
                              height: AppGridDashboardViewStyle.sizIcAppGrid,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
