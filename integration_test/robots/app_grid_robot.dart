import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:twake_chat/generated/assets.gen.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_item.dart';
import 'package:twake_chat/pages/app_grid/app_grid_dashboard_overlay.dart';
import 'package:twake_chat/widgets/link_browser_widget.dart';

import '../base/core_robot.dart';
import 'abstract/abstract_app_grid_robot.dart';

class AppGridRobot extends CoreRobot implements AbstractAppGridRobot {
  AppGridRobot(super.$);

  PatrolFinder _svgAsset(String assetPath) {
    return $(
      find.byWidgetPredicate(
        (widget) =>
            widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName == assetPath,
      ),
    );
  }

  PatrolFinder appGridButton() =>
      _svgAsset(Assets.images.icApplicationGrid.path);

  PatrolFinder twakeLogo() => _svgAsset(Assets.images.icTwakeImageBeta.path);

  PatrolFinder appGridOverlay() => $(AppGridDashboardOverlay);

  @override
  bool isAppGridButtonVisible() => appGridButton().exists;

  @override
  bool isHelpButtonVisible() =>
      $(find.byKey(const ValueKey('AppHelpTooltip'))).exists;

  @override
  bool isAppGridOpen() => appGridOverlay().exists;

  @override
  List<String> getVisibleAppNames() {
    return find
        .descendant(
          of: find.byType(AppGridDashboardItem),
          matching: find.byType(Text),
        )
        .evaluate()
        .map((element) => (element.widget as Text).data)
        .whereType<String>()
        .toList();
  }

  @override
  List<String> getVisibleAppLinks() {
    return find
        .descendant(
          of: find.byType(AppGridDashboardItem),
          matching: find.byType(LinkBrowserWidget),
        )
        .evaluate()
        .map((element) => (element.widget as LinkBrowserWidget).uri.toString())
        .toList();
  }

  @override
  Future<void> openAppGrid() async {
    await $.waitUntilVisible(appGridButton());
    await appGridButton().tap();
    await $.waitUntilVisible($(AppGridDashboardItem));
  }

  @override
  Future<void> closeAppGridByTappingButton() async {
    await appGridButton().tap();
    await waitUntilAbsent($, appGridOverlay());
  }

  @override
  Future<void> closeAppGridByTappingOutside() async {
    await twakeLogo().tap();
    await waitUntilAbsent($, appGridOverlay());
  }
}
