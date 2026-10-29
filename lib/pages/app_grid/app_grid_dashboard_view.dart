import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/pages/app_grid/app_grid_applications.provider.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_overlay.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_view_style.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/utils/extension/value_notifier_extension.dart';
import 'package:twake_chat/utils/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:twake_chat/generated/l10n/app_localizations.dart';

class AppGridDashboard extends ConsumerStatefulWidget {
  const AppGridDashboard({super.key});

  @override
  ConsumerState<AppGridDashboard> createState() => _AppGridDashboardState();
}

class _AppGridDashboardState extends ConsumerState<AppGridDashboard> {
  final _isOpenAppGridDashboard = ValueNotifier<bool>(false);

  final _hoverColorAppGrid = ValueNotifier<Color>(Colors.transparent);

  final _hoverColorAppHelp = ValueNotifier<Color>(Colors.transparent);

  void _hideAppGridDashboard() {
    if (!mounted || !_isOpenAppGridDashboard.value) return;
    _isOpenAppGridDashboard.value = false;
  }

  @override
  void deactivate() {
    // Close the portal before deactivation to prevent accessing
    // the Overlay context after the widget is deactivated
    _hideAppGridDashboard();
    super.deactivate();
  }

  @override
  void dispose() {
    _isOpenAppGridDashboard.dispose();
    _hoverColorAppGrid.dispose();
    _hoverColorAppHelp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linagoraApplications = ref.watch(appGridApplicationsProvider).value;
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
                _hoverColorAppHelp.value = Colors.transparent;
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => _hoverColorAppHelp.value =
                    AppGridDashboardViewStyle.hoverColor,
                onExit: (_) {
                  _hoverColorAppHelp.value = Colors.transparent;
                },
                child: TooltipVisibility(
                  visible: true,
                  child: Tooltip(
                    key: const ValueKey('AppHelpTooltip'),
                    message: L10n.of(context)!.help,
                    showDuration: const Duration(seconds: 1),
                    waitDuration: const Duration(seconds: 1),
                    child: ValueListenableBuilder(
                      valueListenable: _hoverColorAppHelp,
                      builder: (context, color, _) {
                        return Container(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: AppGridDashboardViewStyle
                                .appGridIconBorderRadius,
                          ),
                          padding: AppGridDashboardViewStyle.appGridIconPadding,
                          child: SvgPicture.asset(
                            Assets.configurations.icons.icTwakeSupport.path,
                            width:
                                AppGridDashboardViewStyle.sizeIcSupportButton,
                            height:
                                AppGridDashboardViewStyle.sizeIcSupportButton,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ValueListenableBuilder(
            valueListenable: _isOpenAppGridDashboard,
            builder: (context, isOpenAppGridDashboard, _) {
              return TapRegion(
                behavior: HitTestBehavior.opaque,
                onTapInside: (_) {
                  _isOpenAppGridDashboard.toggle();
                },
                onTapOutside: (_) {
                  _hideAppGridDashboard();
                  _hoverColorAppGrid.value = Colors.transparent;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  onEnter: (_) => _hoverColorAppGrid.value =
                      AppGridDashboardViewStyle.hoverColor,
                  onExit: (_) {
                    if (!isOpenAppGridDashboard) {
                      _hoverColorAppGrid.value = Colors.transparent;
                    }
                  },
                  child: ValueListenableBuilder(
                    valueListenable: _hoverColorAppGrid,
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
                          portalFollower: linagoraApplications == null
                              ? const SizedBox.shrink()
                              : AppGridDashboardOverlay(linagoraApplications),
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
                              Assets.images.icApplicationGrid.path,
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
