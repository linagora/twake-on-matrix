import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_route_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AppAdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? secondaryBody;
  final bool? displayAppBar;

  static const scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const breakpointMobileKey = Key('BreakPointMobile');

  static const breakpointWebAndDesktopKey = Key('BreakpointWebAndDesktopKey');

  const AppAdaptiveScaffold({
    Key? key,
    required this.body,
    this.secondaryBody,
    this.displayAppBar = true,
  }) : super(key: key ?? scaffoldWithNestedNavigationKey);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: displayAppBar == true ? const AdaptiveScaffoldAppBar() : null,
      body: AdaptiveLayout(
        internalAnimations: false,
        body: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            const WidthPlatformBreakpoint(
              end: ResponsiveUtils.maxMobileWidth,
            ): SlotLayout.from(
              key: breakpointMobileKey,
              builder: (_) => secondaryBody != null
                  ? _secondaryBodyWidget(context, isWebAndDesktop: false)
                  : _bodyWidget(context, isWebAndDesktop: false),
            ),
            const WidthPlatformBreakpoint(
              begin: ResponsiveUtils.minTabletWidth,
            ): SlotLayout.from(
              key: breakpointWebAndDesktopKey,
              builder: (_) => _bodyWidget(context),
            ),
          },
        ),
        bodyRatio: ResponsiveUtils.bodyRadioWidth / context.width,
        secondaryBody: SlotLayout(
          config: <Breakpoint, SlotLayoutConfig>{
            const WidthPlatformBreakpoint(end: ResponsiveUtils.maxMobileWidth):
                SlotLayout.from(
              key: breakpointMobileKey,
              builder: null,
            ),
            const WidthPlatformBreakpoint(
              begin: ResponsiveUtils.minTabletWidth,
            ): SlotLayout.from(
              key: breakpointWebAndDesktopKey,
              builder: secondaryBody != null
                  ? (_) => _secondaryBodyWidget(context)
                  : AdaptiveScaffold.emptyBuilder,
            ),
          },
        ),
      ),
    );
  }

  Widget _secondaryBodyWidget(
    BuildContext context, {
    bool isWebAndDesktop = true,
  }) {
    return Padding(
      padding: AdaptiveScaffoldRouteStyle.secondaryBodyWidgetPadding(
        isWebAndDesktop,
      ),
      child: ClipRRect(
        borderRadius:
            AdaptiveScaffoldRouteStyle.secondaryBodyBorder(isWebAndDesktop),
        child: Container(
          decoration: BoxDecoration(
            color: LinagoraRefColors.material().primary[100],
          ),
          child: secondaryBody,
        ),
      ),
    );
  }

  Widget _bodyWidget(
    BuildContext context, {
    bool isWebAndDesktop = true,
  }) {
    return Padding(
      padding: AdaptiveScaffoldRouteStyle.bodyWidgetPadding(
        context,
        isWebAndDesktop,
      ),
      child: body,
    );
  }
}
