import 'package:fluffychat/utils/extension/build_context_extension.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:fluffychat/widgets/layouts/adaptive_layout/adaptive_scaffold_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_scaffold/flutter_adaptive_scaffold.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class AdaptiveScaffoldRoute extends StatelessWidget {
  final Widget body;
  final Widget? secondaryBody;
  final bool? displayAppBar;

  static const scaffoldWithNestedNavigationKey =
      ValueKey('ScaffoldWithNestedNavigation');

  static const breakpointMobileKey = Key('BreakPointMobile');

  static const breakpointWebAndDesktopKey = Key('BreakpointWebAndDesktopKey');

  const AdaptiveScaffoldRoute({
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
                  : _bodyWidget(isWebAndDesktop: false),
            ),
            const WidthPlatformBreakpoint(
              begin: ResponsiveUtils.minTabletWidth,
            ): SlotLayout.from(
              key: breakpointWebAndDesktopKey,
              builder: (_) => _bodyWidget(),
            )
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
            )
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
      padding: isWebAndDesktop
          ? const EdgeInsetsDirectional.all(16)
          : EdgeInsetsDirectional.zero,
      child: ClipRRect(
        borderRadius: isWebAndDesktop
            ? const BorderRadius.all(Radius.circular(16.0))
            : BorderRadius.zero,
        child: Container(
          decoration: BoxDecoration(
            color: LinagoraRefColors.material().primary[100],
          ),
          child: secondaryBody,
        ),
      ),
    );
  }

  Widget _bodyWidget({bool isWebAndDesktop = true}) {
    return Padding(
      padding: isWebAndDesktop
          ? const EdgeInsetsDirectional.only(bottom: 16, top: 16)
          : EdgeInsetsDirectional.zero,
      child: body,
    );
  }
}
