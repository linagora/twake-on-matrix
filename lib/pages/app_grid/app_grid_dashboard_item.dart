import 'package:fluffychat/domain/model/app_grid/linagora_app.dart';
import 'package:fluffychat/domain/model/extensions/linagora_app_extensions.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_item_style.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_view_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/link_browser_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

typedef OnAppTap = Future<bool> Function(String url, {bool isNewTab});

class AppGridDashboardItem extends StatelessWidget {
  static const _webOnlyWindowName = '_blank';

  final LinagoraApp app;

  const AppGridDashboardItem(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Color> hoverColor = ValueNotifier(Colors.transparent);

    return LinkBrowserWidget(
      uri: app.appUri,
      child: TapRegion(
        behavior: HitTestBehavior.opaque,
        onTapInside: (_) async {
          await launchUrl(
            Uri.parse(app.appUri.toString()),
            webOnlyWindowName: _webOnlyWindowName,
            mode: LaunchMode.externalApplication,
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) =>
              hoverColor.value = AppGridDashboardViewStyle.hoverColor,
          onExit: (_) => hoverColor.value = Colors.transparent,
          child: ValueListenableBuilder<Color>(
            valueListenable: hoverColor,
            builder: (context, color, child) {
              return Container(
                width: AppGridDashboardItemStyle.itemWidth,
                padding: AppGridDashboardItemStyle.padding,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: AppGridDashboardItemStyle.borderRadius,
                ),
                child: Column(
                  children: [
                    if (app.publicIconUri != null)
                      Image.network(
                        app.publicIconUri.toString(),
                        width: AppGridDashboardItemStyle.iconAppSize,
                        height: AppGridDashboardItemStyle.iconAppSize,
                        fit: BoxFit.fill,
                        errorBuilder: (_, error, stackTrace) {
                          return Container(
                            width: AppGridDashboardItemStyle.iconAppSize,
                            height: AppGridDashboardItemStyle.iconAppSize,
                            color: Theme.of(context).hintColor,
                          );
                        },
                      )
                    else
                      app.iconName.endsWith("svg")
                          ? SvgPicture.asset(
                              ImagePaths.getConfigurationImagePath(
                                app.iconName,
                              ),
                              width: AppGridDashboardItemStyle.iconAppSize,
                              height: AppGridDashboardItemStyle.iconAppSize,
                              fit: BoxFit.fill,
                            )
                          : Image.asset(
                              ImagePaths.getConfigurationImagePath(
                                app.iconName,
                              ),
                              width: AppGridDashboardItemStyle.iconAppSize,
                              height: AppGridDashboardItemStyle.iconAppSize,
                              fit: BoxFit.fill,
                            ),
                    Padding(
                      padding: AppGridDashboardItemStyle.textPadding,
                      child: Text(
                        app.getDisplayAppName(),
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: AppGridDashboardItemStyle.textStyle(context),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
