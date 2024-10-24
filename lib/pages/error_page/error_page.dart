import 'package:fluffychat/pages/error_page/error_page_style.dart';
import 'package:fluffychat/resource/image_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:go_router/go_router.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Add invisible appbar to make status bar on Android tablets bright.
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      extendBodyBehindAppBar: true,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ErrorPageStyle.responsiveUtils.isMobile(context)
                ? const _ErrorPageBackgroundMobile()
                : const _ErrorPageBackgroundWeb(),
            const _ErrorPageText(),
            const _ErrorPageBackButton(),
          ],
        ),
      ),
    );
  }
}

class _ErrorPageBackgroundWeb extends StatelessWidget {
  const _ErrorPageBackgroundWeb();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SvgPicture.asset(
          ImagePaths.icErrorPageBackground,
          colorFilter: ErrorPageStyle.backgroundColorFilter(context),
          fit: BoxFit.contain,
        ),
        SvgPicture.asset(
          ImagePaths.icErrorPage,
          width: ErrorPageStyle.backgroundIconWidthWeb,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

class _ErrorPageBackgroundMobile extends StatelessWidget {
  const _ErrorPageBackgroundMobile();

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      ImagePaths.icErrorPage,
      width: ErrorPageStyle.backgroundIconWidthMobile,
      fit: BoxFit.contain,
    );
  }
}

class _ErrorPageBackButton extends StatelessWidget {
  const _ErrorPageBackButton();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(
        Icons.chevron_left_outlined,
      ),
      onPressed: () => _goToRooms(context),
      label: Text(
        L10n.of(context)!.errorPageButton,
      ),
      style: ErrorPageStyle.buttonStyle(context),
    );
  }

  void _goToRooms(BuildContext context) {
    context.go('/rooms');
  }
}

class _ErrorPageText extends StatelessWidget {
  const _ErrorPageText();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ErrorPageStyle.textPadding,
      child: Column(
        children: [
          Text(
            L10n.of(context)!.errorPageTitle,
            style: ErrorPageStyle.titleTextStyle(context),
          ),
          const SizedBox(height: ErrorPageStyle.textsGap),
          Text(
            L10n.of(context)!.errorPageDescription,
            style: ErrorPageStyle.descriptionTextStyle(context),
          ),
        ],
      ),
    );
  }
}
