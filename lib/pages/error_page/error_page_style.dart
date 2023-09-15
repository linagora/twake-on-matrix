import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:linagora_design_flutter/linagora_design_flutter.dart';

class ErrorPageStyle {
  static final ResponsiveUtils responsiveUtils = getIt.get<ResponsiveUtils>();

  static ColorFilter backgroundColorFilter(BuildContext context) =>
      ColorFilter.mode(
        Theme.of(context).colorScheme.primaryContainer,
        BlendMode.srcATop,
      );

  static const double backgroundIconWidthWeb = 448.0;
  static const double backgroundIconWidthMobile = 280.0;

  static const EdgeInsets textPadding = EdgeInsets.symmetric(vertical: 32.0);

  static TextStyle? titleTextStyle(BuildContext context) =>
      ErrorPageStyle.responsiveUtils.isMobile(context)
          ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              )
          : Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              );
  static TextStyle? descriptionTextStyle(BuildContext context) =>
      ErrorPageStyle.responsiveUtils.isMobile(context)
          ? Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: LinagoraRefColors.material().tertiary[20],
              )
          : Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: LinagoraRefColors.material().tertiary[20],
              );

  static ButtonStyle buttonStyle(BuildContext context) => ButtonStyle(
        iconSize: MaterialStateProperty.all<double>(18),
        textStyle: MaterialStateProperty.all(
          Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
        ),
        backgroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        foregroundColor: MaterialStateProperty.all<Color>(
          Theme.of(context).colorScheme.onPrimary,
        ),
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      );

  static const double textsGap = 12.0;
}
