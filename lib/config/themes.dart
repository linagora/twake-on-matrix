import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/responsive/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:linagora_design_flutter/colors/linagora_ref_colors.dart';
import 'package:linagora_design_flutter/colors/linagora_sys_colors.dart';

import 'app_config.dart';

abstract class TwakeThemes {
  static const double columnWidth = 360.0;
  static const double iconSize = 24.0;

  static bool isColumnModeByWidth(double width) => width > columnWidth * 2 + 64;

  static bool isColumnMode(BuildContext context) =>
      isColumnModeByWidth(MediaQuery.sizeOf(context).width);

  static bool getDisplayNavigationRail(BuildContext context) =>
      !(GoRouterState.of(context).path?.startsWith('/settings') == true);

  static ResponsiveUtils responsive = getIt.get<ResponsiveUtils>();

  static var fallbackTextTheme = const TextTheme(
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: -0.15,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.25,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.4,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
    ),
    displayLarge: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w700,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      fontSize: 32,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w600,
      letterSpacing: -0.15,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
    ),
  );

  static const Duration animationDuration = Duration(milliseconds: 250);
  static const Curve animationCurve = Curves.easeInOut;

  static ThemeData buildTheme(
    BuildContext context,
    Brightness brightness, [
    Color? seed,
  ]) =>
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
        scaffoldBackgroundColor: LinagoraSysColors.material().onPrimary,
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
          toolbarHeight: AppConfig.toolbarHeight(context),
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
          backgroundColor: LinagoraSysColors.material().onPrimary,
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
        highlightColor: LinagoraRefColors.material().tertiary[80],
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
          // TODO: remove when the color scheme is updated
          // ignore: deprecated_member_use
          background: brightness == Brightness.light
              ? LinagoraSysColors.material().background
              : LinagoraSysColors.material().backgroundDark,
          // TODO: remove when the color scheme is updated
          // ignore: deprecated_member_use
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
          surfaceContainerHighest: brightness == Brightness.light
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
            iconSize: WidgetStateProperty.all(iconSize),
            iconColor: WidgetStateProperty.all(
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
          overlayColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
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
          thumbColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return brightness == Brightness.light
                    ? LinagoraSysColors.material().onPrimary
                    : LinagoraSysColors.material().onPrimaryDark;
              } else {
                return brightness == Brightness.light
                    ? LinagoraSysColors.material().outline
                    : LinagoraSysColors.material().outlineDark;
              }
            },
          ),
          trackColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.selected)) {
                return brightness == Brightness.light
                    ? LinagoraSysColors.material().primary
                    : LinagoraSysColors.material().primaryDark;
              } else {
                return brightness == Brightness.light
                    ? LinagoraSysColors.material().surface
                    : LinagoraSysColors.material().surfaceDark;
              }
            },
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return fallbackTextTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  color: LinagoraSysColors.material().primary,
                );
              }
              return responsive.isDesktop(context)
                  ? fallbackTextTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: LinagoraRefColors.material().neutral[10],
                    )
                  : fallbackTextTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: LinagoraSysColors.material().tertiary,
                    );
            },
          ),
          backgroundColor: brightness == Brightness.light
              ? LinagoraSysColors.material().surface
              : LinagoraSysColors.material().surfaceDark,
          shadowColor: brightness == Brightness.light
              ? Colors.black.withOpacity(0.15)
              : Colors.white.withOpacity(0.15),
          elevation: 4.0,
          overlayColor: WidgetStateColor.resolveWith(
            (states) {
              return Colors.transparent;
            },
          ),
        ),
        navigationRailTheme: NavigationRailThemeData(
          indicatorColor: brightness == Brightness.light
              ? LinagoraSysColors.material().inversePrimary
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
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: LinagoraSysColors.material().surface,
          selectedLabelStyle: fallbackTextTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: LinagoraSysColors.material().primary,
          ),
          unselectedLabelStyle: fallbackTextTheme.labelSmall?.copyWith(
            fontSize: 11,
            color: LinagoraSysColors.material().tertiary,
          ),
          selectedItemColor: LinagoraSysColors.material().primary,
          unselectedItemColor: LinagoraSysColors.material().tertiary,
        ),
      );
}

extension on Brightness {
  Brightness get reversed =>
      this == Brightness.dark ? Brightness.light : Brightness.dark;
}
