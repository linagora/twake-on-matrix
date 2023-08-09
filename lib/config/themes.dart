import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import 'app_config.dart';

abstract class FluffyThemes {
  static const double columnWidth = 360.0;
  static const double iconSize = 24.0;

  static bool isColumnModeByWidth(double width) => width > columnWidth * 2 + 64;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.of(context).size.width);

  static bool getDisplayNavigationRail(BuildContext context) =>
      !(GoRouterState.of(context).path?.startsWith('/settings') == true);

  static const fallbackTextStyle = TextStyle(
    fontFamily: 'Inter',
    fontFamilyFallback: ['Inter'],
  );

  static var fallbackTextTheme = TextTheme(
    bodyLarge: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: -0.15,
    ),
    bodyMedium: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.25,
    ),
    bodySmall: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
    labelLarge: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelSmall: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    displayLarge: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w700,
    ),
    displayMedium: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    displaySmall: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    headlineMedium: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    titleLarge: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w600,
    ),
    titleMedium: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: fallbackTextStyle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  );

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Curve animationCurve = Curves.easeInOut;

  static ThemeData buildTheme(Brightness brightness, [Color? seed]) =>
      ThemeData(
        visualDensity: VisualDensity.standard,
        useMaterial3: true,
        fontFamily: 'Inter',
        textTheme: brightness == Brightness.light
            ? Typography.material2021().black.merge(fallbackTextTheme)
            : Typography.material2021().white.merge(fallbackTextTheme),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
        dividerColor: brightness == Brightness.light
            ? Colors.blueGrey.shade50
            : Colors.blueGrey.shade900,
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: UnderlineInputBorder(
            borderSide: BorderSide.none,
            borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
          ),
          hintStyle: fallbackTextTheme.bodyLarge?.merge(
            TextStyle(
              fontSize: 17,
              color: LinagoraRefColors.material().neutralVariant[60],
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          scrolledUnderElevation: 0,
          titleSpacing: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: brightness.reversed,
            statusBarBrightness: brightness,
          ),
          foregroundColor: brightness == Brightness.light
              ? LinagoraSysColors.material().onBackground
              : LinagoraSysColors.material().onBackgroundDark,
          backgroundColor: brightness == Brightness.light
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().backgroundDark,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
            ),
          ),
        ),
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConfig.borderRadius / 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(16),
            textStyle: const TextStyle(fontSize: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConfig.borderRadius),
            ),
          ),
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed ?? AppConfig.colorSchemeSeed,
          brightness: brightness,
          primary: brightness == Brightness.light
              ? LinagoraSysColors.material().primary
              : LinagoraSysColors.material().primaryDark,
          onPrimary: brightness == Brightness.light
              ? LinagoraSysColors.material().onPrimary
              : LinagoraSysColors.material().onPrimaryDark,
          primaryContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().primaryContainer
              : LinagoraSysColors.material().primaryContainerDark,
          onPrimaryContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().onPrimaryContainer
              : LinagoraSysColors.material().onPrimaryContainerDark,
          inversePrimary: brightness == Brightness.light
              ? LinagoraSysColors.material().inversePrimary
              : LinagoraSysColors.material().inversePrimaryDark,
          tertiary: brightness == Brightness.light
              ? LinagoraSysColors.material().tertiary
              : LinagoraSysColors.material().tertiaryDark,
          onTertiary: brightness == Brightness.light
              ? LinagoraSysColors.material().onTertiary
              : LinagoraSysColors.material().onTertiaryDark,
          tertiaryContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().tertiaryContainer
              : LinagoraSysColors.material().tertiaryContainerDark,
          onTertiaryContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().onTertiaryContainer
              : LinagoraSysColors.material().onTertiaryContainerDark,
          secondary: brightness == Brightness.light
              ? LinagoraSysColors.material().secondary
              : LinagoraSysColors.material().secondaryDark,
          onSecondary: brightness == Brightness.light
              ? LinagoraSysColors.material().onSecondary
              : LinagoraSysColors.material().onSecondaryDark,
          secondaryContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().secondaryContainer
              : LinagoraSysColors.material().secondaryContainerDark,
          onSecondaryContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().onSecondaryContainer
              : LinagoraSysColors.material().onSecondaryContainerDark,
          background: brightness == Brightness.light
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().backgroundDark,
          onBackground: brightness == Brightness.light
              ? LinagoraSysColors.material().onBackground
              : LinagoraSysColors.material().onBackgroundDark,
          error: brightness == Brightness.light
              ? LinagoraSysColors.material().error
              : LinagoraSysColors.material().errorDark,
          onError: brightness == Brightness.light
              ? LinagoraSysColors.material().onError
              : LinagoraSysColors.material().onErrorDark,
          errorContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().errorContainer
              : LinagoraSysColors.material().errorContainerDark,
          onErrorContainer: brightness == Brightness.light
              ? LinagoraSysColors.material().onErrorContainer
              : LinagoraSysColors.material().onErrorContainerDark,
          surface: brightness == Brightness.light
              ? LinagoraSysColors.material().surface
              : LinagoraSysColors.material().surfaceDark,
          onSurface: brightness == Brightness.light
              ? LinagoraSysColors.material().onSurface
              : LinagoraSysColors.material().onSurfaceDark,
          surfaceTint: brightness == Brightness.light
              ? LinagoraSysColors.material().surfaceTint
              : LinagoraSysColors.material().surfaceTintDark,
          surfaceVariant: brightness == Brightness.light
              ? LinagoraSysColors.material().surfaceVariant
              : LinagoraSysColors.material().surfaceVariantDark,
          onSurfaceVariant: brightness == Brightness.light
              ? LinagoraSysColors.material().onSurfaceVariant
              : LinagoraSysColors.material().onSurfaceVariantDark,
          inverseSurface: brightness == Brightness.light
              ? LinagoraSysColors.material().inverseSurface
              : LinagoraSysColors.material().inverseSurfaceDark,
          onInverseSurface: brightness == Brightness.light
              ? LinagoraSysColors.material().onInverseSurface
              : LinagoraSysColors.material().onInverseSurfaceDark,
          shadow: brightness == Brightness.light
              ? LinagoraSysColors.material().shadow
              : LinagoraSysColors.material().shadowDark,
          outline: brightness == Brightness.light
              ? LinagoraSysColors.material().outline
              : LinagoraSysColors.material().outlineDark,
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: brightness == Brightness.light
              ? LinagoraSysColors.material().primary
              : LinagoraSysColors.material().primaryDark,
        ),
        iconButtonTheme: IconButtonThemeData(
          style: ButtonStyle(
            iconSize: MaterialStateProperty.all(iconSize),
            iconColor: MaterialStateProperty.all(
              brightness == Brightness.light
                  ? LinagoraSysColors.material().onSurface
                  : LinagoraSysColors.material().onSurfaceDark,
            ),
          ),
        ),
        iconTheme: IconThemeData(
          size: iconSize,
          color: brightness == Brightness.light
              ? LinagoraSysColors.material().onBackground
              : LinagoraSysColors.material().onBackgroundDark,
        ),
        switchTheme: SwitchThemeData(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return brightness == Brightness.light
                    ? LinagoraSysColors.material().primary
                    : LinagoraSysColors.material().primaryDark;
              } else {
                return brightness == Brightness.light
                    ? LinagoraSysColors.material().outline
                    : LinagoraSysColors.material().outlineDark;
              }
            },
          ),
          thumbColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return brightness == Brightness.light
                  ? LinagoraSysColors.material().onPrimary
                  : LinagoraSysColors.material().onPrimaryDark;
            } else {
              return brightness == Brightness.light
                  ? LinagoraSysColors.material().outline
                  : LinagoraSysColors.material().outlineDark;
            }
          }),
          trackColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return brightness == Brightness.light
                  ? LinagoraSysColors.material().primary
                  : LinagoraSysColors.material().primaryDark;
            } else {
              return brightness == Brightness.light
                  ? LinagoraSysColors.material().surface
                  : LinagoraSysColors.material().surfaceDark;
            }
          }),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 64,
          backgroundColor: brightness == Brightness.light
              ? LinagoraSysColors.material().surface
              : LinagoraSysColors.material().surfaceDark,
          shadowColor: brightness == Brightness.light
              ? Colors.black.withOpacity(0.15)
              : Colors.white.withOpacity(0.15),
          elevation: 4.0,
        ),
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: brightness == Brightness.light
              ? LinagoraSysColors.material().secondaryContainer
              : LinagoraSysColors.material().secondaryContainerDark,
        ),
        bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: brightness == Brightness.light
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().backgroundDark,
          surfaceTintColor: brightness == Brightness.light
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().backgroundDark,
        ),
      );
}

extension on Brightness {
  Brightness get reversed =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}
