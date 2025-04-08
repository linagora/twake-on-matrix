import 'package:flutter/material.dart';
import 'package:super_context_menu/super_context_menu.dart';

class CustomMobileMenuWidgetBuilder extends DefaultMobileMenuWidgetBuilder {
  CustomMobileMenuWidgetBuilder({
    super.brightness,
  }) : super(
          enableBackgroundBlur: true,
        );

  @override
  Widget buildOverlayBackground(BuildContext context, double opacity) {
    return Opacity(
      opacity: opacity,
      child: Container(
        color: Colors.transparent,
      ),
    );
  }
}
