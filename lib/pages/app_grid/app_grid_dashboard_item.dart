import 'package:fluffychat/domain/model/app_grid/linagora_app.dart';
import 'package:fluffychat/pages/app_grid/app_grid_dashboard_item_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:fluffychat/widgets/link_browser_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class AppGridDashboardItem extends StatelessWidget {
  static const _webOnlyWindowName = '_blank';

  final LinagoraApp app;

  const AppGridDashboardItem(this.app, {super.key});

  @override
  Widget build(BuildContext context) {
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
          child: Container(
            width: AppGridDashboardItemStyle.itemWidth,
            padding: AppGridDashboardItemStyle.padding,
            child: Column(
              children: [
                app.iconName.endsWith("svg")
                    ? SvgPicture.asset(
                        ImagePaths.getConfigurationImagePath(app.iconName),
                        width: AppGridDashboardItemStyle.iconAppSize,
                        height: AppGridDashboardItemStyle.iconAppSize,
                        fit: BoxFit.fill,
                      )
                    : Image.asset(
                        ImagePaths.getConfigurationImagePath(app.iconName),
                        width: AppGridDashboardItemStyle.iconAppSize,
                        height: AppGridDashboardItemStyle.iconAppSize,
                        fit: BoxFit.fill,
                      ),
                Padding(
                  padding: AppGridDashboardItemStyle.textPadding,
                  child: Text(
                    app.appName,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
