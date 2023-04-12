import 'package:flutter/material.dart';

import '../../config/themes.dart';

class TwoColumnLayout extends StatelessWidget {
  final Widget mainView;
  final Widget sideView;

  const TwoColumnLayout({
    Key? key,
    required this.mainView,
    required this.sideView,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xfff0f0f0)
            : const Color(0x000e0e0f),
        body: Row(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 16.0, bottom: 16.0, right: 16.0),
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(),
              width: 360.0 +
                  (FluffyThemes.getDisplayNavigationRail(context) ? 64 : 0),
              child: mainView,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.0),
                  child: sideView,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
