import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/go_routes/go_router.dart';
import 'package:fluffychat/config/localizations/localization_service.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/di/global/get_it_initializer.dart';
import 'package:fluffychat/utils/custom_scroll_behaviour.dart';
import 'package:fluffychat/utils/network_connection_service.dart';
import 'package:fluffychat/widgets/theme_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

import 'matrix.dart';

class TwakeApp extends StatefulWidget {
  final Widget? testWidget;
  final List<Client> clients;
  static GlobalKey<NavigatorState> routerKey = GlobalKey<NavigatorState>();

  const TwakeApp({
    super.key,
    this.testWidget,
    required this.clients,
  });

  /// getInitialLink may rereturn the value multiple times if this view is
  /// opened multiple times for example if the user logs out after they logged
  /// in with qr code or magic link.
  static bool gotInitialLink = false;

  // Router must be outside of build method so that hot reload does not reset
  // the current path.
  static final GoRouter router = GoRouter(
    routes: AppRoutes.routes,
    debugLogDiagnostics: true,
    navigatorKey: routerKey,
    onException: (context, state, router) {
      Logs().e('GoRouter exception: ${state.error}');
      return router.go('/error');
    },
  );

  @override
  TwakeAppState createState() => TwakeAppState();
}

class TwakeAppState extends State<TwakeApp> {
  final networkConnectionService = getIt.get<NetworkConnectionService>();

  @override
  void initState() {
    super.initState();
    networkConnectionService.onInit();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      LocalizationService.currentLocale.value =
          await LocalizationService.getLocaleFromLanguage(
        context: context,
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    networkConnectionService.onDispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeBuilder(
      builder: (context, themeMode, primaryColor) => ValueListenableBuilder(
        valueListenable: LocalizationService.currentLocale,
        builder: (context, local, _) {
          return MaterialApp.router(
            restorationScopeId: 'Twake',
            title: AppConfig.applicationName,
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: TwakeThemes.buildTheme(
              context,
              Brightness.light,
              primaryColor,
            ),
            darkTheme: TwakeThemes.buildTheme(
              context,
              Brightness.light,
              primaryColor,
            ),
            scrollBehavior: CustomScrollBehavior(),
            localizationsDelegates: const [
              LocaleNamesLocalizationsDelegate(),
              L10n.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: LocalizationService.supportedLocales,
            locale: local,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              for (final locale in supportedLocales) {
                if (locale.languageCode == deviceLocale?.languageCode) {
                  return deviceLocale;
                }
              }
              return supportedLocales.first;
            },
            routerConfig: TwakeApp.router,
            builder: (context, child) => Matrix(
              clients: widget.clients,
              child: child,
            ),
          );
        },
      ),
    );
  }
}
