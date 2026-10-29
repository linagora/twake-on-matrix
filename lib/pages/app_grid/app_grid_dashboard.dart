import 'package:twake_chat/config/app_config.dart';
import 'package:twake_chat/domain/model/app_grid/linagora_applications.dart';
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

class AppGridDashboard extends ConsumerWidget {
  const AppGridDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linagoraApplications = ref.watch(appGridApplicationsProvider).value;
    return Align(
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (AppConfig.supportUrl.isNotEmpty) const _AppHelpButton(),
          _AppGridButton(linagoraApplications: linagoraApplications),
        ],
      ),
    );
  }
}

class _AppHelpButton extends StatefulWidget {
  const _AppHelpButton();

  @override
  State<_AppHelpButton> createState() => _AppHelpButtonState();
}

class _AppHelpButtonState extends State<_AppHelpButton> {
  final _hoverColor = ValueNotifier<Color>(Colors.transparent);

  @override
  void dispose() {
    _hoverColor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      behavior: HitTestBehavior.opaque,
      onTapInside: (_) {
        UrlLauncher(context, url: AppConfig.supportUrl).openUrlInAppBrowser();
      },
      onTapOutside: (_) {
        _hoverColor.value = Colors.transparent;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) =>
            _hoverColor.value = AppGridDashboardViewStyle.hoverColor,
        onExit: (_) {
          _hoverColor.value = Colors.transparent;
        },
        child: TooltipVisibility(
          visible: true,
          child: Tooltip(
            key: const ValueKey('AppHelpTooltip'),
            message: L10n.of(context)!.help,
            showDuration: const Duration(seconds: 1),
            waitDuration: const Duration(seconds: 1),
            child: ValueListenableBuilder(
              valueListenable: _hoverColor,
              builder: (context, color, _) {
                return Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius:
                        AppGridDashboardViewStyle.appGridIconBorderRadius,
                  ),
                  padding: AppGridDashboardViewStyle.appGridIconPadding,
                  child: SvgPicture.asset(
                    Assets.configurations.icons.icTwakeSupport.path,
                    width: AppGridDashboardViewStyle.sizeIcSupportButton,
                    height: AppGridDashboardViewStyle.sizeIcSupportButton,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AppGridButton extends StatefulWidget {
  const _AppGridButton({required this.linagoraApplications});

  final LinagoraApplications? linagoraApplications;

  @override
  State<_AppGridButton> createState() => _AppGridButtonState();
}

class _AppGridButtonState extends State<_AppGridButton> {
  final _isOpen = ValueNotifier<bool>(false);

  final _hoverColor = ValueNotifier<Color>(Colors.transparent);

  void _hide() {
    if (!mounted || !_isOpen.value) return;
    _isOpen.value = false;
  }

  @override
  void deactivate() {
    // Close the portal before deactivation to prevent accessing
    // the Overlay context after the widget is deactivated
    _hide();
    super.deactivate();
  }

  @override
  void dispose() {
    _isOpen.dispose();
    _hoverColor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linagoraApplications = widget.linagoraApplications;
    return ValueListenableBuilder(
      valueListenable: _isOpen,
      builder: (context, isOpen, _) {
        return TapRegion(
          behavior: HitTestBehavior.opaque,
          onTapInside: (_) {
            _isOpen.toggle();
          },
          onTapOutside: (_) {
            _hide();
            _hoverColor.value = Colors.transparent;
          },
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) =>
                _hoverColor.value = AppGridDashboardViewStyle.hoverColor,
            onExit: (_) {
              if (!isOpen) {
                _hoverColor.value = Colors.transparent;
              }
            },
            child: ValueListenableBuilder(
              valueListenable: _hoverColor,
              builder: (context, color, child) {
                return PortalTarget(
                  portalFollower: const SizedBox(
                    width: AppGridDashboardViewStyle.sizIcAppGrid,
                  ),
                  visible: isOpen,
                  child: PortalTarget(
                    anchor: const Aligned(
                      follower: Alignment.topRight,
                      target: Alignment.bottomRight,
                    ),
                    portalFollower: linagoraApplications == null
                        ? const SizedBox.shrink()
                        : AppGridDashboardOverlay(linagoraApplications),
                    visible: isOpen,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            AppGridDashboardViewStyle.appGridIconBorderRadius,
                      ),
                      padding: AppGridDashboardViewStyle.appGridIconPadding,
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
    );
  }
}
