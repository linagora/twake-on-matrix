import 'package:fluffychat/presentation/widget_keys/widget_keys.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_route_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AppAdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? secondaryBody;
  final bool? displayAppBar;

  const AppAdaptiveScaffold({
    super.key,
    required this.body,
    this.secondaryBody,
    this.displayAppBar = true,
  });

  static final _responsiveUtils = ResponsiveUtils();

  @override
  Widget build(BuildContext context) {
    return Portal(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Column(
              children: [
                const AdaptiveScaffoldAppBar(),
                Expanded(
                  child: AdaptiveLayout(
                    internalAnimations: false,
                    body: SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig>{
                        const WidthPlatformBreakpoint(
                          end: ResponsiveUtils.maxMobileWidth,
                        ): SlotLayout.from(
                          key: NavigationKeys.breakpointMobile.key,
                          builder: (_) => secondaryBody != null
                              ? _secondaryBodyWidget(
                                  context,
                                  isWebAndDesktop: false,
                                )
                              : _bodyWidget(context, isWebAndDesktop: false),
                        ),
                        const WidthPlatformBreakpoint(
                          begin: ResponsiveUtils.minTabletWidth,
                        ): SlotLayout.from(
                          key: NavigationKeys.breakpointWebAndDesktop.key,
                          builder: (_) => _bodyWidget(context),
                        ),
                      },
                    ),
                    bodyRatio: _responsiveUtils.getChatBodyRatio(context),
                    secondaryBody: SlotLayout(
                      config: <Breakpoint, SlotLayoutConfig>{
                        const WidthPlatformBreakpoint(
                          end: ResponsiveUtils.maxMobileWidth,
                        ): SlotLayout.from(
                          key: NavigationKeys.breakpointMobile.key,
                          builder: null,
                        ),
                        const WidthPlatformBreakpoint(
                          begin: ResponsiveUtils.minTabletWidth,
                        ): SlotLayout.from(
                          key: NavigationKeys.breakpointWebAndDesktop.key,
                          builder: secondaryBody != null
                              ? (_) => _secondaryBodyWidget(context)
                              : AdaptiveScaffold.emptyBuilder,
                        ),
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryBodyWidget(
    BuildContext context, {
    bool isWebAndDesktop = true,
  }) {
    return Padding(
      padding: AdaptiveScaffoldRouteStyle.secondaryBodyWidgetPadding(
        context,
        isWebAndDesktop,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: LinagoraSysColors.material().surface,
              width: 1.0,
            ),
          ),
        ),
        child: secondaryBody,
      ),
    );
  }

  Widget _bodyWidget(BuildContext context, {bool isWebAndDesktop = true}) {
    return Padding(
      padding: AdaptiveScaffoldRouteStyle.bodyWidgetPadding(
        context,
        isWebAndDesktop,
      ),
      child: body,
    );
  }
}
